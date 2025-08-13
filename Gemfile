source "https://rubygems.org"

ruby "3.1.6"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 7.1.5", ">= 7.1.5.1"

gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "bcrypt", "~> 3.1.7"
gem "tzinfo-data", platforms: %i[ windows jruby ]
gem "bootsnap", require: false
gem "rack-cors"

# Authentication
gem "devise"
gem "devise-jwt"
gem "jwt", "~> 2.8"

gem "active_model_serializers"

gem "sidekiq"

gem "rack-attack"
gem "secure_headers"

group :development, :test do

  gem "byebug", platforms: [:mri, :mingw, :x64_mingw]

  gem "debug", platforms: %i[ mri windows ]
  gem 'pry-byebug'
  
  # Testing
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "faker"
  gem "shoulda-matchers"
end

group :production do
  gem "lograge"
  gem "sentry-ruby"
  gem "sentry-rails"
end

group :development do
  gem "letter_opener_web"
  gem "web-console"
  gem "annotate"
  gem "listen"
  gem "rubocop", require: false
  gem "rubocop-rails", require: false
  gem "rubocop-rspec", require: false
end
gem "rubocop-discourse", "~> 3.12"
