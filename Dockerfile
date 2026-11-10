# syntax=docker/dockerfile:1

FROM rust:1.94-bookworm AS builder

ARG LUNAROUTE_REF=main
ARG CARGO_BUILD_JOBS=1

WORKDIR /src

ADD --keep-git-dir=true \
    https://github.com/jtsang4/lunaroute.git#${LUNAROUTE_REF} \
    /src

RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/usr/local/cargo/git \
    --mount=type=cache,target=/src/target \
    mkdir -p /out \
    && git rev-parse HEAD | tee /out/lunaroute-revision \
    && cargo build --release --package lunaroute-server --jobs "${CARGO_BUILD_JOBS}" \
    && cp target/release/lunaroute-server /out/lunaroute-server

FROM ubuntu:24.04

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /out/lunaroute-server /usr/local/bin/lunaroute-server
COPY --from=builder /out/lunaroute-revision /usr/local/share/lunaroute-revision

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
