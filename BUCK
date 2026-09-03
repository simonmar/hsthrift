# The subset of thrift/annotation/*.thrift actually `include`d anywhere in
# this repo (lib/, tests/ and http/ each need some of haskell.thrift,
# thrift.thrift and scope.thrift - haskell.thrift includes both of the
# others, thrift.thrift includes scope.thrift) - exported here individually
# so every thrift_compile() that needs them can depend on exactly these
# real BUCK targets (see buck2/thrift.bzl's own top comment for why: a
# bare "-I" directory path, or a glob covering a whole package, both
# failed once this cell could be built standalone, nested inside another
# project, or under remote execution).
# Named after their own real basename (matching lib/BUCK's math.thrift/
# echoer.thrift exports) rather than an "annotation-" prefix: thrift_library()
# derives a compiled main file's output module path from its *name* here,
# not its content's `namespace hs` directive, so a differently-named target
# for the exact same file produces a differently-named (and wrong) output.
export_file(
    name = "scope.thrift",
    src = "thrift/annotation/scope.thrift",
    visibility = ["PUBLIC"],
)

export_file(
    name = "thrift.thrift",
    src = "thrift/annotation/thrift.thrift",
    visibility = ["PUBLIC"],
)

export_file(
    name = "haskell.thrift",
    src = "thrift/annotation/haskell.thrift",
    visibility = ["PUBLIC"],
)
