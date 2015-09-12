require 'test_helper'

describe FeedImporter do

  describe 'basic methods' do

    let(:rss_importer) { FeedImporter.new }

    it 'accepts options' do
      options = {}
      rss_importer = FeedImporter.new(options)
      rss_importer.options.must_equal options
    end

    it 'sets default source' do
      rss_importer.source_name.must_equal 'feed'
    end

  end

  describe "imports into pmp" do

    before {
      if use_webmock?

        ENV['PMP_CLIENT_ID'] = ""
        ENV['PMP_CLIENT_SECRET'] = ""
        ENV['PMP_ENDPOINT'] = 'https://api.pmp.io/'

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

        stub_request(:get, "https://api.pmp.io/docs?itag=rss:http://99percentinvisible.prx.org").
          to_return(:status => 200, :body => "", :headers => {})

        stub_request(:get, "http://feeds.99percentinvisible.org/99percentinvisible").
          to_return(:status => 200, :body => test_file('/fixtures/99percentinvisible.xml'), :headers => { 'Expires' => 1.day.since.httpdate, 'Date' => Time.now.httpdate })


        stub_request(:put, "https://publish.pmp.io/docs/9996db7a-93e6-4987-9313-4d70d74051a1").
          with(:body => "{\"version\":\"1.0\",\"links\":{\"profile\":[{\"href\":\"https://api.pmp.io/profiles/series\",\"type\":\"application/vnd.collection.doc+json\"}],\"alternate\":[{\"href\":\"http://feeds.99percentinvisible.org/99percentinvisible\"}]},\"attributes\":{\"guid\":\"9996db7a-93e6-4987-9313-4d70d74051a1\",\"title\":null,\"teaser\":null,\"description\":null,\"byline\":null,\"itags\":[\"prx_test\",\"feed:\"]}}").
          to_return(:status => 200, :body => '{"url":"https://api.pmp.io/docs/9996db7a-93e6-4987-9313-4d70d74051a1"}', :headers => {})

        stub_request(:put, "https://publish.pmp.io/docs/9996db7a-93e6-4987-9313-4d70d74051a7").
          with(:body => "{\"version\":\"1.0\",\"links\":{\"profile\":[{\"href\":\"https://api.pmp.io/profiles/series\",\"type\":\"application/vnd.collection.doc+json\"}],\"alternate\":[{\"href\":\"http://feeds.99percentinvisible.org/99percentinvisible\"}]},\"attributes\":{\"guid\":\"9996db7a-93e6-4987-9313-4d70d74051a7\",\"title\":null,\"teaser\":null,\"description\":null,\"byline\":null,\"itags\":[\"prx_test\",\"feed:\"]}}").
          to_return(:status => 200, :body => '{"url":"https://api.pmp.io/docs/9996db7a-93e6-4987-9313-4d70d74051a7"}', :headers => {})




        # stub the guid to a predictable value
        PMPGuidMapping.class_eval do

          cattr_accessor :counter

          def self.next_counter
            self.counter = self.counter.to_i + 1
          end

          def self.new_guid
            '9996db7a-93e6-4987-9313-4d70d74051a' + next_counter.to_s
          end

        end

      end
    }

    let(:rss_importer) { FeedImporter.new }

    it "imports a feed" do
      PMPGuidMapping.counter = 0 if use_webmock?

      feed = Feed.create(feed_url: "http://feeds.99percentinvisible.org/99percentinvisible")
      feed.sync
      FeedImporter.new.import(feed_id: feed.id)

      feed.entries
    end

  end

end
