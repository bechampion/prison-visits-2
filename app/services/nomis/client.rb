require 'excon'
require 'excon/middleware/custom_idempotent'
require 'excon/middleware/custom_instrumentor'
require 'excon/middleware/deadline'

module Nomis
  APIError = Class.new(StandardError)

  class Client
    TIMEOUT = 2 # seconds
    EXCON_INSTRUMENT_NAME = 'nomis_api'.freeze

    def initialize(host, client_token, client_key)
      @host = host
      @client_token = client_token
      @client_key = client_key

      @connection = Excon.new(
        host, persistent: true,
              connect_timeout: TIMEOUT, read_timeout: TIMEOUT, write_timeout: TIMEOUT,
              middlewares: excon_middlewares,
              instrumentor: ActiveSupport::Notifications,
              instrumentor_name: EXCON_INSTRUMENT_NAME)
    end

    def get(route, params = {})
      request(:get, route, params, idempotent: true)
    end

    def post(route, params, idempotent:)
      request(:post, route, params, idempotent: idempotent)
    end

  private

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/AbcSize
    def request(method, route, params, idempotent:)
      # For cleanliness, strip initial / if supplied
      route = route.sub(%r{^\/}, '')
      path = "/nomisapi/#{route}"
      api_method = "#{method.to_s.upcase} #{path}"

      options = {
        method: method,
        path: path,
        expects: http_method_expects(method),
        idempotent: idempotent,
        deadline: RequestStore.store[:deadline],
        retry_limit: 2,
        headers: {
          'Accept' => 'application/json',
          'Authorization' => auth_header,
          'X-Request-Id' => RequestStore.store[:request_id]
        }
      }.deep_merge(params_options(method, params))

      response = @connection.request(options)

      JSON.parse(response.body)
    rescue Excon::Errors::HTTPStatusError => e
      body = e.response.body

      # API errors should be returned as JSON, but there are many scenarios
      # where this may not be the case.
      begin
        error = JSON.parse(body)
      rescue JSON::ParserError
        # Present non-JSON bodies truncated (e.g. this could be HTML)
        error = "(invalid-JSON) #{body[0, 80]}"
      end

      Raven.capture_exception(e, fingerprint: excon_fingerprint)
      raise APIError,
        "Unexpected status #{e.response.status} calling #{api_method}: #{error}"
    rescue Excon::Errors::Error => e
      Raven.capture_exception(e, fingerprint: excon_fingerprint)
      raise APIError, "Exception #{e.class} calling #{api_method}: #{e}"
    end
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/AbcSize

    def http_method_expects(method)
      if method == :get
        [200]
      else
        # TODO: Add 409 when idempotency key is ready
        # TODO: Change 400 to 422 when api is updated.
        # Currently it returns 400 for validation errors.
        [200, 400, 409]
      end
    end

    # Returns excon options which put params in either the query string or body.
    def params_options(method, params)
      return {} if params.empty?

      if %i[get delete].include?(method)
        { query: params }
      else
        {
          body: params.to_json,
          headers: { 'Content-Type' => 'application/json' }
        }
      end
    end

    def auth_header
      return unless @client_token && @client_key

      token = auth_token(@client_token, @client_key)
      "Bearer #{token}"
    end

    def auth_token(client_token, client_key)
      payload = {
        iat: Time.now.to_i,
        token: client_token
      }
      JWT.encode(payload, client_key, 'ES256')
    end

    def excon_fingerprint
      %w[nomis excon]
    end

    # Custom middlewares for:
    # - Setting an overall deadline
    # - Modifying the Idempotent middleware so that it doesn't retry Timeouts
    # - Modify the Instrumentor middleware so that it doesn't error on the
    # response call and put it at the start of the stack so that it measures the
    # time taken to read the response.
    def excon_middlewares
      [
        Excon::Middleware::CustomInstrumentor,
        Excon::Middleware::Mock,
        Excon::Middleware::Deadline,
        Excon::Middleware::ResponseParser,
        Excon::Middleware::Expects,
        Excon::Middleware::CustomIdempotent
      ]
    end
  end
end
