FROM alpine:latest

LABEL org.opencontainers.image.source="https://github.com/anujdatar/dynv6-ddns-docker"
LABEL org.opencontainers.image.description="DynV6 DDNS Updater"
LABEL org.opencontainers.image.author="Anuj Datar <anuj.datar@gmail.com>"
LABEL org.opencontainers.image.url="https://github.com/anujdatar/dynv6-ddns-docker/blob/main/README.md"
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.version=23.05

# default env variables
ENV FREQUENCY 5
ENV RECORD_TYPE AAAA

# install dependencies
RUN apk update && apk add --no-cache curl jq bind-tools

# copy scripts over
COPY scripts /
RUN chmod 700 /ddns-update.sh /entry.sh

CMD ["/entry.sh"]
