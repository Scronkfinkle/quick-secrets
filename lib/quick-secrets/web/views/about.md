# FAQ

## What is Quick Secrets?
Quick secrets is a small, portable, web app which allows users to create and share temporary secrets, via generated links.  

Secrets are encrypted using AES-256 encryption and stored in memory. The password used to encrypt the secret and the original secret are not kept. Without the password, a secret cannot be recovered.

Once a secret is viewed, it is permanently deleted. 

## Who can create and view secrets?
Anybody can view a secret. However to create a secret, an account is required. This enables organizations to host this web app on a public facing web server and distribute secrets to anyone, but prevents outside users from taking advantage of the application.

# Scripting

## Getting a token
To query the server for password generation, an access token is required. This can be retrieved by navigating to the account page.  

## Querying the API
To use your token, append it to your HTTP header with the key **qsecret-token**, like so

```
curl -X GET -H "qsecret-token: my_access_token"
```

## Generating a secret using a token
To generate a secret, a JSON object needs to be sent to the **/secret** endpoint as a POST, with the following keys:  
**secret**  
**password**  

Example:  
```
curl -d '{"secret":"my secret phrase", "password":"my secret password"}' -H "qsecret-token: access_token" -X POST mysite.com/secret
```

If the authentication suceeds, a resulting JSON will come with a **status** and **digest** field. The digest field will return a SHA2 hash which can be used to resolve the secret URL. The URL can be resolved by appending the digest to the end of the URL with the secret endpoint.  

For example:  
```
mysite.com/secret/99dcb82a9f8e695c0baff2609d87411be7b23f3d9189ef24c6ef29a80ea512c3
```
