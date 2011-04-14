require 'haml'
require 'sass'

module Copycat
  class UiServer < Copycat::Base
    helpers do 
      def users
        users = redis.smembers("users").collect { |u| JSON.parse(redis.get("users:#{u}")) }
        users
      end

      def current_user
        JSON.parse(redis.get("users:#{env["REMOTE_USER"]}"))
      end
    end

    use Rack::Auth::Basic do |username, password|
      redis = Redis.new(settings.redis)
      r = Redis::Namespace.new(settings.redis[:ns], :redis => redis)
      
      r.setnx "users:#{settings.default_username}", {
        "username" => settings.default_username,
        "password" => settings.default_password,
        "superuser" => true,
        "name" => "Default User"
      }.to_json
      r.sadd "users", settings.default_username
      
      (r.sismember("users", username) && JSON.parse(r.get("users:#{username}"))["password"] == password)
    end
    
    set :default_username, "admin"
    set :default_password, "password"
    
    set :public, File.expand_path("../../../assets", __FILE__)
    set :views, File.expand_path("../../../views", __FILE__)
    
    def initialize(app=nil)
      super
    end

    get '/' do
      haml :index
    end

    get '/styles.css' do
      scss :styles
    end

    get '/users' do
      return [ 401, "Not authorised" ] unless current_user["superuser"]
      haml :users
    end

    post '/users' do
      return [ 401, "Not authorised" ] unless current_user["superuser"]
      redis.setnx "users:#{params[:username]}", { 
        "name" => params[:name], 
        "username" => params[:username], 
        "password" => params[:password], 
        "superuser" => params[:superuser] == "true"
      }.to_json
      redis.sadd "users", params[:username]

      redirect "/users"
    end
  end
end
