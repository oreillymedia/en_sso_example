class ApplicationController < ActionController::Base
  protect_from_forgery

  # Determine whether the current_user is permitted to access the current
  # product.
  #
  # For brevity, punt on making sure the request times out promptly... to do
  # that, use Net::HTTP, invoke the RDFXML Reader directly, and insert the
  # RDF into an empty graph.
  def authorize_user!
    identity_url = current_user.identity_url
    # Enterprise Rails (Ebook)
    product_uri = "urn:x-domain:oreilly.com:product:9780596515201.EBOOK"

    uri = URI.parse(Rails.configuration.oreilly.permissions_api_url)
    uri.query = { :grantee => identity_url, :accessTo => product_uri }.to_query

    # Make Graph.load work with https
    ENV['SSL_CERT_FILE'] ||= "#{Rails.root}/config/ca-certificates.crt"

    # We could probably just call graph.count and ensure the answer is not zero,
    # but for thoroughness, let's actually ensure the returned graph contains
    # the applicable permission.
    logger.debug "Loading permission from #{uri}"
    RDF::Graph.load(uri) do |graph|
      perms = RDF::Vocabulary.new("http://purl.oreilly.com/permission/")
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
        logger.debug solutions.first.inspect
        return true
      end
    end

    flash[:alert] = "You are not authorized to access: Enterprise Rails (Ebook)"
    redirect_to root_path
  end
end
