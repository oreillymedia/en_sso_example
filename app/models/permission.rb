module Permission
  module_function
  extend ActiveSupport::Benchmarkable

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

    solutions.map {|sol| Product.from_uri(sol.product_uri) }
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

    logger.debug "Fetching permissions from #{filter_uri_password(uri)}"
    rdf = fetch_body(uri)

    # Since not loading from URL or file, we need to hint the serialization
    # format of the RDF.
    stmts = RDF::Reader.for(:rdfxml).new(rdf)
    # ...and it seems as a result we have to create a graph and then add to it
    graph = RDF::Graph.new
    graph.insert stmts

    graph
  end

  def perms
    @perms_namespace ||=
      RDF::Vocabulary.new("http://purl.oreilly.com/permission/")
  end

  def fetch_body(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.read_timeout = 5
    http.open_timeout = 5

    # SSL stuff
    if uri.scheme == "https"
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      http.ca_file = "#{Rails.root}/config/ca-certificates.crt"
    end

    # Basic auth stuff
    req = Net::HTTP::Get.new(uri.request_uri)
    req.basic_auth uri.user, uri.password

    resp = benchmark("GET #{uri.request_uri}") { http.request(req) }

    # Raise on error
    resp.value

    resp.body
  end

  def filter_uri_password(original_uri)
    uri = original_uri.clone
    if uri.password
      uri.password = "*" * uri.password.length
    end
    uri
  end

  def logger
    Rails.logger
  end
end
