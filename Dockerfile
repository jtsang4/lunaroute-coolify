FROM debian:bookworm-slim

ARG LUNAROUTE_VERSION=0.2.1
ARG TARGETARCH

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl \
    && rm -rf /var/lib/apt/lists/* \
    && case "$TARGETARCH" in \
        amd64) ARCH=amd64 ;; \
        arm64) ARCH=arm64 ;; \
        *) echo "Unsupported arch: $TARGETARCH" && exit 1 ;; \
    esac \
    && curl -fsSL -o /usr/local/bin/lunaroute-server \
        "https://github.com/erans/lunaroute/releases/download/v${LUNAROUTE_VERSION}/lunaroute-server-linux-${ARCH}-${LUNAROUTE_VERSION}" \
    && chmod +x /usr/local/bin/lunaroute-server

RUN useradd -r -u 10001 lunaroute \
    && mkdir -p /data/lunaroute/sessions \
    && chown -R lunaroute:lunaroute /data/lunaroute

ENV LUNAROUTE_HOST=0.0.0.0 \
    LUNAROUTE_PORT=8081 \
    LUNAROUTE_UI_ENABLED=true \
    LUNAROUTE_UI_HOST=0.0.0.0 \
    LUNAROUTE_UI_PORT=8082 \
    LUNAROUTE_DIALECT=both \
    LUNAROUTE_ENABLE_SESSION_RECORDING=true \
    LUNAROUTE_SESSIONS_DIR=/data/lunaroute/sessions \
    LUNAROUTE_SESSIONS_DB_PATH=/data/lunaroute/sessions.db \
    LUNAROUTE_LOG_LEVEL=info

EXPOSE 8081 8082
USER lunaroute

HEALTHCHECK --interval=30s --timeout=5s --retries=5 \
    CMD curl -fsS http://127.0.0.1:8081/healthz || exit 1

CMD ["lunaroute-server", "serve"]
