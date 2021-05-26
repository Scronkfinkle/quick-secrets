require 'yaml'

module QuickSecrets
  class Configuration
    attr_reader :config
    attr_reader :config_file

    CONFIG_DEFAULT = "/etc/quick_secrets/config.yml"
    CONFIG_TEMPLATE = __dir__+"/templates/config.yml"

    def initialize(args = nil)
      # save reference to args locally; used in hash accessor (`def []`)
      @args = args

      # Default config file to that provided on the command line
      @config_file = args['--config']

      # If not specified in command line, check environment variable
      @config_file = ENV["QUICK_SECRETS_CONFIG"] if @config_file.nil?

      # If specified nowhere, fallback to default
      @config_file = CONFIG_DEFAULT if @config_file.nil?

      # Load from whatever we found
      load_config
    end

    def load_config
      config_dir = File.dirname config_file
      begin
        FileUtils.mkdir_p config_dir unless File.exists? config_dir
      rescue 
        puts "ERROR: trying to create config directory #{config_dir}"
        puts "Please create this directory and give the user you run this application under permission to read/write to it"
        exit 1
      end

      # If the config file does not exist, deploy it
      unless File.exists? config_file
        begin
          puts "seeding config from template #{CONFIG_TEMPLATE}"
          FileUtils.cp(CONFIG_TEMPLATE, config_file)
        rescue
          puts "ERROR: trying to create config file #{config_file}"
          puts "Please give the user you run this application under permission to read/write to #{config_dir}"
          exit 1
        end
      end
      # load config
      puts "loading config #{config_file}"
      @config = YAML.load(File.read(config_file))
      @config = {} if @config == false
    end

    # Return config value based upon key, in precedence order (highest first):
    def [](key)
      # - command line
      arg_val = @args["--#{key.downcase}"]
      unless arg_val.nil?
        return arg_val
      end
      # - environment variable
      env_val = ENV["QUICK_SECRETS_#{key.upcase}"]
      unless env_val.nil?
        return (env_val.size < 1) ? nil : env_val
      end
      # - config file
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
