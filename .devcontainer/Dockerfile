# Development image: Ruby (matches backend/.ruby-version) + Node (matches frontend/.nvmrc)
# with everything needed to build the pg gem and run Rails, Sidekiq and Vite.
ARG RUBY_VERSION=3.3.10
ARG NODE_VERSION=24

FROM node:${NODE_VERSION}-slim AS node

FROM ruby:${RUBY_VERSION}-slim

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential ca-certificates curl git less libpq-dev libvips libyaml-dev \
      pkg-config postgresql-client sudo && \
    rm -rf /var/lib/apt/lists/*

COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -s ../lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm && \
    ln -s ../lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx

# Non-root user (UID 1000 matches the default WSL / Linux user, so bind-mounted files keep your ownership).
ARG USERNAME=dev
ARG USER_UID=1000
RUN groupadd --gid ${USER_UID} ${USERNAME} && \
    useradd --uid ${USER_UID} --gid ${USER_UID} --create-home --shell /bin/bash ${USERNAME} && \
    echo "${USERNAME} ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} && \
    chown -R ${USERNAME}:${USERNAME} /usr/local/bundle

USER ${USERNAME}
WORKDIR /workspace
