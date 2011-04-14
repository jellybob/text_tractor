require 'haml'
require 'sass'
require 'digest/md5'

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
      Digest::MD5.hexdigest("#{username}.#{password}.#{Copycat.configuration.salt}")
    end
    
    use Rack::Auth::Basic do |username, password|
      redis = Redis.new(Copycat.configuration.redis)
      r = Redis::Namespace.new(Copycat.configuration.redis[:ns], :redis => redis)
      
      r.setnx "users:#{Copycat.configuration.default_username}", {
        "username" => Copycat.configuration.default_username,
        "superuser" => true,
        "name" => "Default User"
      }.to_json
      r.sadd "users", Copycat.configuration.default_username
      r.sadd "user_hashes", hash_user(Copycat.configuration.default_username, Copycat.configuration.default_password)
      
      r.sismember "user_hashes", hash_user(username, password)
    end
    
    set :environment, Copycat.configuration.environment
    
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
