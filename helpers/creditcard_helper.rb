require 'jwt'
require 'config_env'
require 'rbnacl/libsodium'
require 'pony'
require 'base64'
require_relative '../model/user'
require 'openssl'
require 'httparty'
require 'json'


module CreditCardHelper
  API_URL_BASE = 'https://credit-card-service-api.herokuapp.com'
  class Registration
    attr_accessor :username, :email, :password, :dob, :fullname, :address

    def initialize(user_hash)
      @username = user_hash['username'] || user_hash[:username]
      @email = user_hash['email'] || user_hash[:email]
      @password = user_hash['password'] || user_hash[:password]
      @fullname = user_hash['fullname'] || user_hash[:fullname]
      @dob = user_hash['dob'] || user_hash[:dob]
      @address = user_hash['address'] || user_hash[:address]
    end

    def complete?

      (username && username.length > 0) &&
      (email && email.length > 0) &&
      (password && password.length > 0) &&
      (address && address.length > 0) &&
      (dob && dob.length > 0) &&
      (fullname && fullname.length > 0)
    end
  end

  def api_card_index
    JSON.parse(HTTParty.get("#{API_URL_BASE}/api/v1/credit_card?user_id=#{@current_user.id}",
    :headers  => {'Content-Type' => 'application/json', 'Accept' => 'application/json', 'authorization' => ('Bearer ' + user_jwt)
    }))
    # url = API_URL+'operation'
    # headers = {'authorization' => ('Bearer ' + user_jwt)}
    # HTTParty.get url, headers: headers
  end


  def user_jwt
    jwt_payload = {'iss' => 'https://creditcardserviceapp.herokuapp.com',
                    'sub' => @current_user.id }
    jwt_key = OpenSSL::PKey::RSA.new(Base64.urlsafe_decode64(ENV['UI_PRIVATE_KEY']))
    JWT.encode jwt_payload, jwt_key, 'RS256'
  end

  def login_user(user)
    payload = {user_id: user.id}
    token = JWT.encode payload, ENV['MSG_KEY'], 'HS256'
    session[:auth_token] = token
    redirect '/'
  end

  def create_gh_user(username, email, token)

    reg = Registration.new({'username'=> username, 'email' => email, 'password' => token})
    create_account_with_git_registration(reg)
  end

  def find_user_by_token(token)
    return nil unless token
    decoded_token = JWT.decode token, ENV['MSG_KEY'], true
    payload = decoded_token.first
    User.find_by_id(payload['user_id'])
  end

  def find_user_by_username(username)
    User.find_by_username(username)
  end

  def email_registration_verification(registration)
    payload = {username: registration.username, email: registration.email,
              password: registration.password, dob: registration.dob,
              address: registration.address, fullname: registration.fullname}
    token = JWT.encode payload, ENV['MSG_KEY'], 'HS256'
    verification = encrypt_message(token)
    Pony.mail(to: registration.email,
             subject: "Your Credit Card API Account is Ready",
             html_body: registration_email(verification))
  end

  def registration_email(token)
    verification_url = "#{request.base_url}/register?token=#{token}"
    "<H1>Credit Card API Registration Received<H1>" \
    "<p>Please <a href=\"#{verification_url}\" style = 'color:red'>click here</a> to validate " \
    "your email and activate your account</p>"
  end

  def encrypt_message(message)
    key = Base64.urlsafe_decode64(ENV['MSG_KEY'])
    secret_box = RbNaCl::SecretBox.new(key)
    nonce = RbNaCl::Random.random_bytes(secret_box.nonce_bytes)
    nonce_s = Base64.urlsafe_encode64(nonce)
    message_enc = secret_box.encrypt(nonce, message.to_s)
    message_enc_s = Base64.urlsafe_encode64(message_enc)
    Base64.urlsafe_encode64({'message'=>message_enc_s, 'nonce'=>nonce_s}.to_json)
  end

  def decrypt_message(secret_message)
    key = Base64.urlsafe_decode64(ENV['MSG_KEY'])
    secret_box = RbNaCl::SecretBox.new(key)
    message_h = JSON.parse(Base64.urlsafe_decode64(secret_message))
    message_enc = Base64.urlsafe_decode64(message_h['message'])
    nonce = Base64.urlsafe_decode64(message_h['nonce'])
    message = secret_box.decrypt(nonce, message_enc)
    rescue
      raise "INVALID ENCRYPTED MESSAGE"
  end

  def create_account_with_registration(registration)
    new_user = User.new(username: registration.username, email: registration.email)
    new_user.password =  registration.password
    new_user.fullname = new_user.attribute_encrypt(registration.fullname)
    new_user.dob = new_user.attribute_encrypt(registration.dob)
    new_user.address = new_user.attribute_encrypt(registration.address)
    new_user.save! ? login_user(new_user) : fail('Could not create a new user')
  end

  def create_account_with_git_registration(registration)
    new_user = User.new(username: registration.username, email: registration.email)
    new_user.password =  registration.password
    new_user.save! ? login_user(new_user) : fail('Could not create new user')
  end

  def create_user_with_encrypted_token(token_enc)
    token = decrypt_message(token_enc)
    payload = (JWT.decode token, ENV['MSG_KEY']).first
    reg = Registration.new(payload)
    create_account_with_registration(reg)
  end

  def user_available(user)
    User.find_by_username(user)
  end
end
