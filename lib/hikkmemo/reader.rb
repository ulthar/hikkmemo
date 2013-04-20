require 'nokogiri'

module Hikkmemo
  class Reader
    attr_reader :url

    def initialize(url, &block)
      @url = url
      self.instance_eval(&block)
    end

    def doc(url)
      begin
        Nokogiri::HTML(open(url))
      rescue
        puts "Failed accessing #{url}, retrying..."
        sleep 2
        retry
      end
    end

    def fringe
      @threads.(doc(@url)).map do |t|
        [@thread_id.(t), @post_id.(@posts.(t).last)]
      end
    end

    def thread_posts(thread_id, after: nil)
      posts = @posts.(doc(@thread_url.(thread_id)))
      after ? posts.drop_while {|p| @post_id.(p) <= after } : posts
    end

    def post_data(node, thread_id)
      { :id      => @post_id.(node),
        :thread  => thread_id,
        :date    => @post_date.(node),
        :author  => @post_author.(node),
        :subject => @post_subject.(node),
        :message => @post_message.(node),
        :image   => @post_image.(node),
        :video   => @post_video.(node)
      }
    end
  end
end
