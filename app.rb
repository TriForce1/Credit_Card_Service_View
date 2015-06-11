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


# Credit Card Web Service
class CreditCardService < Sinatra::Base
  include CreditCardHelper

  enable :logging


  API_BASE_URI = 'http://credit-card-service-api.herokuapp.com/api/v1'

  configure do
    use Rack::Session::Cookie, secret: ENV['MSG_KEY']
    use Rack::Flash, sweep: true
  end

  configure do
    require 'hirb'
    Hirb.enable
    ConfigEnv.path_to_config("#{__dir__}/config/config_env.rb")
  end

  configure :production do
    use Rack::SslEnforcer
    set :session_secret, ENV['MSG_KEY']
  end

  configure do
    use Rack::Session::Cookie, secret: settings.session_secret
    use Rack::Flash, sweep: true
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

  get '/' do
    # 'The CreditCardAPI is up and running!'
    haml :index
  end

  # get '/api/v1/credit_card/validate/:card_number' do
  #   c = CreditCard.new(
  #     number: params[:card_number]
  #   )
  #
  #   # Method to convert string to integer
  #   # Returns false if string is not only digits
  #   result = Integer(params[:card_number]) rescue false
  #
  #   # Validate for string length and correct type
  #   if result == false || params[:card_number].length < 2
  #     return { "Card" => params[:card_number], "validated" => "false" }.to_json
  #   end
  #
  #   {"Card" => params[:card_number], "validated" => c.validate_checksum}.to_json
  # end



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

  get '/retrieve' , :auth => [:user] do
    if params[:user_id]
      @get_user == params[:user_id]
      @cards = HTTParty.get api_url("#{@get_user}.json")
    end
    haml :retrieve
  end

  get '/retrieve/all', :auth => [:user] do
    # status, headers, body = call env.merge("PATH_INFO" => '/api/v1/get')
    # @cards = JSON.parse(body[0])
    haml :retrieve
  end

  get '/validate', :auth => [:user] do
    # @validate = params[:card_number]
    # if @validate
    #   redirect "/validate/#{@validate}"
    # end
    haml :validate
  end

  get '/validate/:card_number', :auth => [:user] do
    # @validate = params[:card_number]
    # puts @validate
    # status, headers, body = call env.merge("PATH_INFO" => "/api/v1/credit_card/validate/#{@validate}")
    # puts headers
    # puts status
    # @body =  JSON.parse(body[0])
    haml :validate
  end

  get '/store' , :auth => [:user] do

    haml :store
  end

  post '/store' , :auth => [:user] do
    url = "#{API_BASE_URI}/credit_card"
    body_json = {
        owner: params[:name],
        user_id: @current_user.id,
        number: params[:card_number],
        credit_network: params[:network],
        expiration_date: params[:expiration],
    }.to_json
    headers = {'authorization' => ('Bearer ' + user_jwt) }
    puts user_jwt
    HTTParty.post url, body: body_json, headers: headers
    flash[:notice] = "Credit card information sent"
    haml :store
  end


  get '/user/:username' , :auth => [:user] do
    username = params[:username]
    unless username == @current_user.username
      flash[:error] = "You may only look at your own profile"
      redirect '/'
    end
    haml :profile
  end
end
