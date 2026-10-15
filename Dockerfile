FROM nginx:alpine

LABEL org.opencontainers.image.title="ArtCraft Apps Web"
LABEL org.opencontainers.image.description="Static web builds of WordCraft, DeckCraft, GridCraft, and PdfCraft"
LABEL org.opencontainers.image.source="https://github.com/jokudev/ArtCraftAppsWeb"

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY site/ /usr/share/nginx/html/
COPY LICENSE /usr/share/nginx/html/LICENSE
COPY THIRD_PARTY_NOTICES.md /usr/share/nginx/html/THIRD_PARTY_NOTICES.md

EXPOSE 80
