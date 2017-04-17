module SpreeAvataxCertified
  class AvataxLog
    def initialize(file_name, log_info = nil, schedule = nil)
      if !Spree::Config.avatax_log_to_stdout
        schedule = 'weekly' unless schedule != nil
        @logger ||= Logger.new("#{Rails.root}/log/avatax.log", schedule)
        progname(file_name.split('/').last.chomp('.rb'))
        info(log_info) unless log_info.nil?
      else
        log_info = "-#{file_name} #{log_info}"
        @logger ||= Logger.new(STDOUT)
      end
    end

    def logger
      @logger
    end

    def enabled?
      Spree::Config.avatax_log || Spree::Config.avatax_log_to_stdout
    end

    def progname(progname = nil)
      if enabled?
        progname.nil? ? logger.progname : logger.progname = progname
      end
    end

    def info(message, obj = nil)
      if enabled?
        logger.info "[AVATAX] #{message} #{obj}"
      end
    end

    def info_and_debug(log_info, response)
      if enabled?
        logger.info "[AVATAX] #{log_info}"
        if response.is_a?(Hash)
          logger.debug "[AVATAX] #{JSON.generate(response)}"
        else
          logger.debug "[AVATAX] #{response}"
        end
      end
    end


    def debug(obj, message='')
      if enabled?
        logger.debug "[AVATAX] #{message} #{obj.inspect}"
      end
    end

    def error(obj, message='')
      if enabled?
        logger.error "[AVATAX] #{message} #{obj}"
      end
    end
  end
end
