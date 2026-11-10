# lunaroute-coolify

Publish [jtsang4/lunaroute](https://github.com/jtsang4/lunaroute) as a container image with GitHub Actions and deploy it with Coolify. Coolify pulls the image and manages runtime configuration, domains, and persistent storage.

## Release an image

1. Open **Actions → Release image → Run workflow**.
2. Enter a new version such as `v1.0.0` and a LunaRoute source branch, tag, or full commit SHA. The default source ref is `main`.
3. Run the workflow and wait for it to succeed.

The workflow resolves the source ref to an exact commit, builds a `linux/amd64` image, and checks API health, UI startup, source revision, and writable persistent storage before publishing:

- Versioned image: `ghcr.io/jtsang4/lunaroute-coolify:v1.0.0`
- Latest successful release: `ghcr.io/jtsang4/lunaroute-coolify:latest`
- GitHub Release: includes the immutable image digest and both source commits

Existing release tags are rejected. Choose a new version for each release. Syncing the LunaRoute fork does not publish an image automatically; run this workflow to release the selected source. The build uses the lockfile from that source commit. Its revision is also stored at `/usr/local/share/lunaroute-revision` in the image.

The workflow uses the repository's `GITHUB_TOKEN` with package and contents write permissions. It does not need production API keys, proxy credentials, or a personal GitHub token. After the first publication, set the GHCR package visibility to **Public**, or authenticate every Coolify deployment server to GHCR with a token that has `read:packages`.

## Coolify setup

1. Create a **Docker Image** application in the target project, environment, and server.
2. Set the image to `ghcr.io/jtsang4/lunaroute-coolify` and select a published version tag. For a fixed deployment, use the digest from its GitHub Release.
3. Set **Ports Exposes** to `8081,8082`.
4. Configure separate domains:
   - API: `https://lunaroute-api.example.com:8081`
   - UI: `https://lunaroute-ui.example.com:8082`
5. Mount a persistent volume at `/data/lunaroute`.
6. Add runtime-only environment variables, then deploy.

The image already sets the listeners, enables both API dialects and session recording, and stores SQLite and JSONL data under `/data/lunaroute`. Override these defaults with runtime variables as needed.

| Configuration | Location |
| --- | --- |
| LunaRoute source ref and release version | GitHub Actions workflow inputs |
| `CARGO_BUILD_JOBS` | GitHub Actions build argument |
| `LUNAROUTE_LOG_LEVEL`, `LUNAROUTE_ENABLE_JSONL_WRITER` | Coolify runtime variables |
| `HTTP_PROXY`, `HTTPS_PROXY`, `NO_PROXY` | Coolify runtime variables |
| `OPENAI_API_KEY`, `ANTHROPIC_API_KEY` when needed | Coolify runtime secrets |
| Domains, ports, volumes, and resource limits | Coolify application settings |

API keys can remain in local clients and pass through request headers. A Docker Image application does not need a Git source, Dockerfile location, build server, or build-time environment variables. See [Coolify's image deployment guide](https://coolify.io/docs/applications/deployments/docker-image).

### Migrate an existing application

Prepare the image application on the same server with the original runtime variables, ports, health checks, resource limits, and Docker network. Initially verify it with a temporary data volume and without the production domains.

Before switching, stop the old application and back up its persistent data. Attach the original volume by its full Docker volume name; creating a new volume with the same short label does not restore existing data. Mount it at `/data/lunaroute`. Transfer the production domains and any UI proxy authentication rules, updating application-specific service references, then deploy and verify the API and UI.

Keep the old application stopped and available for rollback until the new deployment is verified. Each server or region needs its own runtime configuration and persistent volume; all can pull the same release image.

## Protect the UI

The LunaRoute UI exposes session metadata and can expose raw request/response data when JSONL session files are present. Protect the UI domain at the proxy layer.

For Traefik Basic Auth in Coolify, define a server-level Dynamic Configuration with a higher-priority UI router and Basic Auth middleware. Point that router at the application's UI Docker service and keep the API router unauthenticated for model clients.

## Client configuration

```bash
export ANTHROPIC_BASE_URL=https://lunaroute-api.example.com
export OPENAI_BASE_URL=https://lunaroute-api.example.com/v1
```

## Upgrade or roll back

Run **Release image** with a new version to publish an upgrade. In Coolify, select the new version or digest, save, and redeploy. Coolify pulls the published image without compiling Rust. Verify `/healthz` and the protected UI after deployment.

To roll back, select a previous release image and redeploy. Database compatibility must be checked when rolling back across application schema changes. Image publication and production deployment are separate operations; releasing an image does not automatically redeploy Coolify.

## Local smoke test

Run the published image with local ports and persistent storage:

```bash
docker run --rm --name lunaroute \
  -p 127.0.0.1:8081:8081 -p 127.0.0.1:8082:8082 \
  -v lunaroute-data:/data/lunaroute \
  ghcr.io/jtsang4/lunaroute-coolify:latest
```

To build from source locally:

```bash
docker compose -f docker-compose.yml -f docker-compose.local.yml up --build
curl http://127.0.0.1:8081/healthz
```
