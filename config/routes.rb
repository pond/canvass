Rails.application.routes.draw do

  root :controller => :polls, :action => :index

  # Local users are mirrors of Hub users with extra information stored so that
  # they can be associated with created Polls and Donations. However, Poll and
  # Donation objects contain enough information about themselves that a User
  # can be deleted without breaking them, if necessary.
  #
  # When managing Polls and Donations in the context of the user, only index
  # and show actions are supported to keep things simple.
  #
  resources :users, :only => [ :index, :show, :delete ] do | user |
    resources :polls,     :only => [ :index, :show ]
    resources :donations, :only => [ :index, :show ]
  end

  # Privileged users browse donations without limiting the scope by user ID.
  # Polls can be similarly viewed without restriction.
  #
  # Polls have many donations. Resource-ful URLs are used when creating a
  # donation to associate with the poll to which the donation is being made.
  # The payment gateway process proceeds in the context of the current logged
  # in user, with the poll identified by the context inferred by the URL.
  #
  resources :donations, :only => [ :index, :show ]
  resources :polls do | poll |
    resources :donations, :only => [ :index, :show, :new, :create ]
    resource  :payment_gateway_onsite,  :controller => :payment_gateway_onsite,  :member => { :delete => :get }
    resource  :payment_gateway_offsite, :controller => :payment_gateway_offsite, :member => { :delete => :get }
  end

  # Full currency support, for number formatting, editing etc. (CRUD interface
  # available to privileged users only). Likewise, the audits interface - index
  # only.
  #
  resources :currencies
  resources :auditers, :only => :index

  # Preview for RedCloth (Textile) text; translatable help pages.
  #
  resource  :redcloth, :only => :create, :controller => :redcloth
  resources :help,     :only => :show

end
