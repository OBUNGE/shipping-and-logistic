Rails.application.routes.draw do
  # === Devise / ActiveAdmin ===
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  devise_for :users
  post "toggle_role",   to: "users#toggle_role",   as: :toggle_role
  post "become_seller", to: "users#become_seller", as: :become_seller
  post "become_buyer",  to: "users#become_buyer",  as: :become_buyer

  # === Products and nested resources ===
  resources :products do
    resources :orders, only: [:new, :create]
    resources :reviews, only: [:create, :edit, :update, :destroy, :show] do
      resources :votes,   only: [:create]
      resources :reports, only: [:new, :create]
    end
    resources :variants,    only: [:new, :create, :edit, :update, :destroy]
    resources :inventories, only: [:new, :create, :edit, :update, :destroy]

    member do
      post   :upload_additional_images
      delete :delete_additional_image
      post   :bulk_inventory_upload
      delete :delete_image
    end

    delete "gallery_images/:image_id", to: "products#remove_gallery_image", as: :remove_gallery_image
  end

  # === M-PESA Callback (single global route) ===
  post "/mpesa/callback/:order_id", to: "payments#mpesa_callback", as: :mpesa_callback

  # === Orders and nested payment/shipment routes ===
  resources :orders, only: [:index, :show, :new, :create] do
    resources :order_items, only: [:create, :destroy]

    resources :payments, only: [:create] do
      collection do
        match :paystack_callback, via: [:get, :post]
        get   :paypal_callback,   via: [:get, :post]
      end
    end

    resource :shipment, only: [:create, :show, :edit, :update] do
      post :track, on: :member
    end

    resources :notifications, only: [:index]
    member do
      get :receipt
    end
  end

  # === Other resources ===
  resources :shipments, only: [:index]
  resources :messages, only: [:index, :create]
  resources :notifications, only: [:index] do
    patch :mark_read, on: :member
  end

  # Sellers (slug-based)
  resources :sellers, only: [:show, :edit, :update], param: :slug do
    get :subcategories, on: :member
  end

  resources :discounts, only: [:new, :create, :edit, :update, :destroy]
  resources :product_images, only: [:destroy]

  # Categories
  resources :categories do
    get :subcategories, on: :member
  end

  # === Dashboards and Cart ===
  get "dashboard/buyer",  to: "dashboards#buyer",  as: :buyer_dashboard
  get "dashboard/seller", to: "dashboards#seller", as: :seller_dashboard

  resource :cart, only: [:show] do
    post 'add',    to: 'carts#add'
    post 'remove', to: 'carts#remove'
    post 'clear',  to: 'carts#clear'
    post 'update', to: 'carts#update', as: :update
  end

  # === Webhooks ===
  post "/dhl/webhook", to: "webhooks#dhl"

  # === ActiveStorage (remove if fully on Supabase) ===
  mount ActiveStorage::Engine => "/rails/active_storage"

  # === Health check and root ===
  get "up" => "rails/health#show", as: :rails_health_check
  root "products#index"
end
