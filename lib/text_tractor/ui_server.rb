require 'haml'
require 'sass'
require 'digest/md5'

module TextTractor
  class UiServer < TextTractor::Base
    helpers do 
      def current_user
        Users.get(env["REMOTE_USER"])
      end

      def pjax?
        env.key? "HTTP_X_PJAX"
      end
    end
    
    use Rack::Auth::Basic do |username, password|
      unless Users.exists?(TextTractor.configuration.default_username)
        Users.create(username: TextTractor.configuration.default_username, password: TextTractor.configuration.default_password, name: "Default User", superuser: true) 
      end

      Users.authenticate(username, password)
    end
    
    set :environment, TextTractor.configuration.environment
    
    set :public, File.expand_path("../../../assets", __FILE__)
    set :views, File.expand_path("../../../views", __FILE__)
    
    def initialize(app=nil)
      super
    end
    
    def render_haml(template)
      haml template, :layout => !pjax? 
    end

    get '/' do
      @projects = Projects.for_user(current_user)
      render_haml :index
    end

    get '/styles.css' do
      scss :styles
    end

    get '/users' do
      return not_authorised unless current_user["superuser"]
      
      @users = Users.all
      render_haml :users
    end

    post '/users' do
      return not_authorised unless current_user["superuser"]
      
      Users.create(params[:user])  
      redirect "/users"
    end

    get '/projects/new' do
      return not_authorised unless current_user["superuser"]
      
      @users = Users.all
      render_haml :"projects/new"
    end
    
    get '/projects/:api_key/*' do |api_key, path|
      @api_key = api_key
      @path = path
      @key = path.gsub("/", ".")
      @blurb = redis.get("projects:#{@api_key}:draft_blurbs:#{@key}")

      render_haml :"blurbs/edit"
    end
    
    post '/projects/:api_key/*' do |api_key, path|
      @key = path.gsub("/", ".")
      @value = params[:blurb]
      
      Projects.update_draft_blurbs(api_key, { @key => @value }, { :overwrite => true })
      
      if pjax?
        haml :"blurbs/value", :layout => false
      else
        redirect "/projects/#{api_key}"
      end
    end

    get '/projects/:api_key' do |api_key|
      return not_authorised unless Projects.authorised?(current_user, api_key)

      @project = Projects.get(api_key)
      @blurbs = Projects.draft_blurbs(api_key)
      
      if @blurbs.size > 0
        render_haml :"projects/show"
      else
        render_haml :"projects/getting_started"
      end
    end
    
    post '/projects' do
      project = Projects.create(params[:project])
      redirect "/projects/#{project["api_key"]}"
    end
  end
end
