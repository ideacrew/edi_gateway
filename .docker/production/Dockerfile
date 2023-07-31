########################
###    app config    ###
########################

FROM ruby:2.7.8 AS app

LABEL author="IdeaCrew"

RUN curl -sL https://deb.nodesource.com/setup_12.x | bash -

# Configure bundler and PATH
ENV LANG=C.UTF-8 \
    GEM_HOME=/bundle \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3
ENV BUNDLE_PATH $GEM_HOME
ENV BUNDLE_APP_CONFIG=$BUNDLE_PATH \
    BUNDLE_BIN=$BUNDLE_PATH/bin

RUN apt-get update && \
    apt-get -yq dist-upgrade && \
    apt-get install -y imagemagick tzdata build-essential nodejs vim && \
    apt-get autoremove -y && \
    gem install bundler && \
    npm install --global yarn

ENV HOME /edi_gateway

RUN mkdir -p $HOME

WORKDIR $HOME
COPY . $HOME

COPY package.json package.json
COPY yarn.lock yarn.lock
RUN yarn install

# Setting env up
ARG SECRET_KEY_BASE
ARG EDI_GATEWAY_DB_HOST
ARG EDI_GATEWAY_DB_PORT
ARG EDI_GATEWAY_DB_NAME
ARG RABBITMQ_URL
ARG RABBITMQ_URL_EVENT_SOURCE
ARG RABBITMQ_HOST
ARG RABBITMQ_PORT
ARG RABBITMQ_VHOST
ENV RAILS_ENV='production'
ENV NODE_ENV='production'
ENV MEDICAID_GATEWAY_DB_HOST=$EDI_GATEWAY_DB_HOST
ENV MEDICAID_GATEWAY_DB_PORT=$EDI_GATEWAY_DB_PORT
ENV MEDICAID_GATEWAY_DB_NAME=$EDI_GATEWAY_DB_NAME
ENV RABBITMQ_URL=$RABBITMQ_URL
ENV RABBITMQ_URL_EVENT_SOURCE=$RABBITMQ_URL_EVENT_SOURCE
ENV RABBITMQ_HOST=$RABBITMQ_HOST
ENV RABBITMQ_PORT=$RABBITMQ_PORT
ENV RABBITMQ_VHOST=$RABBITMQ_VHOST
ENV SECRET_KEY_BASE=$SECRET_KEY_BASE

#RUN rm -f /edi_gateway/config/master.key && rm -f /edi_gateway/config/credentials.yml.enc

# Adding gems
COPY Gemfile Gemfile
COPY Gemfile.lock Gemfile.lock

RUN bundle install --jobs 20 --retry 5 --without development test
RUN bundle exec rake assets:precompile


########################
### web/nginx config ###
########################

FROM nginx:1.17.6-alpine as web

RUN mkdir /edi_gateway

# copy assets from the app build and nginx config
COPY --from=app /edi_gateway/public /edi_gateway/
COPY .docker/production/nginx.conf /etc/nginx/conf.d/edi_gateway.conf
RUN mv /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf-bkp
