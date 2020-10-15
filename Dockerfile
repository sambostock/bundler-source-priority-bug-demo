FROM ruby:latest

WORKDIR /usr/src/app

ENV RED '\033[0;31m'
ENV GREEN '\033[0;32m'
ENV YELLOW '\033[0;33m'
# No-Color
ENV NC '\033[0m'

RUN mkdir registry && \
    { \
      echo 'Gem::Specification.new do |spec|'; \
      echo '  spec.name    = "example"'; \
      echo '  spec.version = "0.1.0"'; \
      echo 'end'; \
    } > example.gemspec && \
    gem build --force && \
    gem install --install-dir registry --local ./example-0.1.0.gem & \
    { \
      echo 'source "https://rubygems.org"'; \
      echo 'gem "example", source: "http://localhost:8808"'; \
    } > Gemfile && \
    gem server --daemon --dir registry && \
    bundle install && \
    gem install --remote example

CMD gem server --daemon --dir registry && \
    cp Gemfile.lock Gemfile.lock.orig && \
    echo "${YELLOW}Updating example...${NC}" && \
    bundle update example && \
    echo "${YELLOW}Diffing lockfile...${NC}" && \
    (( diff Gemfile.lock Gemfile.lock.orig && echo "#{GREEN}No difference; source respected!${NC}" ) || \
      echo "${RED}Difference; source not respected!${NC}" && cat Gemfile.lock ) && \
    gem info example && \
    diff -q Gemfile.lock Gemfile.lock.orig
