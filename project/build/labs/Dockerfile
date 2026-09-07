FROM ruby:3.3-slim-bookworm

RUN apt-get update \
    && apt-get install -y --no-install-recommends fonts-dejavu graphviz \
    && rm -rf /var/lib/apt/lists/*

RUN gem install --no-document asciidoctor:2.0.23 asciidoctor-pdf:2.3.19 \
    asciidoctor-diagram:2.3.1 rouge:4.5.2

ENV LANG=C.UTF-8
WORKDIR /workspace
