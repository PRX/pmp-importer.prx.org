require 'test_helper'

describe RSSImporter do

  describe 'basic methods' do

    let(:rss_importer) { RSSImporter.new }

    it 'accepts options' do
      options = {}
      rss_importer = RSSImporter.new(options)
      rss_importer.options.must_equal options
    end

    it 'sets default source' do
      rss_importer.source_name.must_equal 'rss'
    end

  end

  describe "imports into pmp" do

    before {
      if use_webmock?

        ENV['PMP_CLIENT_ID'] = ""
        ENV['PMP_CLIENT_SECRET'] = ""

        RSSImporter.class_eval do
          def retrieve_feed(url)
            feed_file = test_file("/fixtures/99percentinvisible.xml")
            feed = Feedjira::Feed.parse(feed_file)
            feed
          end
        end

        # pmp stubs
        pmp_token = {
          access_token: "thisisnotanaccesstokenno",
          token_type: "Bearer",
          token_issue_date: DateTime.now,
          token_expires_in: 24*60*60
        }.to_json

        # login
        stub_request(:post, "https://api.pmp.io/auth/access_token").
          with(:body => {"grant_type"=>"client_credentials"},
               :headers => {'Accept'=>'application/json', 'Authorization'=>'Basic Og==', 'Content-Type'=>'application/x-www-form-urlencoded', 'Host'=>'api.pmp.io:443'}).
          to_return(:status => 200, :body => pmp_token, :headers => {'Content-Type' => 'application/json; charset=utf-8'})

        # get root doc
        stub_request(:get, "https://api.pmp.io/").
          to_return(:status => 200, :body => json_file(:pmp_root), :headers => {})

        stub_request(:get, "https://api.pmp.io/docs?limit=1&tag=_rss_http://99percentinvisible.prx.org_").
          to_return(:status => 200, :body => "", :headers => {})


      end
    }

    let(:rss_importer) { RSSImporter.new }

    it "imports a prx piece" do
      items = rss_importer.import(rss_url: "http://feeds.99percentinvisible.org/99percentinvisible")
    end

  end

end
