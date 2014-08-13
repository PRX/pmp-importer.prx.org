require 'test_helper'

describe ApplicationImporter do

  it 'accepts options' do
    options = {}
    importer = ApplicationImporter.new(options)
    importer.options.must_equal options
  end

end
