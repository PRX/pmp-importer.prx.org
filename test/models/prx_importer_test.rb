require 'test_helper'

describe PRXImporter do

  describe 'basic methods' do

    let(:prx_importer) { PRXImporter.new }

    it 'accepts options' do
      options = {}
      prx_importer = PRXImporter.new(options)
      prx_importer.options.must_equal options
    end

    it 'sets default source' do
      prx_importer.source_name.must_equal 'prx'
    end

    it 'creates prx url endpoint and path' do
      prx_importer.prx_url('foo').must_equal 'https://hal.prx.org/api/v1/foo'
    end

    it 'creates a tag value for a prx object' do
      prx_importer.prx_tag('https://hal.prx.org/api/v1/foos/1').must_equal "prx:foos-1"
    end

    it 'links to a prx web page' do
      prx_importer.prx_web_link('foo').must_equal 'https://www.prx.org/foo'
    end

    it 'prx web endpoint is default or option' do
      prx_importer.prx_web_endpoint.must_equal 'https://www.prx.org/'
      prx_importer.options[:prx_web_endpoint] = 'https://test.prx.org/'
      prx_importer.prx_web_endpoint.must_equal 'https://test.prx.org/'
    end

    it 'prx api endpoint is default or option' do
      prx_importer.prx_api_endpoint.must_equal 'https://hal.prx.org/api/v1/'
      prx_importer.options[:prx_api_endpoint] = 'https://test.prx.org/'
      prx_importer.prx_api_endpoint.must_equal 'https://test.prx.org/'
    end

    it 'returns a prx client' do
      prx_importer.prx.must_be_instance_of HyperResource
    end

    it 'wraps urls with count redirect' do
      url = prx_importer.count_audio_url('/audio_files/blah/1/test.mp3', 123, 456, 'thisis-aguid-fortesting')
      if use_webmock?
        url.must_equal "https://count.prx.org/redirect?action=request&action_value=%7B%22audioFileId%22%3A123%2C%22pieceId%22%3A456%7D&location=https%3A%2F%2Fhal.prx.org%2Faudio_files%2Fblah%2F1%2Ftest.mp3&referrer=https%3A%2F%2Fapi.pmp.io%2Fdocs%2Fthisis-aguid-fortesting"
      end
    end
  end

  describe "imports into pmp" do

    before {

      if use_webmock?

        ENV['PMP_CLIENT_ID'] = ""
        ENV['PMP_CLIENT_SECRET'] = ""

        stub_request(:get, "https://hal.prx.org/api/v1/").
          to_return(:status => 200, :body => json_file(:prx_root), :headers => {})

        stub_request(:get, "https://hal.prx.org/api/v1/stories/87683").
          to_return(:status => 200, :body => json_file(:prx_story), :headers => {})

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

        # Story start...

        # find story by tag
        stub_request(:get, "https://api.pmp.io/docs?itag=prx:stories-87683").
          to_return(:status => 200, :body => "", :headers => {})

        # Account

        # prx account
        stub_request(:get, "https://hal.prx.org/api/v1/accounts/45139").
          to_return(:status => 200, :body => json_file(:prx_account), :headers => {})

        # find account by tag
        stub_request(:get, "https://api.pmp.io/docs?itag=prx:accounts-45139").
          to_return(:status => 200, :body => "", :headers => {})

        # create account
        stub_request(:put, "https://publish.pmp.io/docs/9ff6db7a-93e6-4987-9313-4d70d74051b2").
          with(:body => "{\"version\":\"1.0\",\"links\":{\"profile\":[{\"href\":\"https://api.pmp.io/profiles/property\",\"type\":\"application/vnd.collection.doc+json\"}],\"alternate\":[{\"href\":\"https://www.prx.org/group_accounts/45139\"}]},\"attributes\":{\"guid\":\"9ff6db7a-93e6-4987-9313-4d70d74051b2\",\"title\":\"The Moth\",\"tags\":[\"PRX\"],\"itags\":[\"prx_test\",\"prx:accounts-45139\"]}}").
          to_return(:status => 200, :body => '{"url":"https://api.pmp.io/docs/9ff6db7a-93e6-4987-9313-4d70d74051b2"}', :headers => {})

        # Series

        # prx series
        stub_request(:get, "https://hal.prx.org/api/v1/series/32832").
          to_return(:status => 200, :body => json_file(:prx_series), :headers => {})

        # find series by tag
        stub_request(:get, "https://api.pmp.io/docs?itag=prx:series-32832").
          to_return(:status => 200, :body => "", :headers => {})

        # prx series image
        stub_request(:get, "https://hal.prx.org/api/v1/series_images/8696").
          to_return(:status => 200, :body => json_file(:prx_series_image), :headers => {})

        # find series image by tag
        stub_request(:get, "https://api.pmp.io/docs?itag=prx:series_images-8696").
          to_return(:status => 200, :body => "", :headers => {})

        # create image for series
        stub_request(:put, "https://publish.pmp.io/docs/9ff6db7a-93e6-4987-9313-4d70d74051b4").
          with(:body => "{\"version\":\"1.0\",\"links\":{\"profile\":[{\"href\":\"https://api.pmp.io/profiles/image\",\"type\":\"application/vnd.collection.doc+json\"}],\"enclosure\":[{\"href\":\"https://hal.prx.org/pub/e56ce22b1bce78de79993ebcccf76611/0/web/series_image/8696/medium/WEEKLY_LOGO.jpg\",\"type\":\"image/jpeg\",\"meta\":{\"crop\":\"medium\"}}]},\"attributes\":{\"guid\":\"9ff6db7a-93e6-4987-9313-4d70d74051b4\",\"title\":\"\",\"byline\":\"\",\"tags\":[\"PRX\"],\"itags\":[\"prx_test\",\"prx:series_images-8696\"]}}").
          to_return(:status => 200, :body => '{"url":"https://api.pmp.io/docs/9ff6db7a-93e6-4987-9313-4d70d74051b4"}', :headers => {})

        # create property for series
        stub_request(:put, "https://publish.pmp.io/docs/9ff6db7a-93e6-4987-9313-4d70d74051b3").
          with(:body => "{\"version\":\"1.0\",\"links\":{\"profile\":[{\"href\":\"https://api.pmp.io/profiles/series\",\"type\":\"application/vnd.collection.doc+json\"}],\"alternate\":[{\"href\":\"https://www.prx.org/series/32832\"}],\"item\":[{\"href\":\"https://api.pmp.io/docs/9ff6db7a-93e6-4987-9313-4d70d74051b4\",\"title\":\"\",\"rels\":[\"urn:collectiondoc:image\"]}]},\"attributes\":{\"guid\":\"9ff6db7a-93e6-4987-9313-4d70d74051b3\",\"title\":\"Moth Weekly Episodes for 2013\",\"description\":\"Brought to you by PRX and Jay Allison of Atlantic Public Media. Learn more about The Moth, the series and live events at prx.org/themoth. Please confirm carriage of The Moth Radio Hour by contacting Deb Blakeley at blakeley.deb@gmail.com.\",\"tags\":[\"PRX\"],\"itags\":[\"prx_test\",\"prx:series-32832\"]}}").
          to_return(:status => 200, :body => '{"url":"https://api.pmp.io/docs/9ff6db7a-93e6-4987-9313-4d70d74051b3"}', :headers => {})


        # Image

        # prx image file
        stub_request(:get, "https://hal.prx.org/api/v1/story_images/203874").
          to_return(:status => 200, :body => json_file(:prx_story_image), :headers => {})

        # find story image by tag
        stub_request(:get, "https://api.pmp.io/docs?itag=prx:story_images-203874").
          to_return(:status => 200, :body => "", :headers => {})

        # create image for story
        stub_request(:put, "https://publish.pmp.io/docs/9ff6db7a-93e6-4987-9313-4d70d74051b5").
          with(:body => "{\"version\":\"1.0\",\"links\":{\"profile\":[{\"href\":\"https://api.pmp.io/profiles/image\",\"type\":\"application/vnd.collection.doc+json\"}],\"enclosure\":[{\"href\":\"https://hal.prx.org/pub/f8b82b49a679ab9a621791bc9b752ff2/0/web/story_image/203874/medium/Moth_ElnaBaker_1301.jpg\",\"type\":\"image/jpeg\",\"meta\":{\"crop\":\"medium\"}}]},\"attributes\":{\"guid\":\"9ff6db7a-93e6-4987-9313-4d70d74051b5\",\"title\":\"Elna Baker\",\"byline\":\"Elna Baker\",\"tags\":[\"PRX\"],\"itags\":[\"prx_test\",\"prx:story_images-203874\"]}}").
          to_return(:status => 200, :body => '{"url":"https://api.pmp.io/docs/9ff6db7a-93e6-4987-9313-4d70d74051b5"}', :headers => {})

        # Audio

        # prx audio file
        stub_request(:get, "https://hal.prx.org/api/v1/audio_files/451642").
          to_return(:status => 200, :body => json_file(:prx_audio_file), :headers => {})

        # find audio by tag
        stub_request(:get, "https://api.pmp.io/docs?itag=prx:audio_files-451642").
          to_return(:status => 200, :body => "", :headers => {})

        # create audio
        stub_request(:put, "https://publish.pmp.io/docs/9ff6db7a-93e6-4987-9313-4d70d74051b6").
          with(:body => "{\"version\":\"1.0\",\"links\":{\"profile\":[{\"href\":\"https://api.pmp.io/profiles/audio\",\"type\":\"application/vnd.collection.doc+json\"}],\"enclosure\":[{\"href\":\"https://count.prx.org/redirect?action=request\\u0026action_value=%7B%22audioFileId%22%3A451642%2C%22pieceId%22%3A87683%7D\\u0026location=https%3A%2F%2Fhal.prx.org%2Fpub%2F472875466d225aca0480000fea4b5fc2%2F0%2Fweb%2Faudio_file%2F451642%2Fbroadcast%2FMoth1301GarrisonFinal.mp3\\u0026prx_story_id=87683\\u0026referrer=https%3A%2F%2Fapi.pmp.io%2Fdocs%2F9ff6db7a-93e6-4987-9313-4d70d74051b6\",\"type\":\"audio/mpeg\",\"meta\":{\"duration\":3179,\"size\":101617830}}]},\"attributes\":{\"guid\":\"9ff6db7a-93e6-4987-9313-4d70d74051b6\",\"title\":\"Moth 1301 Single File\",\"tags\":[\"PRX\"],\"itags\":[\"prx_test\",\"prx:audio_files-451642\"]}}").
          to_return(:status => 200, :body => '{"url":"https://api.pmp.io/docs/9ff6db7a-93e6-4987-9313-4d70d74051b6"}', :headers => {})

        # ... Story Finish

        # create story
        stub_request(:put, "https://publish.pmp.io/docs/9ff6db7a-93e6-4987-9313-4d70d74051b1").
          with(:body => "{\"version\":\"1.0\",\"links\":{\"profile\":[{\"href\":\"https://api.pmp.io/profiles/story\",\"type\":\"application/vnd.collection.doc+json\"}],\"collection\":[{\"href\":\"https://api.pmp.io/docs/9ff6db7a-93e6-4987-9313-4d70d74051b2\",\"title\":\"The Moth\",\"rels\":[\"urn:collectiondoc:collection:property\"]},{\"href\":\"https://api.pmp.io/docs/9ff6db7a-93e6-4987-9313-4d70d74051b3\",\"title\":\"Moth Weekly Episodes for 2013\",\"rels\":[\"urn:collectiondoc:collection:series\"]}],\"item\":[{\"href\":\"https://api.pmp.io/docs/9ff6db7a-93e6-4987-9313-4d70d74051b5\",\"title\":\"Elna Baker\",\"rels\":[\"urn:collectiondoc:image\"]},{\"href\":\"https://api.pmp.io/docs/9ff6db7a-93e6-4987-9313-4d70d74051b6\",\"title\":\"Moth 1301 Single File\",\"rels\":[\"urn:collectiondoc:audio\"]}],\"alternate\":[{\"href\":\"https://www.prx.org/pieces/87683\"}]},\"attributes\":{\"guid\":\"9ff6db7a-93e6-4987-9313-4d70d74051b1\",\"hreflang\":\"en\",\"title\":\"Virginity, Fidelity, and Fertility\",\"teaser\":\"A special live edition of The Moth at Town Hall in NYC with Garrison Keillor, with additional hosting by Jay Allison. World renowned conservationist and field biologist Alan Rabinowitz (\\\"Man and Beast\\\", MRH episode 902) makes a life-changing friendship while studying the Taron tribe of the Himilayas; a woman describes how her father’s risky entrepreneurial endeavors kept her close-knit Southern family in flux; and a woman raised as a Mormon is terrified that her parents will disown her when she confesses that she has left the faith. \\n\\n\\n \\n\",\"description\":\"Tina McElroy Ansa is a little girl when her father\\u0026rsquo;s business goes under and her family must leave their beloved, expansive home.Alan Rabinowitz treks through the Himilayas to study the Taron, a dying race of people, and makes discoveries about himself.\\u0026nbsp;\\nElna Baker must tell her Mormon parents that she has made an irreversible change in her life.\\n\\u0026nbsp;Hosted by Jay Allison/Garrison Keillor\\u0026nbsp;\",\"contentencoded\":\"\\u003cdiv\\u003eTina McElroy Ansa is a little girl when her father\\u0026rsquo;s business goes under and her family must leave their beloved, expansive home.\\u003cbr /\\u003e\\u003cbr /\\u003eAlan Rabinowitz treks through the Himilayas to study the Taron, a dying race of people, and makes discoveries about himself.\\u003cbr /\\u003e\\u0026nbsp;\\u003c/div\\u003e\\n\\u003cdiv\\u003eElna Baker must tell her Mormon parents that she has made an irreversible change in her life.\\u003c/div\\u003e\\n\\u003cdiv\\u003e\\u0026nbsp;\\u003cbr /\\u003eHosted by Jay Allison/Garrison Keillor\\u0026nbsp;\\u003c/div\\u003e\",\"byline\":\"The Moth\",\"published\":\"2012-12-20T18:57:45.000+00:00\",\"valid\":{\"from\":\"2012-12-20T18:57:45.000+00:00\",\"to\":\"3012-12-20T18:57:45.000+00:00\"},\"tags\":[\"PRX\",\"Weekly Program\"],\"itags\":[\"prx_test\",\"prx:stories-87683\"]}}").
          to_return(:status => 200, :body => '{"url":"https://api.pmp.io/docs/9ff6db7a-93e6-4987-9313-4d70d74051b1"}', :headers => {})

        # stub the guid to a predictable value
        PMPGuidMapping.class_eval do

          cattr_accessor :counter

          def self.next_counter
            self.counter = self.counter.to_i + 1
          end

          def self.new_guid
            '9ff6db7a-93e6-4987-9313-4d70d74051b' + next_counter.to_s
          end

        end

      else

        # delete to clean up prior runs
        pi = PRXImporter.new
        delete_count = 0

        puts "delete prx_test: #{pi.pmp.inspect}\n\n"
        items = pi.pmp.query["urn:collectiondoc:query:docs"].where(itag: 'prx_test', limit: 100).items
        puts "\n\nitems: #{items.inspect}\n\nitems json: #{items.to_json}\n\n"

        items.each{|i|
          puts "#{i.to_json}\n\n"
          i.delete rescue nil
          delete_count+=1
        }
        puts "deleted #{delete_count}"
      end

    }

    let(:prx_importer) { PRXImporter.new }

    it "imports a prx piece" do
      doc = prx_importer.import(prx_story_id: 87683)

      doc.title.must_equal "Virginity, Fidelity, and Fertility"
      doc.tags.sort.must_equal  ["PRX", "Weekly Program"]
      doc.itags.sort.must_equal  ["prx:stories-87683", "prx_test"]

      doc.links['profile'].href.must_match /story$/
      doc.links['collection'].count.must_equal 2
      doc.links['item'].count.must_equal 2
      doc.links['alternate'].first.href.must_equal "https://www.prx.org/pieces/87683"
    end

  end

end
