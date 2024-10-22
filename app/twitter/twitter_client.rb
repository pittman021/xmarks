class TwitterClient
    BASE_URL = "https://api.x.com/2"
  
    def initialize(user)
      @user = user
    end

    def get_latest_x_activity

    # over the past 30 days, see your tweet activity
    ## what you bookmarked
    ## what you liked
    ## what your top followers

    # get liked tweets and author info for main processing including: 
    liked_tweets = get_liked_tweets
    updated_tweets = add_user_info_to_tweets(liked_tweets)
    recent_tweets = last_30_days(updated_tweets[:data])
    
    # get bookmarked tweets
    bookmarks = get_bookmarks
    updated_bookmarks = add_user_info_to_tweets(bookmarks)
    recent_bookmarks = last_30_days(bookmarks[:data])

    # save twetts and bookmarks 
    save_tweets(recent_tweets, 'like')
    save_tweets(recent_bookmarks, 'bookmark')
    end

    def save_tweets(recent_tweets, tweet_type)

      Tweet.where('owner_id = ? AND posted_at < ?', @user.id, 30.days.ago).destroy_all

      recent_tweets.each do |tweet|

        if tweet[:created_at] > 30.days.ago.utc

        puts "#{tweet_type} - #{tweet[:created_at]}"
        # Extract the author information from :author_info
        author_data = tweet[:author_info]
      
        # Find or create the author based on the twitter_id
        author = Author.find_or_create_by(twitter_id: author_data[:twitter_id]) do |a|
          a.name = author_data[:name]
          a.username = author_data[:username] || 'Unknown'  # Handle nil usernames gracefully
          a.followers_count = author_data[:followers_count]
          a.profile_image_url = author_data[:profile_image_url]
        end

        is_liked = tweet_type == 'like'
        is_bookmarked = tweet_type == 'bookmark'
      
        # Find or create the tweet based on twitter_id
        Tweet.find_or_create_by(twitter_id: tweet[:id]) do |t|
          t.text = tweet[:text].truncate(255)  # The tweet text
          t.author = author      # Associate the tweet with the found or created author
          t.posted_at = tweet[:created_at]  # Use created_at from the tweet
          t.liked = is_liked
          t.bookmarked = is_bookmarked         # Assuming you mark all fetched tweets as liked
          t.owner_id = @user.id  # Associate the tweet with the current user
        end
      end
      end
      
      # Update the last fetched time for the user
      @user.update(last_fetched_at: Time.current)
      
      true
    end

    def add_user_info_to_tweets(tweets_hash)

      # Extract users array from the "includes" section of the hash
      users = tweets_hash[:includes][:users]
    
      # Create a hash for quick user lookup by id
      users_by_id = users.each_with_object({}) do |user, hash|
        hash[user[:id]] = user
      end
    
      # Loop through each tweet in the data and add user info
      tweets_hash[:data].each do |tweet|
        # Find the author of the tweet by author_id
        author_info = users_by_id[tweet[:author_id]]

        username = author_info[:username] || author_info.dig(:public_metrics, :username)

        # Add the full author information to the tweet
        tweet[:author_info] = {
          name: author_info[:name],
          username: username,
          profile_image_url: author_info[:profile_image_url],
          followers_count: author_info[:public_metrics][:followers_count],
          twitter_id: author_info[:id]
        }
      end
    
      tweets_hash
    end  

    def last_30_days(tweets)

    today = DateTime.now
    thirty_days_ago = 30.days.ago.utc

    recent_tweets = []

    tweets.each do |tweet| 
      created_at = DateTime.parse(tweet[:created_at])

      if created_at >= thirty_days_ago
        recent_tweets << tweet
      end
    end

    end

    def me
      get '/users/me'
    end
  
    def get_user(handle)
      get "/users/by/username/#{handle}"
    end

    def json_status
      get "/"
  end
  
    def get_spaces_by_creator_ids(creator_ids)
      query = {
        user_ids: creator_ids.join(','),
        expansions: 'speaker_ids,creator_id,host_ids',
        'topic.fields': 'name,description',
        'user.fields': 'username,name,location',
        'space.fields':'host_ids,created_at,creator_id,id,lang,invited_user_ids,participant_count,speaker_ids,started_at,ended_at,subscriber_count,topic_ids,state,title,updated_at,scheduled_start,is_ticketed',
      }.to_query
      get "/spaces/by/creator_ids?#{query}"
    end
  
    def my_spaces
      query = {
        user_ids: @user.twitter_id,
        expansions: 'speaker_ids,creator_id,host_ids',
        'topic.fields': 'name,description',
        'user.fields': 'username,name,location',
        'space.fields':'host_ids,created_at,creator_id,id,lang,invited_user_ids,participant_count,speaker_ids,started_at,ended_at,subscriber_count,topic_ids,state,title,updated_at,scheduled_start,is_ticketed',
      }.to_query
      get "/spaces/by/creator_ids?#{query}"
    end
  
    def get_bookmarks
      query = {
        'tweet.fields': 'created_at',
        'expansions': 'author_id',
        'user.fields': 'name,username,profile_image_url,public_metrics'
      }.to_query
      get "/users/#{@user.twitter_id}/bookmarks?#{query}"
    end

    def get_liked_tweets
      query = {
        'expansions': 'author_id',
        'user.fields': 'name,username,profile_image_url,public_metrics',
        'tweet.fields': 'created_at'
    }.to_query
      get "/users/#{@user.twitter_id}/liked_tweets?#{query}"
    end

    def get_user_profiles(user_ids)

      query = {
        'ids': user_ids.join(','),
        'user.fields': 'public_metrics,verified,description,profile_image_url'
    }.to_query

      get "/users?#{query}"
    end

    def refresh

      client_id = ENV['CLIENT_ID']
      client_secret = ENV['CLIENT_SECRET']     
      authorization = Base64.strict_encode64("#{client_id}:#{client_secret}")
      url = "https://api.x.com/2/oauth2/token"

      puts "Refresh token #{@user.refresh_token}"
    
      payload = {
        'refresh_token' => @user.refresh_token,
        'grant_type' =>'refresh_token'
      }
    
      headers = {
        'content_type' => 'application/x-www-form-urlencoded',
        'Authorization' => "Basic #{authorization}"
      }
    
      # Debug output
      puts "URL: #{url}"
      puts "Payload: #{payload}"
      puts "Headers: #{headers}"
    
      begin
        response = RestClient.post(url, payload, headers)
        save_refresh_token(JSON.parse(response.body))
      rescue RestClient::ExceptionWithResponse => e
        puts "Error Response Body: #{e.response.body}"
        error_response = JSON.parse(e.response.body) rescue nil
        error_message = error_response ? error_response['error_description'] : e.response.body
        raise "Request failed: #{e.response.code} - #{error_message}"
      rescue => e
        raise "An error occurred: #{e.message}"
      end
    end

    def extract_author_ids(liked_tweets)
      author_ids = []

      liked_tweets.each do |tweet|
        i = tweet[:author_id].to_i
        author_ids.push(i)
      end
      author_ids
    end

    def get(path)
      request(:get, path)
    end

    def request(method, path, body: {})
    # Generate a unique cache key based on the request method and URL

    # Use Rails cache to store the API response
      params = {
        method: method,
        url: "#{BASE_URL}#{path}",
        headers: headers, 
        max_results: 10
      }

      if method == :put || method == :post
        params[:payload] = body.to_json
        params[:headers]["Content-Type"] = "application/json"
      end

      begin
        if Time.now.to_i >= @user.expires_at.to_i
          puts "Refresh token expired!"
          puts @user.expires_at

          new_token = refresh

          # Store new access token and refresh token
        end
      rescue OAuth2::Error => e
        puts "Failed to refresh token: #{e.message}"
        # Handle error, e.g., prompt user to reauthenticate
      end

        response = RestClient::Request.execute(params)
        puts 'response worked!'
        JSON.parse(response.body, symbolize_names: true)

    rescue RestClient::BadRequest => e
      # Log and inspect the 400 Bad Request error
      Rails.logger.error "400 Bad Request: #{e.message}"
      Rails.logger.error "Response body: #{e.response.body}" if e.response
      begin
        return JSON.parse(e.response.body, symbolize_names: true) if e.response
      rescue JSON::ParserError
        Rails.logger.error "Failed to parse error response JSON"
      end
      nil
    rescue RestClient::ExceptionWithResponse => e
      # Log any other HTTP errors
      Rails.logger.error "HTTP request failed: #{e.message}"
      Rails.logger.error "Response body: #{e.response.body}" if e.response
    end
      nil
    rescue StandardError => e
      # Catch any other unexpected errors
      Rails.logger.error "Unexpected error: #{e.message}"
      nil
    end
    
    def headers
      {
        "Authorization": "Bearer #{@user.token}",
        "User-Agent": "RailsBookmarksSearch",
      }
    end

    def expired
      return false unless @user.expires_at
      Time.now.to_i >= expires_at
    end

    def save_refresh_token(response)

      puts response.class
      puts response.inspect

      puts "Saving new refresh token to user"

      puts response['refresh_token']

      new_refresh_token = response['refresh_token']
      new_access_token = response['access_token']
      expires_at = Time.now + 7200

    if @user.update(refresh_token: new_refresh_token, token: new_access_token, expires_at: expires_at)
       puts "User updated successfully"
    else
      puts "Error updating user"
      puts @user.errors.full_messages # Shows validation errors if any
    end

    def filter_tweets(liked_tweets)
      liked_tweets[:data].select do |tweet|
        tweet[:author_id][:public_metrics][:followers_count] > 0
      end
    end



  end
