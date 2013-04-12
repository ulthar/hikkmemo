require 'fileutils'
require 'open-uri'
require 'nokogiri'
require 'sequel'

module Hikkmemo
  class << self
    Thread.abort_on_exception = true
    attr_reader :hikkpath, :workers
  end

  @hikkpath = File.expand_path('~/.hikkmemo')
  @workers  = {}

  def hikkpath=(path)
    @hikkpath = File.expand_path(path).chomp('/')
  end
  module_function :hikkpath=

  def log(msg)
    puts msg
  end

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

    def post_data(post_node, thread_id) {
        :id      => @post_id_f.(post_node),
        :thread  => thread_id,
        :date    => @post_date_f.(post_node),
        :author  => @post_author_f.(post_node),
        :message => @post_message_f.(post_node),
        :image   => @post_image_f.(post_node)
      }
    end
  end

  class Worker
    include Hikkmemo
    attr_accessor :timeout, :thread

    def initialize(db, board, reader)
      @db, @board, @reader = db, board, reader
      @timeout = 30
    end

    def add_post(post_node, thread_id)
      data = @reader.post_data(post_node, thread_id)
      @db[:posts].insert(data)
      log "+ #{data[:id]}[#{thread_id}] - '#{data[:message][0..29].tr("\n",'')}...'"
      if data[:image]
        path = "#{Hikkmemo.hikkpath}/#{@board}/#{File.basename(data[:image])}"
        begin
          bytes = open(data[:image]).read
          File.open(path, 'wb') {|f| f << bytes }
        rescue
          log "! #{data[:image]}"
        else
          log "@ #{path}"
        end
      end
    end

    def run
      @thread ||= Thread.new {
        while true do
          @reader.fringe.each do |tid,pid|
            thread = @db[:threads][:id => tid]
            if thread
              if thread[:last_post] != pid
                @reader.thread_posts(tid, after: thread[:last_post])
                  .each {|p| add_post(p, tid) }
                @db[:threads][:id => tid] = { :last_post => pid }
              end
            else
              posts = @reader.thread_posts(tid)
              date  = @reader.post_data(posts[0], tid)[:date]
              @db[:threads].insert [tid, pid, date]
              log "+ [#{tid}]"
              posts.each {|p| add_post(p, tid) }
            end
          end
          sleep @timeout
        end
      }
    end
  end

  def memo(board, reader)
    FileUtils.mkdir_p [@hikkpath, "#{@hikkpath}/#{board}/"]
    File.open("#{@hikkpath}/#{board}.db", 'a') {}
    db = Sequel.sqlite("#{@hikkpath}/#{board}.db")

    db.create_table? :posts do
      Integer :id, :primary_key => true
      foreign_key :thread, :threads
      String :date
      String :author
      String :message
      String :image
    end

    db.create_table? :threads do
      Integer :id, :primary_key => true
      Integer :last_post
      String  :date
    end

    @workers[board] = Worker.new(db, board, reader)
    @workers[board].run
  end
  module_function :memo

  module Readers
    def nullchan(section)
      Reader.new('http://0chan.hk' + section) do
        @thread_url_f   = ->(tid) { "http://0chan.hk#{section}res/#{tid}.html" }
        @thread_css     = 'div[id^="thread"]'
        @thread_id_f    = ->(t) { t['id'].tr('^0-9', '').to_i }
        @post_css       = 'div.postnode'
        @post_id_f      = ->(p) { p.css('span[class^="dnb"]')[0]['class'].tr('^0-9', '').to_i }
        @post_date_f    = ->(p) { p.css('label').children.last.text.strip }
        @post_author_f  = ->(p) { p.css('span.postername').text }
        @post_message_f = ->(p) {
          msg = p.css('div.postmessage')
          msg.children.each {|c| c.replace(c.text + "\n") if ['br', 'span'].include?(c.name) }
          msg.text.strip
        }
        @post_image_f = ->(p) {
          img = p.css('img')[0]
          img && "http://0chan.hk#{section}src/#{File.basename(img['src']).to_i}#{File.extname(img['src'])}"
        }
      end
    end
    module_function :nullchan #, :dvach
  end
end

Hikkmemo::memo('codach', Hikkmemo::Readers.nullchan('/c/'))

=begin
# cr = Hikkmemo::Readers.nullchan('/c/')
# cr.thread_posts(25711, after: 25711).map {|p| cr.post_message_f.(p) }.each {|m| puts "---------"; puts m }
    def dvach(section)
      Reader.new('http://2ch.hk' + section) do
        @thread_url_f = ->(tid) { "http://2ch.hk#{section}res/#{tid}.html" }
        @thread_css  = 'div[id^="thread"]'
        @thread_id_f = ->(t) { t['id'].tr('^0-9', '').to_i }
        @post_css    = 'div.postnode'
        @post_id_f   = ->(p) {
          lp = p.css('td.reply')[0]
          lp && lp['id'].tr('^0-9', '').to_i
        }
      end
    end
=end
