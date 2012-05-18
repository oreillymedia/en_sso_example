class Rack::OpenID
    private
      # Copied and tweaked from rack-openid gem
      def begin_authentication(env, qs)
        req = Rack::Request.new(env)
        params = self.class.parse_header(qs)
        session = env["rack.session"]

        unless session
          raise RuntimeError, "Rack::OpenID requires a session"
        end

        consumer   = ::OpenID::Consumer.new(session, @store)
        identifier = params['identifier'] || params['identity']
        immediate  = params['immediate'] == 'true'

        begin
          oidreq = consumer.begin(identifier)
          add_simple_registration_fields(oidreq, params)
          add_attribute_exchange_fields(oidreq, params)
          add_oauth_fields(oidreq, params)
          url = open_id_redirect_url(req, oidreq, params["trust_root"], params["return_to"], params["method"], immediate)
          return redirect_to(url)
        rescue ::OpenID::OpenIDError, Timeout::Error => e
          # Add additional spew 
          Rails.logger.error "#{__FILE__}:#{__LINE__} #{__method__}: #{e.inspect}"
          env[RESPONSE] = MissingResponse.new
          return @app.call(env)
        end
      end
end

