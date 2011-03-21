ActionController::Routing::Routes.draw do |map|

  map.root :controller => :polls, :action => :index

  # Local users are mirrors of Hub users with extra information stored so that
  # they can be associated with created Polls and Donations. However, Poll and
  # Donation objects contain enough information about themselves that a User
  # can be deleted without breaking them, if necessary.
  #
  # When managing Polls and Donations in the context of the user, only index
  # and show actions are supported to keep things simple.

  map.resources :users, :only => [ :index, :show, :delete ] do | user |
    user.resources :polls,     :only => [ :index, :show ]
    user.resources :donations, :only => [ :index, :show ]
  end

  # Privileged users browse donations without limiting the scope by user ID.
  # Polls can be similarly viewed without restriction.
  #
  # Polls have many donations. Resource-ful URLs are used when creating a
  # donation to associate with the poll to which the donation is being made.
  # The payment gateway process proceeds in the context of the current logged
  # in user, with the poll identified by the context inferred by the URL.

  map.resources :donations, :only => [ :index, :show ]
  map.resources :polls do | poll |
    poll.resources :donations, :only => [ :index, :show, :new, :create ]
    poll.resource  :payment_gateway_onsite,  :controller => :payment_gateway_onsite,  :member => { :delete => :get }
    poll.resource  :payment_gateway_offsite, :controller => :payment_gateway_offsite, :member => { :delete => :get }
  end

  # Full currency support, for number formatting, editing etc. (CRUD interface
  # available to privileged users only). Likewise, the audits interface - index
  # only.

  map.resources :currencies
  map.resources :auditers, :only => :index

  # Preview for RedCloth (Textile) text; translatable help pages.

  map.resource  :redcloth, :only => :create, :controller => :redcloth
  map.resources :help,     :only => :show

end
