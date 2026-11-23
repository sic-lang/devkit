def everything:
  [
    .annotations[]?
    | select(.path == "**" or (.path | type == "array" and any(.[]; . == "**")))
  ];

def custom:
  [
    .files[].spdx_expressions[].value
    | scan("(?:LicenseRef|AdditionRef)-[A-Za-z0-9.-]+")
  ]
  | unique[];

def outside:
  .files[]
  | [.path]
    + (
      (.copyrights[] | ["copyright", .source, .source_type]),
      (.spdx_expressions[] | ["license", .source, .source_type])
    )
  | select(.[3] != "reuse-toml")
  | "\(.[0]) takes its \(.[1]) from \(.[2]) (\(.[3]))";
