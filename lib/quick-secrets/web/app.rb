require 'sinatra/base'
require 'json'

#################################################################################
# To be honest, these routes are a really lazy an ineffective way to properly   #
# build a REST API, but it isn't less secure, so i'm keeping it until some more #
# serious interest is invested and a more robust solution is needed             #
#################################################################################

module QuickSecrets
  module Web
    class App < Sinatra::Base

      set :bind, QuickSecrets::Core.core.config["listen_address"]
      set :port, QuickSecrets::Core.core.config["listen_port"]
      enable :sessions

      # Authenticator
      def auth
        QuickSecrets::Core.core.authenticator
      end

      # Secrets Manager
      def secrets
        QuickSecrets::Core.core.secrets
      end

      # Wrapper method which checks permissions for an action.
      def auth_web(session, perm)
        session["token"] = request.env["HTTP_QSECRET_TOKEN"]
        if auth.authorize(session,perm)
          yield
        else
          redirect "/login"
        end
      end

      # Makes default page the "Create A New Secret Page"
      get '/' do
        auth_web(session, QuickSecrets::Privilege::USER) do
          redirect '/new_secret'
        end
      end

      # Render markdown for about page
      get '/about' do
        erb :about, :locals => { :markdown_text => markdown(:about) }
      end

      # Changes a user's password
      # Returns whether successful or not in retval[:status]
      # TODO move arbitrary password length to config
      post '/change_password' do
        auth_web(session, QuickSecrets::Privilege::USER) do
          params = JSON.parse request.body.read
          password = params["password"]
          retval = {status: false}
          if !password.nil? and password.size > 6
            account_id = auth.resolve_account(session)[:id]
            retval[:status] = auth.change_password(account_id,password)
          end
          retval.to_json
        end
      end

      get '/secret/list' do
        auth_web(session, QuickSecrets::Privilege::ADMIN) do
          secrets.keys.to_json
        end
      end

      # Renders a page to get a secret based on ID
      get '/secret/:id' do
        digest = params['id']
        if secrets.exists? digest
          erb :secret, :locals => {digest: digest}
        else
          erb :no_secret
        end
      end

      # Renders the "Create a New Secret" Page
      get '/new_secret' do
        auth_web(session, QuickSecrets::Privilege::USER) do
          erb :new_secret, :locals => {base_url: QuickSecrets::Core.core.config["url"]+"/secret/"}
        end
      end

      # Admin panel
      get '/admin' do
        auth_web(session, QuickSecrets::Privilege::ADMIN) do
          erb :admin
        end
      end


      # Account settings
      get '/account' do
        auth_web(session, QuickSecrets::Privilege::USER) do
          erb :account, :locals => {token: auth.get_token(session)}
        end
      end
      
      # Deletes an account
      post '/delete_account/:id' do
        auth_web(session, QuickSecrets::Privilege::ADMIN) do
          delete_id = params["id"].to_i
          admin = auth.resolve_session(session)
          retval = {status: false, reason: "Cannot delete own account"}
          if admin[:id] != delete_id
            retval[:status] = auth.delete_user_by_id(delete_id)
            if retval[:status]
              retval[:reason] = "Account deleted successfully"
            else
              retval[:reason] = "Account does not exist"
            end
          end
          retval.to_json
        end
      end

      # Creates a new account
      post '/new_account' do
        auth_web(session, QuickSecrets::Privilege::ADMIN) do
          params = JSON.parse request.body.read
          username = params["username"]
          password = params["password"]
          privilege = params["privilege"]
          lengths = [5,6,1]
          valid = true
          # TODO refactor
          # Schema checks like these need to be more standardized into the API...
          [username,password,privilege].each_with_index do |field, i|
            valid = false if field.nil?
            valid = false if field.size < lengths[i]
            valid = false unless field.is_a? String
          end
          privilege = privilege.to_i
          # Ensures that the created user is either a user, admin, or someone with mixed permissions in between
          # TODO Refactor, really clunky looking and confusing...
          valid = false if (privilege < QuickSecrets::Privilege::USER || privilege > QuickSecrets::Privilege::ADMIN)

          retval = {status: false, reason: "Invalid parameters"}
          if valid
            user = auth.lookup_user_by_name(username)
            if user.nil?
              auth.create_user(username,password,privilege)
              retval[:status] = true
              retval[:reason] = "User created successfully!"
            else
              retval[:reason] = "User '#{username}' already exists"
            end
          end
          retval.to_json
        end

      end

      # Destroys a session for a user and logs them out
      # TODO Consider switching to POST. GET may be triggered by browser pre-caching
      get '/logout' do
        auth.destroy(session)
        redirect '/login'
      end

      # Attempt to decrypt a secret
      # TODO Refactor, status retval is clunky
      post '/secret/:id' do
        digest = params["id"]
        password = JSON.parse(request.body.read)["password"]
        secret = secrets.retrieve(digest,password)
        if status = !secret.nil?
          secrets.destroy(digest)
        end
        {secret: secret, status: status}.to_json
      end

      # Destroy a secret without the password
      post '/burn/:id' do
        digest = params["id"]
        if status = secrets.exists?(digest)
          secrets.destroy(digest)
        end
        {status: status}.to_json
      end

      # Create a secret
      post '/secret' do
        auth_web(session, QuickSecrets::Privilege::USER) do
          params = JSON.parse request.body.read
          secret = params["secret"]
          password = params["password"]
          # TODO make password requirements configurable
          digest = if secret.length > 0 && password.length > 0
                     secrets.store(secret,password)
                   else
                     nil
                   end
          status = !digest.nil?
          {status: status, digest: digest}.to_json
        end
      end

      # Render login page
      get '/login' do
        erb :login
      end

      # Login...
      post '/login' do
        params = JSON.parse request.body.read
        if auth.authenticate(session,params["username"],params["password"])
          { url: "/new_secret" }.to_json
        else
          { url: "/login" }.to_json
        end
      end

      # catch all 404 for any undefined pages
      get "/*" do
        status 404
        body "404 Not Found"
      end

    end
  end
end
