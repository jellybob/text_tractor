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
    
    def self.hash_user(username, password)
      Digest::MD5.hexdigest("#{username}.#{password}.#{salt}")
    end
    
    use Rack::Auth::Basic do |username, password|
      redis = Redis.new(settings.redis)
      r = Redis::Namespace.new(settings.redis[:ns], :redis => redis)
      
      r.setnx "users:#{settings.default_username}", {
        "username" => settings.default_username,
        "superuser" => true,
        "name" => "Default User"
      }.to_json
      r.sadd "users", settings.default_username
      r.sadd "user_hashes", hash_user(settings.default_username, settings.default_password)
      
      r.sismember "user_hashes", hash_user(username, password)
    end
    
    set :salt, "Aingoomeichushae0ooshuso6Fiexaiqu0phophe"
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
        "superuser" => params[:superuser] == "true"
      }.to_json
      redis.sadd "users", params[:username]
      redis.sadd "user_hashes", self.class.hash_user(params[:username], params[:password])
      
      redirect "/users"
    end
  end
end
