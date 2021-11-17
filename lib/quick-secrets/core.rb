require 'sequel'
require "rubygems"

module QuickSecrets
  class Core
    attr_reader :authenticator
    attr_reader :secrets
    attr_reader :config

    def initialize
      @gemspec = Gem::Specification::load("quick-secrets.gemspec")
      @args = QuickSecrets::ParseArgs.new(@gemspec)
      @config = QuickSecrets::Configuration.new(@args)
      @authenticator = QuickSecrets::Auth.new
      @secrets = QuickSecrets::Secret::Manager.new

      puts "initializing db " # debug: #{@config['database']}"
      db_init
      check_default_admin
    end

    # If a default admin password is set in the configuration file,
    # create the user "admin" with set password
    def check_default_admin
      admin_pass = @config["admin_password"]
      return if admin_pass.nil?
      if (admin = db[:account].where(username: "admin", expired: false).first).nil?
        puts "Admin account not found, creating..."
        db[:account].insert(username: "admin", password: admin_pass, privilege: QuickSecrets::Privilege::ADMIN, expired: false)
      end

      admin = db[:account].where(username: "admin", expired: false).first
      if admin[:password] != admin_pass
        puts "Updating admin password..."
        db[:account].where(id: admin[:id]).update(password: admin_pass)
      end

    end

    # Create database tables if needed
    def db_init
      unless db.table_exists? :account
        db.create_table :account do
          primary_key :id
          String :username
          String :password
          Integer :privilege
          Boolean :expired
        end
      end
      unless db.table_exists? :token
        db.create_table :token do
          primary_key :id
          String :token
          Integer :account_id
        end
      end
      unless db.table_exists? :secret
        db.create_table :secret do
          primary_key :id
          String :uuid
          String :expiration_date
          Blob :initialization_vector
          Blob :encrypted_data
        end
      end
    end


    def db
      Sequel.connect(@config["database"])
    end

    def self.core
      $QUICKSECRETS_CORE = QuickSecrets::Core.new if $QUICKSECRETS_CORE.nil?
      $QUICKSECRETS_CORE
    end
  end
end
