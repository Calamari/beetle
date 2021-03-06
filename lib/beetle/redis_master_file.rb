module Beetle
  module RedisMasterFile #:nodoc:
    private
    def master_file_exists?
      File.exist?(master_file)
    end

    def redis_master_from_master_file
      redis.find(read_redis_master_file)
    end

    def clear_redis_master_file
      write_redis_master_file("")
    end

    def read_redis_master_file
      File.read(master_file).chomp
    end

    def write_redis_master_file(redis_server_string)
      logger.warn "Writing '#{redis_server_string}' to redis master file '#{master_file}'"
      File.open(master_file, "w"){|f| f.puts redis_server_string }
    end

    def master_file
      config.redis_server
    end

    def verify_redis_master_file_string
      if master_file =~ /^[0-9a-z.]+:[0-9]+$/
        raise ConfigurationError.new("To use the redis failover, redis_server config option must point to a file")
      end
    end
  end
end
