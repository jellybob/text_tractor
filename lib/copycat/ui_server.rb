require 'haml'
require 'sass'

module Copycat
  class UiServer < Sinatra::Application
    use Rack::Auth::Basic do |username, password|
      username == settings.default_username && password == settings.default_password
    end
    
    set :default_username, "admin"
    set :default_password, "password"
    
    set :redis, {
      :ns => "copycat",
      :host => "localhost",
      :port => 6379
    }
    
    set :public, File.expand_path("../../../assets", __FILE__)
    set :views, File.expand_path("../../../views", __FILE__)
    
    get '/' do
      haml :index
    end

    get '/styles.css' do
      scss :styles
    end
  end
end
