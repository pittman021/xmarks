class GoogleClient 

def fetch_book_data(book_title)

  api_key = "AIzaSyCCXJ5DQXwGWBo0aAkyezVhy0toSPMOT4c"  # Replace with your actual Google Books API Key
  url = "https://www.googleapis.com/books/v1/volumes?q=#{book_title}&key=#{api_key}"

  # Make the GET request using RestClient
  begin
    response = RestClient.get(url)
    data = JSON.parse(response.body)

    if data['items'] && data['items'].any?
      first_result = data['items'].first['volumeInfo']

      # Return a hash with the necessary book details
      {
        title: first_result['title'],
        authors: first_result['authors'],
        description: first_result['description'],
        image: first_result.dig('imageLinks', 'thumbnail')
      }
    else
      puts "No results found for #{book_title}"
      nil
    end
  rescue RestClient::ExceptionWithResponse => e
    puts "API request failed: #{e.response}"
    nil
  end
end

end
