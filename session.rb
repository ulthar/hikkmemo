require_relative 'ring_buffer'

module Hikkmemo
  class Session
    attr_reader :path, :workers, :history

    def initialize(path, log_to: :console_and_files, history_size: 10, &block)
      @path    = File.expand_path(path).chomp('/')
      @history = RingBuffer.new(history_size)
      @logger  = ->(){}
      @workers = {}
      cl = ->(t,b,m) { puts "#{t} (#{b}) #{m}"}
      fl = ->(t,b,m) { File.open("#{@path}/#{b}.log", 'a') {|f| f.puts "#{t} #{m}" } }
      case log_to
      when :console then @logger = cl
      when :files   then @logger = fl
      when :console_and_files
        @logger = ->(t,b,m) { cl.(t,b,m); fl.(t,b,m) }
      end
      self.instance_eval(&block)
    end

    def log(type, board, msg)
      @history.push("#{type} (#{board}) #{msg}")
      @logger.(type, board, msg)
    end

    private

    def serve(board, reader)
      FileUtils.mkdir_p [@path, "#{@path}/#{board}/"]
      File.open("#{@path}/#{board}.db", 'a') {}
      db = Sequel.sqlite("#{@path}/#{board}.db")

      db.create_table? :posts do
        Integer :id, :primary_key => true
        foreign_key :thread, :threads
        String :date
        String :author
        String :message
        String :image
        String :video
      end

      db.create_table? :threads do
        Integer :id, :primary_key => true
        Integer :last_post
        String  :date
      end

      @workers[board] = Worker.new(self, db, board, reader)
      @workers[board].run
    end

    def interact
      loop do
        inp = $stdin.gets
        next unless inp
        cmd = inp.split
        case cmd[0]
        when 'exit'    then break
        when 'history' then @history.last_n(cmd[1].to_i).reverse.each {|m| puts m }
        end
      end
    end
  end
end
