ARG JELLYFIN_VERSION="10.8.8"
ARG DOTNET_VERSION="6"

FROM registry.home.estelsmith.com/alpine:3.17 AS builder
ARG JELLYFIN_VERSION
ARG DOTNET_VERSION
ENV JELLYFIN_VERSION=${JELLYFIN_VERSION}
ENV DOTNET_VERSION=${DOTNET_VERSION}

RUN apk --no-cache add git dotnet${DOTNET_VERSION}-sdk
RUN git clone --branch "v${JELLYFIN_VERSION}" --single-branch --depth 1 https://github.com/jellyfin/jellyfin.git build

WORKDIR /build
RUN git submodule update --init
RUN dotnet publish Jellyfin.Server \
    --disable-parallel \
    --configuration Release \
    --output="/output" \
    --self-contained \
    --runtime linux-musl-x64 \
    -p:DebugSymbols=false -p:DebugType=none -p:UseAppHost=true

# ---

FROM registry.home.estelsmith.com/alpine:3.17 AS builder-web
ARG JELLYFIN_VERSION
ENV JELLYFIN_VERSION=${JELLYFIN_VERSION}

RUN apk --no-cache add git nodejs npm
RUN git clone --branch "v${JELLYFIN_VERSION}" --single-branch --depth 1 https://github.com/jellyfin/jellyfin-web.git build

WORKDIR /build
RUN npm ci --no-audit --unsafe-perm
RUN mv dist /output

# ---

FROM registry.home.estelsmith.com/alpine:3.17

RUN apk --no-cache add ffmpeg

COPY --from=builder /output /app
COPY --from=builder-web /output /app/web
