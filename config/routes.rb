Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  scope module: :api, defaults: { format: :json } do
    namespace :v1 do
      resources :companies, except: %i[new edit] do
        member do
          put :mark_deleted
          get :geeks
          get :applies
        end
        resources :jobs, except: %i[new edit] do
          get :geeks, on: :member
          resources :applies, only: :index
        end
      end
      resources :jobs, except: %i[new edit] do
        get :geeks, on: :member
        resources :applies, only: :index
      end
      resources :geeks, except: %i[new edit] do
        member do
          get :read_applies
          get :invited_applies
          put :resume
        end
        resources :applies, only: :index
      end
      resources :applies, except: %i[new edit] do
        member do
          put :mark_read
          put :invite
        end
      end
    end
  end

  match "/", to: "application#catch_404", via: :all
  match "*path", to: "application#catch_404", via: :all
end
