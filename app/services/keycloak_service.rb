require "net/http"
require "uri"
require "json"

class KeycloakService < ApplicationRecord
    def get_token(code)
        # Use the same URL transformation for token as we do for login
        browser_keycloak_url = ENV['KEYCLOAK_URL'].gsub('keycloak:8080', 'localhost:8080')
        token_uri = URI("#{browser_keycloak_url}/realms/#{ENV['REALM_NAME']}/protocol/openid-connect/token")
        
        Rails.logger.info "Requesting token from: #{token_uri}"
        
        begin
            uri = URI(token_uri)
            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = (uri.scheme == 'https')
            http.verify_mode = OpenSSL::SSL::VERIFY_NONE if http.use_ssl?
            
            request = Net::HTTP::Post.new(uri.request_uri)
            request.set_form_data({
                grant_type: "authorization_code",
                code: code,
                redirect_uri: ENV['REDIRECT_URI'],
                client_id: ENV['CLIENT_ID'],
                client_secret: ENV['CLIENT_SECRET'],
            })
            
            response = http.request(request)
            
            Rails.logger.info "Token response code: #{response.code}"
            
            if response.is_a?(Net::HTTPSuccess)
                JSON.parse(response.body)
            else
                Rails.logger.error "Token request failed: #{response.code} - #{response.body}"
                { "error" => "Failed to get token: #{response.message}" }
            end
        rescue => e
            Rails.logger.error "Token request exception: #{e.message}"
            { "error" => "Connection error: #{e.message}" }
        end
    end

    def get_user_info(access_token)
        # Use the same URL transformation for user_info as we do for login
        browser_keycloak_url = ENV['KEYCLOAK_URL'].gsub('keycloak:8080', 'localhost:8080')
        user_info_uri = URI("#{browser_keycloak_url}/realms/#{ENV['REALM_NAME']}/protocol/openid-connect/userinfo")
        
        Rails.logger.info "Requesting user info from: #{user_info_uri}"

        request = Net::HTTP::Get.new(user_info_uri)
        request["Authorization"] = "Bearer #{access_token}"

        begin
            uri = URI(user_info_uri)
            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = (uri.scheme == 'https')
            http.verify_mode = OpenSSL::SSL::VERIFY_NONE if http.use_ssl?
            
            Rails.logger.info "Making request to #{uri.host}:#{uri.port} with SSL: #{http.use_ssl?}"
            
            response = http.request(request)
            
            Rails.logger.info "User info response code: #{response.code}"
            Rails.logger.info "User info response body: #{response.body}"
            
            if response.is_a?(Net::HTTPSuccess)
                if response.body && !response.body.empty?
                    JSON.parse(response.body)
                else
                    Rails.logger.error "Empty response body from userinfo endpoint"
                    { "error" => "Empty response from userinfo endpoint" }
                end
            else
                Rails.logger.error "User info request failed: #{response.code} - #{response.body}"
                { "error" => "Failed to get user info: #{response.message}" }
            end
        rescue JSON::ParserError => e
            Rails.logger.error "JSON parsing error: #{e.message}, Response body: '#{response.body}'"
            { "error" => "Invalid JSON response: #{e.message}" }
        rescue => e
            Rails.logger.error "User info request exception: #{e.message}"
            { "error" => "Connection error: #{e.message}" }
        end
    end

    def keycloak_logout(refresh_token)
        # Use the same URL transformation for logout as we do for login
        browser_keycloak_url = ENV['KEYCLOAK_URL'].gsub('keycloak:8080', 'localhost:8080')
        logout_uri = URI("#{browser_keycloak_url}/realms/#{ENV['REALM_NAME']}/protocol/openid-connect/logout")
        
        Rails.logger.info "Requesting logout at: #{logout_uri}"

        begin
            uri = URI(logout_uri)
            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = (uri.scheme == 'https')
            http.verify_mode = OpenSSL::SSL::VERIFY_NONE if http.use_ssl?
            
            request = Net::HTTP::Post.new(uri.request_uri)
            request.set_form_data(
                "client_id" => ENV['CLIENT_ID'],
                "client_secret" => ENV['CLIENT_SECRET'],
                "refresh_token" => refresh_token,
            )

            response = http.request(request)
            
            if !response.is_a?(Net::HTTPSuccess)
                Rails.logger.error "Logout request failed: #{response.code} - #{response.body}"
            end
            
            response
        rescue => e
            Rails.logger.error "Logout request exception: #{e.message}"
            nil
        end
    end
end
