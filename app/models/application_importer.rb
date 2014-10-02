class ApplicationImporter

  attr_accessor :options

  def logger
    @logger = Rails.logger
  end

  def initialize(options={})
    self.options = HashWithIndifferentAccess.new(options)
  end

  def source_name
    raise NotImplementedError.new("Subclass must implement source_name")
  end

  def import(options)
    self.options.merge!(options)
  end

  def pmp
    @pmp ||= PMP::Client.new(client_id: pmp_client_id, client_secret: pmp_client_secret, endpoint: pmp_endpoint)
  end

  def pmp_client_id
    options[:pmp_client_id] || ENV['PMP_CLIENT_ID']
  end

  def pmp_client_secret
    options[:pmp_client_secret] || ENV['PMP_CLIENT_SECRET']
  end

  def pmp_endpoint
    options[:pmp_endpoint] || ENV['PMP_ENDPOINT'] || 'https://api.pmp.io/'
  end

  def pmp_url(*path)
    URI.join(pmp_endpoint, *path.collect(&:to_s).join('/')).to_s
  end

  def pmp_doc_by_guid(guid)
    response = pmp.query["urn:collectiondoc:hreftpl:docs"].where(guid: guid).get

    response = nil if (response.response.raw['status'] == '404')
    response = nil if response.response.raw['body'].blank?

    response
  end

  def pmp_doc_find_first(conditions)
    response = pmp.query["urn:collectiondoc:query:docs"].where(conditions).get
    response.items.first
  end

  def retrieve_doc(type, url)
    doc = nil

    guid = PMPGuidMapping.find_guid(source_name, type, url)

    if guid
      doc = pmp_doc_by_guid(guid)
    end

    # no guid yet? look to see if a doc has the right tag
    if !doc
      itag = tag_for_url(source_name, url)
      doc = pmp_doc_find_first(itag: itag)

      if doc && !guid
        PMPGuidMapping.create(source_name: source_name, source_type: type, source_id: url, guid: doc.guid)
      end
    end

    doc
  end

  def tag_for_url(source, url)
    "#{source}:#{url}"
  end

  # these below could all be class methods I think

  def pmp_doc_profile(doc)
    # puts "doc.links['profile']: #{doc.links['profile'].inspect}"
    if profile_link = doc.links['profile']
      profile_link = profile_link.is_a?(Array) ? profile_link.first : profile_link
      profile_link.href.split('/').last.downcase
    end
  end

  def add_tag_to_doc(doc, tag)
    doc.tags ||= []
    return if doc.tags.include?(tag)
    doc.tags << tag
  end

  def add_itag_to_doc(doc, tag)
    doc.itags ||= []
    return if doc.itags.include?(tag)
    doc.itags << tag
  end

  def add_link_to_doc(doc, rel, link_attrs)
    doc.links[rel] ||= []
    return if Array(doc.links[rel]).detect{|l| l[:href] == link_attrs[:href]}
    doc.links[rel] << PMP::Link.new(link_attrs)
  end

  def strip_tags(text)
    ActionController::Base.helpers.strip_tags(text)
  end

end
