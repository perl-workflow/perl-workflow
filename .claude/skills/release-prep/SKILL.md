---
name: release-prep
description: Prepares a Workflow CPAN release — version bump, changelog check, author tests, dist build
---

Run the following release preparation checklist in order:

1. Ask the user for the new version number (e.g. 2.10)
2. Update `$Workflow::VERSION` in `lib/Workflow.pm` and all `$Workflow::*::VERSION` strings across `lib/` to match
3. Update `=head1 VERSION` POD section in `lib/Workflow.pm` and all `$Workflow::*::VERSION` strings across `lib/` to match
4. Verify `Changes.md` has an entry for the new version following the existing format
5. Run: `dzil build --no-tgz --in build`
6. Run: `cd build && AUTHOR_TESTING=1 EXTENDED_TESTING=1 RELEASE_TESTING=1 prove --timer --lib --recurse xt/ t/`
7. Report any failures before proceeding
8. Summarize what changed between the previous version and this one based on `Changes.md`
