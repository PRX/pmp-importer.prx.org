class FeedResponse < ActiveRecord::Base

  # Internal: List of status codes that can be cached:
  # * 200 - 'OK'
  # * 203 - 'Non-Authoritative Information'
  # * 300 - 'Multiple Choices'
  # * 301 - 'Moved Permanently'
  # * 302 - 'Found'
  # * 404 - 'Not Found'
  # * 410 - 'Gone'
  CACHEABLE_STATUS_CODES = [200, 203, 300, 301, 302, 404, 410]

  before_validation :fix_max_age

  belongs_to :feed

  FARADAY_RESPONSE_ATTRIBUTES = [:url, :status, :body, :request, :request_headers, :response_headers]

  serialize :request
  serialize :request_headers
  serialize :response_headers

  def self.for_response(response)
    self.new(response.to_hash.slice(*FARADAY_RESPONSE_ATTRIBUTES)).tap do |f|
      f.now
      f.url           = f.url.to_s
      f.etag          = f.headers['ETag']
      f.last_modified = f.headers['Last-Modified']
      f.fix_max_age
    end
  end

  def headers
    self.response_headers
  end

  def now
    @now ||= Time.now
  end

  # Internal: Checks the response freshness based on expiration headers.
  # The calculated 'ttl' should be present and bigger than 0.
  #
  # Returns true if the response is fresh, otherwise false.
  def fresh?
    ttl && ttl > 0
  end

  # Internal: Checks if the Response returned a 'Not Modified' status.
  #
  # Returns true if the response status code is 304.
  def not_modified?
    status == 304
  end

  # Internal: Gets the response age in seconds.
  #
  # Returns the 'Age' header if present, or subtracts the response 'date'
  # from the current time.
  def age
    (headers['Age'] || (now - date)).to_i
  end

  # Internal: Calculates the 'Time to live' left on the Response.
  #
  # Returns the remaining seconds for the response, or nil the 'max_age'
  # isn't present.
  def ttl
    max_age - age if max_age
  end

  # Internal: Parses the 'Date' header back into a Time instance.
  #
  # Returns the Time object.
  def date
    Time.httpdate(headers['Date'])
  end

  # Internal: Gets the response max age.
  # The max age is extracted from one of the following:
  # * The shared max age directive from the 'Cache-Control' header;
  # * The max age directive from the 'Cache-Control' header;
  # * The difference between the 'Expires' header and the response
  #   date.
  #
  # Returns the max age value in seconds or nil if all options above fails.
  def max_age
    cache_control.shared_max_age ||
      cache_control.max_age ||
      (expires && (expires - now))
  end

  # # Internal: Checks if this response can be revalidated.
  # #
  # # Returns true if the 'headers' contains a 'Last-Modified' or an 'ETag'
  # # entry.
  # def validateable?
  #   headers.key?('Last-Modified') || headers.key?('ETag')
  # end

  # # Internal: The logic behind cacheable_in_private_cache? and
  # # cacheable_in_shared_cache? The logic is the same except for the
  # # treatment of the private Cache-Control directive.
  # def cacheable?(shared_cache)
  #   return false if (cache_control.private? && shared_cache) || cache_control.no_store?

  #   cacheable_status_code? && (validateable? || fresh?)
  # end

  # # Internal: Validates the response status against the
  # # `CACHEABLE_STATUS_CODES' constant.
  # #
  # # Returns true if the constant includes the response status code.
  # def cacheable_status_code?
  #   CACHEABLE_STATUS_CODES.include?(status)
  # end

  # Internal: Gets the 'Expires' in a Time object.
  #
  # Returns the Time object, or nil if the header isn't present.
  def expires
    headers['Expires'] && Time.httpdate(headers['Expires'])
  end

  # Internal: Gets the 'CacheControl' object.
  def cache_control
    @cache_control ||= CacheControl.new(headers['Cache-Control'])
  end

  # Internal: Prepares the response headers to be cached.
  #
  # It removes the 'Age' header if present to allow cached responses
  # to continue aging while cached. It also normalizes the 'max-age'
  # related headers if the 'Age' header is provided to ensure accuracy
  # once the 'Age' header is removed.
  #
  # Returns nothing.
  def fix_max_age
    if headers.key? 'Age'
      cache_control.normalize_max_ages(headers['Age'].to_i)
      headers.delete 'Age'
      headers['Cache-Control'] = cache_control.to_s
    end
  end

end
