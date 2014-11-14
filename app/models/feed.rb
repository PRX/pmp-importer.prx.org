# each entry, determine if new (e.g. new entry id)
require 'object_digest'

class Feed < ActiveRecord::Base

  has_many :responses, class_name: 'FeedResponse'
  has_many :entries, class_name: 'FeedEntry'

  serialize :options

  def sync(force=false)
    return unless response = updated_response(force)

    feed = Feedjira::Feed.parse(response.body)
    feed_importer = FeedImporter.new(options || {})

    feed.entries.each do |entry|
      insert_or_update_entry(entry)
    end
  end

  def insert_or_update_entry(entry)
    if current = find_entry(entry)
      current.update_with_entry(entry)
    else
      FeedEntry.create_with_entry(self, entry)
    end
  end

  def find_entry(entry)
    if !entry.entry_id.blank?
      entries.where(entry_id: entry.entry_id).first
    elsif !entry.url.blank?
      entries.where(url: entry.url).first
    else
      entries.where(digest: FeedEntry.entry_digest(entry)).first
    end
  end

  def updated_response(force=false)
    response = nil

    last_response = last_successful_response

    response = if (force || last_response.nil?)
      retrieve
    elsif !last_response.fresh?
      validate_response(last_response)
    end

    response
  end

  def retrieve
    http_response = connection.get(uri.path)
    response = FeedResponse.for_response(http_response)
    self.responses << response

    response
  end

  def validate_response(last_response)
    http_response = connection.get do |req|
      req.url uri.path
      req.headers['If-Modified-Since'] = last_response.last_modified if last_response.last_modified
      req.headers['If-None-Match']     = last_response.etag if last_response.etag
    end

    response = FeedResponse.for_response(http_response)
    if response.not_modified?
      response = nil
    else
      self.responses << response
    end

    response
  end

  def uri
    @uri ||= URI.parse(feed_url)
  end

  def connection
    client = Faraday.new("#{uri.scheme}://#{uri.host}:#{uri.port}") {|stack| stack.adapter :excon }
  end

  def last_successful_response
    responses.where(url: url, status: '200').order(created_at: :desc).first
  end

end
