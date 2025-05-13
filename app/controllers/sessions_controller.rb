class SessionsController < ApplicationController
  before_action :set_keycloak_service

  def login
    browser_keycloak_url = ENV['KEYCLOAK_URL'].gsub('keycloak:8080', 'localhost:8080')
    
    auth_url = "#{browser_keycloak_url}/realms/#{ENV['REALM_NAME']}/protocol/openid-connect/auth"
    query_params = {
      client_id: ENV['CLIENT_ID'],
      response_type: 'code',
      scope: 'openid',
      redirect_uri: ENV['REDIRECT_URI']
    }
    
    redirect_to "#{auth_url}?#{query_params.to_query}", allow_other_host: true
  end

  def callback
    code = params[:code]
    
    token = @keycloak_service.get_token(code)
    
    if token["error"]
      Rails.logger.error "Token error: #{token["error"]}"
      flash[:alert] = "Authentication failed: #{token["error"]}"
      redirect_to root_path
      return
    end
    
    access_token = token["access_token"]
    refresh_token = token["refresh_token"]
    
    user_info = @keycloak_service.get_user_info(access_token)
    
    if user_info["error"]
      Rails.logger.error "User info error: #{user_info["error"]}"
      flash[:alert] = "Failed to fetch user information: #{user_info["error"]}"
      redirect_to root_path
      return
    end
    
    session[:refresh_token] = refresh_token
    session[:user_info] = user_info

    redirect_to root_path
  end

  def logout
    refresh_token = session[:refresh_token]
    
    @keycloak_service.keycloak_logout(refresh_token)

    reset_session
    redirect_to root_path
  end

  def userinfo
    if session[:user_info].present?
      render json: {
        user_info: session[:user_info],
        refresh_token_present: session[:refresh_token].present?,
        refresh_token_length: session[:refresh_token]&.length
      }
    else
      render json: { error: "No user info in session" }
    end
  end

  private

  def set_keycloak_service
    @keycloak_service = KeycloakService.new
  end
end
