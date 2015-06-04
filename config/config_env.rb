config_env :development, :test do
  set 'DB_KEY', "hY7JBJV1CK0z-yKC7cqMaxzatOf9nWBISR0MIb8x7o8="
  set 'MSG_KEY', "xWSO1VWOMmT3fsDTWspLgngxx6FccRHntT8AE-ul-Ak="
end

config_env :production do
  set 'DB_KEY', "hY7JBJV1CK0z-yKC7cqMaxzatOf9nWBISR0MIb8x7o8="
  set 'MSG_KEY', "xWSO1VWOMmT3fsDTWspLgngxx6FccRHntT8AE-ul-Ak="
end

config_env do
  set 'SENDGRID_DOMAIN', "credit-card-service-api.herokuapp.com"
  set 'SENDGRID_USERNAME', "app35856516@heroku.com"
  set 'SENDGRID_PASSWORD', "s3t2av1i2319"
end
