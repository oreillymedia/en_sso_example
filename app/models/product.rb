class Product
  include RdfApi

  attr_reader :uri

  def self.from_uri(product_uri)
    new.tap do |product|
      product.instance_variable_set('@uri', product_uri)
    end
  end

  def isbn
    # Format: urn:x-domain:oreilly.com:product:9780596103866.EBOOK
    re = /\Aurn:x-domain:oreilly.com:product:([0-9]+)\.[A-Z]+\Z/
    m = re.match(uri)
    return m[1] if m
  end

  def title
    fetch_title
  end

  def fetch_title
    api_uri = URI.parse("http://opmi.labs.oreilly.com/product/#{self.isbn}")
    graph = fetch_graph(api_uri)

    query = RDF::Query.new({
      RDF::URI.new(self.uri) => {
        RDF.type => om.Product,
        om.customerTitle => :title,
      }
    })
    solutions = query.execute(graph)

    logger.debug "Solution count: #{solutions.count}"
    logger.debug "First solution: #{solutions.first.inspect}"

    soln = solutions.first
    soln.title.to_s if soln
  end

  def om
    @@om_namespace ||= RDF::Vocabulary.new("http://purl.oreilly.com/ns/meta/")
  end
end
