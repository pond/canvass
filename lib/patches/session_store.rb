########################################################################
# File::    session_store.rb
# (C)::     https://gist.github.com/570149
#
# Purpose:: Rails 2.3.9 and 2.3.10 don't work properly when either
#           ActiveRecord or MemCache are used for the session store.
#           Although Canvass isn't configured that way by default,
#           this patch is included in an attempt to keep things from
#           breaking should an installer choose an affected store.
# ----------------------------------------------------------------------
#           27-Jan-2011 (ADH): Created.
########################################################################

affected = %w[ActiveRecord::SessionStore ActionController::Session::MemCacheStore]

target = Rails.configuration.middleware.detect do |mid|
  mid.klass.is_a? Class and affected.include? mid.klass.to_s
end

if target
  class RailsCookieMonster
    def initialize(app)
      @app = app
    end

    def call(env)
      # monster MUST HAVE COOKIES om nom nom nom
      env['HTTP_COOKIE'] ||= ""
      @app.call(env)
    end
  end

  Rails.configuration.middleware.insert_before target, RailsCookieMonster
end
