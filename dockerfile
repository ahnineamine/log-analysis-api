# Build stage

FROM ocaml/opam:debian-ocaml-5.3 AS builder

RUN sudo apt-get update && sudo apt-get install -y \
    build-essential \
    pkg-config \
    libev-dev libgmp-dev libssl-dev\
    m4

WORKDIR /app

ENV LOG_LEVEL=DEBUG

COPY . .

USER opam

RUN sudo chown -R opam:opam /app

RUN eval $(opam env) && opam install -y . --deps-only --locked

RUN eval $(opam env) && dune build @install

# Runtime stage
FROM debian:bookworm-slim 

RUN apt-get update && apt-get install -y \
    libgmp10 \
    libssl3 \
    libev4 \ 
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy built executable from build stage
COPY --from=builder /app/_build/default/bin/main.exe /usr/local/bin/app

WORKDIR /usr/local/bin
COPY --from=builder /app/data ./data  

EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/app"]