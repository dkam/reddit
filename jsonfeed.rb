require "sinatra"

require "./lib/reddit"
require "./lib/json_feed"

get "/r/:subreddit" do
  content_type "application/feed+json"
  sr = Reddit::Subreddit.new(params["subreddit"])

  Reddit::JsonFeed.new(sr).feed.to_json
end
