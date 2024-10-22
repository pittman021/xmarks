class SessionsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :create

  def create
    user_info = request.env['omniauth.auth']

    @user = User.find_by(twitter_id: user_info.uid)
      if @user.nil?

        @user = User.create!(
          twitter_id: user_info.uid,
          nickname:user_info.info.nickname,
          name: user_info.info.name,
          token: user_info.credentials.token,
          refresh_token: user_info.credentials.refresh_token,
          profile_image_url: user_info.info.image,
          expires_at:Time.at(user_info.credentials.expires_at).to_datetime
        )
      else
      
        @user.update(
         token: user_info.credentials.token,
         refresh_token: user_info.credentials.refresh_token,
         expires_at: Time.at(user_info.credentials.expires_at).to_datetime,
         profile_image_url: user_info.info.image
        )

        puts "new refresh token: #{user_info.credentials.refresh_token}"
  
    end 

    session[:user_id] = @user.id

    redirect_to '/bookmarks'

  end
    
  def destroy
    session[:user_id] = nil
    redirect_to root_path, notice: 'Signed out!'
  end

  def failure
    redirect_to root_path, alert: 'Authentication failed, please try again.'
  end

  def test
    render plain: "Test route working. ENV vars: #{ENV['TWITTER_KEY'].present?}, #{ENV['TWITTER_SECRET'].present?}"
end

end