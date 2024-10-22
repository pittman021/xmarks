class BooksController < ApplicationController
  before_action :require_user!
  before_action :require_purchased_user!, only: [:get_book_recs]

    def index
      @books = current_user.books.order(created_at: :desc)
    end

    def show
    end

    def destroy
      @book = Book.find(params[:id])
      @book.destroy
      redirect_to books_path, notice: 'Book was successfully deleted.'
    end

    def require_purchased_user!
      # Block if the user has 3 or more books and hasn't purchased a plan
      if current_user.books.count >= 3 && current_user.payment_processor.processor_id.nil?
        flash[:notice] = "You need to purchase a plan to create more than 3 book recommendations."
        redirect_to books_path  # Redirect to a suitable path, e.g., the books index
      end
    end
  
    def get_book_recs
    # Assuming you already have logic to generate the recommendations

    client = TwitterClient.new(current_user)
    # filtered_tweets = client.get_latest_x_activity
    owner_tweets = Tweet.where(owner_id: current_user.id).includes(:author)

    owner_books = Book.where(user_id: current_user.id)
    recommended_book_titles = owner_books.pluck(:title)
    formatted_book_list = recommended_book_titles.map { |book| "- #{book}" }.join("\n")

    hash = owner_tweets.map do |tweet|
      tweet.as_json.merge(author: tweet.author.as_json(only: [:name, :username, :followers_count]))
    end

    openai_client = OpenClient.new
    prompt = build_chatgpt_prompt(hash, formatted_book_list)

    openai_response = openai_client.get_book_recommendations(prompt)

    puts openai_response

    recommendations_key = openai_response.keys.find do |key|
      ["book_recommendations", "bookRecommendations", "recommendations"].include?(key)
    end
    
    # Access the array of book recommendations using the found key
    if recommendations_key
      recommendations = openai_response[recommendations_key]
    else 
      puts "No book recommendations found."
    end

    recommendations.each do |recommendation|
      # Create and save each book to the database
      Book.create!(
        user: current_user,
        title: recommendation['title'],
        author: recommendation['author'],
        summary: recommendation['summary'],
        reason: recommendation['reason']
      )
    end

    puts "books saved to DB"

    @books = recommendations

    redirect_to books_path

    # Redirect or render as needed

  end

  private

  def build_chatgpt_prompt(tweets_hash, books_hash)
    # Prepare the refined prompt with additional context for better personalization
    prompt = <<-PROMPT
      Please analyze the following bookmarked and liked tweets and return 3 personalized book recommendations based on the themes, topics, or explicit books mentioned in these tweets. 
      Priority should be given to books explicitly mentioned or directly referenced by the users in the tweets. Otherwise, recommendations should be derived from the dominant themes and topics found in the tweets.

      The book recommendations must **exclude** any of the following previously recommended books:
      #{books_hash}
  
      For each book recommendation, the "reason" must specifically mention:
      - The **exact tweet content** that inspired the recommendation.
      - The **user handles** of the accounts that posted the relevant tweets.
      - An explanation of how the tweet aligns with the book's themes or content.
      - If applicable, mention books explicitly discussed in the tweets.
  
      The response should be in a fixed JSON format with the following structure:
      
      {
        "book_recommendations": [
          {
            "title": "string",
            "ISBN": number,
            "author": "string",
            "summary": "string",
            "reason": "string (with tweet examples, user handles, and followers)",
            "tweets": [array of tweet IDs]
          }
        ]
      }
  
      Here are the tweets:
    PROMPT
  
    # Add the formatted tweets
    formatted_tweets = tweets_hash.map do |tweet|
      author_username = tweet[:author]["username"]
      author_followers = tweet[:author]["followers_count"]
      tweet_text = tweet["text"]
  
      # Formatting each tweet with author details
      "Tweet ID (#{tweet["twitter_id"]}): @#{author_username} (#{author_followers} followers) tweeted: \"#{tweet_text}\""
    end
  
    # Append the formatted tweets to the prompt
    prompt += formatted_tweets.join("\n\n")
  
    prompt
  end


end
