config_env :development, :test do
  set 'DB_KEY', "hY7JBJV1CK0z-yKC7cqMaxzatOf9nWBISR0MIb8x7o8="
  set 'MSG_KEY', "xWSO1VWOMmT3fsDTWspLgngxx6FccRHntT8AE-ul-Ak="
end

config_env :production do
  set 'DB_KEY', "hY7JBJV1CK0z-yKC7cqMaxzatOf9nWBISR0MIb8x7o8="
  set 'MSG_KEY', "xWSO1VWOMmT3fsDTWspLgngxx6FccRHntT8AE-ul-Ak="
end

config_env do
  set 'SENDGRID_DOMAIN', "creditcardserviceapp.herokuapp.com"
  set 'SENDGRID_USERNAME', "app37458399@heroku.com"
  set 'SENDGRID_PASSWORD', "vr0sw7kd3433"
end
