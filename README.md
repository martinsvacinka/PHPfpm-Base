# PHPfpm-Base

Base phpfpm image

```Dockerfile
FROM ghcr.io/container-driven-development/phpfpm-base:vX.X

ARG APP_VERSION
ENV APP_VERSION $APP_VERSION

COPY --from=BUILDER /app/vendor /srv/vendor
COPY --from=BUILDER-NODE /app/var/tmp/manifest.json /srv/var/tmp/manifest.json
COPY ./www /srv/www
COPY ./config /srv/config
COPY ./app /srv/app
COPY ./bin /srv/bin
COPY ./migrations /srv/migrations
```
