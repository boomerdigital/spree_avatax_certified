module AvataxHelper
  class AvataxLog
    def initialize(path_name, file_name, log_info = nil, schedule = nil)
      schedule = "weekly" unless schedule != nil
      @logger ||= Logger.new('log/' + path_name + '.txt', schedule)
      progname(file_name.split("/").last.chomp(".rb"))
      info(log_info) unless log_info.nil?
    end

    def logger
      @logger
    end

    def progname(progname = nil)
      progname.nil? ? logger.progname : logger.progname = progname
    end

    def info(log_info = nil)
      logger.info log_info unless log_info.nil?
    end

    def info_and_debug(log_info, request_hash)
      logger.info log_info
      logger.debug request_hash
      logger.debug JSON.generate(request_hash)
    end


    def debug(error, text = nil)
      logger.debug error
      if text.nil?
        error
      else
        logger.debug text
        text
      end
    end
  end
end
