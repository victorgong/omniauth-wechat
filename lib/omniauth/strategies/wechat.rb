require 'omniauth/strategies/oauth2'

module OmniAuth
  module Strategies
    class WeChat < OmniAuth::Strategies::OAuth2
      option :name, "wechat"
      
      option :client_options, {
        :site => 'http://open.weixin.qq.com',
        :authorize_url => 'http://open.weixin.qq.com/connect/oauth2/authorize',
        :token_url => "https://api.weixin.qq.com/sns/oauth2/access_token"
      }
      option :authorize_params, {
        :appid => options.client_id,
        :secret => options.client_secret,
        :scope => 'snsapi_base,snsapi_userinfo'
        
      }
      option :token_params, {
        :appid =>options.client_id,
        :secret=>options.client_secret
      }
      def request_phase
        redirect client.auth_code.authorize_url({:redirect_uri => callback_url}.merge(authorize_params))+'#wechat_redirect'
      end
      uid do
        @uid ||= begin
          access_token[:openid]
        end
      end

      info do 
        { 
          :nickname => raw_info['nickname'],
          :name => raw_info['nickname'],
          :image => raw_info['figureurl_1'],
        }
      end
      
      extra do
        {
          :raw_info => raw_info
        }
      end

      def raw_info
        @raw_info ||= begin
          client.request(:get, "https://api.weixin.qq.com/sns/userinfo", :params => {
              :format => :json,
              :openid => uid,
              :oauth_consumer_key => options[:client_id],
              :access_token => access_token.token
            }, :parse => :json).parsed
        end
      end
    end
  end
end

OmniAuth.config.add_camelization('qq_connect', 'QQConnect')