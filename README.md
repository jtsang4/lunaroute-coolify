# lunaroute-coolify

Coolify deployment wrapper for [erans/lunaroute](https://github.com/erans/lunaroute).

This repository builds a small Debian image that downloads the official LunaRoute release binary at build time. It keeps deployment config separate from the upstream LunaRoute source tree.

## Coolify Setup

1. Create a new resource from this Git repository.
2. Select the `Docker Compose` build pack.
3. Set `Base Directory` to `/`.
4. Set `Docker Compose Location` to `/docker-compose.yml`.
5. Assign two domains to the `lunaroute` service:
   - API: `https://lunaroute-api.example.com:8081`
   - UI: `https://lunaroute-ui.example.com:8082`
6. Add runtime environment variables when needed:

```env
LUNAROUTE_VERSION=0.2.1
LUNAROUTE_LOG_LEVEL=info
```

API keys can stay in the local clients and pass through request headers. If you prefer server-side keys, add `OPENAI_API_KEY` and/or `ANTHROPIC_API_KEY` as runtime-only secrets in Coolify.

## Client Configuration

```bash
export ANTHROPIC_BASE_URL=https://lunaroute-api.example.com
export OPENAI_BASE_URL=https://lunaroute-api.example.com/v1
```

## Upgrade LunaRoute

Check the upstream releases, then update `LUNAROUTE_VERSION` in Coolify or in `docker-compose.yml`.

```env
LUNAROUTE_VERSION=0.2.1
```

Deploy again in Coolify after changing the version.

## Local Smoke Test

```bash
docker compose up --build
curl http://127.0.0.1:8081/healthz
open http://127.0.0.1:8082
```

Session records are stored in the `lunaroute-data` Docker volume at `/data/lunaroute`.
