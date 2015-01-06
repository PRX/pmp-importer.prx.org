source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.1.5'
# Use postgers as the database for Active Record
gem 'pg'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 4.0.3'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails', '~> 4.0.0'
# See https://github.com/sstephenson/execjs#readme for more supported runtimes
# gem 'therubyracer',  platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0',  group: :doc

# Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
gem 'spring',            group: :development

gem 'pmp', '~> 0.5'
# gem 'pmp', github: 'PRX/pmp'

gem 'hyperresource'

# for rss feeds
gem 'feedjira'

gem 'excon'
gem 'faraday'
# gem 'faraday-http-cache'
# gem 'redis-activesupport'

gem 'sidekiq'

group :test do
  gem 'minitest-spec-rails'
  gem 'factory_girl_rails'
  gem 'webmock'
  gem 'minitest-reporters', require: false
  gem "codeclimate-test-reporter", require: false
  gem 'simplecov', require: false
  gem 'coveralls', require: false
end

group :production do
  gem 'rails_12factor'
end

group :development, :production, :staging do
  gem 'sinatra' # for sidekiq
  gem 'autoscaler', github: 'JustinLove/autoscaler'
  gem 'foreman'
  gem 'unicorn'
end

ruby "2.1.4"
