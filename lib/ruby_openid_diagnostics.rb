module OpenID
  class StandardFetcher
    def fetch(url, body=nil, headers=nil, redirect_limit=REDIRECT_LIMIT)
      unparsed_url = url.dup
      url = URI::parse(url)
      if url.nil?
        raise FetchingError, "Invalid URL: #{unparsed_url}"
      end

      headers ||= {}
      headers['User-agent'] ||= USER_AGENT

      begin
        Rails.logger.info("#{__method__} url: "+url.inspect)
        conn = make_connection(url)
        response = nil

        response = conn.start {
          # Check the certificate against the URL's hostname
          if supports_ssl?(conn) and conn.use_ssl?
            conn.post_connection_check(url.host)
          end

          if body.nil?
            conn.request_get(url.request_uri, headers)
          else
            headers["Content-type"] ||= "application/x-www-form-urlencoded"
            conn.request_post(url.request_uri, body, headers)
          end
        }
        setup_encoding(response)
      rescue Timeout::Error => why
        raise FetchingError, "Error fetching #{url}: #{why}"
      rescue RuntimeError => why
        raise why
      rescue OpenSSL::SSL::SSLError => why
        raise SSLFetchingError, "Error connecting to SSL URL #{url}: #{why}"
      rescue FetchingError => why
        raise why
      rescue Exception => why
        Rails.logger.info why.message+"\n    "+why.backtrace.join("\n    ")
        raise FetchingError, "Error fetching #{url}: #{why}"
      end

      case response
      when Net::HTTPRedirection
        if redirect_limit <= 0
          raise HTTPRedirectLimitReached.new(
            "Too many redirects, not fetching #{response['location']}")
        end
        begin
          return fetch(response['location'], body, headers, redirect_limit - 1)
        rescue HTTPRedirectLimitReached => e
          raise e
        rescue FetchingError => why
          raise FetchingError, "Error encountered in redirect from #{url}: #{why}"
        end
      else
        return HTTPResponse._from_net_response(response, unparsed_url)
      end
    end
  end

  module Yadis
    def self.discover(uri)
      result = DiscoveryResult.new(uri)
      begin
        resp = OpenID.fetch(uri, nil, {'Accept' => YADIS_ACCEPT_HEADER})
      rescue Exception
        Rails.logger.info $!.message+"\n    "+$!.backtrace.join("\n    ")
        raise DiscoveryFailure.new("Failed to fetch identity URL #{uri} : #{$!}", $!)
      end
      if resp.code != "200" and resp.code != "206"
        raise DiscoveryFailure.new(
                "HTTP Response status from identity URL host is not \"200\"."\
                "Got status #{resp.code.inspect} for #{resp.final_url}", resp)
      end

      # Note the URL after following redirects
      result.normalized_uri = resp.final_url

      # Attempt to find out where to go to discover the document or if
      # we already have it
      result.content_type = resp['content-type']

      result.xrds_uri = self.where_is_yadis?(resp)

      if result.xrds_uri and result.used_yadis_location?
        begin
          resp = OpenID.fetch(result.xrds_uri)
        rescue
          raise DiscoveryFailure.new("Failed to fetch Yadis URL #{result.xrds_uri} : #{$!}", $!)
        end
        if resp.code != "200" and resp.code != "206"
            exc = DiscoveryFailure.new(
                    "HTTP Response status from Yadis host is not \"200\". " +
                                       "Got status #{resp.code.inspect} for #{resp.final_url}", resp)
            exc.identity_url = result.normalized_uri
            raise exc
        end

        result.content_type = resp['content-type']
      end

      result.response_text = resp.body
      return result
    end
  end
end
