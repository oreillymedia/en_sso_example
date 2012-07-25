module ApplicationHelper
  def shop_url(product)
    "http://oreilly.com/catalog/#{product.isbn}"
  end
end
