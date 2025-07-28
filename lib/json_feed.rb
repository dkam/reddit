module Reddit
  DEFAULT_URL = "https://old.reddit.com"
  class JsonFeed
    require "cgi"

    attr_accessor :subreddit, :language, :offset, :count, :base

    def initialize(subreddit, language: "en", base: DEFAULT_URL, offset: 0, count: 100)
      @subreddit = subreddit
      @base = URI.parse(DEFAULT_URL)

      # (optional, string) is the primary language for the feed in the format specified in RFC 5646. The value is usually a 2-letter language tag from ISO 639-1, optionally followed by a region tag. (Examples: en or en-US.)
      @language = language
      @base = URI.parse(base)
      @offset = offset
      @count = count
    end

    def base=(url)
      @base = URI.parse(url)
    end

    attr_reader :base

    # (required, string) is the URL of the version of the format the feed uses. This should appear at the very top, though we recognize that not all JSON generators allow for ordering.
    def version = "https://jsonfeed.org/version/1.1"

    # (required, string) is the name of the feed, which will often correspond to the name of the website (blog, for instance), though not necessarily.
    def title = subreddit.title

    # (optional but strongly recommended, string) is the URL of the resource that the feed describes. This resource may or may not actually be a “home” page, but it should be an HTML page. If a feed is published on the public web, this should be considered as required. But it may not make sense in the case of a file created on a desktop computer, when that file is not shared or is shared only privately.
    def home_page_url = base.tap { |u| u.path = subreddit.about.url }.to_s

    #  (optional but strongly recommended, string) is the URL of the feed, and serves as the unique identifier for the feed. As with home_page_url, this should be considered required for feeds on the public web.
    def feed_url = subreddit.url

    # (optional, string) provides more detail, beyond the title, on what the feed is about. A feed reader may display this text.
    def description = subreddit.public_description || CGI.unescapeHTML(subreddit.description)

    # (optional, string) is a description of the purpose of the feed. This is for the use of people looking at the raw JSON, and should be ignored by feed readers.
    def user_comment = "Converted from Reddit's public  JSON endpoints"

    # (optional, string) is the URL of a feed that provides the next n items, where n is determined by the publisher. This allows for pagination, but with the expectation that reader software is not required to use it and probably won’t use it very often. next_url must not be the same as feed_url, and it must not be the same as a previous next_url (to avoid infinite loops).
    def next_url
    end

    # (optional, string) is the URL of an image for the feed suitable to be used in a timeline, much the way an avatar might be used. It should be square and relatively large — such as 512 x 512 pixels — so that it can be scaled-down and so that it can look good on retina displays. It should use transparency where appropriate, since it may be rendered on a non-white background.
    def icon = subreddit.icon_img

    # (optional, string) is the URL of an image for the feed suitable to be used in a source list. It should be square and relatively small, but not smaller than 64 x 64 pixels (so that it can look good on retina displays). As with icon, this image should use transparency where appropriate, since it may be rendered on a non-white background.
    def favicon = subreddit.icon_img

    # (optional, array of objects) specifies one or more feed authors. The author object has several members. These are all optional — but if you provide an author object, then at least one is required:
    def authors = []

    # (optional, boolean) says whether or not the feed is finished — that is, whether or not it will ever update again. A feed for a temporary event, such as an instance of the Olympics, could expire. If the value is true, then it’s expired. Any other value, or the absence of expired, means the feed may continue to update.
    def expired = false

    # (very optional, array of objects) describes endpoints that can be used to subscribe to real-time notifications from the publisher of this feed. Each object has a type and url, both of which are required. See the section “Subscribing to Real-time Notifications” below for details.
    def hubs = []

    def items
      subreddit.posts[offset...(offset + count)].collect { |i| JsonFeedItem.new(i).item }
    end

    def feed
      {
        version:,
        title:,
        home_page_url:,
        feed_url:,
        items: items
      }
    end
  end

  class JsonFeedItem
    require "marcel"
    attr_reader :post, :base

    def initialize(post, base = DEFAULT_URL)
      @post = post
      @base = base
    end

    def item
      image = post.respond_to?(:preview?) ? CGI.unescapeHTML(post.preview&.dig("images", 0, "source", "url")) : nil

      data = {
        id: url, url: url, title: post.title, content_text: post.selftext,
        authors: author
      }

      data[:image] = image unless image.nil?
      data[:external_url] = external_url unless external_url.nil?
      data[:date_published] = Time.at(post.created_utc).to_datetime.rfc3339
      data[:attachments] = attachments
      data
    end

    def content_text
      post.selftext || post.title
    end

    def content_text
      post.selftext || post.title
    end

    def external_url
      post.respond_to?(:url_overridden_by_dest) ? post.url_overridden_by_dest : post.url
    end

    def url
      Addressable::URI.parse(base).tap { |u| u.path = post.permalink }.to_s
    end

    def author
      [{
        name: post.author,
        url: "https://www.reddit.com/user/#{post.author}"
        # avatar: 'https://blah.com'
      }]
    end

    def attachments
      VideoExtractor.extract(post)
    end
  end

  class VideoExtractor
    VIDEO_EXTENSIONS = [".mp4"]
    VIDEO_NAME = "Video"
    def self.extract(data)
      result = []
      url = Addressable::URI.parse(data.url)
      ext = File.extname(url.path)
      mime = Marcel::MimeType.for(extension: ext)
      if VIDEO_EXTENSIONS.include?(ext)
        result << {
          title: VIDEO_NAME,
          url: url.to_s,
          mime_type: mime
        }
      end

      result << gifv(url) if ext == ".gifv"
      result += reddit_video(data.secure_media || data.media)

      result
    end

    def self.gifv(url)
      curl = Addressable::URI.parse(url).tap do |u|
        u.path = u.path.gsub(/.gifv/, ".mp4")
      end
      cmime = Marcel::MimeType.for(extension: ".mp4")
      {
        title: VIDEO_NAME,
        url: curl.to_s,
        mime_type: cmime
      }
    end

    def self.reddit_video(media)
      return [] if media.nil?
      return [] unless media.key?("reddit_video")

      duration = media.dig("reddit_video", "duration")
      [
        media.dig("reddit_video", "fallback_url"),
        media.dig("reddit_video", "dash_url"),
        media.dig("reddit_video", "hls_url")
      ].compact.map do |v|
        url = Addressable::URI.parse(CGI.unescapeHTML(v))
        ext = File.extname(url.path)
        mime = Marcel::MimeType.for(extension: ext)
        {
          title: VIDEO_NAME,
          url: url.to_s,
          mime_type: mime,
          duraction_in_seconds: duration
        }
      end
    end
  end

  class ImageExtractor
    def self.extract(data)
    end
  end
end
