# Glean/hsthrift-specific defaults layered on top of the *generic*
# haskell_library()/haskell_binary()/haskell_test() in //buck2:haskell.bzl.
#
# `buck2/` used to contain this project's own Haskell macros directly, but
# has since been extracted into its own shared repo (haskell-buck2, pulled
# in here as a worktree/branch per project - see buck2.md) so it can also
# be used by other, unrelated projects (async, cabal, ...) that don't want
# any of Glean/hsthrift's own conventions baked in. Anything specific to
# *this* pair of projects belongs here instead - kept as a byte-identical
# copy in both `buck2_macros/haskell.bzl` (Glean) and `hsthrift/
# buck2_macros/haskell.bzl` (hsthrift), the same convention `buck2/
# haskell.bzl` itself followed pre-extraction, since both projects share
# the exact same "fb-haskell" convention (e.g. hsthrift's own `common/
# mangle` is the original reason `fb_haskell = False` exists at all).
#
# Adds:
#   - the fb-haskell extension set enabled by default, so individual
#     rules don't need to repeat it. Pass fb_haskell = False for a
#     package that doesn't import that common stanza (e.g. mangle,
#     which declares its own minimal default-extensions) -
#     compiler_flags is then used as-is instead of appended to
#     FB_HASKELL_EXTENSIONS.
#   - `-threaded -rtsopts` by default on every haskell_binary() (and, via
#     haskell_test() below, every test binary too) - every Cabal
#     executable/test-suite gets this for free via glean.cabal.in's
#     `common exe` stanza, so this shouldn't be opt-in either. Without
#     it, anything that blocks its main thread in a synchronous FFI/
#     subprocess call while needing a background thread to make progress
#     concurrently (e.g. an embedded Warp server servicing a request
#     while `callCommand` waits on an external tool - see glean-snapshot-
#     {,codemarkup-}haskell) hangs until it times out, even though it
#     compiles and links fine. Merged with, not replaced by, a caller's
#     own `linker_flags` (e.g. gleancli's `-with-rtsopts=-I0`).
#
# haskell_test() can't just delegate to the generic //buck2:haskell.bzl's
# own haskell_test() for this: that function builds its `:name-bin` via
# *its own* module-local haskell_binary() (undecorated - no fb_haskell, no
# -threaded/-rtsopts), not whatever's imported under that name at the call
# site, so a thin wrapper here would only add fb_haskell to directly-
# defined libraries/binaries, silently missing every haskell_test(). It's
# reimplemented here instead, structurally identical to the generic
# version, but calling *this* file's own haskell_binary() for the `:name-
# bin` target.

load("//buck2:haskell.bzl", real_haskell_binary = "haskell_binary", real_haskell_library = "haskell_library")

# Extensions enabled by the `fb-haskell` common stanza in glean.cabal.in.
FB_HASKELL_EXTENSIONS = [
    "-XHaskell2010",
    "-XBangPatterns",
    "-XBinaryLiterals",
    "-XDataKinds",
    "-XDeriveDataTypeable",
    "-XDeriveGeneric",
    "-XEmptyCase",
    "-XExistentialQuantification",
    "-XFlexibleContexts",
    "-XFlexibleInstances",
    "-XGADTs",
    "-XGeneralizedNewtypeDeriving",
    "-XLambdaCase",
    "-XMultiParamTypeClasses",
    "-XMultiWayIf",
    "-XNamedFieldPuns",
    "-XNoMonomorphismRestriction",
    "-XOverloadedStrings",
    "-XPatternSynonyms",
    "-XRankNTypes",
    "-XRecordWildCards",
    "-XScopedTypeVariables",
    "-XStandaloneDeriving",
    "-XTupleSections",
    "-XTypeFamilies",
    "-XTypeSynonymInstances",
    "-XNondecreasingIndentation",
    "-XTypeOperators",
]

def haskell_library(name, compiler_flags = [], fb_haskell = True, **kwargs):
    all_compiler_flags = (FB_HASKELL_EXTENSIONS + compiler_flags) if fb_haskell else compiler_flags
    real_haskell_library(
        name = name,
        compiler_flags = all_compiler_flags,
        **kwargs
    )

def haskell_binary(name, compiler_flags = [], fb_haskell = True, linker_flags = [], **kwargs):
    all_compiler_flags = (FB_HASKELL_EXTENSIONS + compiler_flags) if fb_haskell else compiler_flags
    real_haskell_binary(
        name = name,
        compiler_flags = all_compiler_flags,
        linker_flags = ["-threaded", "-rtsopts"] + linker_flags,
        **kwargs
    )

# Cabal's test-suites (glean.cabal.in) are all `type: exitcode-stdio-1.0` -
# a plain executable, exit code is the result - so `buck2 test` support
# needs nothing Haskell-specific: this builds the exact same
# haskell_binary() `name` would (so `buck2 run :name` is unaffected), plus
# a same-named `:name-test` native.sh_test() wrapping it, which is enough
# for `buck2 test :name-test` to work with zero .buckconfig changes (see
# buck2.md's "buck test" entry for why a plain sh_test() wrapper was
# chosen over writing a bespoke rule - a custom rule would still need this
# same two-target shape under the hood, since a rule can't invoke another
# rule's impl inline, so it would just mean re-implementing sh_test's own
# ExternalRunnerTestInfo wiring ourselves for no functional gain).
#
# `test_args`/`test_env` cover the one real wrinkle: a test-suite that
# shells out to another buck2-built tool (e.g. glean-clang's clang-index)
# needs that tool's location passed in explicitly via a `$(exe_target
# ...)` string-parameter macro, rather than relying on it being on
# `$PATH` - more hermetic than this migration's own earlier practice of
# manually prepending PATH by hand to reproduce these runs (see
# buck2.md). `$(exe_target ...)`, not `$(exe ...)`: resolves the
# referenced target under *this* target's own ordinary configuration
# instead of switching to an execution platform, so a test-time tool
# like this automatically gets the same dev/opt build mode as the test
# itself with nothing further needed here (see buck2.md's "$(exe_target
# ...)" entry - this used to need an exec_compatible_with default on
# this function's own sh_test() to line the two configurations back up,
# now removed as dead weight). `cwd` covers the other wrinkle - some
# tests need to run with a specific working directory - via `//buck2:
# run_in_cwd`, a tiny cd-then-exec wrapper script in the now-generic
# shared repo (unrelated to fb_haskell, so left there).
#
# `LANG` defaults to a UTF-8 locale: unlike `buck2 run` (which inherits
# the caller's shell environment, `LANG` included), `buck2 test` runs
# actions in a sanitized environment with no `LANG` at all - so GHC's
# `hGetContents`/`readFile` fall back to the POSIX/ASCII encoding and
# choke on any non-ASCII byte in a test fixture (found via
# thrift-compiler-tests, whose fixtures include non-ASCII comments:
# "hGetContents: invalid argument (cannot decode byte sequence starting
# from 226)" - 226 = 0xE2, a UTF-8 lead byte). `C.UTF-8` is a glibc
# locale alias needing no locale-generation step, so it's available
# without depending on whatever locales happen to be installed.
def haskell_test(name, test_args = [], test_env = {}, cwd = None, **kwargs):
    bin = name + "-bin"
    haskell_binary(name = bin, **kwargs)
    test_target = ":" + bin
    args = test_args

    if cwd != None:
        test_target = "//buck2:run_in_cwd"
        args = [cwd, "$(exe_target :" + bin + ")"] + test_args

    native.sh_test(
        name = name,
        test = test_target,
        args = args,
        env = {"LANG": "C.UTF-8"} | test_env,
    )
