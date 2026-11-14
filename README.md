Docker image to be used in micro vms

The image is built and pushed automatically by the workflow in `.github/workflows/docker-image.yml` on every push to `main`.

To pull it:

```bash
docker pull ghcr.io/photodialectic/dev-wksp:latest
```

To build and push manually:

```bash
echo $CR_PAT | docker login ghcr.io -u photodialectic --password-stdin
docker build -t ghcr.io/photodialectic/dev-wksp:latest --platform linux/amd64 .
docker push ghcr.io/photodialectic/dev-wksp:latest
```

## Upgrading Node.js

The Node version is set via the `NODE_VERSION` build arg in the `Dockerfile`. When you bump it, you must also update the `NODE_SHA` checksums (one per architecture) to match the new release.

Find the checksums from the official `SHASUMS256.txt` for that version:

```bash
curl -fsSL "https://nodejs.org/dist/v<NODE_VERSION>/SHASUMS256.txt" | grep -E "linux-(x64|arm64)\.tar\.xz$"
```

For example, for v26.13.1:

```bash
curl -fsSL "https://nodejs.org/dist/v26.13.1/SHASUMS256.txt" | grep -E "linux-(x64|arm64)\.tar\.xz$"
```

This prints two lines — `x64` (maps to `amd64` in the Dockerfile) and `arm64`. Copy each SHA into the corresponding `NODE_SHA` entry in the `case` block.

To confirm a version exists before using it:

```bash
curl -fsSL "https://nodejs.org/dist/index.json" | grep '"version":"v<NODE_VERSION>"'
```

## Upgrading Go

The Go version is set via the `GO_VERSION` build arg in the `Dockerfile`. When you bump it, you must also update the `GO_SHA` checksums (one per architecture) to match the new release.

Find the checksums from Go's official download JSON:

```bash
curl -fsSL "https://go.dev/dl/?mode=json&include=all" | python3 -c "
import json, sys
for v in json.load(sys.stdin):
    if v['version'] == 'go<GO_VERSION>':
        for f in v['files']:
            if f['os'] == 'linux' and f['arch'] in ('amd64', 'arm64'):
                print(f['filename'], f['sha256'])
"
```

For example, for go1.22.4:

```bash
curl -fsSL "https://go.dev/dl/?mode=json&include=all" | python3 -c "
import json, sys
for v in json.load(sys.stdin):
    if v['version'] == 'go1.22.4':
        for f in v['files']:
            if f['os'] == 'linux' and f['arch'] in ('amd64', 'arm64'):
                print(f['filename'], f['sha256'])
"
```

This prints two lines — `amd64` and `arm64`. Copy each SHA into the corresponding `GO_SHA` entry in the `case` block. Note that Go's `amd64`/`arm64` naming matches the Dockerfile's `GOARCH` values directly (unlike Node's `x64`).
