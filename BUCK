load("//buck2:thrift.bzl", "thrift_srcs_export")

# The subset of thrift/annotation/*.thrift actually `include`d anywhere in
# this repo (lib/, tests/ and http/ each need some of haskell.thrift,
# thrift.thrift and scope.thrift - haskell.thrift includes both of the
# others, thrift.thrift includes scope.thrift). Individual export_file()s
# below let a thrift_library() elsewhere *compile* one of these as its own
# main file (e.g. lib/BUCK's test-lib, http/BUCK's test-lib); this
# `annotations` collector lets any thrift_library() `deps` on the whole
# trio at once for `include` resolution (see buck2/thrift.bzl's own top
# comment for why that's a `deps` edge rather than a `-I` directory path
# or a glob covering a whole package - both failed once this cell could be
# built standalone, nested inside another project, or under remote
# execution).
thrift_srcs_export(
    name = "annotations",
    srcs = {
        "thrift/annotation/scope.thrift": "thrift/annotation/scope.thrift",
        "thrift/annotation/thrift.thrift": "thrift/annotation/thrift.thrift",
        "thrift/annotation/haskell.thrift": "thrift/annotation/haskell.thrift",
    },
    visibility = ["PUBLIC"],
)

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
