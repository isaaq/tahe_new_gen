require 'faraday'
require 'json'

class LLMService
  include Singleton
  
  def initialize
    @api_key = Common::C['llm_api_key']
    @api_endpoint = Common::C['llm_api_endpoint']
    @model = Common::C['llm_model'] || 'gpt-3.5-turbo'
  end

  def process(prompt)
    conn = Faraday.new(url: @api_endpoint) do |f|
      f.request :json
      f.response :json
      f.adapter Faraday.default_adapter
    end

    response = conn.post do |req|
      req.headers['Authorization'] = "Bearer #{@api_key}"
      req.headers['Content-Type'] = 'application/json'
      req.body = {
        model: @model,
        messages: [{role: 'user', content: prompt}],
        temperature: 0.7,
        max_tokens: 2000
      }.to_json
    end

    handle_response(response)
  rescue => e
    {error: e.message, status: 'error'}
  end

  private

  def handle_response(response)
    if response.success?
      {
        result: response.body['choices'][0]['message']['content'],
        status: 'success'
      }
    else
      {
        error: "API request failed: #{response.body}",
        status: 'error'
      }
    end
  end
end
