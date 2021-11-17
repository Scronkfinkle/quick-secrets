# Quick Secrets - Simple Self-Hosted Secret Sharing

## What is Quick Secrets?

Quick secrets is a small, portable, Ruby web app that allows users to create and share temporary secrets via web links.

## Who can view secrets?

Anyone with a secret link and the corresponding secret passphrase can view the stored secret.   Once viewed, the encrypted secret is deleted and cannot be recovered.

## Who can create secrets?

An account is required to create secrets.  This enables organizations to host this web app on a public facing web server, and distribute secrets to anyone, but prevents outside users from taking advantage of the application for malicious purposes.

## How are secrets stored securely?

Once a secret is entered and submitted, the secret is encrypted using AES-256 and can be configured to be stored **only** in memory or written to the database disk.  Neither the secret passphrase used to encrypt the secret, nor the original plaintext secret are kept.  Without the secret passphrase, a secret cannot be recovered, even by the owner of the system hosting the application.

# Installation

## Run via Docker

For ease of use, it is recommended that you run quick secrets as a docker container. You can run quick secrets instantly with the following command:
```
docker run -p 8080:8080 --rm -it scronkfinkle/quick-secrets
```
This will start the application, exposed on port `8080` of whatever machine you run it on.

Alternatively you can run it with `docker-compose`
```
version: "3.1"
services:
  quick-secrets:
    image: scronkfinkle/quick-secrets
    ports:
      - 8080:8080
    environment:
      - QUICK_SECRETS_URL=http://mysite.com
      - QUICK_SECRETS_LISTEN_ADDRESS=0.0.0.0
      - QUICK_SECRETS_LISTEN_PORT=8080
      - QUICK_SECRETS_SESSION_EXPIRATION=500
      - QUICK_SECRETS_DATABASE=sqlite:///etc/quick_secrets/qsecrets.db
      - QUICK_SECRETS_ADMIN_PASSWORD=65c21921ca10a8502757efc9aa552874d181c6206feb2845a921eb57f5e518d4
      - QUICK_SECRETS_CONFIG=/etc/quick_secrets/config.yml
      - QUICK_SECRETS_SECRET_UUID_LENGTH=8
```

## Debian-based systems

Build and install the gem (on a Debian flavored system) with the following commands:
```
apt install ruby2.5 ruby2.5-dev sqlite3 libsqlite3-dev build-essential patch zlib1g-dev liblzma-dev -y
gem build quick-secrets.gemspec
gem install quick-secrets-*gem
```

## Local Development

```
gem install bundler
bundle config set path 'vendor'
bundle install
```

... which is mostly one-time, excluding dependency updates, then:

```
bundle exec quick-secrets [--args]
```


# Usage

## Configuration File

The default configuration file loads from `/etc/quick_secrets/config.yml`, which will be seeded automatically with a template if it does not already exist.  You can specify an alternative configuration file location by either command-line argument or environment variable:

```bash
quick-secrets --config=FILENAME
# or
QUICK_SECRETS_CONFIG=FILENAME quick-secrets
```

## Default `admin` Account

On **every** launch, a default `admin` account will be created, **only if** it does not already exist.  The password for the account will copied from the `config.yml` file `admin_password` variable, which defaults to `password1!`.

To prevent creation of a default `admin` account, comment out the `admin_password` entry in the `config.yml` or set the environment variable `QUICK_SECRETS_ADMIN_PASSWORD` to an empty string, as in:

```
QUICK_SECRETS_ADMIN_PASSWORD="" quick-secrets
```

We suggest using the default `admin` account to setup alternative admin accounts, and then deleting the default `admin` account.  Once deleted, commenting out the `admin_password` config variable will prevent re-creation of the default `admin` account when the application restarts.

If all other access to admin capable accounts is lost, uncommenting the `admin_password` variable in the config file and restarting the application will recreate and/or reset the `admin` account password for further recovery.

# Configuration
Quick secrets can be configured via configuration file or by environment variables. On first launch, quick secrets will attempt to create a config file in `/etc/quick_secrets/config.yml` unless specified elsewhere. All configuration can be handled in that file, or by using the following environment variables:
|Variable| Description | Default |
|--|--|--|
| `QUICK_SECRETS_URL` | The URL of your site, this is used for generating to copy and paste | http://mysite.com |
| `QUICK_SECRETS_LISTEN_ADDRESS` | The address to bind to | 0.0.0.0 |
| `QUICK_SECRETS_LISTEN_PORT` | The port to bind to | 8080 |
| `QUICK_SECRETS_SESSION_EXPIRATION` | The amount of time in seconds an idle session should last before timing out | 500 |
| `QUICK_SECRETS_DATABASE` | the database to connect to. See `config.yml` for additional information | sqlite:///etc/quick_secrets/qsecrets.db |
| `QUICK_SECRETS_ADMIN_PASSWORD` | The default admin password, stored as a SHA256 hash | 65c21921ca10a8502757efc9aa552874d181c6206feb2845a921eb57f5e518d4  (this is `password1!`) |
| `QUICK_SECRETS_CONFIG` | The location of the `config.yml` | /etc/quick_secrets/config.yml |
| `QUICK_SECRETS_SECRET_UUID_LENGTH` | The length of the UUID used to create a link to a secret | 8 |
| `QUICK_SECRETS_STORE_SECRETS` | The length of the UUID used to create a link to a secret | False |

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
