require 'sinatra/activerecord'
require 'protected_attributes'
require_relative '../environments'
require 'rbnacl/libsodium'
require 'base64'
require 'openssl'

class User < ActiveRecord::Base
  validates :username, presence: true, uniqueness: true
  validates :email, presence: true, format: /@/
  validates :hashed_password, presence: true

  attr_accessible :username, :email , :address , :dob , :fullname

  def password=(new_password)
    generate_nonce
    salt = RbNaCl::Random.random_bytes(RbNaCl::PasswordHash::SCrypt::SALTBYTES)

    digest = self.class.hash_password(salt, new_password)

    self.salt = Base64.urlsafe_encode64(salt)

    self.hashed_password = Base64.urlsafe_encode64(digest)

  end

  def self.authenticate!(username, login_password)
    user = User.find_by_username(username)
    puts user
    user && user.password_matches?(login_password) ? user : nil
  end

  def password_matches?(try_password)
    salt = Base64.urlsafe_decode64(self.salt)
    attempted_password = self.class.hash_password(salt, try_password)
    self.hashed_password == Base64.urlsafe_encode64(attempted_password)
  end

  def self.hash_password(salt, pwd)
    opslimit = 2**20
    memlimit = 2**24
    digest_size = 64
    RbNaCl::PasswordHash.scrypt(pwd, salt, opslimit, memlimit, digest_size)
  end

  def attribute_encrypt(att)
    secret_box = RbNaCl::SecretBox.new(key)
    nonce = Base64.decode64(self.nonce)
    Base64.encode64(secret_box.encrypt(nonce, att))
  end

  def attribute_decrypt(att)
    secret_box = RbNaCl::SecretBox.new(key)
    secret_box.decrypt(Base64.decode64(self.nonce), Base64.decode64(att))
  end

  def key
    Base64.urlsafe_decode64(ENV['DB_KEY'])
  end

  # Encrypts credit card number for storage
  def generate_nonce
    secret_box = RbNaCl::SecretBox.new(key)
    self.nonce = RbNaCl::Random.random_bytes(secret_box.nonce_bytes)
    self.nonce = Base64.encode64(self.nonce)
  end
end
