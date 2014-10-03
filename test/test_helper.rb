def use_webmock?
  ENV['PMP_IMPORTER_WEBMOCK'].nil? || (ENV['PMP_IMPORTER_WEBMOCK'] == 'true')
end

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'factory_girl'
require 'minitest/reporters'
require 'minitest/autorun'
require 'minitest/spec'
require 'minitest/pride'
require 'webmock/minitest'

WebMock.allow_net_connect! unless use_webmock?

class ActiveSupport::TestCase
  include FactoryGirl::Syntax::Methods
end

class MiniTest::Spec
  include FactoryGirl::Syntax::Methods
end

def json_file(name)
  test_file("/fixtures/#{name}.json")
end

def test_file(path)
  File.read( File.dirname(__FILE__) + path)
end
