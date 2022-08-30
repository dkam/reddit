require 'open-uri'
require 'json'
require 'addressable'

#require 'bundler/inline'
#gemfile do
#  source 'https://rubygems.org'
  #gem 'awesome_print'
#  gem 'byebug'
#  gem 'addressable'
#end

# Unused ATM
KINDS = {
  t1:	'Comment',
  t2:	'Account',
  t3:	'Link',
  t4:	'Message',
  t5:	'Subreddit',
  t6:	'Award'
}.freeze

LISTING = %w[hot new top controversial rising]
PERIOD = %w[hour day week month year all]

module Reddit
  class Subreddit
    attr_reader :subreddit, :listing, :period, :safe
    attr_accessor :limit, :before, :after, :safe

    def initialize(name, listing: 'hot', period: 'day', safe: 'true', limit: 100)
      @listing = LISTING.include?(listing) ? listing : 'hot'
      @safe = safe
      @period = period
      @subreddit = name
      @limit = limit
      @posts = []
    end

    def about
      @about ||= OpenStruct.new( Reddit::Client.retrieve(url: url('about')).dig('data') )
    end
    
    def listing=()
      @listing = LISTING.include?(listing) ? listing : 'hot'
    end

    def posts
      next_page if @posts.empty?
      @posts
    end

    def [](i)
      next_page while @posts[i].nil?
      @posts[i]
    end

    def url(path=nil)
      path ||= @listing
      "https://reddit.com/r/#{@subreddit}/#{path}.json?#{params}"
    end

    def method_missing(m, *args, &block)
      if about.respond_to?(m)
        about.send(m)
      else
        super
      end
    end

    private

    def params
      params = URI.encode_www_form({ after: after, limit: limit, safe: safe, t: period }.reject { |_k, v| v.nil? })
    end

    def next_page
      data = Reddit::Client.retrieve(url: url)

      if data.dig('kind') == 'Listing'
        data.dig('data', 'children').each do |post|
          @posts << Post.new(post.dig('data'))
        end
      end
      # Set after so next access is after this page
      self.after = data.dig('data', 'after')
    end
  end

  class Post
    attr_accessor :raw_data, :post, :after, :before, :limit, :comments
    def initialize(raw_data)
      @raw_data = raw_data
      @post = OpenStruct.new(raw_data)
      @limit = 50
      @comments = []
      @comments_available = true
    end

    def to_s
      title
    end

    def [](i)
      return nil unless @comments_available

      next_page while @comments[i].nil? && @comments_available
      @comments[i]
    end

    def post_url
      params = URI.encode_www_form({ after: after, limit: limit }.reject { |_k, v| v.nil? })
      "https://reddit.com#{@post.permalink}.json?#{params}"
    end

    def method_missing(m, *args, &block)
      if @post.respond_to?(m)
        @post.send(m)
      else
        super
      end
    end

    private

    def next_page
      data = Reddit::Client.retrieve(url: post_url)

      post_data = data[0]
      comment_data = data[1]
      if comment_data.dig('kind') == 'Listing'
        comment_data.dig('data', 'children').each do |comment|
          @comments << Reddit::Comment.new(comment.dig('data'), parent: self)
        end
      end
      #debugger if @comments.empty?
      @comments_available = false if @comments.empty?
      # Set after so next access is after this page
      self.after = comment_data.dig('data', 'after')
    end

    def self.url_from_post_id(id)
      "https://www.reddit.com/comments/#{id}/.json"
    end

    def self.from_id(id)
      data = Reddit::Client.retrieve(url: url_from_post_id(id))
      Reddit::Post.new(data.first.dig('data', 'children', 0, 'data'))
    end
  end

  class Comment
    attr_accessor :raw_data, :comment, :parent, :replies, :after, :limit
    def initialize(raw_data, parent:)
      @comment = OpenStruct.new(raw_data)
      @limit = 50

      unless raw_data.dig('replies').nil? || raw_data.dig('replies').empty?
        @replies = raw_data.dig('replies', 'data', 'children')&.map do |c|
          Comment.new(c.dig('data'), parent: self)
        end
      end
    end

    def to_s
      body
    end

    def [](i)
      replies while @replies[i].nil?
      @replies[i]
    end

    def comment_url
      params = URI.encode_www_form({ after: after, limit: limit }.reject { |_k, v| v.nil? })
      "https://reddit.com#{@comment.permalink}.json?#{params}"
    end

    def method_missing(m, *args, &block)
      if @comment&.respond_to?(m)
        @comment.send(m)
      else
        super
      end
    end

    private

    def replies
      data = Reddit::Client.retrieve(url: comment_url)

      post_data = data[0]
      comment_data = data[1]
      if comment_data.dig('kind') == 'Listing'
        comment_data.dig('data', 'children').each do |comment|
          @comments << Reddit::Comment.new(comment.dig('data'), parent: self)
        end
      end

      # Set after so next access is after this page
      self.after = comment_data.dig('data', 'after')
    end
  end

  class Client
    def self.retrieve(url:, agent: 'phblebas')
      puts "Fetching #{url}"
      data = URI.open(url, 'User-Agent' => agent)
      JSON.parse(data.read)
    rescue StandardError => e
      puts "Error #{e.inspect}"
      {}
    end
  end
end