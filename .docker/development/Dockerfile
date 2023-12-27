FROM ruby:3.3.0 AS edi_gateway

LABEL author="IdeaCrew"

ENV WORKDIR /edi_gateway

RUN mkdir -p $WORKDIR

WORKDIR $WORKDIR

RUN curl -sL https://deb.nodesource.com/setup_12.x | bash -

# Configure bundler and PATH
ENV LANG=C.UTF-8 \
    GEM_HOME=/bundle \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3
ENV BUNDLE_PATH $GEM_HOME
ENV BUNDLE_APP_CONFIG=$BUNDLE_PATH \
    BUNDLE_BIN=$BUNDLE_PATH/bin
ENV PATH /edi_gateway/bin:$BUNDLE_BIN:$PATH

RUN apt-get update && \
    apt-get -yq dist-upgrade && \
    apt-get install -y tzdata build-essential nodejs libsodium-dev libsodium23 && \
    apt-get autoremove -y && \
    npm install --global yarn

ARG GEM_OAUTH_TOKEN
ENV BUNDLE_GITHUB__COM=x-access-token:"$GEM_OAUTH_TOKEN"

ARG BUNDLER_VERSION_OVERRIDE
RUN echo $BUNDLER_VERSION_OVERRIDE

COPY .docker/development/database.yml $WORKDIR/config/database.yml
COPY Gemfile.lock $WORKDIR/Gemfile.lock
COPY Gemfile $WORKDIR/Gemfile

# Setting env up
ENV RAILS_ENV='development'
ENV NODE_ENV='development'

RUN gem install bundler:$BUNDLER_VERSION_OVERRIDE && bundle install