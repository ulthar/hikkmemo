require 'open-uri'
require 'nokogiri'
require 'sequel'

module Hikkmemo
  module_function :memo
  attr_accessor :hikkpath, :workers

  @hikkpath = '~/.hikkmemo'
  @workers  = {}

  class Reader
    attr_accessor :url, :thread_css, :thread_id_f, :post_css, :post_id_f

    def initialize(url, &block)
      @url = url
      self.instance_eval(&block)
    end

    def fringe
      doc = Nokogiri::HTML(open(url))
      doc.css(thread_css).map do |t|
        [thread_id_f.(t), post_id_f.(t.css(post_css).last)]
      end
    end
  end

  Worker = Struct.new(:url, :reader) do
    attr_accessor :timeout
    @timeout = 30

    def start
      puts 'pssss'
    end
    
    def stop
      
    end
  end

  def memo(board, url, reader)
    db = Sequel.sqlite("#{hikkpath}/#{board}.db")

    db.create_table? :posts do
      Integer  :id
      Integer  :tid
      DateTime :date
      String   :msg
      String   :img
      primary_key :id
      foreign_key :tid, :threads
    end

    db.create_table? :threads do
      Integer  :id
      DateTime :date
      primary_key :id
    end

    workers[board] = Worker.new(url, reader)
    workers[board].start
  end

  module Readers
    def nullch_reader(section)
      Reader.new('http://0chan.hk' + section) do
        @thread_css  = 'div[id^="thread"]'
        @thread_id_f = ->(t) { t['id'].tr('^0-9', '').to_i }
        @post_css    = 'div.postnode'
        @post_id_f   = ->(p) {
          lp = p.css('td.reply')[0]
          lp && lp['id'].tr('^0-9', '').to_i
        }
      end
    end

    def dvach_reader(section)
      Reader.new('http://2ch.hk' + section) do
        @thread_css  = 'div[id^="thread"]'
        @thread_id_f = ->(t) { t['id'].tr('^0-9', '').to_i }
        @post_css    = 'div.postnode'
        @post_id_f   = ->(p) {
          lp = p.css('td.reply')[0]
          lp && lp['id'].tr('^0-9', '').to_i
        }
      end
    end
  end
end

#hikkpath.chomp('/')
# threads
# puts doc.css('div[id^="thread"]')[0]['id']
# File.open("#{hikkpath}/#{board}.url", "w") {|f| f.write(url) }
#def load
#  Dir.glob('#{hikkpath}/*.url') do |f|
#    url    = IO.read(f)
#    board  = File.basename(f, ".*")
#    reader = YAML.load(File.read('#{hikkpath}/#{board}.rdr'))
#  end
#end
