ENV['ENV'] ||= 'test'
Bundler.require(:default, ENV['ENV'])
require_relative '../lib/terminal'

RSpec.configure do |config|
  config.color= true
  config.order= 'rand'
  config.raise_errors_for_deprecations!
end
