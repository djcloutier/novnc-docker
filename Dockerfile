FROM --platform=$TARGETPLATFORM golang:1.15-alpine as server

WORKDIR /build
COPY src /build
RUN CGO_ENABLED=0 GOOS=$(echo $TARGETPLATFORM| cut -d'/' -f 1) GOARCH=$(echo $TARGETPLATFORM| cut -d'/' -f 2) go build -a -installsuffix cgo -ldflags="-w -s" -o /build/novnc-manager

FROM --platform=$TARGETPLATFORM alpine:3.12 as client

RUN apk add --no-cache git nodejs npm

RUN npm install -g webpack-cli @angular/cli@10

WORKDIR /build/client
COPY src/client /build/client
RUN npm install
RUN ng build --prod

FROM --platform=$TARGETPLATFORM alpine:3.12 as runtime

LABEL maintainer.name="Dave Cloutier" maintainer.email="djcloutier@gmail.com"

RUN mkdir -p /app/client
RUN git clone --depth 1 https://github.com/novnc/noVNC.git /build/noVNC/ && rm -rf /build/noVNC/.git && apk del git
COPY --from=server /build/novnc-manager /app/novnc-manager
COPY --from=client /build/client/dist/client /app/client/


WORKDIR /app
EXPOSE 8084
ENTRYPOINT [ "/app/novnc-manager" ]
