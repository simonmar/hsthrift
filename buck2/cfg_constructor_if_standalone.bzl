# A PACKAGE file (unlike a BUCK/.bzl file) can only contain a flat
# sequence of top-level calls - no `if`/`def` allowed directly in it
# ("if cannot be used outside def", then "def is not allowed in this
# dialect" once wrapped - both confirmed directly). The conditional logic
# hsthrift/PACKAGE needs (call set_cfg_constructor() only when this
# checkout is genuinely standalone - see that file's own comment) has to
# live in a real .bzl file instead, called as a single top-level
# statement from the PACKAGE file itself.
load(
    "@prelude//cfg/modifier/cfg_constructor.bzl",
    "cfg_constructor_post_constraint_analysis",
    "cfg_constructor_pre_constraint_analysis",
)
load("@prelude//cfg/modifier/common.bzl", "MODIFIER_METADATA_KEY")
load("@prelude//cfg/modifier/set_cfg_modifiers.bzl", "set_cfg_modifiers")

def cfg_constructor_if_standalone():
    # get_cell_name() gives the name of *this* PACKAGE file's own cell -
    # "root" when this checkout's own .buckconfig is the outermost one
    # (genuinely standalone), or "hsthrift" when nested inside another
    # project's cell graph (see buck2.md's hsthrift-cell entry for why
    # cell names are global to whichever project is outermost - that's
    # exactly what makes this check correct: a plain read_config() flag
    # in this project's own .buckconfig does *not* work here, since a
    # cell's own .buckconfig is still consulted for ordinary config
    # values even when nested, unlike the special-cased [cells] section -
    # confirmed directly, the first version of this check used that and
    # it read as true (and hard-errored the nested build) either way.
    if get_cell_name() != "root":
        return

    set_cfg_constructor(
        stage0 = cfg_constructor_pre_constraint_analysis,
        stage1 = cfg_constructor_post_constraint_analysis,
        key = MODIFIER_METADATA_KEY,
        aliases = struct(
            dev = "root//buck2/constraints:dev",
            opt = "root//buck2/constraints:opt",
        ),
        extra_data = struct(),
    )

    # `dev` is the default build mode when no -m flag is given.
    set_cfg_modifiers(
        cfg_modifiers = ["root//buck2/constraints:dev"],
    )
