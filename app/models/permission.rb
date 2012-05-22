module Permission
  module_function

  def can_access(identity_url, product_uri)
    uri = URI.parse(Rails.configuration.oreilly.permissions_api_url)
    uri.query = { :grantee => identity_url, :accessTo => product_uri }.to_query

    # Make Graph.load work with https
    ENV['SSL_CERT_FILE'] ||= "#{Rails.root}/config/ca-certificates.crt"

    # We could probably just call graph.count and ensure the answer is not zero,
    # but for thoroughness, let's actually ensure the returned graph contains
    # the applicable permission.
    logger.debug "Loading permission from #{uri}"
    RDF::Graph.load(uri) do |graph|
      perms = RDF::Vocabulary.new("http://purl.oreilly.com/permission/")
      query = RDF::Query.new({
        :permission => {
          RDF.type  => perms.Permission,
          perms.grantee => RDF::URI.new(identity_url),
          perms.accessTo => RDF::URI.new(product_uri),
        }
      })
      solutions = query.execute(graph)

      # This permission should not be repeated, in fact there should only be
      # one permission in the response.
      if solutions.count == 1
        logger.debug solutions.first.inspect
        return true
      end
    end

    return false
  end

  def logger
    Rails.logger
  end
end
