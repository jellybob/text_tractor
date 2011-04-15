require 'haml'
require 'sass'
require 'digest/md5'

module Copycat
  class UiServer < Copycat::Base
    helpers do 
      def current_user
        Copycat::Users.get(env["REMOTE_USER"])
      end
    end
    
    use Rack::Auth::Basic do |username, password|
      unless Copycat::Users.exists?(Copycat.configuration.default_username)
        Copycat::Users.create(username: Copycat.configuration.default_username, password: Copycat.configuration.default_password, name: "Default User", superuser: true) 
      end

      Copycat::Users.authenticate(username, password)
    end
    
    set :environment, Copycat.configuration.environment
    
    set :public, File.expand_path("../../../assets", __FILE__)
    set :views, File.expand_path("../../../views", __FILE__)
    
    def initialize(app=nil)
      super
    end

    get '/' do
      @projects = Copycat::Projects.for_user(current_user)
      haml :index
    end

    get '/styles.css' do
      scss :styles
    end

    get '/users' do
      return [ 401, "Not authorised" ] unless current_user["superuser"]
      
      @users = Copycat::Users.all
      haml :users
    end

    post '/users' do
      return [ 401, "Not authorised" ] unless current_user["superuser"]
      
      Copycat::Users.create(params[:user])  
      redirect "/users"
    end

    get '/projects/new' do
      haml :"projects/new"
    end
    
    get '/projects/:api_key' do |api_key|
      @project = Copycat::Projects.get(api_key)
      haml :"projects/show"
    end

    post '/projects' do
      project = Copycat::Projects.create(params[:project])
      redirect "/projects/#{project["api_key"]}"
    end
  end
end
