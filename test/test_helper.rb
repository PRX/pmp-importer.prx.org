ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'factory_girl'
require 'minitest/reporters'
require 'minitest/autorun'
require 'minitest/spec'
require 'minitest/pride'

class ActiveSupport::TestCase
  include FactoryGirl::Syntax::Methods
end

class MiniTest::Spec
  include FactoryGirl::Syntax::Methods

  def extract_filename(uri)
    URI.parse(uri).path.split('?')[0].split('/').last
  end

end
