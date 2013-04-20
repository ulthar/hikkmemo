module Hikkmemo
  class Worker
    attr_reader   :db
    attr_accessor :timeout, :thread

    def initialize(db, reader)
      @db, @reader = db, reader
      @on_add_thread = []
      @on_add_post   = []
      @timeout       = 30
    end

    def add_post(post_node, thread_id)
      data = @reader.post_data(post_node, thread_id)
      unless @db[:posts][:id => data[:id]]
        @db[:posts].insert(data)
        @on_add_post.each {|p| p.(data) }
      end
    end

    def on_add_post  (&p) @on_add_post   += [p] end
    def on_add_thread(&p) @on_add_thread += [p] end

    def run
      @thread ||= Thread.new do
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
              data  = { :id => tid, :last_post => pid, :date => date }
              @db[:threads].insert(data)
              @on_add_thread.each {|p| p.(data) }
              posts.each {|p| add_post(p, tid) }
            end
          end
          sleep @timeout
        end
      end
    end
  end
end
