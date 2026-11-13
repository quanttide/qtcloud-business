# qtcloud business provider：多阶段构建，静态编译。
# 运行时从环境变量读取配置（LISTEN_ADDR）。

FROM golang:1.26-alpine AS build

WORKDIR /src

ARG GOPROXY=https://goproxy.cn,direct
ENV GOPROXY=${GOPROXY}

COPY go.mod ./
COPY . .
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/qtcloud-business-server ./cmd/server

FROM alpine:3.20

RUN addgroup -S app && adduser -S -G app app
COPY --from=build /out/qtcloud-business-server /usr/local/bin/qtcloud-business-server

USER app
EXPOSE 8080

CMD ["/usr/local/bin/qtcloud-business-server"]
