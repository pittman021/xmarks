Rails.application.config.middleware.use OmniAuth::Builder do
  provider :developer if Rails.env.development?

  provider( 
    :twitter2, 
    ENV['CLIENT_ID'], 
    ENV['CLIENT_SECRET'], 
    callback_path: '/auth/twitter2/callback',
    scope: 'tweet.read users.read bookmark.read like.read offline.access'
   )


end

OmniAuth.config.allowed_request_methods = [:post, :get]
OmniAuth.config.silence_get_warning = true