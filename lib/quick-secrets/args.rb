require 'docopt'

module QuickSecrets
  class ParseArgs
    def initialize(gemspec = nil)
      progname = gemspec.name
      docopt = <<~DOCOPT
        Quick Secrets - #{gemspec.summary}

        Usage:
          #{progname} [--config=FILE]

        Options:
          -h --help           Show this screen.
             --version        Show version.
             --config=FILE    Location of configuration file [default: xxxxx].
      DOCOPT

      begin
        @args = Docopt::docopt(docopt, { :help => true, :version => gemspec.version.to_s })
      rescue Docopt::Exit => e
        puts e.message
        exit
      end
      # print "config file: #{@args['--config']}\n"
    end

    # Allow access to any argument through the instance as if a hash.
    def [](key)
      @args[key]
    end

    def []=(key,val)
      @args[key] = val
    end

    def keys
      @args.keys
    end

    def to_h
      @args.to_h
    end

  end
end
