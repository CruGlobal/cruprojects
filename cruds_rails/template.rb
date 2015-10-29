# Add the current directory to the path Thor uses
# to look up files
def source_paths
  Array(super) +
    [File.expand_path(File.dirname(__FILE__))]
end

def curl_file(name)
  run "curl \"https://raw.githubusercontent.com/CruGlobal/cruprojects/add-template/cruds_rails/#{name}\" -o \"#{name}\""
end

remove_file 'Gemfile'
run 'touch Gemfile'
add_source 'https://rubygems.org'
gem 'rails', '~> 4.2.1'
gem 'puma'

gem 'pg'

gem 'newrelic_rpm'
gem 'rack-cors', require: 'rack/cors'
gem 'redis-rails', '~> 4.0.0'
gem 'rollbar'
gem 'silencer'
gem 'syslog-logger'

gem_group :development, :test do
  gem 'dotenv-rails'
  gem 'guard-rubocop'
  gem 'guard-rspec'
  gem 'rspec-rails'
  gem 'spring'
  gem 'pry-rails'
end

gem_group :test do
  gem 'webmock'
  gem 'simplecov', require: false
  gem 'factory_girl_rails'
  gem 'shoulda', require: false
  gem 'rubocop', '~> 0.34.0'
end

curl_file 'Dockerfile'
curl_file '.env'
gsub_file '.env', /fake-secret-key/, 'fake-' + (0...75).map { ('a'..'z').to_a[rand(26)] }.join
curl_file '.gitignore'
curl_file '.dockerignore'

inside 'config' do
  curl_file 'database.yml'
end

after_bundle do
  remove_file 'public/index.html'
  remove_dir 'app/views' if yes?("Delete all the view files? (y/n) ")
  remove_dir 'app/controllers/concerns'
  remove_dir 'test'

  insert_into_file 'config/application.rb', after: "require 'rails/all'\n" do <<-RUBY
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
  RUBY
  end

  gsub_file 'config/application.rb', /require 'rails\/all'/, '# require "rails/all"'

  application do <<-RUBY
    config.assets.enabled = false
    config.generators do |g|
      g.test_framework :rspec, fixture: true
      g.view_specs false
      g.helper_specs false
      g.template_engine false
      g.stylesheets     false
      g.javascripts     false
    end

    config.log_formatter = ::Logger::Formatter.new
    config.middleware.swap Rails::Rack::Logger, Silencer::Logger, config.log_tags, silence: ['/monitors/lb']
  RUBY
  end

  run 'spring stop'
  generate 'rspec:install'
  run 'guard init'

  route "get 'monitors/lb' => 'monitors#lb'"
  generate :controller, 'monitors', 'lb'
  remove_file 'app/helpers/monitors_helper.rb'
  remove_file 'spec/controllers/monitors_controller_spec.rb'
  insert_into_file 'app/controllers/monitors_controller.rb', after: "ApplicationController\n" do <<-RUBY
  layout nil
  newrelic_ignore

  RUBY
  end
  insert_into_file 'app/controllers/monitors_controller.rb', after: "def lb\n" do <<-RUBY
    render text: File.read(Rails.public_path.join('lb.txt'))
  RUBY
  end
  run 'echo "OK" > public/lb.txt'

  git :init
  git add: "."
  git commit: "-a -m 'Initial commit'"
end
