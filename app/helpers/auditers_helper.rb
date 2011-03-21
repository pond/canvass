########################################################################
# File::    auditers_helper.rb
# (C)::     Hipposoft 2011
#
# Purpose:: Utility methods for audit-related views.
# ----------------------------------------------------------------------
#           23-Feb-2011 (ADH): Created.
########################################################################

module AuditersHelper

  # Return an HTML-safe description of a user's name from a given Auditer
  # record, linking to the User Controller's "show" action for that User if
  # the object still exists and dealing with 'nil' names in passing.
  #
  def auditershelp_user_link( record )
    if ( record.user.nil? )
      if ( record.username.blank? )
        apphelp_generic( :unknown )
      else
        h( record.username )
      end
    else
      link_to( h( record.user.name ), record.user )
    end
  end

  # Return an HTML table describing the changes in the given Auditer record
  # in human readable form.
  #
  def auditershelp_changes( record )
    type      = record.auditable_type
    changes   = record.changes
    model     = type.constantize
    translate = model.respond_to?( :columns_for_translation )

    return apphelp_view_hint( :no_other_details ) if ( changes.nil? or changes.empty? ) # Not 'changes.blank?', as this would ignore changes to 'false' since 'false.blank?' => 'true'

    output  = '<table border="1" cellspacing="1" cellpadding="1" class="audit_changes">'
    output << '<tr><th>' <<
              apphelp_view_hint( :change_details_field ) <<
              '</th><th>'
              
    if ( record.action == "create" )
      output << apphelp_view_hint( :change_details_became )
    elsif ( record.action == "destroy" )
      output << apphelp_view_hint( :change_details_was )
    else
      output << apphelp_view_hint( :change_details_from ) <<
                '</th><th>' <<
                apphelp_view_hint( :change_details_to )
    end

    output << '</th></tr>'

    # A sorted change table is easier to follow on the whole

    keys = changes.keys.sort do | a, b |
      if ( translate )
        a = model.untranslated_column( a )
        b = model.untranslated_column( b )
      end

      model.human_attribute_name( a ) <=> model.human_attribute_name( b )
    end

    # There's special support here for models containing a single currency
    # value split as integer and fraction strings.

    have_had_currency_value = false
    currency_keys           = %w{ amount_integer amount_fraction total_integer total_fraction }

    keys.each do | key |
      cdata = changes[ key ]
      key   = model.untranslated_column( key ) if ( translate )

      # Deal with amounts of money.

      if ( currency_keys.include?( key ) )
        next if ( have_had_currency_value )

        if ( model == Poll )
          integer_key  = 'total_integer'
          fraction_key = 'total_fraction'
        else # Assume any other model uses "amount"
          integer_key  = 'amount_integer'
          fraction_key = 'amount_fraction'
        end

        # We need to find the model instance in question in order to determine
        # its currency. If we can't, then we have to drop through to the 'raw'
        # display of change values below.

        model_instance = model.find_by_id( record.auditable_id )

        unless ( model_instance.nil? || model_instance.currency.nil? )

          integer_changes  = changes[ integer_key  ]
          fraction_changes = changes[ fraction_key ]

          # Changes may occur only in the integer or fraction part. In that case,
          # treat the unchanged part as a change from and to the current value
          # for the model.

          if ( integer_changes.nil? )
            integer_value    = model_instance.send( integer_key )
            integer_changes  = [ integer_value, integer_value ]
          elsif ( fraction_changes.nil? )
            fraction_value   = model_instance.send( fraction_key )
            fraction_changes = [ fraction_value, fraction_value ]
          end

          # The above code means that we might have synthesized change arrays
          # for an integer or fractin part, because only the corresponding
          # fraction or integer part had a change recorded. But if that change
          # was from 'unset'/nil to a value, the change record will be a single
          # item, not an array. We need to deal with the combination of arrays
          # and non-arrays.

          if ( ! integer_changes.is_a?( Array ) || ! fraction_changes.is_a?( Array ) )
            integer_changes  = integer_changes[ 0 ] if ( integer_changes.is_a?( Array ) )
            fraction_changes = fraction_changes[ 0 ] if ( fraction_changes.is_a?( Array ) )

            cdata = currencyhelp_compose( model_instance.currency, integer_changes, fraction_changes )
          else
            cdata = []
            cdata[ 0 ] = currencyhelp_compose( model_instance.currency, integer_changes[ 0 ], fraction_changes[ 0 ] )
            cdata[ 1 ] = currencyhelp_compose( model_instance.currency, integer_changes[ 1 ], fraction_changes[ 1 ] )
          end

          if ( model == Poll )
            key = 'total_for_sorting'
          else # Assume any other model uses "amount"
            key = 'amount_for_sorting'
          end

          have_had_currency_value = true

        end # 'unless ( model_instance.nil? )'
      end   # 'if ( currency_keys.include?( key.to_sym ) )'

      # Sort out human-readable versions of the change string. Change data and
      # even the value of 'key' may have been modified by code above if amounts
      # of money were detected in the change set.

      if ( cdata.instance_of?( Array ) )
        cfrom = auditershelp_to_descriptive_s( model, key, cdata[ 0 ] )
        cto   = auditershelp_to_descriptive_s( model, key, cdata[ 1 ] )
      else
        cfrom = '&mdash;'
        cto   = auditershelp_to_descriptive_s( model, key, cdata )
      end

      # Ignore changes from nil to empty strings, or similar.

      next if ( cfrom == '&mdash;' && cto == '&mdash;' )

      # Add the hopefully easily human-readable descriptive change row.

      output << "<tr valign=\"top\"><td>#{ model.human_attribute_name( key ) }</td>"

      if ( record.action == "create" || record.action == "destroy" )
        output << "<td>#{ cto }</td></tr>"
      else
        output << "<td>#{ cfrom }</td><td>#{ cto }</td></tr>"
      end
    end

    return output << '</table>'
  end

  # Return a more descriptive version of a string. Pass the model the string
  # is for, the field it's for and its value (which may be from before or after
  # a recorded change, so it's not read from the model automatically using the
  # field name you give). The field name must be given as a string not a symbol
  # and must be the 'untranslated' form for translatable models (e.g. pass
  # "title" rather than "title_en").
  #
  # Returns a more descriptive string including special case handlers for known
  # fields which contain e.g. Textile data. The returned value is HTML safe.
  #
  def auditershelp_to_descriptive_s( model, field, str )
    str = str.to_s

    return '&mdash;' if ( str.blank? ) # Note this will also catch non-empty, but all whitespace strings

    if ( model == Poll )
      if ( field == 'description' )
        return RedCloth.new( str ).to_html
      elsif ( field == 'currency_id' )
        return auditershelp_link_to( Currency, str, :name )
      elsif ( field == 'user_id' )
        return auditershelp_link_to( User, str, :name )
      end
    elsif ( model == Donation )
      if ( field == 'currency_id' )
        return auditershelp_link_to( Currency, str, :name )
      elsif ( field == 'poll_id' )
        return auditershelp_link_to( Poll, str, :title )
      elsif ( field == 'user_id' )
        return auditershelp_link_to( User, str, :name )
      elsif ( field == 'workflow_state' )
        return apphelp_state( str, DonationsController )
      end
    end

    return h( str )
  end

  # Pass a model class (e.g. User, Currency), an ID as a string or integer
  # and a method. Tries to find an instance of the given model with the given
  # ID. If found, it returns a link to the 'show' view for that instance using
  # the visible link text obtained by sending the given method to the instance.
  # Otherwise, returns the ID again.
  #
  # Example:
  #
  #   auditershelp_ink_to( User, 2, :email )
  #
  # Tries to find a User with ID 2. If not found, returns 2. If found, returns
  # a link to the 'show' action for that user with "user.email" as the visible
  # link text.
  #
  def auditershelp_link_to( model, id, method )
    object = model.find_by_id( id )

    return id if ( object.nil? )
    return link_to( object.send( method ), object )
  end
end
