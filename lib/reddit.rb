require 'bundler/inline'
require 'open-uri'
require 'json'
require 'byebug'

gemfile do
  source 'https://rubygems.org'
  gem 'awesome_print'#, require: false
  gem 'fast_blank'
end

# Unused ATM
KINDS = {
  t1:	'Comment',
  t2:	'Account',
  t3:	'Link',
  t4:	'Message',
  t5:	'Subreddit',
  t6:	'Award'
}

module Reddit
  class Subreddit
    attr_reader :subreddit
    attr_accessor :limit, :before, :after, :agent

    def initialize(name)
      @agent = agent
      @subreddit = name
      @limit = 50
      @posts = []
    end

    def posts
      get_next_page if @posts.empty?
      @posts
    end

    def [](i)
      get_next_page while @posts[i].nil?
      return @posts[i]
    end

    def url
      params = URI.encode_www_form({after: after, limit: limit}.reject {|k,v| v.nil? })
      "https://reddit.com/r/#{@subreddit}.json?#{params}"
    end

    private
    def get_next_page
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
      @post = OpenStruct.new(raw_data)
      @limit = 50
      @comments = []
    end
    
    def to_s
      title
    end
    
    def [](i)
      while @comments[i].nil?
        get_next_page
      end
      return @comments[i]
    end

    def post_url
      params = URI.encode_www_form({after: after, limit: limit}.reject {|k,v| v.nil? })
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

    def get_next_page
      data = Reddit::Client.retrieve(url: post_url)

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

  class Comment
    attr_accessor :raw_data, :comment, :parent, :replies, :after, :limit
    def initialize(raw_data, parent:)
      @comment = OpenStruct.new(raw_data)
      @limit = 50

      @replies = raw_data.dig('replies','data', 'children')&.map do |c| 
        Comment.new(c.dig('data'), parent: self)
      end unless raw_data.dig('replies').nil? || raw_data.dig('replies').empty?
    end
    
    def to_s
      body
    end
    
    def [](i)
      while @replies[i].nil?
        get_replies
      end
      return @replies[i]
    end

    def comment_url
      params = URI.encode_www_form({after: after, limit: limit}.reject {|k,v| v.nil? })
      "https://reddit.com#{@comment.permalink}.json?#{params}"
    end

    def method_missing(m, *args, &block)
      if @comment.respond_to?(m)
        @comment.send(m) 
      else
        super
      end
    end

    private
    def get_replies
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
    def self.retrieve(url: , agent: 'phblebas')
      JSON.parse(URI.open(url,  "User-Agent" => agent).read)
    rescue => e
      puts "Error #{e.inspect}"
      return {}
    end
  end
end
