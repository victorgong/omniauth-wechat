require 'cgi'
require 'uri'
require 'oauth2'
require 'omniauth'
require 'timeout'
require 'securerandom'

module OmniAuth
  module Strategies
    class WeChat
      include OmniAuth::Strategy
      args [:appid, :secret]
      option :appid, nil
      option :secret, nil
      option :name, "wechat"
      option :authorize_params, {}
      option :authorize_options, [:scope]
      option :token_params, {}
      option :token_options, []
      option :auth_token_params, {}
      option :client_options, {
          :site => 'https://api.weixin.qq.com',
          :authorize_url => 'https://open.weixin.qq.com/connect/oauth2/authorize',
          :token_url => 'https://api.weixin.qq.com/sns/oauth2/access_token',
          :token_method => :get,
          :raise_errors => false
      }

      attr_accessor :access_token

      def client(opt={})
        client_options = options.client_options.merge(opt)
        ::OAuth2::Client.new(options.appid, options.secret, deep_symbolize(client_options))
      end

      credentials do
        hash = {'token' => access_token.token}
        hash.merge!('refresh_token' => access_token.refresh_token) if access_token.expires? && access_token.refresh_token
        hash.merge!('expires_at' => access_token.expires_at) if access_token.expires?
        hash.merge!('expires' => access_token.expires?)
        hash
      end

      def request_phase
        redirect client.authorize_url(authorize_params)+'#wechat_redirect'
      end

      def authorize_params
        state_param = SecureRandom.hex(24)
        options.authorize_params.merge({:appid => options.appid,
                                        :redirect_uri => callback_url,
                                        :response_type => 'code',
                                        :scope => 'snsapi_userinfo',
                                        :state => state_param
                                       })
      end

      def callback_url
        full_host + script_name + callback_path + query_string
      end

      def token_params
        {:appid => options.appid, :secret => options.secret}
      end

      def callback_phase
        if request.params['code'].nil? ||!request.params['code'].present?
          raise CallbackError.new('noauthorize', 'user cancel authorizing')
        end

        self.access_token = build_access_token
        log :debug, access_token['openid']
        super
          #self.access_token = refresh_access_token(access_token) if access_token.expired?
      rescue ::OAuth2::Error, CallbackError => e
        fail!(:invalid_credentials, e)
      rescue ::MultiJson::DecodeError => e
        fail!(:invalid_response, e)
      rescue ::Timeout::Error, ::Errno::ETIMEDOUT, Faraday::Error::TimeoutError => e
        fail!(:timeout, e)
      rescue ::SocketError, Faraday::Error::ConnectionFailed => e
        fail!(:failed_to_connect, e)
      end

      uid do
        @uid ||= begin
          access_token['openid']
        end
      end

      info do
        {
            :nickname => raw_info['nickname'],
            :name => raw_info['nickname'],
            :image => raw_info['headimgurl'],
        }
      end

      extra do
        {
            :raw_info => raw_info
        }
      end

      def raw_info
        @raw_info ||= begin
          response = access_token.get(
              '/sns/userinfo',
              {:params => {:access_token => access_token.token,
                           :openid => uid,
                           :lang => 'zh-CN'},
               :parse => :json}
          ).parsed
          log :debug, response
          response
        end
      end

      protected

      def deep_symbolize(hash)
        hash.inject({}) do |h, (k, v)|
          h[k.to_sym] = v.is_a?(Hash) ? deep_symbolize(v) : v
          h
        end
      end

      def build_access_token
        verifier = request.params['code']
        request_params = {:appid => options.appid,
                          :secret => options.secret,
                          :code => verifier,
                          :grant_type => 'authorization_code',
                          :parse => :json
        }
        client.get_token(request_params, {:mode => :query})
      end

      def refresh_access_token(old_token)
        request_params = {:appid => options.appid,
                          :grant_type => 'refresh_token',
                          :refresh_token => old_token.refresh_token,
                          :parse => :json
        }
        client({:token_url => 'https://api.weixin.qq.com/sns/oauth2/refresh_token'}).get_token(request_params, {:mode => :query})
      end

      class CallbackError < StandardError
        attr_accessor :error, :error_reason

        def initialize(error, error_reason=nil)
          self.error = error
          self.error_reason = error_reason
        end

        def message
          [self.error, self.error_reason].compact.join(' | ')
        end
      end
    end
  end
end

OmniAuth.config.add_camelization('wechat', 'WeChat')
