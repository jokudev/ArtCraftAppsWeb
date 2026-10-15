# ArtCraft Apps Web

Serves the browser releases of [WordCraft](https://github.com/storytold/wordcraft),
[DeckCraft](https://github.com/storytold/deckcraft), [GridCraft](https://github.com/storytold/gridcraft),
and [PdfCraft](https://github.com/storytold/pdfcraft) from one small Nginx container.

The build downloads each app's latest `*-web-*.zip` release asset, stages the four static sites,
and builds a container image. It uses upstream release artifacts directly, so the pipeline does
not compile the Rust apps. The source checkouts under `apps/` are ignored by Git and are not
included in the container.

## Open the apps

| App | Path |
| --- | --- |
| WordCraft | `/wordcraft/` |
| DeckCraft | `/deckcraft/` |
| GridCraft | `/gridcraft/` |
| PdfCraft | `/pdfcraft/` |

The root page at `/` links to all four apps. Each bundle uses relative asset paths, so it works
under its URL prefix.

## Run the published image

GitHub Actions publishes `ghcr.io/jokudev/artcraftappsweb:latest` after pushes to `main`. It also
publishes a `sha-<commit>` tag for each successful build and version tags for Git tags matching
`v*.*.*`.

```sh
docker compose -f compose.ghcr.yaml up -d
```

Open <http://localhost:8080>. To use a specific version, change the `image` value in
`compose.ghcr.yaml`, for example `ghcr.io/jokudev/artcraftappsweb:sha-0123456`.

## Stage release assets locally

Requirements: `curl`, `jq`, and `unzip`.

```sh
./scripts/fetch-release-web.sh
```

This downloads each app's latest GitHub release asset matching `wordcraft-web-*.zip`,
`deckcraft-web-*.zip`, `gridcraft-web-*.zip`, and `pdfcraft-web-*.zip`, then extracts each under
`site/<app>/`. The ignored `apps/` folders are optional source checkouts and are not used by this
release-based pipeline.

To serve the staged sites with the local Nginx container:

```sh
docker compose up -d
```

To build the same image locally after staging:

```sh
docker build -t artcraft-apps-web:local .
docker run --rm -p 8080:80 artcraft-apps-web:local
```

## Automated publishing

`.github/workflows/publish-image.yml` runs on pushes to `main`, version tags, and manual
dispatch. It downloads the latest web release assets, builds the static Nginx image, and pushes it
to GitHub Container Registry. There is no scheduled build. Docker layer caching is enabled for
subsequent image builds.

The image contains only Nginx, the generated static app files, and license notices. It serves
WebAssembly with the correct MIME type, enables gzip compression, and gives hashed assets
long-lived cache headers.

## License and notices

The build scripts, container configuration, and landing page in this repository are licensed under
Apache-2.0; see [LICENSE](LICENSE). The bundled apps are separate upstream projects and retain
their own licenses and attribution. See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

ArtCraft names and logos are trademarks and are not licensed by Apache-2.0. This repository is an
independent build and hosting project, not an official ArtCraft service.
