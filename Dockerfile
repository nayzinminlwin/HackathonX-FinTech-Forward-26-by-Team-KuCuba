FROM dart:stable AS build

WORKDIR /app

COPY backend/pubspec.* ./
RUN dart pub get

COPY backend/ ./
RUN dart compile exe bin/server.dart -o bin/server

FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=build /app/bin/server /app/server

ENV PORT=8080
EXPOSE 8080

CMD ["/app/server"]
