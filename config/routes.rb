Hdo::Application.routes.draw do

  #
  # representative sign-in
  #

  devise_for :representative, controllers: { confirmations: 'confirmations', sessions: 'representative_sessions' }
  devise_scope :representative do
    put  'representative/confirmation'  => 'confirmations#update',         as: :update_representative_confirmation
  end

  get  'representative'                       => 'representative#index',         as: :representative_root
  get  'representative/questions/:id'         => 'representative#show_question', as: :representative_question
  post 'representative/questions/:id/answers' => 'representative#create_answer', as: :representative_question_answers


  #
  # user sign-in
  #

  devise_for :users, controllers: { sessions: 'user_sessions' }

  #
  # admin
  #

  namespace :admin do
    resources :issues do
      member do
        get 'edit/:step'   => 'issues#edit',         as: :edit_step
        get 'votes/search' => "issues#votes_search", as: :vote_search
      end
    end

    resources :users

    resources :representatives, only: [:index, :edit, :update] do
      get 'activate'       => 'representatives#activate',       as: :activate
      get 'reset_password' => 'representatives#reset_password', as: :reset_password
    end

    # S&S
    resources :questions, only: [:index, :edit, :update, :destroy] do
      member do
        put 'answer/approve' => 'questions#approve_answer' # unused?
        put 'answer/reject'  => 'questions#reject_answer'  # unused?
        put 'approve'        => 'questions#approve'
        put 'reject'         => 'questions#reject'
      end
    end

    root to: "dashboard#index"
  end


  #
  # non-admin issues
  #

  resources :issues, only: [:index, :show, :votes] do
    member do
      get 'votes'      => 'issues#votes'
      get 'widget'     => 'widgets#issue'
      get 'admin_info' => 'issues#admin_info', as: :admin_info
    end
  end

  #
  # districts
  #

  resources :districts, only: [:index, :show]

  #
  # categories
  #

  resources :categories, only: [:index, :show]

  #
  # parties, committees
  #

  resources :parties,    only: [:index, :show] do
    member do
      get 'positions'
      get 'widget' => 'widgets#party'
    end
  end
  resources :committees, only: [:index, :show]

  #
  # promises
  #

  resources :promises, only: [:index, :show]
  get 'promises/:promises/widget' => 'widgets#promises'

  #
  # parliament_issues
  #

  resources :parliament_issues, path: 'parliament-issues', only: [:index, :show]
  get 'parliament-issues/page/:page' => 'parliament_issues#index'

  #
  # representatives
  #

  resources :representatives, only: [:index, :show] do
    member do
      get 'page/:page' => 'representatives#show'
      get 'widget'     => 'widgets#representative'
    end
  end

  get 'representatives/index/name'     => 'representatives#index_by_name', as: :representatives_by_name
  get 'representatives/index/party'    => 'representatives#index_by_party', as: :representatives_by_party
  get 'representatives/index/district' => 'representatives#index_by_district', as: :representatives_by_district

  #
  # votes
  #

  resources :votes, only: [:index, :show] do
    member do
      get 'propositions'
    end
  end

  get 'votes/page/:page' => 'votes#index'

  #
  # widgets
  #

  get 'widgets'          => 'widgets#load', format: :js
  get 'widgets/topic'    => 'widgets#topic'

  #
  # home
  #

  get 'home/index'
  get 'home/contact'
  get 'home/join'
  get 'home/support'
  get 'home/member'
  get 'home/people'
  get 'home/future'
  get 'home/faq'        => 'home#faq', as: :home_faq
  get 'home/friends'

  get 'home/about'      => 'home#about', as: :home_about
  get 'home/method'     => 'home#about'

  #
  # Q & A
  #

  resources :questions

  #
  # norwegian aliases - don't overdo this without a proper solution
  #

  get "bli-med" => "home#join"

  #
  # docs
  #

  get "docs/index"
  get "docs/analysis"

  #
  # global search
  #

  get 'search/all' => 'search#all', as: :search_all
  get 'search/autocomplete' => 'search#autocomplete', :as => :search_autocomplete

  #
  # various
  #

  get 'robots.txt'    => 'home#robots'
  get 'info/revision' => 'home#revision'
  get 'healthz'       => 'home#healthz' # cheap health check for varnish/others

  root to: 'home#index'
end
