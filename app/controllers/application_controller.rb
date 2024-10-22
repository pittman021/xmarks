class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  protect_from_forgery with: :exception

  def require_user!
    if !current_user
      redirect_to '/'
    end
  end

  def current_user
    @current_user ||= User.find_by(id:session[:user_id])
  end
end
