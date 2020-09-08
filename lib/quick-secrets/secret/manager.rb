require 'quick-secrets'
require 'digest'

# Manager to hold all encrypted secrets in memory...
module QuickSecrets
  module Secret
    class Manager
      

      def initialize
        @secrets = {}
      end

      def crypt_method
        'AES-256-CBC'
      end
      
      def keys
        @secrets.keys
      end

      def exists?(digest)
        @secrets.key? digest
      end
      
      # Stores a secret
      def store(secret, password)
        cipher = OpenSSL::Cipher.new(crypt_method)
        cipher.encrypt
        iv = cipher.random_iv
        cipher.iv = iv
        cipher.key = Digest::SHA256.digest password
        encrypted = cipher.update(secret)+cipher.final
        key = Digest::SHA256.hexdigest encrypted
        @secrets[key] = {iv: iv, enc: encrypted}
        return key
      end

      # Destroys it
      def destroy(digest)
        @secrets.delete(digest)
      end
      

      def retrieve(digest, password)
        if (data = @secrets[digest]).nil?
          return nil
        else
          cipher = OpenSSL::Cipher.new(crypt_method)
          cipher.decrypt
          cipher.iv = data[:iv]
          cipher.key = Digest::SHA256.digest password
          begin
            return cipher.update(data[:enc])+cipher.final
          rescue
            nil
          end
        end
      end
        
    end
  end
end

