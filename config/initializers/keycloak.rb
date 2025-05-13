# Set default values for Keycloak environment variables if they're not set
ENV['REALM_NAME'] ||= 'BMATraining'
ENV['CLIENT_ID'] ||= 'BMATraining_test'
ENV['CLIENT_SECRET'] ||= '7cNqGiISZIbshLf6N5LIg0DVYr3rKYBY'
ENV['KEYCLOAK_URL'] ||= 'http://localhost:8080'
ENV['REDIRECT_URI'] ||= 'http://localhost:3000/auth/callback'

# Log the Keycloak configuration (except the secret)
Rails.logger.info "Keycloak configuration:"
Rails.logger.info "  REALM_NAME: #{ENV['REALM_NAME']}"
Rails.logger.info "  CLIENT_ID: #{ENV['CLIENT_ID']}"
Rails.logger.info "  KEYCLOAK_URL: #{ENV['KEYCLOAK_URL']}"
Rails.logger.info "  REDIRECT_URI: #{ENV['REDIRECT_URI']}" 