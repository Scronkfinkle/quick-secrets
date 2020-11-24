require 'docopt'

module QuickSecrets
  class ParseArgs
    def initialize(gemspec = nil)
      progname = gemspec.name
      docopt = <<~DOCOPT
        Quick Secrets - #{gemspec.summary}

        Usage:
          #{progname} [options]
          #{progname} -h | --help
          #{progname} --version

        Options:
          -h --help           Show this screen.
             --version        Show version.
          -c --config=FILE    Configuration file location.
          -d --database=URL   Database connection url or location.
      DOCOPT

      begin
        @args = Docopt::docopt(docopt, { :help => true, :version => gemspec.version.to_s })
      rescue Docopt::Exit => e
        puts e.message
        exit
      end
      # puts @args.to_s
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
