require 'test_helper'

describe PRXImporter do

  it 'accepts options' do
    options = {}
    prx_importer = PRXImporter.new(options)
    prx_importer.options.must_equal options
  end

  describe "imports into pmp" do

    let(:prx_importer) { PRXImporter.new(pmp_endpoint: 'https://api-sandbox.pmp.io/') }

    before {
      # delete to clean up prior runs
      delete_count = 0
      prx_importer.pmp.query["urn:collectiondoc:query:docs"].where(tag: 'prx_test', limit: 100).items.each{|i| i.delete; delete_count+=1 }
      # puts "deleted #{delete_count}"
    }

    it "imports a prx piece" do
      prx_importer.import(prx_story_id: 88486)
    end

  end

end
