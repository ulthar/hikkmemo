module Hikkmemo
  class Worker
    attr_accessor :timeout, :thread

    def initialize(session, db, board, reader)
      @session, @db, @board, @reader = session, db, board, reader
      @timeout = 30
    end

    def add_post(post_node, thread_id)
      data = @reader.post_data(post_node, thread_id)
      @db[:posts].insert(data)
      @session.log('+', @board, "#{data[:id]}[#{thread_id}] - '#{data[:message][0..29].tr("\n",'')}...'")
      if data[:image]
        path = "#{@session.path}/#{@board}/#{File.basename(data[:image])}"
        begin
          bytes = open(data[:image]).read
          File.open(path, 'wb') {|f| f << bytes }
        rescue
          @session.log('!', @board, data[:image])
        else
          @session.log('@', @board, path)
        end
      end
    end

    def run
      @thread ||= Thread.new {
        loop do
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
              @session.log('+', @board, "[#{tid}]")
              posts.each {|p| add_post(p, tid) }
            end
          end
          sleep @timeout
        end
      }
    end
  end
end
