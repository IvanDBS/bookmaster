module Users
  class ConfirmationsController < Devise::ConfirmationsController
    # Redirect confirmation link from email to the frontend, where API confirmation happens
    def show
      token = params[:confirmation_token]
      frontend_base = ENV['FRONTEND_URL'].presence || 'http://localhost:5173'
      if token.present?
        redirect_to "#{frontend_base}/login?confirmation_token=#{CGI.escape(token)}"
      else
        redirect_to "#{frontend_base}/login?confirmation_error=missing_token"
      end
    end
  end
end
