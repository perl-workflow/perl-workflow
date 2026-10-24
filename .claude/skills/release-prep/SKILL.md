---
name: release-prep
description: Prepares a Workflow CPAN release — version bump, changelog check, author tests, dist build
---

Run the following release preparation checklist in order:

1. Ask the user for the new version number (e.g. 2.10)
2. Update `$Workflow::VERSION` in `lib/Workflow.pm` and all `$Workflow::*::VERSION` strings across `lib/` to match. Not every module uses that form, so a pattern matching only `$Workflow::*::VERSION` misses some:
   - `Exception.pm` has extra spaces before the `=`
   - `Condition::{IsTrue,IsFalse,Result}.pm` assign to the bare package name with no `::VERSION` suffix (a known quirk, leave it as is)
   - `Condition::{LazyAND,LazyOR,Negated}.pm` use `our $VERSION = '...';`
3. Update `=head1 VERSION` POD section in `lib/Workflow.pm` and all `$Workflow::*::VERSION` strings across `lib/` to match
4. Verify the bump with `grep -rn "OLD_VERSION" lib/`. The only hits allowed are historical references, such as the contributor credits in the `AUTHORS` POD of `lib/Workflow.pm` ("resulting in release X.XX"). Do not change those. Every module must have both a new version assignment and a new `describes version` POD line, so compare those two counts against the number of modules
5. Verify `Changes.md` has an entry for the new version following the existing format
6. Remove any leftover `build/` or `Workflow-*/` directory from earlier local builds. `GatherDir` ignores `.gitignore`, and a stray one gets duplicated into the release tarball (issue #288)
7. Run: `dzil build --no-tgz --in build`
8. Run: `cd build && AUTHOR_TESTING=1 EXTENDED_TESTING=1 RELEASE_TESTING=1 prove --timer --lib --recurse t/` (`dzil build` filters `xt/` into `t/` as `author-*.t` / `release-*.t`, so `build/` has no `xt/` directory)
9. Report any failures before proceeding
10. Remove `build/` again once the tests have run, so it cannot end up in the real release tarball
11. Summarize what changed between the previous version and this one based on `Changes.md`
