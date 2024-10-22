class BookmarksController < ApplicationController
    before_action :require_user!
  
    def index
      
     if current_user.last_fetched_at.nil? || current_user.last_fetched_at < 7.days.ago
        
        client = TwitterClient.new(current_user)
        tweets_saved = client.get_latest_x_activity

      end

     # Get all tweets from the last 30 days
     @tweets = Tweet.where(owner_id: current_user.id, liked: true).includes(:author)

     # Filter tweets that are bookmarked
     @bookmarked_tweets = Tweet.where(owner_id: current_user.id, bookmarked: true).includes(:author)
 
     # Collect author data from the tweets
     @authors = @tweets
                 .select(:author_id)
                 .distinct
                 .map do |tweet|
                   {
                     name: tweet.author[:name],
                     username: tweet.author[:username],
                     followers_count: tweet.author[:followers_count],
                     profile_image_url: tweet.author[:profile_image_url]
                   }
                 end
  puts @bookmarked_tweets


                end
end