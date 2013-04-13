require 'fileutils'
require 'open-uri'
require 'nokogiri'
require 'sequel'

require_relative 'reader'
require_relative 'worker'
require_relative 'readers'
require_relative 'session'

Thread.abort_on_exception = true

module Hikkmemo
  def run(*args, &block)
    Session.new(*args, &block)
  end
  module_function :run
end

####################################################

include Hikkmemo

Hikkmemo.run '~/.hikkmemo', :log_to => :console_and_files do
  serve 'codach', Readers.nullchan('/c/')
  # serve 'programmach', Readers.dvach '/pr/'
  interact
end


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
