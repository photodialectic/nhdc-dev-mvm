Docker image to be used in micro vms

The image is built and pushed automatically by the workflow in `.github/workflows/docker-image.yml` on every push to `main`.

To pull it:

```bash
docker pull ghcr.io/photodialectic/nhdc-dev-mvm:latest
```

To build and push manually:

```bash
echo $CR_PAT | docker login ghcr.io -u photodialectic --password-stdin
docker build -t ghcr.io/photodialectic/nhdc-dev-mvm:latest --platform linux/amd64 .
docker push ghcr.io/photodialectic/nhdc-dev-mvm:latest
```
