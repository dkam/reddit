require 'sinatra'

require './lib/reddit.rb'
require './lib/json_feed.rb'

get '/r/:subreddit' do
  content_type 'application/feed+json'
  sr = Reddit::Subreddit.new(params['subreddit'])

  Reddit::JsonFeed.new(sr).feed.to_json
end
