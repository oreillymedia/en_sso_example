module Permission
  module_function
  extend RdfApi

  def permitted_products(user)
    identity_url = user.identity_url
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

  def can_access(user, product)
    user_guid = user.identity_guid
    isbn, format = product.isbn, product.format_code.downcase
    url = Rails.configuration.oreilly.permissions_service_url
    url += "/v1/permissions"
    url += "/owners/#{user_guid}/products/#{isbn}/formats/#{format}"

    resp = fetch_response(URI.parse(url))
    logger.info "Response code: #{resp.code} (#{resp.message})"

    case resp.code.to_i
    when 200, 204 then true
    when 404 then false
    else resp.error!
    end
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
