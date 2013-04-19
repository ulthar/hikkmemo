# -*- coding: utf-8 -*-
require 'date'
require_relative 'util'

module Hikkmemo
  module Readers
    def nullchan(section)
      Reader.new('http://0chan.hk' + section) do
        @threads      = ->(d) { d.css('div[id^="thread"]') }
        @posts        = ->(d) { d.css('div.postnode') }
        @thread_url   = ->(i) { "http://0chan.hk#{section}res/#{i}.html" }
        @thread_id    = ->(t) { t['id'].tr('^0-9', '').to_i }
        @post_id      = ->(p) { p.css('span[class^="dnb"]')[0]['class'].tr('^0-9', '').to_i }
        @post_author  = ->(p) { p.css('span.postername').text }
        @post_subject = ->(p) { p.css('span.filetitle').text }
        @post_date    = ->(p) {
          date_str = p.css('label').children.last.text.strip
          DateTime.strptime(Util.delocalize_ru_date(date_str), '%a %Y %b %e %H:%M:%S')
        }
        @post_message = ->(p) {
          msg = p.css('div.postmessage')
          msg.children.each {|c| c.replace(c.text + "\n") if ['br', 'span'].include?(c.name) }
          msg.text.strip
        }
        @post_image = ->(p) {
          img = p.css('img')[0]
          img && "http://0chan.hk#{section}src/#{File.basename(img['src']).to_i}#{File.extname(img['src'])}"
        }
        @post_video = ->(p) {
          vid = p.css('embed')[0]
          vid && vid['src']
        }
      end
    end
    module_function :nullchan

    def dvach_hk(section)
      Reader.new('http://2ch.hk' + section) do
        @threads      = ->(d) { d.css('div.thread') }
        @posts        = ->(d) { d.css('div.oppost') + d.css('table.post') }
        @thread_url   = ->(i) { "http://2ch.hk#{section}res/#{i}.html" }
        @thread_id    = ->(t) { t['id'][7..-1].to_i }
        @post_id      = ->(p) { p['id'][5..-1].to_i }
        @post_author  = ->(p) { p.css('span.name').text }
        @post_subject = ->(p) { p.css('span.subject').text }
        @post_date    = ->(p) {
          date_str = p.css('span.posttime').text.strip
          DateTime.strptime(Util.delocalize_ru_date(date_str), '%a %e %b %Y %H:%M:%S')
        }
        @post_message = ->(p) {
          msg = p.css('blockquote.postMessage')
          msg.children.each {|c| c.replace(c.text + "\n") if ['br', 'span'].include?(c.name) }
          msg.text.strip
        }
        @post_image = ->(p) {
          img = p.css('span[id^="exlink"] a')[0]
          img && "http://2ch.hk#{img['href']}"
        }
        @post_video = ->(p) {
          vid = p.css('embed')[0]
          vid && vid['src']
        }
      end
    end
    module_function :dvach_hk
  end
end
