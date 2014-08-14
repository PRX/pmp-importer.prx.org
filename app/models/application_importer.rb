class ApplicationImporter

  attr_accessor :options

  def source_name
    raise NotImplementedError.new("Subclass must implement source_name")
  end

  def initialize(options={})
    self.options = HashWithIndifferentAccess.new(options)
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
    options[:pmp_endpoint] || ENV['PMP_ENDPOINT'] || 'https://api-sandbox.pmp.io/'
  end

  def pmp_doc_find_first(conditions)
    pmp.query["urn:collectiondoc:query:docs"].where(conditions.merge(limit: 1)).items.first
  end

  def add_tag_to_doc(tag, doc)
    doc.tags = doc.tags || []
    return if doc.tags.include?(tag)
    doc.tags << tag
  end

  def strip_tags(text)
    ActionController::Base.helpers.strip_tags(text)
  end

end
