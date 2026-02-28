# frozen_string_literal: true

source 'https://rubygems.org'

# gem "rails"
gem 'fastlane'
gem 'ostruct'

group :development do
  gem 'rubocop', require: false
  gem 'ruby-lsp', require: false
end

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
