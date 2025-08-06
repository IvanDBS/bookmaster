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

# Authorization
gem "pundit"

# API serialization
gem "active_model_serializers"

# Validation and error handling
gem "dry-validation"

# Date/Time handling
gem "ice_cube"

group :development, :test do
  # Call 'byebug' anywhere in the code to stop and debug your application
  gem "byebug", platforms: [:mri, :mingw, :x64_mingw]
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ]
  gem 'pry-byebug'
  
  # Testing
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "faker"
  gem "shoulda-matchers"
end

group :development do
  gem "web-console"
  gem "error_highlight", ">= 0.4.0", platforms: [:ruby]
  gem "annotate"
  gem "listen"
  gem "rubocop", require: false
  gem "rubocop-rails", require: false
  gem "rubocop-rspec", require: false
end

