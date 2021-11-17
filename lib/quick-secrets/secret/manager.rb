require 'quick-secrets'
require 'securerandom'
require 'digest'

# Manager to hold all encrypted secrets in memory...
module QuickSecrets
  module Secret
    class Manager
      
      AUTH_UUID_LEN_DEFAULT = 8

      def initialize
        @secrets = {}
      end

      def crypt_method
        'AES-256-CBC'
      end
      
      def keys
        if store_secrets?
          qs_db[:secret].select(:uuid).all.map{|e| e[:uuid]}
        else
          @secrets.keys
        end
      end

      def size
        if store_secrets?
          qs_db[:secret].count
        else
          keys.size
        end
      end

      def qs_db
        QuickSecrets::Core.core.db
      end

      def exists?(uuid)
        if store_secrets?
          return true unless qs_db[:secret].where(uuid: uuid).first.nil?
        else
          @secrets.key? uuid
        end
      end

      def qs_config
        QuickSecrets::Core.core.config
      end

      def store_secrets?
        qs_config['store_secrets']
      end

      # get the length for secret UUID's used in URL's
      def uuid_len
        qs_config["secret_uuid_length"]&.to_i || AUTH_UUID_LEN_DEFAULT
      end

      # Generate a UUID for the secret's URL
      def gen_uuid
        new_uuid = nil
        loop do
          new_uuid = SecureRandom.alphanumeric(uuid_len)
          break unless exists?(new_uuid)
        end
        new_uuid
      end
      
      # Stores a secret
      def store(secret, password)
        cipher = OpenSSL::Cipher.new(crypt_method)
        cipher.encrypt
        iv = cipher.random_iv
        cipher.iv = iv
        cipher.key = Digest::SHA256.digest password
        encrypted = cipher.update(secret)+cipher.final
        #key = Digest::SHA256.hexdigest encrypted
        secret_uuid = gen_uuid()
        if store_secrets?
          qs_db[:secret].insert(uuid: secret_uuid, initialization_vector: iv, encrypted_data: encrypted, expiration_date: nil)
        else
          @secrets[secret_uuid] = {initialization_vector: iv, encrypted_data: encrypted}
        end
        return secret_uuid
      end

      # Destroys a secret
      def destroy(uuid)
        if store_secrets?
          qs_db[:secret].where(uuid: uuid).delete
        else
          @secrets.delete(uuid)
        end
      end
      
      
      def retrieve(uuid, password)
        return nil unless exists?(uuid)
        data = if store_secrets?
                 qs_db[:secret].where(uuid: uuid).first
               else
                 @secrets[uuid]
               end
        cipher = OpenSSL::Cipher.new(crypt_method)
        cipher.decrypt
        cipher.iv = data[:initialization_vector]
        cipher.key = Digest::SHA256.digest password
        begin
          return cipher.update(data[:encrypted_data])+cipher.final
        rescue
          nil
        end
      end
        
    end
  end
end

