######################################################################
# File::    donation.rb
# (C)::     Hipposoft 2011
#
# Purpose:: Keep track of donation payments.
# ----------------------------------------------------------------------
#           30-Jan-2011 (ADH): Created.
########################################################################

class Donation < Collectable

  # Note inheritance from Collectable.

  # ===========================================================================
  # CHARACTERISTICS
  # ===========================================================================

  acts_as_audited :except => [ :amount_for_sorting, :authorisation_tokens ]

  # The user's name and e-mail address along with the poll's title is copied
  # into the donation object. While it's useful to have a link back to the
  # original object in the database by ID, it's also useful to make sure that
  # the donation object stands alone should the user account or original poll
  # object be deleted for any reason.

  belongs_to :user
  belongs_to :poll
  belongs_to :currency

  serialize  :authorisation_tokens # A hash of tokens is stored here

  # Limitations and requirements.

  MAXLEN_STATE = 16 # See STATE MACHINE below

  # NB - *DO NOT* validate user names or e-mail addresses beyond "not blank".
  # In redistribution donations, these are set to "-" and the associated user
  # ID to "0". See "app/models/poll.rb".

  validates_presence_of     :user_id,
                            :user_name,
                            :user_email,
                            :poll_id,
                            :poll_title,
                            :currency_id,
                            :workflow_state

  validates_numericality_of :amount_integer,
                            :amount_fraction,

                            :only_integer => true

  validate :credit_donations_must_be_above_zero
  
  def credit_donations_must_be_above_zero
    if ( self.amount_for_sorting <= 0.0 && self.debit == false )
      self.errors.add :amount_for_sorting, :greater_than, :count => 0
    end
  end

  # Keep a for-sorting cache column up to date.
  #
  def update_sorting_amount
    amount = Currency.simplify(
      self.amount_integer,
      self.amount_fraction
    ).to_f

    amount = -amount if ( self.debit )
    self.amount_for_sorting = amount
  end

  before_validation :update_sorting_amount

  # See Jason King's "good_sort" plugin:
  #
  #   http://github.com/JasonKing/good_sort/tree/master
  #
  # As with Workflow (see later), must use a "table_exists?" check here.

  if ( Donation.table_exists? )
    sort_on( :updated_at,
             :poll_title,
             :user_name,
             :user_email,
             :amount_for_sorting )
  end

  # How many entries to list per index page? See the Will Paginate plugin:
  #
  #   http://wiki.github.com/mislav/will_paginate

  def self.per_page
    MAXIMUM_LIST_ITEMS_PER_PAGE
  end

  # Search columns for views rendering the "shared/_simple_search.html.erb"
  # view partial and using "appctrl_build_search_conditions" to handle queries.

  SEARCH_COLUMNS = %w{ poll_title user_name user_email amount_for_sorting }

  # ===========================================================================
  # PERMISSIONS
  # ===========================================================================

  # N/A

  # ===========================================================================
  # STATE MACHINE
  # ===========================================================================

  STATE_INITIAL = :initial
  STATE_PAID    = :paid

  # Must use "table_exists?", as Workflow needs to check the database but this
  # class may be examined by migrations before the table is created.

  if ( Donation.table_exists? )
    include Workflow # http://github.com/geekq/workflow
    workflow do

      # ***********************************************************************
      # WARNING! You must always wrap state changes herein with a transaction
      # block as other objects may be updated as a result of the state change;
      # inconsistencies will result if one or more of these alterations fail
      # without rollback.
      #
      # WARNING! Debit donations do not automatically update their associated
      # poll when saved. See comments below for more information.
      # ***********************************************************************

      # STATE_INITIAL: Payment is pending and not confirmed; subject to garbage
      # collection / timeout.
      #
      state STATE_INITIAL do
        event :paid, :transitions_to => STATE_PAID
      end

      # STATE_PAID: Payment has been made. We may find that the poll has gone
      # into a "non-donatable" state by now, though and have to give the user
      # their money back straight away - an edge case, but a genuine risk.
      # Must use pessimistic locking here to make sure that we get an exclusive
      # hold of the item and don't end up incrementing vote or total counts for
      # an object that's concurrently being updated in another request thread,
      # leading to a race condition with one or the other thread's changes
      # getting overwritten.
      #
      # DEBIT DONATIONS RESULTING FROM POLL EXPIRY AND FUNDS REDISTRIBUTION DO
      # NOT RESULT IN AUTOMATIC DECREMENTING OF THE ASSOCIATED POLL'S TOTALS OR
      # ANY CHANGE TO ITS VOTE COUNT. The creator of the debit donation is
      # responsible for this.
      #
      state STATE_PAID do
        on_entry do

          unless ( self.debit )
            Poll.transaction do # Transaction required for pessimistic lock

              # That ":lock => true" is enough to eventually mean that the
              # database layer works its magic and no matter how many threads
              # run this code concurrently, they'll end up seralised and each
              # work on an at-that-instant valid, up to date Poll object.

              poll = Poll.find_by_id( self.poll_id, :lock => true )

              if ( poll.nil? )
                raise I18n.t( :'activerecord.errors.models.donation.poll_has_vanished' )
              elsif ( poll.workflow_state.to_sym != Poll::STATE_OPEN )
                raise I18n.t( :'activerecord.errors.models.donation.poll_is_not_open' )
              end

              poll.votes = poll.votes + 1

              poll.total_integer, poll.total_fraction = Currency.add(
                poll.total_integer,
                poll.total_fraction,
                self.amount_integer,
                self.amount_fraction
              )

              poll.save!
            end # Transaction required for pessimistic lock
          end   # 'unless ( self.debit )'
        end     # 'on_entry do'
      end       # State machine block for STATE_PAID

    end
  end

  # ===========================================================================
  # GENERAL
  # ===========================================================================

  # Apply a default sort to the given array of model instances. The array is
  # modified in place. See also "default_sort_hash".
  #
  def self.apply_default_sort_order( array )
    array.sort! { | x, y | y.updated_at <=> y.updated_at }
  end

  # Return the default sort hash for Donations objects to avoid duplication
  # in the DonationsController and PollsController, both of which can generate
  # sortable lists of donations. The hash is suitable for passing as the
  # ":default_sorting" option to "appctrl_search_sort_and_paginate". See also
  # "apply_default_sort_order".
  #
  def self.default_sort_hash
    { 'down' => 'true', 'field' => 'updated_at' }
  end

  # See the Collectable superclass for details.
  #
  def self.garbage_collect( session )
    super(
      session,
      Donation,
      [
        '( updated_at < ? ) AND ( workflow_state = ? )',
        TIMEOUT.seconds.ago,
        STATE_INITIAL.to_s
      ]
    )
  end

  # Safely destroy all donations in STATE_INITIAL for the given user. There
  # should only be one of these, but just in case there are many, a transaction
  # is used so that destruction is done as an atomic operation in the database.
  #
  def self.safely_destroy_initial_state_donations_for( user )
    Donation.transaction do
      Donation.destroy_all(
       :user_id        => user.id,
       :workflow_state => Donation::STATE_INITIAL.to_s
      )
    end
  end

  # Return a conditions array, suitable for passing as a value to the
  # :conditions key in a 'find'-style operation, which returns only donations
  # that can be viewed by the user given in the last parameter.
  #
  # The first parameter can be e.g. a request's "params" hash - any has which
  # contains things like a 'user_id' key (or not), influencing the generated
  # constraints.
  #
  # The returned constraints ensure that initial state items are not found.
  #
  # Note that sensible results are only returned in the presence of a current
  # user value, so a user must be logged in if this method is called. Do NOT
  # try to pass 'nil' in the last parameter.
  #
  def self.conditions_for( params, current_user )
    user_id = params[ :user_id ]
    poll_id = params[ :poll_id ]

    # Only administrators can do anything other than list their own donations.
    # To keep life simple, only administrators can get per-poll donations.

    unless ( current_user.admin? )
      user_id = current_user.id
      poll_id = nil
    end

    # Generate the constraints array.

    constraints = 'workflow_state <> (?)'
    arguments   = [ Donation::STATE_INITIAL.to_s ]

    unless ( user_id.nil? )
      constraints << ' AND user_id = (?)'
      arguments   << user_id
    end

    unless ( poll_id.nil? )
      constraints << ' AND poll_id = (?)'
      arguments   << poll_id
    end

    return [ "(#{ constraints })" ] + arguments
  end

  # Build a Donation object for the given poll, donor, donation amount as
  # the integer part string and donation amount as the fraction part string.
  #
  # Throws an exception on failure, else has succeeded. Failure is unexpected
  # and no recovery is possible, beyond apologising to the user and maybe
  # asking them to try again later (while some sysadmin looks at the web server
  # and database trying to figure out what's wrong!). Returns a reference to
  # the new Donation instance upon success.
  #
  # Any initial state items belonging to the user on entry are deleted with a
  # call to "safely_destroy_initial_state_donations_for" since the new item
  # will supercede them. The new donation is in an initial state on exit. No
  # financial contributions are made to the associated poll until the payment
  # completes; see the state machine for details.
  #
  # THE OBJECT IS NOT SAVED to allow for validations to be checked at a higher
  # level. THE CALLER MUST SAVE THE OBJECT unless it is temporary.
  #
  # As a special case for administrators registering external donations, you
  # can pass override options in the last parameter for the recorded user name
  # and e-mail address. The donation is still recorded against the given User
  # in the second parameter - this should be the admin - but the name and
  # e-mail can be different (e.g. the admin fills this into a form). Set keys
  # ":external" to "true", ":name" to the human readable person's full name and
  # ":email" to the e-mail address. If nil, an empty string is stored. If you
  # fail to pass ":external => true" in the options, then the administrator's
  # in-progress initial state donations, if any, may be accidentally wiped.
  #
  def self.generate_for( poll, donor, donation_integer, donation_fraction, options = {} )

    self.safely_destroy_initial_state_donations_for( donor ) unless options[ :external ] == true

    return Donation.transaction do

      # In English as this is a debug-only exception.

      raise( "Associated poll cannot receive donations" ) if ( poll.workflow_state.to_sym != Poll::STATE_OPEN )

      # Create the new donation object.

      options[ :name  ] = donor.name  unless options.has_key?( :name  )
      options[ :email ] = donor.email unless options.has_key?( :email )

      donation = Donation.new(
        :user            => donor,
        :user_name       => options[ :name  ] || "",
        :user_email      => options[ :email ] || "",

        :poll            => poll,
        :poll_title      => poll.title,

        :currency        => poll.currency,

        :amount_integer  => donation_integer,
        :amount_fraction => donation_fraction
      )

      donation # Transaction block return value
    end        # "return Donation.transaction do"
  end

  # Send a notification e-mail message to the seller confirming their
  # purchase. For checks and balances, send one to 'admin' too. Why is this
  # done here, rather than inside the Purchase and Order model state change
  # transactions? Well:
  #
  # (1) We could allow sending failures to unwind the transactions and
  #     return the user to the cart with the purchase cancelled - but
  #     any messages sent before the one which failed would have gone
  #     out already, with very confusing consequences for users.
  #
  # (2) We could implement some kind of queueing mechanism. For example
  #     Retrospectiva extends Action Mailer to provide a queue which is
  #     persisted in the database and uses a cron-style scheduled task
  #     to periodically flush the mail queue. But this doesn't really
  #     gain us anything - either all messages send, or some fail but
  #     some have already been sent to people, whether we process the queue
  #     inside the purchase/order state change transaction blocks or not.
  #
  # Bottom line is we consider e-mail to be unreliable and NOT critical to
  # operations. If sending fails, we ignore it. But we must make sure that all
  # purchase and order state changes succeeded before starting to (try to) send
  # related messages. As a result, callers should only call this method when
  # they are sure that all relevant database updates to confirm a purchase and
  # its orders have been successfully committed.
  #
  # All errors inside this method are suppressed; exceptions are not thrown.
  #
  def send_new_item_notifications
    begin
      CanvassMailer.deliver_new_donation_made( self )
    rescue
      # Ignore everything.
    end

    begin
      CanvassMailer.deliver_new_donation_made_admin( self )
    rescue
      # Ignore everything.
    end
  end

  # Convert the internal integer and fraction amount strings into a quantity
  # expressed as a BigDecimal which is rounded and (if necessary) multiplied to
  # meet the requirements of the payment gateway, according to PaymentGateway's
  # 'get_amount_for_gateway' class method.
  #
  def amount_for_gateway
    return PaymentGateway.get_amount_for_gateway(
      BigDecimal.new(
        self.currency.round(
          Currency.simplify(
            self.amount_integer,
            self.amount_fraction
          )
        )
      )
    )
  end

private

  # May need to void a transaction if destroyed mid-way through the on-site
  # payment process. Do this once this and all associated objects have been
  # destroyed and this instance has been frozen - call via "after_destroy".
  #
  # The method tries to be as robust as possible, ignoring errors from any
  # particular token and trying its best to void all of the transactions.
  #
  def void_transaction_if_necessary
    unless ( authorisation_tokens.blank? )
      authorisation_tokens.values.each do | token |
        begin
          PaymentGateway.instance.gateway.void( token )
        rescue
          # Ignore failures; there's simply nothing we can do about them. The
          # reservation of money on the buyer's card will expire eventually. In
          # the mean time, keep trying for all of the tokens - others may work.
        end
      end
    end
  end

end
