---
title: "Push rock to GitHub Container Registry"
summary: "How to use GitHub Actions to create a rock with Rockcraft, push the image to GitHub Container Registry, and generate its attestation"
date: 2025-03-05T20:27:47+03:00
type: til
math: true
meta: true
topics:
  - rockcraft
  - github-actions
---

Recently, I needed to push an OCI image created with [Rockcraft](https://documentation.ubuntu.com/rockcraft/en/stable/index.html) {{<marginnote>}} Rockcraft is a tool used to create rocks - a new generation of secure, stable and OCI-compliant container images, based on Ubuntu.{{</marginnote>}} to the GitHub Container Registry (GHCR) and generate an artifact attestation for it. I ended up having to do a bit of digging and tinkering to come up with a GitHub workflow that I liked, so I thought I would share it here in case someone else encounters the same problem.

You can use this GitHub Action to push to GHCR but it can be adapted to push to any container registry. Make sure to replace `<username>` with your GitHub username/organization and `<repository>` with the name of your repository in the last 2 steps. This workflow also assumes that you have a `rockcraft.yaml` file in the root of your repository but you can modify it to point to a different location. I've added these as `TODOs`.

```yaml
name: Push Image to GitHub Container Registry

on:
  push:
    branches:
      - main
  workflow_dispatch: {}

jobs:
  release:
    runs-on: ubuntu-latest

    permissions:
      contents: write     # required to work with repository contents
      packages: write     # required to push the image to the container registry
      attestations: write # required to persist the attestation
      id-token: write     # required to mint the OIDC token needed to request a Sigstore signing certificate

    steps:
      - name: Check out the repository
        uses: actions/checkout@v4

      # LXD is required to pack the rock
      - name: Setup LXD
        uses: canonical/setup-lxd@main

      - name: Install Rockcraft
        run: |
          sudo snap install rockcraft --classic

          sudo snap install yq

      - name: Build rock
        run: |
          ROCKCRAFT_ENABLE_EXPERIMENTAL_EXTENSIONS=True rockcraft pack --verbose

      - name: Log in to the container registry
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      # TODO: Replace <username> and <repository>
      # TODO: Change path to rockcraft.yaml if it's not in the root of the repository
      - name: Push image to container registry
        id: push
        run: |
          NAME=$(yq .name rockcraft.yaml)
          VERSION=$(yq .version rockcraft.yaml)

          rockcraft.skopeo --insecure-policy copy \
            oci-archive:${NAME}_${VERSION}_amd64.rock \
            docker://ghcr.io/<username>/<repository>:${VERSION} \
            --dest-creds ${{ github.actor }}:${{ secrets.GITHUB_TOKEN }}

          DIGEST=$(rockcraft.skopeo inspect --format "{{.Digest}}" docker://ghcr.io/<username>/<repository>:${VERSION})
          echo "digest=${DIGEST}" >> $GITHUB_OUTPUT

      # TODO: Replace <username> and <repository>
      - name: Generate attestation
        uses: actions/attest-build-provenance@v1
        with:
          subject-name: ghcr.io/<username>/<repository>
          subject-digest: ${{ steps.push.outputs.digest }}
          push-to-registry: true
```

Happy crafting! ✨
