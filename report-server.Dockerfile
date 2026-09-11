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
    && apt-get install -y --no-install-recommends ca-certificates chromium libnss3-tools openssl \
    && rm -rf /var/lib/apt/lists/*
COPY ottawa-ca.crt /usr/local/share/ca-certificates/ottawa-ca.crt
RUN update-ca-certificates \
    && useradd --create-home --uid 1000 renderer \
    && mkdir -p /home/renderer/.pki/nssdb \
    && certutil -d sql:/home/renderer/.pki/nssdb -N --empty-password \
    && awk 'BEGIN {c=0} /-----BEGIN CERTIFICATE-----/ {c++} {print > ("/tmp/city-ca-" c ".pem")} /-----END CERTIFICATE-----/ {close("/tmp/city-ca-" c ".pem")}' /usr/local/share/ca-certificates/ottawa-ca.crt \
    && for cert in /tmp/city-ca-*.pem; do \
         if openssl x509 -in "$cert" -noout -text | grep -q 'CA:TRUE'; then \
           certutil -d sql:/home/renderer/.pki/nssdb -A -n "$(basename "$cert")" -t 'C,,' -i "$cert"; \
         fi; \
       done \
    && chown -R renderer:renderer /home/renderer \
    && rm -f /tmp/city-ca-*.pem
COPY --from=builder /out/report-generator /report-generator
ENV HOME=/home/renderer
CMD ["/report-generator"]
