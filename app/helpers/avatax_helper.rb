module AvataxHelper
  class AvataxLog
    def initialize(path_name, file_name, log_info = nil, schedule = nil)
      if !(Spree::Config.avatax_log_to_stdout)
        schedule = "weekly" unless schedule != nil
        @logger ||= Logger.new("#{Rails.root}/log/#{path_name}.log", schedule)
        progname(file_name.split("/").last.chomp(".rb"))
      else
        log_info = "-#{file_name} #{log_info}"
        @logger = Logger.new(STDOUT)
      end

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
        unless log_info.nil?
          logger.info "[AVATAX] #{log_info}"
        end
      end
    end

    def info_and_debug(log_info, response)
      if logger_enabled?
        logger.info "[AVATAX] #{log_info}"
        if response.is_a?(Hash)
          logger.debug "[AVATAX] #{JSON.generate(response)}"
        else
          logger.debug "[AVATAX] #{response}"
        end
      end
    end

    def debug(error, text = nil)
      if logger_enabled?
        logger.debug "[AVATAX] #{error.inspect}"
        if text.nil?
          error
        else
          logger.debug "[AVATAX] text"
          text
        end
      end
    end
  end
end
