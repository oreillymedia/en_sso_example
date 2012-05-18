# When integrating with Devise, this happens in config/initializers/devise.rb
#Rails.application.config.middleware.use OmniAuth::Builder do
#  provider :open_id, :identifier => 'https://openid.orielly.com/'
#end

OmniAuth.config.logger = Rails.logger
# We need to reach down to ruby-openid to configure a ca cert
OpenID.fetcher.ca_file = "#{Rails.root}/config/ca-certificates.crt"
