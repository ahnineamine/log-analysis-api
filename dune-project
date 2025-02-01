(lang dune 3.17)

(name log_analysis_api)

(generate_opam_files true)

(source
 (github ahnineamine/log-analysis-api))

(authors "Author Name <ahnineamine6@gmail.com>")

(maintainers "Maintainer Name <ahnineamine6@gmail.com>")

(license LICENSE)

(documentation https://url/to/documentation)

(package
 (name log_analysis_api)
 (synopsis "A short synopsis")
 (description "A longer description")
 (depends ocaml
 dune
 yojson
 csv
 re
 dream
 logs
 alcotest
 qcheck
 )
 (tags
  ("add topics" "to describe" your project)))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/reference/dune-project/index.html
