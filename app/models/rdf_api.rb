module RdfApi
  include HttpApi

  def fetch_graph(uri)
    logger.debug "Fetching permissions from #{filter_uri_password(uri)}"
    rdf = fetch_body(uri)

    benchmark "parse resulting graph" do
      # Since not loading from URL or file, we need to hint the serialization
      # format of the RDF.
      stmts = RDF::Reader.for(:rdfxml).new(rdf)
      # ...and it seems as a result we have to create a graph and then add to it
      graph = RDF::Graph.new
      graph.insert stmts

      graph
    end
  end

end
