class Product
  include RdfApi

  attr_reader :uri, :isbn, :format_code

  def self.from_uri(product_uri)
    new(product_uri)
  end

  def initialize(product_uri)
    @uri = product_uri

    # Format: urn:x-domain:oreilly.com:product:9780596103866.EBOOK
    re = /\Aurn:x-domain:oreilly.com:product:([0-9]+)\.([A-Z]+)\Z/
    m = re.match(uri)
    @isbn, @format_code = m[1], m[2]
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
