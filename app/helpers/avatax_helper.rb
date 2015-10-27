module AvataxHelper
  class AvataxLog
    def initialize(path_name, file_name, log_info = nil, schedule = nil)
      schedule = "weekly" unless schedule != nil
      @logger ||= Logger.new("#{Rails.root}/log/#{path_name}.log", schedule)
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

    def info_and_debug(log_info, response)
      if logger_enabled?
        logger.info log_info
        if response.is_a?(Hash)
          logger.debug JSON.generate(response)
        else
          logger.debug response
        end
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
  end
end
