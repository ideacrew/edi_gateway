#!/bin/bash

bundle exec rake db:drop
bundle exec rake db:create

bundle exec rake sequent:db:create_event_store
bundle exec rake sequent:db:create_view_schema

# only run this when you add or change projectors in SequentMigrations
bundle exec rake sequent:migrate:online
bundle exec rake sequent:migrate:offline
