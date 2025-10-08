FROM golang:1.24 AS build

ENV CGO_ENABLED=0
ENV GOTOOLCHAIN=local
ENV GOCACHE=/go/pkg/mod

RUN apt-get update  \
  && apt-get install -y --no-install-recommends net-tools curl

WORKDIR /app

COPY go.mod go.sum ./

RUN --mount=type=cache,id=s/75ead2a8-dd36-47e9-bdec-cdd2d485bf69-/go/pkg/mod,target=/go/pkg/mod go mod download

COPY . /app

RUN --mount=type=cache,id=s/75ead2a8-dd36-47e9-bdec-cdd2d485bf69-/go/pkg/mod,target=/go/pkg/mod \
    go build -ldflags="-s -w" -o /go/bin/mcp-server ./cmd/slack-mcp-server

FROM build AS dev

RUN --mount=type=cache,id=s/75ead2a8-dd36-47e9-bdec-cdd2d485bf69-/go/pkg/mod,target=/go/pkg/mod \
    go install github.com/go-delve/delve/cmd/dlv@v1.25.0 && cp /go/bin/dlv /dlv

WORKDIR /app/mcp-server

EXPOSE 13080

CMD ["mcp-server", "--transport", "stdio"]

FROM alpine:3.22 AS production

RUN apk add --no-cache ca-certificates net-tools curl

COPY --from=build /go/bin/mcp-server /usr/local/bin/mcp-server

WORKDIR /app

EXPOSE 13080

CMD ["mcp-server", "--transport", "stdio"]
