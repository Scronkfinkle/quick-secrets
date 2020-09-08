require 'sinatra/base'

# Runs the app from the command quick-secrets
# TODO add command line args
module QuickSecrets
  class Command
    def run(args)
      require 'quick-secrets'
      QuickSecrets::Core.core
      QuickSecrets::Web::App.run!
    end
  end
end
