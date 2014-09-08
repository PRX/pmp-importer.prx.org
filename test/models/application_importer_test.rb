require 'test_helper'

describe ApplicationImporter do

  let(:importer) {ApplicationImporter.new }

  it 'accepts options' do
    options = {}
    ApplicationImporter.new(options).options.must_equal options
  end

  it 'has no source name' do 
    lambda { importer.source_name }.must_raise(NotImplementedError)
  end

  it 'import accepts options' do
    importer.import({"a" => 1}).must_equal Hash({"a" => 1})
  end

  it 'returns a memoized pmp client object' do
    importer.pmp.must_be_instance_of PMP::Client
    importer.pmp.must_equal importer.pmp
  end

  it 'has optional or env based pmp id, secret and endpoint' do
    {pmp_client_id: nil, pmp_client_secret: nil, pmp_endpoint: 'https://api-sandbox.pmp.io/'}.each  do |k, v|
      env_key = k.to_s.upcase
      ENV[env_key] = nil
      importer.send(k).must_equal v

      ENV[env_key] = "#{k}_1"
      importer.send(k).must_equal "#{k}_1"

      importer.options[k] = "#{k}_2"
      importer.send(k).must_equal "#{k}_2"

      ENV[env_key] = nil # reset
    end
  end

  it 'constructs pmp url from endpoint and args' do
    importer.pmp_url('foo').must_equal "#{importer.pmp_endpoint}foo"
    importer.pmp_url('foo', 'bar', 1).must_equal "#{importer.pmp_endpoint}foo/bar/1"
    importer.pmp_url('foo/bar', '1').must_equal "#{importer.pmp_endpoint}foo/bar/1"
    importer.pmp_url('foo/bar/1').must_equal "#{importer.pmp_endpoint}foo/bar/1"
  end

  it 'finds the first pmp doc that matches conditions' do

    stub_request(:get, "https://api-sandbox.pmp.io/").
      to_return(:status => 200, :body => json_file(:pmp_root), :headers => {})

    stub_request(:get, "https://api-sandbox.pmp.io/docs?limit=1").
      to_return(:status => 200, :body => '{"items":[{"attributes":{"a":"1"}}]}', :headers => {})

    result = importer.pmp_doc_find_first({}).a.must_equal "1"



    stub_request(:get, "https://api-sandbox.pmp.io/docs?guid=onlythelonely&limit=1").
      to_return(:status => 200, :body => '{"items":[{"attributes":{"a":"2"}}]}', :headers => {})

    result = importer.pmp_doc_find_first({guid: 'onlythelonely'}).a.must_equal "2"
  end

  describe "doc based methods" do

    let(:doc) { importer.pmp.doc_of_type('story') }

    it 'gets the profile for a doc' do
      importer.pmp_doc_profile(doc).must_equal 'story'
    end

    it 'adds tags to the doc, starting with nil and no duplicates' do
      doc.tags.must_equal nil

      importer.add_tag_to_doc(doc, 'foo')
      doc.tags.must_equal ['foo']

      importer.add_tag_to_doc(doc, 'bar')
      doc.tags.must_equal ['foo', 'bar']

      importer.add_tag_to_doc(doc, 'bar')
      doc.tags.must_equal ['foo', 'bar']
    end

    it 'adds links to the doc, starting with nil and no duplicates' do
      doc.links.keys.must_equal ['profile']

      doc.links['foo'].must_equal nil
      importer.add_link_to_doc(doc, 'foo', {href: 'http://example.org/foo'})

      doc.links.keys.sort.must_equal ['foo', 'profile']
      doc.links['foo'].must_be_instance_of Array

      link = doc.links['foo'].first
      link.must_be_instance_of PMP::Link
      link.href.must_equal 'http://example.org/foo'
    end

    it 'will not add link with dupe rel and href' do    
      importer.add_link_to_doc(doc, 'foo', {href: 'http://example.org/foo'})
      importer.add_link_to_doc(doc, 'foo', {href: 'http://example.org/bar'})
      importer.add_link_to_doc(doc, 'foo', {href: 'http://example.org/foo'})

      doc.links['foo'].must_be_instance_of Array
      doc.links['foo'].size.must_equal 2
      doc.links['foo'].collect{|l| l.href}.sort.must_equal ['http://example.org/bar', 'http://example.org/foo']
    end

    it 'provides convenience method to strip html tags' do
      importer.strip_tags('<b>what</b>').must_equal 'what'
    end

  end
end
