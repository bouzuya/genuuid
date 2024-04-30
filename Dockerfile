FROM rust:1.77-alpine AS chef
RUN apk update && apk add --no-cache musl-dev
WORKDIR /app
RUN cargo install cargo-chef --locked

FROM chef AS planner
COPY . .
RUN cargo chef prepare --recipe-path recipe.json

FROM chef AS cacher
COPY --from=planner /app/recipe.json recipe.json
RUN cargo chef cook --recipe-path recipe.json --release --target=x86_64-unknown-linux-musl

FROM chef AS builder
COPY . .
COPY --from=cacher /app/target target
RUN cargo build --release --target=x86_64-unknown-linux-musl

FROM scratch
LABEL org.opencontainers.image.source https://github.com/bouzuya/genuuid
ENV PORT=8080
COPY --from=builder /app/target/x86_64-unknown-linux-musl/release/genuuid /usr/local/bin/genuuid
ENTRYPOINT ["genuuid"]
