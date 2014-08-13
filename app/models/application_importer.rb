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

end
