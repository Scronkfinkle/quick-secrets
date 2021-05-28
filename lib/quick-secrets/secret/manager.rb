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
        @secrets.keys
      end

      def exists?(uuid)
        @secrets.key? uuid
      end

      # get the length for secret UUID's used in URL's
      def uuid_len
        QuickSecrets::Core.core.config["secret_uuid_length"]&.to_i || AUTH_UUID_LEN_DEFAULT
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
      def store(secret, passphrase)
        cipher = OpenSSL::Cipher.new(crypt_method)
        cipher.encrypt
        iv = cipher.random_iv
        cipher.iv = iv
        cipher.key = Digest::SHA256.digest passphrase
        encrypted = cipher.update(secret)+cipher.final
        #key = Digest::SHA256.hexdigest encrypted
        secret_uuid = gen_uuid()
        @secrets[secret_uuid] = {iv: iv, enc: encrypted}
        return secret_uuid
      end

      # Destroys a secret
      def destroy(uuid)
        @secrets.delete(uuid)
      end


      def retrieve(uuid, passphrase)
        if (data = @secrets[uuid]).nil?
          return nil
        else
          cipher = OpenSSL::Cipher.new(crypt_method)
          cipher.decrypt
          cipher.iv = data[:iv]
          cipher.key = Digest::SHA256.digest passphrase
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
