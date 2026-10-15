# ArtCraft Apps Web

Builds and serves the browser editions of [WordCraft](https://github.com/storytold/wordcraft),
[DeckCraft](https://github.com/storytold/deckcraft), [GridCraft](https://github.com/storytold/gridcraft),
and [PdfCraft](https://github.com/storytold/pdfcraft) from one small Nginx container.

The app source repositories are cloned into `apps/` only when building. That directory is ignored
by Git, so this repository stays focused on the build pipeline, hosting configuration, and landing
page. Every build updates the app checkouts to the latest `main`, runs their upstream web packaging
scripts, stages the generated sites under `site/`, and builds the container image.

## Open the apps

| App | Path |
| --- | --- |
| WordCraft | `/wordcraft/` |
| DeckCraft | `/deckcraft/` |
| GridCraft | `/gridcraft/` |
| PdfCraft | `/pdfcraft/` |

The root page at `/` links to all four apps. The app bundles use relative asset paths and work under
these URL prefixes.

## Run a prebuilt image

The GitHub Actions workflow publishes `ghcr.io/jokudev/artcraftappsweb:latest` after builds on
`main`. It also publishes a `sha-<commit>` tag for every workflow run and a version tag for Git
tags matching `v*.*.*`.

```sh
docker compose -f compose.ghcr.yaml up -d
```

Open <http://localhost:8080>. To use a specific image tag, edit the `image` value in
`compose.ghcr.yaml`, for example `ghcr.io/jokudev/artcraftappsweb:sha-0123456`.

The published package may need to be made public once in the GitHub Packages settings. After that,
Docker hosts can pull it without logging in.

## Build locally

Requirements: Git, Rust/Cargo, Trunk, the `wasm32-unknown-unknown` target, `zip`, `unzip`, and Docker
with Compose.

```sh
cargo install trunk --locked
rustup target add wasm32-unknown-unknown
./scripts/update-build-web.sh
docker build -t artcraft-apps-web:local .
docker run --rm -p 8080:80 artcraft-apps-web:local
```

Or serve the generated files directly with Nginx using the local Compose configuration:

```sh
docker compose up -d
```

The local compose file mounts `site/` from the workspace. `compose.ghcr.yaml` runs the immutable
image published to GHCR instead.

The update script clones repositories that are missing and fast-forwards clean checkouts on
`main`. It stops if an existing checkout is on another branch or has local changes. Run it again
after upstream updates to rebuild the bundles and refresh the published static sites.

## Automated builds and publishing

`.github/workflows/publish-image.yml` runs on pushes to `main`, version tags, a weekly schedule,
and manual dispatch. It checks out this repository, fetches the latest app sources, compiles and
packages their web versions, then publishes a static Nginx image to GitHub Container Registry.

The image contains only Nginx, the generated static app files, and license notices; Rust and the
application source trees stay in the build runner. The static files are served with WebAssembly
MIME handling, gzip compression, and long-lived caching for hashed assets.

## License and notices

The build scripts, container configuration, and landing page in this repository are licensed under
Apache-2.0; see [LICENSE](LICENSE). The bundled applications are separate upstream projects and
retain their own licenses and attribution. See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

ArtCraft names and logos are trademarks and are not licensed by Apache-2.0. This repository is an
independent build and hosting project, not an official ArtCraft service.
