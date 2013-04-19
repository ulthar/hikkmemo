module Hikkmemo
  class RingBuffer
    def initialize(capacity)
      @buff = [nil] * capacity
      @i = 0
    end

    def push(elem)
      @buff[@i] = elem
      @i = @i == @buff.size - 1 ? 0 : @i + 1
      self
    end

    def pop
      @i = (@i == 0 ? @buff.size : @i) - 1
      @buff[@i]
    end

    def last_n(n)
      n = [n, @buff.size].min
      i = @i == 0 ? @buff.size : @i
      i < n ? @buff[-(n-i)..-1] + @buff[0..i-1] : @buff[i-n..i-1]
    end
  end
end
