########################################################################
# File::    collectable.rb
# (C)::     Hipposoft 2010, 2011
#
# Purpose:: A database object which can be garbage collected based on
#           its "updated_at" column's value.
# ----------------------------------------------------------------------
#           12-Feb-2010 (ADH): Created.
#           30-Jan-2011 (ADH): Imported from Artisan.
########################################################################

class Collectable < ActiveRecord::Base

  # ===========================================================================
  # CHARACTERISTICS
  # ===========================================================================

  self.abstract_class = true

  # Timeout period in seconds and garbage collection interval in seconds.

  TIMEOUT        = 2.hours
  SWEEP_INTERVAL = 1.day

  # ===========================================================================
  # PERMISSIONS
  # ===========================================================================

  # Anyone can do anything to collectable objects by default.

  def self.can_modify?( ignore1, ignore2 )
    true
  end

  # ===========================================================================
  # GENERAL
  # ===========================================================================

  # Get rid of expired objects. They time out after TIMEOUT. Pass session
  # details from the current request; this is used to see if this session has
  # already caused a garbage collection sweep recently. If it has, nothing will
  # be done. The minimum interval between sweeps is SWEEP_INTERVAL. Pass also
  # the model subclass to operate upon. By default the method simply destroys
  # objects with a sufficiently old updated_at value, but the caller can
  # optionally override this by passing their own destroy conditions in a 3rd
  # input parameter.
  #
  # Call only from subclasses.
  #
  def self.garbage_collect( session, model, conditions = [ 'updated_at < ?', TIMEOUT.seconds.ago ] )
    key = "#{ model.table_name }_sweep".to_sym

    if ( session[ key ].nil? ||
         session[ key ] < SWEEP_INTERVAL.seconds.ago )

      # Although destroy_all may be slow, we must use this because the join
      # tables related to the HABTM relationships need updating too.

      begin
        model.transaction do
          model.destroy_all( conditions )
        end
      rescue
        # Consume all exceptions
      end

      session[ key ] = Time.now
    end
  end
end
