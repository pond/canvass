########################################################################
# File::    redcloth_controller.rb
# (C)::     Hipposoft 2011
#
# Purpose:: Generate RedCloth (Textile) previews.
# ----------------------------------------------------------------------
#           18-Feb-2011 (ADH): Created.
########################################################################

class RedclothController < ApplicationController
  def create
    render :text => RedCloth.new( params[ :textile ] || '' ).to_html
  end
end