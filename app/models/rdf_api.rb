module RdfApi
  include ActiveSupport::Benchmarkable

  def fetch_graph(uri)
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
