require 'fileutils'
require 'nokogiri'
require 'open-uri'
require 'readline'
require 'rainbow'
require 'sequel'
require 'hikkmemo/ring_buffer'
require 'hikkmemo/worker'
require 'hikkmemo/util'

module Hikkmemo
  class Session
    attr_reader :path, :workers, :history

    def initialize(path, opts = {})
      opts[:log_to]       ||= :files
      opts[:boards]       ||= {}
      opts[:history_size] ||= 10
      @prompt       = opts[:prompt] || 'hikkmemo/%b>'
      @prompt_color = opts[:prompt_color] || :default
      @theme   = opts[:theme]   || :solid
      @colors  = opts[:colors]  || :default
      @log_msg = opts[:log_msg] || '%t %k (%b) %m'
      @msg_sz  = opts[:msg_sz]  || 100

      @path    = File.expand_path(path).chomp('/')
      @history = RingBuffer.new(opts[:history_size])
      @aux_cnt = 0
      @workers = {}
      @cmds    = {}
      @board   = opts[:boards].keys[0].to_s

      cl = ->(k,b,m) { print "\r#{log_msg(k,b,m)}\n#{prompt}"}
      fl = ->(k,b,m) { File.open("#{@path}/#{b}.log", 'a') {|f| f.puts "#{time} #{k} #{m}" } }
      @logger = {
        :console => cl,
        :files   => fl,
        :console_and_files => ->(k,b,m) { cl.(k,b,m); fl.(k,b,m) }
      }[opts[:log_to]]

      opts[:boards].each {|b,r| serve(b.to_s, r) }
    end

    def serve(board, reader)
      FileUtils.mkdir_p [@path, "#{@path}/#{board}/"]
      File.open("#{@path}/#{board}.db", 'a') {}
      db = Sequel.sqlite("#{@path}/#{board}.db")

      db.create_table? :posts do
        Integer :id, :primary_key => true
        foreign_key :thread, :threads
        DateTime :date
        String :author
        String :subject
        String :message
        String :image
        String :embed
      end

      db.create_table? :threads do
        Integer :id, :primary_key => true
        Integer :last_post
        DateTime :date
      end

      worker = @workers[board] = Worker.new(db, reader)
      worker.on_add_thread {|t| log('+', board, "[#{t[:id]}]") }
      worker.on_add_post do |p|
        log('+', board, "#{p[:id]}[#{p[:thread]}] - '#{p[:message][0..@msg_sz].tr("\n",'')}...'")
        (img = p[:image]) && img.split(',').each {|img| download_image(board, img) }
      end
      worker.run
    end

    def interact
      loop do
        inp = Readline.readline(prompt, true)
        next unless inp
        cmd = inp.split
        case cmd[0]
        when 'exit' then break
        when 'help'
          puts '=========================================================================='
          puts '#  b = board'
          puts '#  p = post id'
          puts '#  t = thread id'
          puts '# ?x = optional x'
          puts '=========================================================================='
          puts 'history n      -- last n events'
          puts 'context b      -- set board in context (for cmds like "post" and "thread")'
          puts 'post    p   ?b -- print post'
          puts 'posts   n   ?b -- last n posts'
          puts 'tposts  n t ?b -- last n posts of thread'
          puts 'thread  t   ?b -- print all posts of thread'
        when 'history' then @history.last_n(cmd[1].to_i).each {|m| puts m }
        when 'context' then cmd_context cmd[1]
        when 'post'    then cmd_post    cmd[1].to_i, cmd[2] || @board
        when 'posts'   then cmd_posts   cmd[1].to_i, cmd[2] || @board
        when 'tposts'  then cmd_tposts  cmd[1].to_i, cmd[2].to_i, cmd[3] || @board
        when 'thread'  then cmd_thread  cmd[1].to_i, cmd[2] || @board
        else
          fn = @cmds[cmd[0]]
          fn && fn.(cmd.drop(1))
        end
        puts ''
      end
    end

    def notice(msg)
      print "\r#{time} ~ #{msg}\n#{prompt}".color(:cyan)
    end

    def hook(board = nil, &block)
      if board
        with_board_worker (board.to_s) {|w| w.on_add_post(&block) }
      else
        @workers.each do |b,w|
          w.on_add_post {|p| block.call(p,b) }
        end
      end
    end

    def cmd(name, &block)
      @cmds[name] = block
    end

    private

    def log(kind, board, msg)
      @history.push log_msg(kind, board, msg, colored: false)
      @logger.(kind, board, msg)
    end

    def time
      Time.now.strftime '%H:%M:%S'
    end

    def log_msg(kind, board, msg, colored: true)
      text = @log_msg.gsub /%t|%k|%b|%m/, {
        '%t' => time,  '%k' => kind,
        '%b' => board, '%m' => msg
      }
      colored ? colorize(text) : text
    end

    def colorize(text)
      case @theme
        when :solid then text.color(@colors)
        when :zebra then text.color(@colors[@aux_cnt = (@aux_cnt + 1) % @colors.size])
        else text
      end
    end

    def prompt
      @prompt.gsub('%b', @board).color(@prompt_color)
    end

    def download_image(board, src)
      path = "#{@path}/#{board}/#{File.basename(src)}"
      begin
        bytes = open(src).read
        File.open(path, 'wb') {|f| f << bytes }
      rescue
        log('!', board, src)
      else
        log('@', board, path)
      end
    end

    def print_post(post)
      puts "\n(#{post[:author]}) - #{post[:date]} - #{post[:id]}[#{post[:thread]}]".underline
      puts post[:message]
    end

    def with_board_worker(board, &block)
      worker = @workers[board]
      worker ? block.call(worker) : puts('unknown board')
    end

    def cmd_context(board)
      with_board_worker (board) { @board = board }
    end

    def cmd_post(id, board)
      with_board_worker board do |wr|
        post = wr.db[:posts][:id => id]
        post ? print_post(post) : puts('post not found')
      end
    end

    def cmd_posts(n, board)
      with_board_worker board do |wr|
        wr.db[:posts].order(Sequel.desc(:date)).limit(n)
          .all.reverse.each {|p| print_post(p) }
      end
    end

    def cmd_tposts(n, tid, board)
      with_board_worker board do |wr|
        wr.db[:posts].where(:thread => tid)
          .order(Sequel.desc(:date)).limit(n)
          .all.reverse.each {|p| print_post(p) }
      end
    end

    def cmd_thread(tid, board)
      with_board_worker board do |wr|
        if_nil wr.db[:threads][:id => tid] { puts 'thread not found'; return }
        wr.db[:posts].where(:thread => tid).each {|p| print_post(p) }
      end
    end
  end
end
