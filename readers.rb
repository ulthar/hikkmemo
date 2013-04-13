module Hikkmemo
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
        @post_video_f = ->(p) {
          vid = p.css('embed')[0]
          vid && vid['src']
        }
      end
    end
    module_function :nullchan #, :dvach
  end
end
