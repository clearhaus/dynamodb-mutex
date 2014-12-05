require 'logger'

module Logging
  attr_writer :logger

  def logger
    @logger ||= lambda {
      logger = Logger.new(STDOUT, 1024*1024, 10)
      logger.level = Logger::DEBUG
      logger
    }.call
  end

end
