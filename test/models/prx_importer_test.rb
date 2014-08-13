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

      if use_webmock?

        # prx stubs
        stub_request(:get, "https://hal.prx.org/api/v1").
          to_return(:status => 200, :body => json_file(:prx_root), :headers => {})

        stub_request(:get, "https://hal.prx.org/api/v1/stories/97474").
          to_return(:status => 200, :body => json_file(:prx_story), :headers => {})

        # pmp stubs
        pmp_token = {
          access_token: "thisisnotanaccesstokenno",
          token_type: "Bearer",
          token_issue_date: DateTime.now,
          token_expires_in: 24*60*60
        }.to_json

        stub_request(:post, "https://api-sandbox.pmp.io/auth/access_token").
          with(:body => {"grant_type"=>"client_credentials"},
               :headers => {'Accept'=>'application/json', 'Authorization'=>'Basic ODI2YzVlMzctYWFlMy00NjAzLWIzMDMtYjlmZjU3N2YyM2MzOjEyYTkzZTk1NWU5Mzk2YjhiOWY5NjkzMg==', 'Content-Type'=>'application/x-www-form-urlencoded', 'Host'=>'api-sandbox.pmp.io:443'}).
          to_return(:status => 200, :body => pmp_token, :headers => {'Content-Type' => 'application/json; charset=utf-8'})

        stub_request(:get, "https://api-sandbox.pmp.io/").
          with(:headers => {'Accept'=>'application/vnd.collection.doc+json', 'Authorization'=>'Bearer thisisnotanaccesstokenno', 'Content-Type'=>'application/vnd.collection.doc+json', 'Host'=>'api-sandbox.pmp.io:443'}).
          to_return(:status => 200, :body => json_file(:pmp_root), :headers => {})

        stub_request(:put, "https://publish-sandbox.pmp.io/docs/9ff6db7a-93e6-4987-9313-4d70d74051b3").
          with(:body => "{\"links\":{\"profile\":[{\"href\":\"https://api-sandbox.pmp.io/profiles/story\",\"type\":\"application/vnd.collection.doc+json\"}]},\"attributes\":{\"guid\":\"9ff6db7a-93e6-4987-9313-4d70d74051b3\",\"title\":\"Gambling and Long Lost Dads\",\"tags\":[\"prx_test\"]}}",
               :headers => {'Accept'=>'application/vnd.collection.doc+json', 'Authorization'=>'Bearer thisisnotanaccesstokenno', 'Content-Type'=>'application/vnd.collection.doc+json', 'Host'=>'publish-sandbox.pmp.io:443'}).
          to_return(:status => 200, :body => '{"url":"https://api-sandbox.pmp.io/docs/9ff6db7a-93e6-4987-9313-4d70d74051b3"}', :headers => {})


        PMPGuidMapping.class_eval do 
          def self.new_guid
            '9ff6db7a-93e6-4987-9313-4d70d74051b3'
          end
        end

      else

        # delete to clean up prior runs
        delete_count = 0
        prx_importer.pmp.query["urn:collectiondoc:query:docs"].where(tag: 'prx_test', limit: 100).items.each{|i| i.delete; delete_count+=1 }
        puts "deleted #{delete_count}"

      end

    }

    it "imports a prx piece" do
      prx_importer.import(prx_story_id: 97474)
    end

  end

end
