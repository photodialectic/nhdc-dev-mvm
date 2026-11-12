Docker image to be used in micro vms

echo $CR_PAT | docker login ghcr.io -u photodialectic  --password-stdin
docker build -t ghcr.io/photodialectic/nhdc-dev-mvm:latest --platform linux/amd64 .
docker push ghcr.io/photodialectic/nhdc-dev-mvm:latest
