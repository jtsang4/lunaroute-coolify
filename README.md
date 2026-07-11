# lunaroute-coolify

Coolify deployment wrapper for [jtsang4/lunaroute](https://github.com/jtsang4/lunaroute), a fork of [erans/lunaroute](https://github.com/erans/lunaroute).

This repository builds LunaRoute from the selected source ref and keeps deployment config separate from the application source tree. The default ref is the fork's `main` branch, so upstream changes enter production only after the fork is synced and Coolify is manually redeployed.

## Coolify Setup

1. Create a new resource from this Git repository.
2. Select the `Dockerfile` build pack.
3. Set `Base Directory` to `/` and `Dockerfile Location` to `/Dockerfile`.
4. Set `Ports Exposes` to `8081,8082`.
5. Assign two domains to the application:
   - API: `https://lunaroute-api.example.com:8081`
   - UI: `https://lunaroute-ui.example.com:8082`
6. Add the following variables and make them available at build time:

```env
LUNAROUTE_REF=main
CARGO_BUILD_JOBS=1
LUNAROUTE_LOG_LEVEL=info
```

For a dedicated Coolify build server, configure a Docker registry image and tag, enable `Use a Build Server?`, and authenticate the build and deployment servers to that registry. Mount a persistent volume at `/data/lunaroute`.

### Multi-server deployments

Compile the source once and reuse that image for additional regions:

1. Choose one application as the source builder. Keep `/Dockerfile`, the build server, and a stable registry image such as `registry.example.com/lunaroute:latest` on that application.
2. Set each additional application to `/Dockerfile.runtime`.
3. Add `--build-arg LUNAROUTE_IMAGE=registry.example.com/lunaroute:latest` to its `Custom Docker Options`.
4. Give each additional application its own registry output image, domains, environment variables, and persistent volume.

This keeps the expensive Rust build in one deployment. Regional applications create a thin image from the builder's published image and retain independent runtime configuration.

API keys can stay in the local clients and pass through request headers. If you prefer server-side keys, add `OPENAI_API_KEY` and/or `ANTHROPIC_API_KEY` as runtime-only secrets in Coolify.

## Protect the UI

The LunaRoute UI exposes session metadata and can expose raw request/response data when JSONL session files are present. Protect the UI domain at the proxy layer.

For Traefik Basic Auth in Coolify, define a server-level Dynamic Configuration with a higher-priority UI router and Basic Auth middleware. Point that router at the application's UI Docker service and keep the API router unauthenticated for model clients.

## Client Configuration

```bash
export ANTHROPIC_BASE_URL=https://lunaroute-api.example.com
export OPENAI_BASE_URL=https://lunaroute-api.example.com/v1
```

## Upgrade LunaRoute

1. Open [jtsang4/lunaroute](https://github.com/jtsang4/lunaroute).
2. Select `Sync fork`, then `Update branch`.
3. In Coolify, force deploy the source-builder application without the Docker build cache. The dedicated build server compiles the image, pushes it to the configured registry, and the application server pulls it for deployment.
4. Confirm the source commit in the build log and verify `/healthz`.
5. Redeploy each regional runtime application so `/Dockerfile.runtime` resolves the builder's new `latest` image.

Keep `LUNAROUTE_REF=main` for normal manual upgrades. To deploy or roll back to an exact revision, set it to the full commit SHA and force deploy again.

The resolved commit is stored at `/usr/local/share/lunaroute-revision` in the runtime image.

## Local Smoke Test

```bash
docker compose -f docker-compose.yml -f docker-compose.local.yml up --build
curl http://127.0.0.1:8081/healthz
open http://127.0.0.1:8082
```

The base `docker-compose.yml` and local override are retained for local smoke testing. Coolify deployments use the repository Dockerfile directly.

Session records are stored in the `lunaroute-data` Docker volume at `/data/lunaroute`.
