# app/openai/openai_client.rb
class OpenClient

  def initialize()
    api_key = ENV['OPEN_AI_KEY']
    org_ig = "org-Jgegr2n9O7iFXqOerHEjkfas",
    project = ENV['OPEN_AI_PROJECT_ID']
    
    @client = OpenAI::Client.new(access_token: api_key, organization: org_ig, log_errors:true)
  end

  def get_book_recommendations(prompt)
    response = @client.chat(
      parameters: {
        model: "gpt-4o-mini",
        response_format: { type: "json_object" },
        messages: [
          {role: "system", content: "You are a highly skilled research assistant whose primary goal is to recommend well-researched book recommendations." },
          { role: "assistant", content: "I will provide 5 book recommendations from tweets history, including a summary and reason for recommending each book. My response will be in JSON format." },
          { role: "user", content: prompt }
        ]
      }
      )

      response_content = response.dig("choices", 0, "message", "content")
  
      # Parse the JSON string into a Ruby hash
      begin
        recommendations = JSON.parse(response_content)
      rescue JSON::ParserError => e
        puts "Error parsing JSON: #{e.message}"
        recommendations = {}
      end

  end

  def headers ()
    api_key = ENV['OPEN_API_KEY']
    project_id = ENV['OPEN_AI_PROJECT_ID']
  
    {
      "content-type": "application/json",
      "Authorization": "Bearer #{api_key}",
      "OpenAI-Organization": "org-Jgegr2n9O7iFXqOerHEjkfas",
      "OpenAI-Project": "#{project_id}",
    }

end
end



