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
          String :initialization_vector
          String :encrypted_data
        end
      else
        # Hotfix for instances that had buggy database
        # https://github.com/Scronkfinkle/quick-secrets/issues/39
        unless db[:secret].detect {|x| x[:initialization_vector].class == Sequel::SQL::Blob }.nil?
          puts "OLD DB DETECTED, MIGRATING"
          old_entries = db[:secret].map do |row|
            row[:initialization_vector] = row[:initialization_vector].unpack('H*')[0]
            row[:encrypted_data] = row[:encrypted_data].unpack('H*')[0]
            row
          end

          # Drop all older tables
          db[:secret].delete
          
          # Convert columns
          db.alter_table(:secret) do
            drop_column :initialization_vector
            drop_column :encrypted_data
            add_column :initialization_vector, String
            add_column :encrypted_data, String
          end

          # Re-insert
          db[:secret].multi_insert(old_entries)
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
