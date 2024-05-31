# Create a Jekyll container from a Ruby Alpine image

# At a minimum, use Ruby 2.5 or later
# FROM ruby:2.7-alpine3.15
FROM ruby:3.3-alpine3.20

# Add Jekyll dependencies to Alpine
RUN apk update
RUN apk add --no-cache build-base gcc cmake git

# Update the Ruby bundler and install Jekyll
RUN gem update bundler && gem install bundler jekyll
# RUN gem install bundler -v 2.4.22 && gem install bundler jekyll