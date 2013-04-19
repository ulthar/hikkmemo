require 'fileutils'
require 'open-uri'
require 'nokogiri'
require 'readline'
require 'rainbow'
require 'sequel'
require 'date'

require_relative 'ring_buffer'
require_relative 'reader'
require_relative 'worker'
require_relative 'session'
require_relative 'readers'

module Hikkmemo
  def run(*args)
    Thread.abort_on_exception = true
    Session.new(*args).interact
  end
  module_function :run
end
