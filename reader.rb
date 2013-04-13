module Hikkmemo
  class Reader
    attr_reader   :url
    attr_accessor :thread_url_f, :thread_css, :thread_id_f
    attr_accessor :post_css, :post_id_f, :post_date_f, :post_author_f
    attr_accessor :post_message_f, :post_image_f

    def initialize(url, &block)
      @url = url
      self.instance_eval(&block)
    end

    def fringe
      Nokogiri::HTML(open(@url)).css(@thread_css).map do |t|
        [@thread_id_f.(t), @post_id_f.(t.css(@post_css).last)]
      end
    end

    def thread_posts(thread_id, after: nil)
      posts = Nokogiri::HTML(open(@thread_url_f.(thread_id))).css(@post_css)
      after ? posts.drop_while {|p| @post_id_f.(p) <= after } : posts
    end

    def post_data(node, thread_id)
      { :id      => @post_id_f.(node),
        :thread  => thread_id,
        :date    => @post_date_f.(node),
        :author  => @post_author_f.(node),
        :message => @post_message_f.(node),
        :image   => @post_image_f.(node),
        :video   => @post_video_f.(node)
      }
    end
  end
end
