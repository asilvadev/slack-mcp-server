# syntax=docker/dockerfile:1.7

FROM golang:1.24 AS build

ENV CGO_ENABLED=0
ENV GOTOOLCHAIN=local
ENV GOCACHE=/go/pkg/mod

RUN apt-get update && apt-get install -y --no-install-recommends net-tools curl

WORKDIR /app

COPY go.mod go.sum ./

# Cache de módulos Go
RUN --mount=type=cache,id=s/slack-mcp-go-mod,target=/go/pkg/mod \
    go mod download

COPY . .

# Cache de build Go
RUN --mount=type=cache,id=s/slack-mcp-go-build,target=/root/.cache/go-build \
    go build -ldflags="-s -w" -o /go/bin/mcp-server ./cmd/slack-mcp-server

# Dev
FROM build AS dev

RUN --mount=type=cache,id=s/slack-mcp-go-tools,target=/go/pkg/mod \
    go install github.com/go-delve/delve/cmd/dlv@v1.25.0 && cp /go/bin/dlv /dlv

WORKDIR /app/mcp-server

EXPOSE 3001
CMD ["mcp-server", "--transport", "sse"]

# Produção
FROM alpine:3.22 AS production

RUN apk add --no-cache ca-certificates net-tools curl

COPY --from=build /go/bin/mcp-server /usr/local/bin/mcp-server

WORKDIR /app

EXPOSE 3001
CMD ["mcp-server", "--transport", "sse"]
