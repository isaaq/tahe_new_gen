require 'net/http'
require 'json'
require 'yaml'
require 'erb'

def get_embedding(text)
  uri = URI("https://api.openai.com/v1/embeddings")
  headers = {
    "Authorization" => "Bearer #{ENV['VECTOR_API_KEY']}",
    "Content-Type" => "application/json"
  }
  body = { model: "text-embedding-3-small", input: text }.to_json

  response = Net::HTTP.post(uri, body, headers)
  JSON.parse(response.body)["data"][0]["embedding"]
end

get_embedding("你好")