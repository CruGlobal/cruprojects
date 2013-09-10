Rails.application.config.middleware.use OmniAuth::Builder do
  provider :github, Rails.configuration.github_key, Rails.configuration.github_secret
end
