require 'sinatra'
require 'config_env'
require 'rack-flash'
require 'json'
require 'protected_attributes'
require 'rack-flash'
require 'email_veracity'
require 'rack/ssl-enforcer'
require_relative './model/user'
require_relative './helpers/creditcard_helper'
require 'rack/ssl-enforcer'
require 'httparty'
require 'jwt'
require 'rbnacl/libsodium'
require 'openssl'
require 'hirb'



# Credit Card Web Service
class CreditCardService < Sinatra::Base
  # API_URL_BASE = 'http://creditcard-api.herokuapp.com'
  API_URL_BASE = 'http://credit-card-service-api.herokuapp.com'

  include CreditCardHelper

  enable :logging

  configure do
    use Rack::Session::Cookie, secret: ENV['MSG_KEY']
    use Rack::Flash, sweep: true
    Hirb.enable
  end

  configure :development, :test do
    ConfigEnv.path_to_config("#{__dir__}/config/config_env.rb")
  end

  configure :production do
    use Rack::SslEnforcer
    set :session_secret, ENV['MSG_KEY']
  end

  register do
    def auth(*types)
      condition do
        if (types.include? :user) && !@current_user
          flash[:error] = "You must be logged in to access this page"
          redirect "/login"
        end
      end
    end
  end


  before do
    @current_user = session[:auth_token] ? find_user_by_token(session[:auth_token]) : nil
  end

  register do
    def auth(*types)
      condition do
        if (types.include? :user) && !@current_user
          flash[:error] = 'You must be logged in for that page'
          redirect '/login'
        end
      end
    end
  end

  get '/' do
    haml :index
  end

  get '/register' do
    if token = params[:token]
      begin
        create_user_with_encrypted_token(token)
        flash[:notice] = "Your account has been successfully created."
      rescue
        flash[:error] = "Your account could not be created. Your link is either expired or invalid."
      end
      redirect '/'
    else
      haml(:register)
    end
  end

  post '/register' do
    logger.info('Register')
    registration = Registration.new(params)
    if (registration.complete?) != true
      flash[:error]= "Please fill in ALL fields."
      redirect '/register'
    elsif (params[:password] == params[:password_confirm]) != true
      flash[:error]= "Please ensure that the passwords are the SAME."
      redirect '/register'
    elsif EmailVeracity::Address.new(params[:email]).valid? != true
      flash[:error]= "Please enter a valid email address."
      redirect '/register'
    elsif user_available(params[:username]) != nil
      flash[:error]= "This username is not available."
      redirect '/register'
    else
      begin
        email_registration_verification(registration)
        flash[:notice] = "A verification link has been sent to #{params[:email]}. Please check your email!"
        redirect '/'
      rescue => e
        logger.error "FAIL EMAIL: #{e}"
      end
    end
  end

  get '/login' do
    haml :login
  end



  post '/login' do
    username = params[:username]
    password = params[:password]
    user = User.authenticate!(username, password)
    if user
      login_user(user)
    else
      flash[:error] = "Incorrect username or password!"
      redirect('/login')
    end
  end

  get '/logout' do
    session[:auth_token] = nil
    flash[:notice] = "You have successfully logged out."
    redirect '/'
  end


  get '/validate', :auth => [:user] do
    haml :validate
  end

  get '/validate/card', :auth => [:user] do
    num = params['card_number']
    url = "#{API_URL_BASE}/api/v1/credit_card/validate/#{num}"
    @card = HTTParty.get (url)
    @valid = JSON.parse(@card)
    haml :validate
  end

  get '/callback' do
    gh = HTTParty.post('https://github.com/login/oauth/access_token',
                        body: {client_id: ENV['GH_CLIENT_ID'],
                               client_secret: ENV['GH_CLIENT_SECRET'],
                               code: params['code']},
                        headers: {'Accept' => 'application/json'})
    gh_user = HTTParty.get(
              'https://api.github.com/user',
              body: {params: {access_token: gh['access_token']}},
              headers: {'User-Agent' => 'Credit Card Service',
                        'Authorization' => "token #{gh['access_token']}"})
    username = gh_user['login']
    email = gh_user['email']
    if user = find_user_by_username(username)
      login_user(user)
    else
      create_gh_user(username, email, gh['access_token'])
    end
    redirect '/'
  end



  get '/retrieve', :auth => [:user] do
    result = HTTParty.get("#{API_URL_BASE}/api/v1/credit_card/#{@current_user.id}")
    @cards = result.parsed_response
    haml :retrieve
  end

  get '/user/:username' , :auth => [:user] do
    username = params[:username]
    unless username == @current_user.username
      flash[:error] = "You may only look at your own profile"
      redirect '/'
    end
    haml :profile
  end

  get '/store', :auth => [:user] do
    haml :store
  end

  post '/store' do
    begin
      data = {
        'user_id'           => @current_user.id,
        'number'            => params[:card_number],
        'expiration_date'   => params[:expiration],
        'owner'             => params[:name],
        'credit_network'    => params[:network]
      }.to_json

      response = HTTParty.post("#{API_URL_BASE}/api/v1/credit_card", {
        :body     => data,
        :headers  => {'Content-Type' => 'application/json', 'Accept' => 'application/json', 'authorization' => ('Bearer ' + user_jwt)}
        })
      unless response.code == 201
        flash[:error] = "Invalid Card number"
        redirect '/store'
      end
    end
    flash[:notice] = "Card saved successfully!"
    redirect '/'

  end
end
