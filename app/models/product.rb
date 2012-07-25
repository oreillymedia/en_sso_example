class Product

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

end
