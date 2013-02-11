class ApplicationController < ActionController::Base
  protect_from_forgery

  # Determine whether the current_user is permitted to access the current
  # product.
  #
  # For brevity, punt on making sure the request times out promptly... to do
  # that, use Net::HTTP, invoke the RDFXML Reader directly, and insert the
  # RDF into an empty graph.
  def authorize_user!
    # MapReduce Design Patterns (PDF)
    product_uri = "urn:x-domain:oreilly.com:product:9781449341992.PDF"
    product = Product.from_uri(product_uri)

    if Permission.can_access(current_user, product)
      return true
    end

    title, oracle_id = product.title, product.oracle_id
    flash[:alert] = "You are not authorized to access: #{title} (#{oracle_id})"
    redirect_to root_path
  end
end
