########################################################################
# File::    poll.rb
# (C)::     Hipposoft 2011
#
# Purpose:: Describe a bounty poll.
# ----------------------------------------------------------------------
#           30-Jan-2011 (ADH): Created.
########################################################################

class Poll < ActiveRecord::Base

  acts_as_audited :protect => false, :except => [ :total_for_sorting ]

  belongs_to :user
  belongs_to :currency
  has_many   :donations

  # Limitations and requirements.

  MAXLEN_TITLE = 60
  MAXLEN_STATE = 16 # See STATE MACHINE below

  validates_presence_of     :title,
                            :description,
                            :workflow_state

  validates_numericality_of :total_integer,
                            :total_fraction,

                            :only_integer => true

  validate :currency_alteration_is_permitted

  def currency_alteration_is_permitted
    if ( changes.has_key?( 'currency_id' ) && votes > 0 )
      errors.add( :currency_id, :cannot_change_currency )
    end
  end

  attr_accessible :title,
                  :description,
                  :currency_id

  # Keep a for-sorting cache column up to date.
  #
  def update_sorting_amount
    amount = Currency.simplify(
      self.total_integer,
      self.total_fraction
    ).to_f

    self.total_for_sorting = amount
  end

  before_save :update_sorting_amount

  # How many entries to list per index page? See the Will Paginate plugin:
  #
  #   http://wiki.github.com/mislav/will_paginate

  def self.per_page
    MAXIMUM_LIST_ITEMS_PER_PAGE
  end

  # Search columns for views rendering the "shared/_simple_search.html.erb"
  # view partial and using "appctrl_build_search_conditions" to handle queries.

  SEARCH_COLUMNS = %w{ workflow_state#pollhelp_search_states title description total_for_sorting }

  # Set up sorting based on current locale. See Application Controller's
  # "set_language_dependent_sorting" method for details.

  SORT_COLUMNS = %w{title workflow_state votes total_for_sorting}

  def self.set_sorting
    columns = self.translated_sort_columns()
    sort_on( *columns )
  end

  # ===========================================================================
  # TRANSLATION
  # ===========================================================================

  # See "prepare_model_for_translation" in "translations_controller.rb" and the
  # migrations.
  #
  # (In Canvass, the Translations Controller is not present - this was imported
  # from Artisan which has a full GUI for translation editing and creation).
  #
  def self.columns_for_translation
    [ 'title', 'description' ]
  end

  def self.column_type( name )
    case name.to_sym
      when :title
        :string
      when :description
        :text
    end
  end

  def self.column_options( name )
    case name.to_sym
      when :title
        { :limit => Poll::MAXLEN_TITLE }
      when :description
        {}
    end
  end

  # See the "translatable_columns" plugin:
  #
  #   http://github.com/iain/translatable_columns/tree/master
  #   http://iain.nl/2008/09/plugin-translatable_columns/

  translatable_columns( *columns_for_translation() )

  def self.translated_column( name )
    Translation.translated_column( self, name ) # See this for details
  end

  def self.untranslated_column( name_with_locale )
    Translation.untranslated_column( self, name_with_locale ) # See this for details
  end

  # Return a list of translated, sortable columns.
  #
  def self.translated_sort_columns
    SORT_COLUMNS.map { | name | self.translated_column( name ) }
  end

  # ===========================================================================
  # PERMISSIONS
  # ===========================================================================

  # N/A

  # ===========================================================================
  # STATE MACHINE
  # ===========================================================================

  STATE_INITIAL   = :initial # Unused and not valid but kept for convenience and use with InvoiceableHelper methods

  STATE_OPEN      = :a_open
  STATE_UNDERWAY  = :b_underway
  STATE_COMPLETED = :c_completed
  STATE_EXPIRED   = :d_expired

  # Must use "table_exists?", as Workflow needs to check the database but this
  # class may be examined by migrations before the table is created.

  if ( Poll.table_exists? )
    include Workflow # http://github.com/geekq/workflow
    workflow do

      # ***********************************************************************
      # WARNING! You must always wrap state changes herein with a transaction
      # block as other objects may be updated as a result of the state change;
      # inconsistencies will result if one or more of these alterations fail
      # without rollback.
      #
      # WARNING! Take note of the error flagging behaviour of transitions into
      # the STATE_EXPIRED state.
      # ***********************************************************************

      # STATE_OPEN: The poll has been created and people can vote on it.
      #
      state STATE_OPEN do
        event :underway, :transitions_to => STATE_UNDERWAY
        event :expired,  :transitions_to => STATE_EXPIRED
      end

      # STATE_UNDERWAY: The poll has received sufficient votes to attract a
      # developer and work on the associated feature is underway. The poll
      # cannot be voted for.
      #
      # Administrators can still choose to expire a poll if they wish, should
      # the developer be taking "too long" to complete the work. That's up to
      # individual administrators or organisations to assess.
      #
      # Organisations may choose to pay developers before or after they
      # complete work. The general recommendation is to do so only when the
      # poll reaches a STATE_COMPLETED state, but again, individual
      # administrators or organisations need to decide this themselves.
      #
      state STATE_UNDERWAY do
        event :completed, :transitions_to => STATE_COMPLETED
        event :expired,   :transitions_to => STATE_EXPIRED
      end

      # STATE_COMPLETED: Work on the poll completed; the associated feature is
      # implemented to the satisfaction of the administrators. The poll is
      # now closed/archived and cannot be voted for.
      #
      # The developer(s) who worked on the feature must now be paid, if they
      # haven't already (this is something for administrators to do outside
      # of Canvass, usually through e.g. PayPal).
      #
      state STATE_COMPLETED do
      end

      # STATE_EXPIRED: For any reason, administrators may choose to expire a
      # poll. Money allocated to this poll will be redistributed to all other
      # open polls in a linear fashion.
      #
      # If an exception is raised with an empty message, then an error message
      # has been added to the record's "workflow_state" attribute - this will
      # indicate that there are no other open polls using the same currency so
      # donations cannot be redistributed (only if "this" poll has non-zero
      # votes). Non-empty messages indicate a genuine, unexpected fault.
      #
      state STATE_EXPIRED do
        on_entry do

          unless ( self.votes.zero? )
            conditions = {
              :conditions => {
                :workflow_state => Poll::STATE_OPEN.to_s,
                :currency_id    => self.currency_id
              }
            }

            open_poll_count = Poll.count( conditions )

            if ( open_poll_count.zero? )
              self.errors.add( :workflow_state, :no_others_open )
              raise "" # (sic.) - see comments above 'state STATE_EXPIRED do'.
            end

            Poll.transaction do
              self.lock!

              # Create a redistribution donation for the expired poll.

              take_donation                 = Donation.new
              take_donation.redistribution  = true
              take_donation.debit           = true
              take_donation.amount_integer  = self.total_integer
              take_donation.amount_fraction = self.total_fraction
              take_donation.user_id         = 0
              take_donation.user_name       = "-"
              take_donation.user_email      = "-"
              take_donation.poll            = self
              take_donation.poll_title      = self.title
              take_donation.currency        = self.currency

              take_donation.save!
              take_donation.paid!

              self.votes += 1 # Saving happens later, see below

              # To avoid rounding errors, keep dividing the amount left in this
              # pot by the number of other open polls to which we have yet to
              # redistribute funds. Round the result according to the poll's
              # currency, add it to one of the found other open polls, subtract
              # it from this poll's total, then go around the loop again,
              # re-dividing over and over until eventually at the last poll
              # there's a divide-by-one as the last remaining amount is added.

              polls_remaining = open_poll_count
              conditions[ :lock ] = true

              Poll.find_each( conditions ) do | poll |

                give_integer, give_fraction = Currency.divide(
                  self.total_integer, self.total_fraction,
                  polls_remaining.to_s
                )

                give_integer, give_fraction = self.currency.round(
                  Currency.simplify( give_integer, give_fraction )
                ).split( '.' )

                if ( give_integer != "0" || give_fraction != "0" )

                  give_donation                   = Donation.new
                  give_donation.redistribution    = true
                  give_donation.source_poll_id    = self.id
                  give_donation.source_poll_title = self.title
                  give_donation.amount_integer    = give_integer
                  give_donation.amount_fraction   = give_fraction
                  give_donation.user_id           = 0
                  give_donation.user_name         = "-"
                  give_donation.user_email        = "-"
                  give_donation.poll              = poll
                  give_donation.poll_title        = poll.title
                  give_donation.currency          = poll.currency

                  give_donation.save!
                  give_donation.paid!

                  self.total_integer, self.total_fraction = Currency.subtract(
                    self.total_integer, self.total_fraction,
                          give_integer,       give_fraction
                  )

                end

                polls_remaining -= 1

              end # 'Poll.find_each... do...'

              # There must always be *exactly* nothing left.

              unless ( self.total_integer == '0' && self.total_fraction == '0' )
                raise "Internal mathematical error during donation redistribution"
              end

              self.save!

            end   # 'Poll.transaction do'
          end     # 'unless ( self.votes.zero? )'
        end       # 'on_entry do'
      end         # 'state STATE_EXPIRED do'
    end           # 'workflow do'
  end             # 'if ( Poll.table_exists? )'

  # ===========================================================================
  # GENERAL
  # ===========================================================================

  # Apply a default sort to the given array of model instances. The array is
  # modified in place.
  #
  def self.apply_default_sort_order( array )
    array.sort! { | x, y | x.title <=> y.title }
  end

  def thingytest
    I18n.t("Hello")
  end

  # Returns an array of state name symbols to which this object may be
  # transitioned given its current state.
  #
  def allowed_new_states
    allowed_transitions = self.current_state.events.values.collect do | event |
      event.transitions_to
    end
  end
end
