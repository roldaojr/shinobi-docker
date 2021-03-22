FROM node:12-alpine

ENV SHINOBI_SHA="c4d5b7833982739693822861ea5d27957bc9d32b"
ENV SHINOBI_BRANCH="master"

# Set environment variables to default values
# ADMIN_USER : the super user login name
# ADMIN_PASSWORD : the super user login password
# PLUGINKEY_MOTION : motion plugin connection key
# PLUGINKEY_OPENCV : opencv plugin connection key
# PLUGINKEY_OPENALPR : openalpr plugin connection key
ENV DB_USER=majesticflame \
    DB_PASSWORD='' \
    DB_HOST='localhost' \
    DB_DATABASE=ccio \
    SUBSCRIPTION_ID=sub_XXXXXXXXXXXX \
    PLUGIN_KEYS='{}'
ARG DEBIAN_FRONTEND=noninteractive

RUN apk --update update && apk upgrade --no-cache

# runtime dependencies
RUN apk add --update --no-cache ffmpeg gnutls x264 libssh2 tar xz bzip2 mariadb-client ttf-freefont

# Install ffmpeg static build version from cdn.shinobi.video
RUN wget -q https://cdn.shinobi.video/installers/ffmpeg-release-64bit-static.tar.xz \
 && tar xpf ./ffmpeg-release-64bit-static.tar.xz -C ./ \
 && cp -f ./ffmpeg-3.3.4-64bit-static/ff* /usr/bin/ \
 && chmod +x /usr/bin/ff* \
 && rm -f ffmpeg-release-64bit-static.tar.xz \
 && rm -rf ./ffmpeg-3.3.4-64bit-static

RUN mkdir -p /config /tmp/shinobi

# Install build dependencies, fetch shinobi, and install
RUN apk add --virtual .build-dependencies --no-cache \ 
  build-base \ 
  coreutils \ 
  nasm \
  python \
  make \
  pkgconfig \
  wget \
  freetype-dev \ 
  gnutls-dev \ 
  lame-dev \ 
  libass-dev \ 
  libogg-dev \ 
  libtheora-dev \ 
  libvorbis-dev \ 
  libvpx-dev \ 
  libwebp-dev \ 
  opus-dev \ 
  rtmpdump-dev \ 
  x264-dev \ 
  x265-dev \ 
  yasm-dev \
 && wget -q "https://gitlab.com/Shinobi-Systems/Shinobi/-/archive/$SHINOBI_BRANCH/Shinobi-$SHINOBI_BRANCH.tar.bz2?sha=$SHINOBI_SHA" -O /tmp/shinobi.tar.bz2 \
 && tar -xjpf /tmp/shinobi.tar.bz2 -C /tmp/shinobi \
 && mv /tmp/shinobi/Shinobi-$SHINOBI_BRANCH /opt/shinobi \
 && rm -f /tmp/shinobi.tar.bz2 \
 && cd /opt/shinobi \
 && npm i npm@latest -g \
 && npm install pm2 -g \
 && npm install \
 && apk del .build-dependencies

# Copy code
COPY docker-entrypoint.sh pm2Shinobi.yml /opt/shinobi/
RUN chmod -f +x /opt/shinobi/docker-entrypoint.sh

EXPOSE 8080

WORKDIR /opt/shinobi

VOLUME ["/opt/shinobi/videos"]
VOLUME ["/opt/shinobi/plugins"]
VOLUME ["/config"]
VOLUME ["/customAutoLoad"]

ENTRYPOINT ["/opt/shinobi/docker-entrypoint.sh"]

CMD ["pm2-docker", "pm2Shinobi.yml"]
