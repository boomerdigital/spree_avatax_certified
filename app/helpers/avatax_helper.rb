module AvataxHelper
  class AvataxLog
    def initialize(path_name, file_name, log_info = nil, schedule = nil)
      schedule = "weekly" unless schedule != nil
      path = "#{Rails.root}/log/#{path_name}.log"
      @logger ||= new_logger(path, schedule)
      progname(file_name.split("/").last.chomp(".rb"))
      info(log_info) unless log_info.nil?
    end

    def logger
      @logger
    end

    def logger_enabled?
      Spree::Config.avatax_log
    end

    def progname(progname = nil)
      if logger_enabled?
        progname.nil? ? logger.progname : logger.progname = progname
      end
    end

    def info(log_info = nil)
      if logger_enabled?
        logger.info log_info unless log_info.nil?
      end
    end

    def info_and_debug(log_info, request_hash)
      if logger_enabled?
        logger.info log_info
        logger.debug request_hash
        logger.debug JSON.generate(request_hash)
      end
    end


    def debug(error, text = nil)
      if logger_enabled?
        logger.debug error
        if text.nil?
          error
        else
          logger.debug text
          text
        end
      end
    end

    private

    def new_logger(path, schedule)
      FileUtils.touch path # prevent autocreate messages in log
      Logger.new(path, schedule)
    end
  end
end
