require 'hikkmemo/session'
require 'hikkmemo/readers'

module Hikkmemo
  def run(*args)
    Thread.abort_on_exception = true
    Session.new(*args).interact
  end
  module_function :run
end
