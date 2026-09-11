# syntax=docker/dockerfile:1

FROM rust:1.85-bookworm AS builder
WORKDIR /src
COPY . .
RUN rustup target add x86_64-unknown-linux-gnu \
    && cargo build --release --target x86_64-unknown-linux-gnu \
    && mkdir -p /out \
    && cp target/x86_64-unknown-linux-gnu/release/o2_report_generator /out/report-generator

FROM debian:bookworm-slim
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates chromium \
    && rm -rf /var/lib/apt/lists/*
COPY ottawa-ca.crt /usr/local/share/ca-certificates/ottawa-ca.crt
RUN update-ca-certificates
COPY --from=builder /out/report-generator /report-generator
CMD ["/report-generator"]
