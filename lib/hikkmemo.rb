require 'hikkmemo/session'
require 'hikkmemo/readers'

module Hikkmemo
  module_function
  def run(*args, &block)
    Thread.abort_on_exception = true
    s = Session.new(*args)
    s.instance_eval(&block)
    s.interact
  end
end
