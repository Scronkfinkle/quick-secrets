require 'quick-secrets'
require 'digest'
require 'securerandom'

module QuickSecrets

  class Auth
    def initialize
      @session_map = {}
      @expiration_map = {}
    end
    
    # Get the database
    def db
      QuickSecrets::Core.core.db
    end

    def config
      QuickSecrets::Core.core.config
    end

    # Hash that contains all active sessions for users on the app
    def session_map
      @session_map
    end
    
    # Hash that contains session timeout info
    # TODO probably can more cleanly combine this with sessions...
    def expiration_map
      @expiration_map
    end

    # Determines if a user session is expired
    # If a session is expired, automatically destroy the session
    # TODO I know in ruby you're supposed to make mutable methods end with ! 
    # but I already have the ? and probably need to refactor this method...
    def expired?(session)
      session_id = session["session_id"]
      date = expiration_map[session_id]
      if date.nil? || Time.now > date
        destroy(session)
        return true
      else
        return false
      end
    end

    # Refreshes the timeout for a user. This is called when a user interacts with the website
    def refresh_expiration(session)
      session_id = session["session_id"]
      expiration_time = config["session_expiration"].to_i
      if expiration_time.nil?
        puts "WARNING: Session expiration not set. Defaulting to 5 minutes.."
        expiration_time = 300
      end
      expiration_map[session_id] = Time.now + expiration_time
    end

    # Authenticates a login
    def authenticate(session, username, password)
      session_id = session["session_id"]
      hash_pass = Digest::SHA256.hexdigest password
      account = lookup_user_by_name(username)
      if account.nil? || account[:password] != hash_pass
        return false
      else
        session_map[session_id] = account[:id]
        refresh_expiration(session)
        return true
      end
    end
    
    # Authorizes an action.
    def authorize(session, min_perm)
      return get_perm(session) >= min_perm
    end

    # Returns an API token for a user. 
    # If one does not exist, create it
    def get_token(session)
      account = resolve_account(session)
      return nil if account.empty?
      token = db[:token].where(account_id: account[:id]).first
      if token.nil?
        new_token = Digest::SHA256.hexdigest SecureRandom.random_bytes
        db[:token].insert(token: new_token, account_id: account[:id])
      end
      db[:token].where(account_id: account[:id]).first[:token]
    end

    # Deprecated function name. Needs to be refactored out of code base
    def resolve_account(session)
      resolve_session(session)
    end

    # Resolves a user from a session
    def resolve_session(session)
      session_id = session["session_id"]
      if (acc_id = session_map[session_id]).nil?
        {}
      else
        lookup_user_by_id(acc_id)
      end
    end
    
    # Attempts to change a user password.
    # Returns true/false based on success
    def change_password(account_id, new_password)
      begin
        hash_pass = Digest::SHA256.hexdigest new_password
        db[:account].where(id: account_id).update(password: hash_pass)
        return true
      rescue
        return false
      end
    end

    # Attempts to find a user by username
    # Returns either a hash of user details or nil
    def lookup_user_by_name(username)
      db[:account].where(username: username,expired: false).first
    end

    # Attempts to find a user by username
    # Returns either a hash of user details or nil
    def lookup_user_by_id(id)
      db[:account].where(id: id,expired: false).first
    end

    # Attempts to delete a user by username
    # Returns true/false based on success
    def delete_user_by_name(username)
      user = lookup_user_by_name(username)
      return false if user.nil?

      db[:account].where(id: user[:id]).update(expired: true, password: "")
      return true
    end

    # Attempts to delete a user by id
    # Returns true/false based on success
    def delete_user_by_id(id)
      user = lookup_user_by_id(id)
      return false if user.nil?
      active_sessions = session_map.select {|_k,v| v == user[:id]}
      active_sessions.each do |k,_v|
        session_map.delete(k)
      end
      db[:account].where(id: user[:id]).update(expired: true, password: "")
      return true
    end

    # Creates a new user
    def create_user(username,password,privilege)
      user = lookup_user_by_name(username)
      if user.nil?
        hash_pass = Digest::SHA256.hexdigest password
        db[:account].insert(username: username, password: hash_pass, privilege: privilege, expired: false)
        return lookup_user_by_name(username)
      end
      return nil
    end
    
    # destroys a user session,
    # effectively expiring it so the cookie is no longer valid
    def destroy(session)
      session_id = session["session_id"]
      session_map.delete(session_id)
      expiration_map.delete(session_id)
    end

    # Returns the permission for the user
    # -1 if not valid
    # TODO Stop mixing the terms privilege and permission
    def get_perm(session)
      
      # First handle token auth
      token = session["token"]
      unless token.nil?
        token_entry = db[:token].where(token: token).first
        return -1 if token_entry.nil?
        account = lookup_user_by_id(token_entry[:account_id])
        return -1 if account.nil?
        refresh_expiration(session)
        return account[:privilege]
      end

      # Make sure session is not expired
      return -1 if expired?(session)
      
      # If no access token is present, use the session to resolve an account
      account = resolve_account(session)
      return -1 if account.empty?
      refresh_expiration(session)
      return account[:privilege]
    end


  end

end
