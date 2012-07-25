module Permission
  module_function
  extend RdfApi

  def permitted_products(identity_url)
    graph = fetch_permissions_graph(:grantee => identity_url)

    query = RDF::Query.new({
      :permission => {
        RDF.type  => perms.Permission,
        perms.grantee => RDF::URI.new(identity_url),
        perms.accessTo => :product_uri,
      }
    })
    solutions = query.execute(graph)

    logger.debug "Solution count: #{solutions.count}"
    logger.debug "First solution: #{solutions.first.inspect}"

    solutions.map {|sol| Product.from_uri(sol.product_uri.try(&:to_s)) }
  end

  def can_access(identity_url, product_uri)
    graph = fetch_permissions_graph(:grantee => identity_url,
                                    :accessTo => product_uri)

    # We could probably just call graph.count and ensure the answer is not zero,
    # but for thoroughness, let's actually ensure the returned graph contains
    # the applicable permission.

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
      logger.debug "Solution: #{solutions.first.inspect}"
      return true
    end

    return false
  end

  def fetch_permissions_graph(parameters)
    uri = URI.parse(Rails.configuration.oreilly.permissions_api_url)
    uri.query = parameters.to_query

    fetch_graph(uri)
  end

  def perms
    @perms_namespace ||=
      RDF::Vocabulary.new("http://purl.oreilly.com/permission/")
  end

end
