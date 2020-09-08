FROM debian:stable-slim
LABEL maintainer "Jesse Roland <j.roland277@gmail.com>"

RUN apt update && apt install ruby2.5 ruby2.5-dev sqlite3 libsqlite3-dev build-essential patch zlib1g-dev liblzma-dev -y
RUN mkdir /etc/quick_secrets/

ADD . /build
WORKDIR /build

RUN gem build quick-secrets.gemspec
RUN gem install --no-document quick-secrets-*gem

CMD ["quick-secrets"]
