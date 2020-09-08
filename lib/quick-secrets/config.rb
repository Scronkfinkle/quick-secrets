require 'yaml'

module QuickSecrets
  class Configuration
    attr_reader :config
    attr_reader :config_file
    
    # TODO add config file as command line argument so it can be passed to here
    def initialize(config_file = nil)
      # If not specified in command line, check environment variable
      @config_file = ENV["QUICK_SECRETS_CONFIG"] if config_file.nil?

      # If specified nowhere, fallback to default
      @config_file = "/etc/quick_secrets/config.yml" if @config_file.nil?
      load_config
    end

    # If the config file does not exist, deploy it
    def load_config
      unless File.exists? config_file
        FileUtils.cp(__dir__+"/templates/config.yml",config_file)
      end
      @config = YAML.load(File.read(config_file))
      @config = {} if @config == false
    end

    def [](key)
      env_val = ENV["QUICK_SECRETS_#{key.upcase}"]
      unless env_val.nil?
        if env_val.size < 1
          return nil
        else
          return env_val
        end
      end
      @config[key]
    end

    def []=(key,val)
      @config[key] = val
    end

    def keys
      @config.keys
    end

    def to_h
      @config.to_h
    end

  end
end

