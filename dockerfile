# Base image
FROM ocaml/opam:debian-ocaml-5.3

USER root

RUN apt-get update && apt-get install -y \
    libgmp-dev \ 
    pkg-config \
    libev-dev \
    libssl-dev

WORKDIR /app

ENV LOG_LEVEL=DEBUG

COPY --chown=opam:opam . .

RUN eval $(opam env) && opam install -y . --deps-only --locked

USER opam

RUN eval $(opam env) && dune build

EXPOSE 8080

CMD ["dune", "exec", "bin/main.exe"]
