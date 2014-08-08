OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE if Rails.env.development?
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :github, Rails.configuration.github_key, Rails.configuration.github_secret, scope: 'user,user:email,repo'
end
