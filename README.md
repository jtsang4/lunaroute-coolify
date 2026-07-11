# lunaroute-coolify

Coolify deployment wrapper for [jtsang4/lunaroute](https://github.com/jtsang4/lunaroute), a fork of [erans/lunaroute](https://github.com/erans/lunaroute).

This repository builds LunaRoute from the selected source ref and keeps deployment config separate from the application source tree. The default ref is the fork's `main` branch, so upstream changes enter production only after the fork is synced and Coolify is manually redeployed.

## Coolify Setup

1. Create a new resource from this Git repository.
2. Select the `Docker Compose` build pack.
3. Set `Base Directory` to `/`.
4. Set `Docker Compose Location` to `/docker-compose.yml`.
5. Assign two domains to the `lunaroute` service:
   - API: `https://lunaroute-api.example.com:8081`
   - UI: `https://lunaroute-ui.example.com:8082`
6. Add runtime environment variables:

```env
LUNAROUTE_REF=main
CARGO_BUILD_JOBS=1
LUNAROUTE_LOG_LEVEL=info
```

API keys can stay in the local clients and pass through request headers. If you prefer server-side keys, add `OPENAI_API_KEY` and/or `ANTHROPIC_API_KEY` as runtime-only secrets in Coolify.

## Protect the UI

The LunaRoute UI exposes session metadata and can expose raw request/response data when JSONL session files are present. Protect the UI domain at the proxy layer.

For Traefik Basic Auth in Coolify, edit the generated container labels and attach a Basic Auth middleware only to the UI HTTPS router. Keep the API router unauthenticated for model clients.

## Client Configuration

```bash
export ANTHROPIC_BASE_URL=https://lunaroute-api.example.com
export OPENAI_BASE_URL=https://lunaroute-api.example.com/v1
```

## Upgrade LunaRoute

1. Open [jtsang4/lunaroute](https://github.com/jtsang4/lunaroute).
2. Select `Sync fork`, then `Update branch`.
3. In Coolify, run a force deployment without the Docker build cache.
4. Confirm the source commit in the build log and verify `/healthz` before updating the next instance.

Keep `LUNAROUTE_REF=main` for normal manual upgrades. To deploy or roll back to an exact revision, set it to the full commit SHA and force deploy again.

The resolved commit is stored at `/usr/local/share/lunaroute-revision` in the runtime image.

## Local Smoke Test

```bash
docker compose -f docker-compose.yml -f docker-compose.local.yml up --build
curl http://127.0.0.1:8081/healthz
open http://127.0.0.1:8082
```

The base `docker-compose.yml` uses `expose` for Coolify. The local override maps ports to your host for testing.

Session records are stored in the `lunaroute-data` Docker volume at `/data/lunaroute`.
