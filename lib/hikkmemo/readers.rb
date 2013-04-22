# -*- coding: utf-8 -*-
require 'date'
require 'hikkmemo/reader'
require 'hikkmemo/util'
require "unicode_utils/titlecase"

module Hikkmemo
  module Readers
    module_function

    def nullchan(section)
      Reader.new('http://0chan.hk' + section) do
        @threads      = ->(d) { d.css('div[id^="thread"]') }
        @posts        = ->(d) { d.css('div.postnode') }
        @thread_url   = ->(i) { "http://0chan.hk#{section}res/#{i}.html" }
        @thread_id    = ->(t) { t['id'].tr('^0-9', '').to_i }
        @post_id      = ->(p) { p.css('span[class^="dnb"]')[0]['class'].tr('^0-9', '').to_i }
        @post_subject = ->(p) { p.css('span.filetitle').text }
        @post_author  = ->(p) {
          trip = p.css('span.postertrip')[0]
          p.css('span.postername').text + (trip && trip.text || '')
        }
        @post_date = ->(p) {
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
        @post_embed = ->(p) {
          vid = p.css('embed')[0]
          vid && vid['src']
        }
      end
    end

    def dvach_hk(section)
      Reader.new('http://2ch.hk' + section) do
        @threads      = ->(d) { d.css('div.thread') }
        @posts        = ->(d) { d.css('div.oppost') + d.css('table.post') }
        @thread_url   = ->(i) { "http://2ch.hk#{section}res/#{i}.html" }
        @thread_id    = ->(t) { t['id'][7..-1].to_i }
        @post_id      = ->(p) { p['id'][5..-1].to_i }
        @post_subject = ->(p) { p.css('span.subject').text }
        @post_author  = ->(p) {
          trip = p.css('span.postertrip')[0]
          p.css('span.name').text + (trip && trip.text || '')
        }
        @post_date = ->(p) {
          date_str = p.css('span.posttime').text.strip
          DateTime.strptime(Util.delocalize_ru_date(date_str), '%a %e %b %Y %H:%M:%S')
        }
        @post_message = ->(p) {
          msg = p.css('blockquote.postMessage p')
          msg.children.each {|c| c.replace(c.text + "\n") if ['br'].include?(c.name) }
          msg.text.strip
        }
        @post_image = ->(p) {
          img = p.css('span[id^="exlink"] a')[0]
          img && "http://2ch.hk#{img['href']}"
        }
        @post_embed = ->(p) {
          vid = p.css('embed')[0]
          vid && vid['src']
        }
      end
    end

    def dobrochan(section)
      Reader.new('http://dobrochan.ru' + section) do
        @threads      = ->(d) { d.css('div.thread') }
        @posts        = ->(d) { d.css('div.oppost') + d.css('table.post') }
        @thread_url   = ->(i) { "http://dobrochan.ru#{section}res/#{i}.xhtml" }
        @thread_id    = ->(t) { t['id'][7..-1].to_i }
        @post_id      = ->(p) { p['id'][5..-1].to_i }
        @post_subject = ->(p) { p.css('span.replytitle').text }
        @post_author  = ->(p) {
          trip = p.css('span.postertrip')[0]
          p.css('span.postername').text + (trip && trip.text || '')
        }
        @post_date = ->(p) {
          date_str = p.css('label').children.last.text.strip
          DateTime.strptime(date_str, '%e %B %Y (%a) %H:%M')
        }
        @post_message = ->(p) {
          msg = p.css('div.message')
          msg.children.each {|c| c.replace("\n" + c.text.delete("\n")) if c.name == 'blockquote' }
          msg.text.strip
        }
        @post_image = ->(p) {
          imgs = p.css('a[href^="/src"]').to_a.map{|a| a['href'] }.uniq
          imgs.size > 0 && imgs.map {|img| "http://dobrochan.ru#{img}" }.join(',')
        }
        @post_embed = ->(_) { nil }
      end
    end

    def iichan(section)
      Reader.new('http://iichan.hk' + section) do
        @threads = ->(d) { d.css('div[id^="thread"]') }
        @posts   = ->(d) {
          d.css('span.filetitle').attr('class', 'replytitle')
          d.css('span.commentpostername').attr('class', 'postername')
          d = d.at_css('div[id^="thread"]') if d.name == 'document'
          p = d.at_css('table')
          r = p && (d.children.index(p) - 1) || -1
          td = d.document.create_element 'td', {
            :class => 'reply',
            :id    => "reply#{d['id'][7..-1].to_i}"
          }
          td.children = d.children[0..r].unlink
          if d.children.empty? then d.add_child(td) else d.children.before(td) end
          d.css('td.reply')
        }
        @thread_url   = ->(i) { "http://iichan.hk#{section}res/#{i}.html" }
        @thread_id    = ->(t) { t['id'][7..-1].to_i }
        @post_id      = ->(p) { p['id'][5..-1].to_i }
        @post_subject = ->(p) { p.css('span.replytitle').text }
        @post_author  = ->(p) {
          trip = p.css('span.postertrip')[0]
          p.css('span.postername').text + (trip && trip.text || '')
        }
        @post_date = ->(p) {
          d = p.css('label')[0].children.last.text.strip.split(' ').drop(1)
          d[1] = 'Май' if d[1] == 'мая'
          d[1] = UnicodeUtils.titlecase(d[1][0..2])
          date_str = Util.delocalize_ru_date(d.join(' '))
          DateTime.strptime(date_str, '%e %b %Y %H:%M:%S')
        }
        @post_message = ->(p) {
          msg = p.at_css('blockquote')
          msg.traverse {|c| c.replace(c.text + "\n") if ['p', 'br'].include?(c.name) }
          msg.text.strip
        }
        @post_image = ->(p) {
          img = p.at_css('span.filesize a[target="_blank"]')
          img && "http://iichan.hk#{img['href']}"
        }
        @post_embed = ->(_) { nil }
      end
    end
  end
end
