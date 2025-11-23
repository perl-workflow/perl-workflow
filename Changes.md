# Revision history for the Workflow Perl Distribution

## 2.09 2025-11-23 maintenance release, update not required

- Deprecation notice of use of XML configuration files, issue [#125](https://github.com/perl-workflow/perl-workflow/issue/125) and deprecation notices implementation by @ehuelsmann via PR [#256](https://github.com/perl-workflow/perl-workflow/pull/256).
  - YAML configuration files are now the preferred format for configuration of Workflow instances. The XML implementation was based on [XML::Simple](https://metacpan.org/pod/XML::Simple), which itself has been discouraged for use for several years. The distribution still supports XML configuration files, but this support will be removed in a future unscheduled major release.

- Improvements to test suite, PR [#275](https://github.com/perl-workflow/perl-workflow/pull/275) by @ehuelsmann. This is a follow up on release 2.08, since we spotted the issue in the tests running as part of the CI pipeline on GitHub

## 2.08 2025-11-12 bug fix release, update not required

### Fixed

- Issue: [#271](https://github.com/perl-workflow/perl-workflow/issues/271) reported by [@andk](https://github.com/andk). Fixed via PR: [#272](https://github.com/perl-workflow/perl-workflow/pull/272) by @ehuelsmann
  This issue was discovered by the CPAN smoke testers, the report can be found on [CPAN Testers](https://www.cpantesters.org/cpan/report/f9442cc8-bccd-11f0-b805-8614eb2737ae)

## 2.07 2025-11-08 bug fix release, update not required

### Fixed

- Issue: [#266](https://github.com/perl-workflow/perl-workflow/issues/266) discovered by Erik Huelsmann. A regression introduced with 2.X releases. Fixed via PR: [#267](https://github.com/perl-workflow/perl-workflow/pull/267) also by Erik Huelsmann

## 2.06 2025-08-12 bug fix release, update not required

### Fixed

- Autorun triggered upon workflow creation invoking non-existent method, PR [#258](https://github.com/perl-workflow/perl-workflow/pull/258)
- Observers not notified of events triggered by autorun initial actions, issue [#259](https://github.com/perl-workflow/perl-workflow/pull/259)
- Remove duplicated POD section from YAML config module, PR [#255](https://github.com/perl-workflow/perl-workflow/pull/255)
- Missing 'autorun' value in 'completed' event, issue [#257](https://github.com/perl-workflow/perl-workflow/pull/257)
- Clarified documentation and release notes on event changes between 1.62 and 2.x, issue [#257](https://github.com/perl-workflow/perl-workflow/pull/257)

## 2.05 2025-02-01 bug fix release, update not required

### Fixed

- Workflow::Persister::DBI::ExtraData fails to return the extra
  data retrieved, PR [#251](https://github.com/perl-workflow/perl-workflow/pull/251)
- Logger reports 'CODE(0x...)' instead of actual error message, PR [#252](https://github.com/perl-workflow/perl-workflow/pull/252)
- Documentation of incompatibilities no longer observed (removed), issue: [#248](https://github.com/perl-workflow/perl-workflow/issues/248)
- Example web application not compatible with 2.0, issue: [#243](https://github.com/perl-workflow/perl-workflow/issues/243)
- Example web application throwing errors, isse: [#244](https://github.com/perl-workflow/perl-workflow/issues/244)
- Removed dead link from CONTRIBUTORS section
- Links updated to reflect the new repository location, issue: [#242](https://github.com/perl-workflow/perl-workflow/issues/242)

## 2.04 2025-01-29 Feature and bug fix release, update not required

### Added

- Allow `$context` parameter in `create_workflow` and `fetch_workflow` to be
  an unblessed hash (loosens requirement for it to me a `Workflow::Context`
  instance)

### Fixed

- Conditions with a `test` attribute (i.e. without a `name` attribute),
  declared 'inline' in the workflow->state->action definition
- Conditions provided as examples in `eg/` should have been ported to 2.0
- Broken URLs in documentation

## 2.03 2025-01-24 Bug fix release, update recommended

### Fixed

- Instances of Workflow::Condition::IsFalse interpreted as `true` return values
  under `$Workflow::Condition::STRICT_BOOLEANS = 0`

## 2.02 2025-01-11 Major release, update recommended

### Added

- Support for configurable history classes other than `Workflow::History`
- Support for configuration of observers through a separate configuration file;
  i.e. independently of `Workflow` configuration
- Added new observer events startup, finalize, run
- Add new accessor methods `last_action_executed`, `get_all_actions` to `Workflow` object
- Support for configuration of content of the first history item of a workflow
  through `Workflow` (instead of through the persister)
- New persister `Workflow::Persister::DBI::ExtraData` to load data from a database
  when loading a workflow instance

### Changed

- Clarification that `Workflow::Validator` and `Workflow::Condition` define interfaces, not classes
- Conditions return `Workflow::Condition::IsTrue`/`Workflow::Condition::IsFalse` on success/
  failure instead of throwing a condition error
- `Workflow::Persister->fetch_history` returns constructor arguments instead of
  `Workflow::History` objects, moving the responsibility of instantiating history instances
  to the factory
- Logging library changed from `Log::Log4perl` to [Log::Any](https://metacpan.org/pod/Log::Any);
  to get logging, install a [Log::Any::Adapter](https://metacpan.org/pod/Log::Any::Adapter)
- Moved `add_observer` and `notify_observers` from private to public API of `Workflow`
- `$wf->context->param( $key => undef )` removes `$key` from the context instead of setting
  it to `undef`
- Autorunning now loops through executed actions instead of recursing; preventing stack
  overflows on very large execution chains
- `Workflow` no longer calls `{commit,rollback}_transaction`; the factory has assumed this
  responsibility as it's the factory which is in charge of serializing workflows
- `Workflow::Action->execute` must return a scalar value or undef (no references)
- Renamed observer event `execute` to `completed`, changed arguments for `state change` and `completed`
  observer events to be a hash (not positional arguments).

### Removed

- `Workflow::Persister->fetch_extra_workflow_data` replaced by
  `Workflow::Persister::DBI::ExtraData`
- Removed `condition_error` in light of the changed return value of conditions
- Removed `Workflow::Validator->_init` since the private function does not need to be
  part of the specified public interface
- Removed `Workflow::Condition::CheckReturn` and `Workflow::Condition::GreedyOR`
- Removed empty modules `Workflow::Condition::Nested` and `Workflow::Action::Mailer`
- Support for [SPOPS](https://metacpan.org/dist/SPOPS) - `Workflow::Persister::SPOPS` -
  has been removed from the Workflow dist; it has been moved to the
  [Workflow-Persister-SPOPS](https://metacpan.org/dist/Workflow-Persister-SPOPS) dist for
  those who still need it.  Reason for removal is that it does not seem to be actively
  supported and the latest release (0.87; released in 2004) has [failed its cpantesters
  tests on every released Perl version since 5.11.1](http://matrix.cpantesters.org/?dist=SPOPS+0.87)

### Fixed

- Workaround for Perls between 5.18 and 5.39.2 clobbering %SIG in Safe->reval()
  which is used internally by `Workflow::Condition::Evaluate`

## 2.02-TRIAL 2024-07-13 TRIAL release, update not required

- Separation of the following classes into separate files, for proper meta-data indexing:
  - `Workflow::Condition::Result`
  - `Workflow::Condition::IsTrue`
  - `Workflow::Condition::IsFalse`

## 2.01-TRIAL 2024-05-17 TRIAL release, update not required

- See above for changes for version 2.0
- Specified requirement for functioning DBD::Mock

## 2.00-TRIAL 2024-05-13 TRIAL release, update not required

- See above for changes 2.0

## 1.62 2023-02-11 bug fix/maintenance release, update recommended

- Minor correction to documentation via PR [#208](https://github.com/jonasbn/perl-workflow/pull/208) from @ehuelsmann

- Improvement to the overall codebase by localizing `$EVAL_ERROR` in conjunction with `eval` structures, via PR [#211](https://github.com/jonasbn/perl-workflow/pull/211) from @ehuelsmann

## 1.61 2022-10-01 bug fix release, update recommended

- We have removed some code, which was no longer used, which was causing some grievance see PR [#203](https://github.com/jonasbn/perl-workflow/pull/203) from by Oliver Welter (@oliwell)

## 1.60 2022-03-02 bug fix release, update recommended

- We have discovered a minor regression, founded in our eager to implement more clean code. This has been addressed via PR [#195](https://github.com/jonasbn/perl-workflow/pull/195) by Erik Huelsmann (@ehuelsmann).

  It was followed up by PR [#196](https://github.com/jonasbn/perl-workflow/pull/196/files) by Oliver Welter (@oliwell).

  We are now setting the bar a bit lower for the 1.x releases in regard to best practices and code quality and focus on improving the code for 2.x, so we do not experience any more regressions.

## 1.59 2022-02-02 bug fix release, update required

- Unfortunately we discovered a minor mishap, where a dependency was referenced without being properly declared as a dependency, which could result in inability for the distribution to work in a clean environment. This has now been addressed via PR [#190](https://github.com/jonasbn/perl-workflow/pull/190)

We are sorry about any inconvenience this might have caused

## 1.58 2022-02-02 Maintenance release, update not required

- Addressed violations of [Perl::Critic](https://metacpan.org/pod/Perl::Critic) policies:
  - [Subroutines::ProhibitExplicitReturnUndef](https://metacpan.org/pod/Perl::Critic::Policy::Subroutines::ProhibitExplicitReturnUndef)
  - [ValuesAndExpressions::ProhibitMixedBooleanOperators](https://metacpan.org/pod/Perl::Critic::Policy::ValuesAndExpressions::ProhibitMixedBooleanOperators)

  Adjustments to Perl::Critic resourcefile (`t/perlcriticrc`), this somewhat addresses issue [#43](https://github.com/jonasbn/perl-workflow/issues/43), there is more work to be done in this area, this will be adressed eventually

  By Jonas Brømsø (@jonasbn)

- Requirement for Perl 5.14 has been made more explicit, see also PR [#185](https://github.com/jonasbn/perl-workflow/pull/185) by Erik Huelsmann (@ehuelsmann)

- Delay of instantation, prevents additional loggings attempts, this makes logging less noisy when running tests. Via PR [#174](https://github.com/jonasbn/perl-workflow/pull/174) from Erik Huelsmann (@ehuelsmann)

## 1.57 2021-10-17 Bug fix release, update recommended

- PR [#170](https://github.com/jonasbn/perl-workflow/pull/170) by @ehuelsmann addresses an issue where Workflow tries to log during the execution of `use` statements, at which time it's highly unlikely that the logger has already been initialized, resulting in warnings being printed on the console

- PR [#171](https://github.com/jonasbn/perl-workflow/pull/171) by @ehuelsmann adds initialization of context parameters passed at instantiation; currently, parameters need to be added explicitly and individually after instantiation

- PR [#173](https://github.com/jonasbn/perl-workflow/pull/173) by @ehuelsmann addresses issue [#172](https://github.com/jonasbn/perl-workflow/pull/172), fixing failure to automatically run actions from the `INITIAL` state

## 1.56 2021-07-28 Bug fix release, update recommended

- PR [#139](https://github.com/jonasbn/perl-workflow/pull/139) by @ehuelsmann addresses an issue introduced in 1.55, where action configurations would contain unnecessary information

- Elimination of global state, with improved abstraction the complexity could be removed via PR [#140](https://github.com/jonasbn/perl-workflow/pull/140) by @ehuelsmann

- PR [#141](https://github.com/jonasbn/perl-workflow/pull/141) improves test suite, following up on PR [#131](https://github.com/jonasbn/perl-workflow/pull/131) by @ehuelsmann

- PR [#132](https://github.com/jonasbn/perl-workflow/pull/132) by @ehuelsmann follows up on issue [#129](https://github.com/jonasbn/perl-workflow/issues/129) by improving documentation on group property of Workflow::Action

- Elimination of warning about undefined value, which surfaced with release 1.55, adressed with PR [#135](https://github.com/jonasbn/perl-workflow/pull/135) by @ehuelsmann

- PR [#131](https://github.com/jonasbn/perl-workflow/pull/131) by @ehuelsmann documents the importance of overriding `init` for processing of parameters and not using `new`

- PR [#130](https://github.com/jonasbn/perl-workflow/pull/130) bu @ehuelsmann addresses issue [#129](https://github.com/jonasbn/perl-workflow/issues/129), respects encapsulation by adhering to the API

- Improves some error and log messages via PR [#128](https://github.com/jonasbn/perl-workflow/pull/128) by @ehuelsmann

## 1.55 2021-07-09 Minor feature release, update not required

- PR [#119](https://github.com/jonasbn/perl-workflow/pull/119) by @ehuelsmann adds capability of configuring custom workflow classes addressing issue [#107](https://github.com/jonasbn/perl-workflow/issues/107)

- Simplified logging handing in code base via PR [#108](https://github.com/jonasbn/perl-workflow/pull/108) by @ehuelsmann. Investigation into possible performance issue described in [#89](https://github.com/jonasbn/perl-workflow/issues/89) determined penalty to be insignificant

- `Workflow::State->get_conditions()` now returns all conditions, fixed via PR [#122](https://github.com/jonasbn/perl-workflow/pull/122) by @ehuelsmann addressing issue [#121](https://github.com/jonasbn/perl-workflow/issues/121), This fix actually implements, what is documented, but if you rely on previously undocumented behaviour, you might need to evaluate this fix

- Issue with broken support action attribute specified in the state config has been addressed via PR [#123](https://github.com/jonasbn/perl-workflow/pull/123) by @ehuelsmann described in issue [#113](https://github.com/jonasbn/perl-workflow/issues/113)

- A warning emitted from the test suite has been addressed via PR [#115](https://github.com/jonasbn/perl-workflow/pull/115) by @ehuelsmann

- A timing issue observed with the Travis CI setup have been addressed in PR [#112](https://github.com/jonasbn/perl-workflow/pull/112) by @ehuelsmann

## 1.54 2021-04-25 Minor feature release, update not required

- The existing private API: `Workflow->_get_action()` has been made public as: `get_action()` via PR [#56](https://github.com/jonasbn/perl-workflow/pull/56) by @ehuelsmann addressing issue [#54](https://github.com/jonasbn/perl-workflow/issues/54), a private version is still available as `_get_action()` ensuring backwards compatibility. The change should improve and ease implementations where actions are consumed

- The existing methods: `fields()`, `optional_fields()` and `required_fields` have all been made public PR [#57](https://github.com/jonasbn/perl-workflow/pull/57) by @ehuelsmann addressing issue [#55](https://github.com/jonasbn/perl-workflow/issues/55) these methods provide information a UI or other consumer of the workflow could use for user interaction as for issue [#54](https://github.com/jonasbn/perl-workflow/issues/54) and PR: [#56](https://github.com/jonasbn/perl-workflow/pull/56) mentioned above

- The implementation of caching for evaluation of nested has been revisted and improved via PR [#90](https://github.com/jonasbn/perl-workflow/pull/90) by @ehuelsmann

- A minor issue has been corrected in the documentation was corrected via PR [#111](https://github.com/jonasbn/perl-workflow/pull/111) by @ehuelsmann, it seems some design ideas had snuck into the documentation a long time ago, without ever being implemented

## 1.53 2021-04-09 Minor feature release, update not required

- This release changes logging granularity: instead of using the Log::Log4perl root logger for all logging output, use the instance class for logging in object methods as recommended [in the Log4perl documentation](https://metacpan.org/pod/Log::Log4perl#Pitfalls-with-Categories). This change allows logging from workflow to be suppressed in your application by changing the logging level for the `Workflow` category by setting `log4perl.category.Workflow = OFF` in your logging configuration. Please note that if you created classes derived from Workflow, the logger will use those class names as categories. To suppress output entirely, those categories need their own logging configuration.
  **NOTE** This change adds a `log()` accessor to the "Workflow::Base" class. If you implement your own `log()` accessor or method, please take care to make it return a valid logger instance before calling `SUPER::new()` so the logger is immediately available for logging. Please see PR: [#69](https://github.com/jonasbn/perl-workflow/pull/69) by @ehuelsmann

- PR [#101](https://github.com/jonasbn/perl-workflow/pull/101) by @jonasbn, changing confusing logging statements regarding observers having been added when none specified

- Added test cases covering Workflow::Exception [#102](https://github.com/jonasbn/perl-workflow/pull/102) by @jonasbn

## 1.52 2021-02-11 Bug fix release, update recommended

- Addressed bug/issue [#95](https://github.com/jonasbn/perl-workflow/issues/95) via PR [#96](https://github.com/jonasbn/perl-workflow/pull/96) by @ehuelsmann, the issue was introduced with PR [#85](https://github.com/jonasbn/perl-workflow/pull/85) by @ehuelsmann included in release 1.51

- Improvements to Dist::Zilla config, only ExtUtils::MakeMaker supported via Dist::Zilla now. Module::Build support having been removed. See the [article by Neil Bowers](https://neilb.org/2015/05/18/two-build-files-considered-harmful.html) (NEILB) on the topic. Thanks to Karen Etheridge (ETHER) for information and link to the above-mentioned article (issue [#93](https://github.com/jonasbn/perl-workflow/issues/95), resolved via PR [#98](https://github.com/jonasbn/perl-workflow/pull/98) by @jonasbn)

- Documentation in `INSTALL` file updated, the information was somewhat scarce and outdated (issue [#92](https://github.com/jonasbn/perl-workflow/issues/92), resolved via PR [#99](https://github.com/jonasbn/perl-workflow/pull/99) by @jonasbn)

- Some URLs fixed via PR [#97](https://github.com/jonasbn/perl-workflow/pull/97), thanks to Michiel W. Beijen (@mbeijen) for the contribution

- More unit-tests added via PR [#94](https://github.com/jonasbn/perl-workflow/pull/94), continued work on issue [#36](https://github.com/jonasbn/perl-workflow/pull/94) by @jonasbn improving test coverage

## 1.51 2021-01-31 Bug fix release, update recommended

- Addressed bug/issue [#10](https://github.com/jonasbn/perl-workflow/issues/10) of failing observers test, ref PR [#61](https://github.com/jonasbn/perl-workflow/pull/61). Documentation also updated accordingly via PR [#66](https://github.com/jonasbn/perl-workflow/pull/66)

- PR [#86](https://github.com/jonasbn/perl-workflow/pull/86) reverts fix to issue [#10](https://github.com/jonasbn/perl-workflow/issues/10) introduced in release 1.49

- PR [#85](https://github.com/jonasbn/perl-workflow/pull/85) addressing bug with use of database fields in persister

- Adressed bug/issue [#72](https://github.com/jonasbn/perl-workflow/issues/72) (_reopened_) and [#73](https://github.com/jonasbn/perl-workflow/issues/73) via PR [#74](https://github.com/jonasbn/perl-workflow/pull/74)

- Improved test coverage, addressing issue [#36](https://github.com/jonasbn/perl-workflow/issues/36) (_not closed_), ref PRs:

  - [#80](https://github.com/jonasbn/perl-workflow/pull/80)
  - [#81](https://github.com/jonasbn/perl-workflow/pull/81)
  - [#91](https://github.com/jonasbn/perl-workflow/pull/91)

- Cleaned POD formatting, PR [#83](https://github.com/jonasbn/perl-workflow/pull/83)

- Removed SVN/CVS legacy tags and adjusted shebang lines, PR [#82](https://github.com/jonasbn/perl-workflow/pull/82)

- Change log converted from plain text to Markdown, PR [#76](https://github.com/jonasbn/perl-workflow/pull/76)

- Added missing contributor Mohammad S Anwar to ACKNOWLEDGEMENT section, contribtution was included in release 1.49

- [#70](https://github.com/jonasbn/perl-workflow/pull/70), corrections to documentation on persisters

- [#71](https://github.com/jonasbn/perl-workflow/pull/71) added a missing point to the change log for release 1.50

- PR [#65](https://github.com/jonasbn/perl-workflow/pull/65), converting two older text files to Markdown. Documentation rewrite is being considered and improvements and additions will be made in this area in the future

- PR [#67](https://github.com/jonasbn/perl-workflow/pull/67) converting tabs to spaces

## 1.50 2021-01-25 Bug fix release, update not required

- Removal of unused dependency: Log::Dispatch, PR [#64](https://github.com/jonasbn/perl-workflow/pull/64)

- Perl::Critic annotations addressed, enabled a few Perl::Critic tests, PR [#58](https://github.com/jonasbn/perl-workflow/pull/58) and [#59](https://github.com/jonasbn/perl-workflow/pull/59)

- Cleared out VSCode configuration file from distribution

- Removed obsolete notes directory containing older coverage reports, now covered by Coveralls.io, PR [#63](https://github.com/jonasbn/perl-workflow/pull/63)

- Removed obsolete prototypes directory containing minor examples for code constructs, PR [#62](https://github.com/jonasbn/perl-workflow/pull/62)

- Addressed reports of failling tests from CPAN-testers for release 1.49, test suite now supports being run without `PERL_USE_UNSAFE_INC`, PR [#53](https://github.com/jonasbn/perl-workflow/pull/53), addressing issue [#52](https://github.com/jonasbn/perl-workflow/issues/52)

- Implementation of workaround for issue [#10](https://github.com/jonasbn/perl-workflow/issues/10) with the failing observers, this is expected to be readdressed, as the observer implementation will be revisited, PR [#60](https://github.com/jonasbn/perl-workflow/pull/60)

- Stop requiring a DSN to be configured when the DBI handle is sourced from elsewhere; instead, require a `driver` attribute to be specified, PR [#51](https://github.com/jonasbn/perl-workflow/pull/51)

## 1.49 2021-01-12 Minor feature release, update not required

- Addressed an issue with return values from Workflow::Condition::GreedyOR's `evaluate_condition`, PR [#50](https://github.com/jonasbn/perl-workflow/pull/50) from Erik Huelsmann

- Fixed a bug in condition caching described in issue [#9](https://github.com/jonasbn/perl-workflow/issues/9), PR [#27](https://github.com/jonasbn/perl-workflow/pull/27) from Erik Huelsmann

- Cleaned up some TODO items, PR [#41](https://github.com/jonasbn/perl-workflow/pull/41), all TODO items migrated to issues

- Fixed a bug in Workflow::Condition::LazyAND with wrongful return values, PR [#40](https://github.com/jonasbn/perl-workflow/pull/40) from Erik Huelsmann

- Fixed a bug in Workflow::Validator::InEnumeratedType with wrongful naming, PR [#39](https://github.com/jonasbn/perl-workflow/pull/39) from Erik Huelsmann

- Updated Dist::Zilla configuration and added LICENSE file to repository based on generated from Dist::Zilla build, this should be automated like the README generation at some point

- Improved internal handling for quoting in internal SQL statements, PR [#30](https://github.com/jonasbn/perl-workflow/pull/30) from Erik Huelsmann

- Improved the SQL used for database creation by adding referentiel integrity, PR [#29](https://github.com/jonasbn/perl-workflow/pull/29) from Erik Huelsmann

- Improved loading of external of a few dependencies, improving error handling, PR [#31](https://github.com/jonasbn/perl-workflow/pull/31) from Erik Huelsmann

- Addressed a bug in initialization and improved the ability to handle a database handle, PR [#32](https://github.com/jonasbn/perl-workflow/pull/32) from Erik Huelsmann

- Additions to test suite, WIP on better scoped condition caching, PR [#26](https://github.com/jonasbn/perl-workflow/pull/26) from Erik Huelsmann

- Minor feature addition addressing issue [#5](https://github.com/jonasbn/perl-workflow/issues/5) with condition caching, PR [#25](https://github.com/jonasbn/perl-workflow/pull/25) from Erik Huelsmann

  Condition caching can be disabled by setting:

  ```perl
  $Workflow::Condition::CACHE_RESULTS = 0; # false
  ```

  The default is `1`, indicating true,

- Improvements to test suite, moved from time to counter, speeding up the test, PR [#24](https://github.com/jonasbn/perl-workflow/pull/24) from Erik Huelsmann

- Documentation updates, PR [#23](https://github.com/jonasbn/perl-workflow/pull/23) from Erik Huelsmann

- Addressing issue [#21](https://github.com/jonasbn/perl-workflow/issues/21) fixing broken URLs, PR [#22](https://github.com/jonasbn/perl-workflow/pull/22) from Erik Huelsmann

- Fix to POD errors reported by CPANTS, ref: PR [#20](https://github.com/jonasbn/perl-workflow/pull/20) from Mohammad S Anwar

## 1.48 2019-09-05 Bug fix release, update not required

- Eliminated warning emitted from test run. Issue [#14](https://github.com/jonasbn/perl-workflow/issues/14) reported by Petr Pisar

## 1.47 2019-09-05 Bug fix release, update not required

- Accidently included cartons local directory in the distribution tar-ball. Issue [#17](https://github.com/jonasbn/perl-workflow/issues/17) reported by Tina Müller (tinita)

## 1.46 2019-05-28 Bug fix release, update not required

- Patch from Oliver Welter, addressing issue with greedy join handling error message, ref: PR [#16](https://github.com/jonasbn/perl-workflow/pull/16)

## 1.45 2017-06-29 Maintenance release, update not required

- Addressing issue [#13](https://github.com/jonasbn/perl-workflow/issues/13), moved Data::UUID from recommendations to prerequisites/requirements section

## 1.44 2017-06-28 Maintenance release, update recommended

- Yet another PR from Oliver Welter providing improvements to exception
  handling in relation to condition validation

- Exchanged use of: [Dist::Zilla::Plugin::GitHub::Meta](https://metacpan.org/pod/Dist::Zilla::Plugin::GitHub::Meta) for [Dist::Zilla::Plugin::GithubMeta](https://metacpan.org/pod/Dist::Zilla::Plugin::GithubMeta)
  to specify a proper homepage attribute

## 1.43 2017-06-02 Maintenance release, update recommended

- PR from Oliver Welter providing improvements to logging in relation to
  condition validation, ref: PR [#11](https://github.com/jonasbn/perl-workflow/pull/11)

- Exchanged CJM´s:
  [Dist::Zilla::Plugin::VersionFromModule](https://metacpan.org/pod/Dist::Zilla::Plugin::VersionFromModule)

  For Dave Rolskys:
  [Dist::Zilla::Plugin::VersionFromMainModule](https://metacpan.org/pod/Dist::Zilla::Plugin::VersionFromMainModule)

  There are some deprecation notices from Dist::Zilla making tests fail
  see XDG's [PR](https://github.com/madsen/dist-zilla-plugins-cjm/pull/5)

## 1.42 2015-09-06 Maintenance release, update not required

- Release migrated from [Module::Build](https://metacpan.org/pod/Module::Build) to [Dist::Zilla](https://metacpan.org/pod/Dist::Zilla)

- All version numbers aligned, so traceability to distribution is more
  transparent, this is a best practice and since we hold a lot of modules
  it makes sense to do this

## 1.41 2014-08-15 Maintenance release, update not required

- Fixed POD issue with encoding, so we now support UTF-8 for authors names

- Minor POD fix by dtikhonov to POD introduced in 1.40, ref: PR [#3](https://github.com/jonasbn/perl-workflow/pull/3)

- Adjusted permissions on some files, which were executable for no apparent reason

## 1.40 2014-06-01 Bug fix release, update recommended

- Update recommended due to bug fix by dtikhonov in observer handling

- Merged pull request from dtikhonov holding a bug fix in observer handling and a feature enabling attribute validation for actions, see the POD added to Workflow::Action, ref: PR [#2](https://github.com/jonasbn/perl-workflow/pull/2)

- Cleaned up the `Build.PL` file

- Repository migrated from SourceForge, Subversion to git (Github)

## 1.39 2013-08-02 Maintenance release, update not required

- Fixed up Changes file as part of my Questhub quest adhering to the standard
  described in: [CPAN::Changes::Spec](https://metacpan.org/module/CPAN::Changes::Spec)

## 1.38 2013-07-07 Bug fix release, update recommended

- Patch to minor bug where Workflow history did not set proper timezone in Workflow::Persister::DBI, ref: [RT:85380](https://rt.cpan.org/Ticket/Display.html?id=85380)

- Added information on issue with Perl 5.8.8 in the INCOMPATIBILITIES section

- Updated ACKNOWLEDGEMENTS section

- Corrected some minor POD issues

## 1.37 2013-07-03 Bug fix release, update recommended

- Added patch from Heiko Schlittermann fixing an issue with serialization of context (was evaluated as release 1.35_1), ref: [RT:64940](https://rt.cpan.org/Public/Bug/Display.html?id=64940)

## 1.36 2013-07-02  Bug fix release, update recommended

- Update recommended if you use release 1.35

- Applied minor patch from Oliver Welter following up on the custom workflow patch in release 1.35

## 1.35 2012-11-08 Maintenance release, update not required

- Applied patches from Scott Hardin implementing lazy evaluation of conditions

- Applied patch from Oliver Welter implementing support for multiple factories, ref: [RT:18159](https://rt.cpan.org/Public/Bug/Display.html?id=18159)

- Added patch from Oliver Welter implementing the feature of creating custom workflow classes, in addition a patch to silence some warning emitted during test from Workflow::Validator

- Added patch from Scott Hardin implementing nested conditions

- Added patch from Steven van der Vegt implementing autorun for the INITIAL state, ref: [RT:52841](https://rt.cpan.org/Public/Bug/Display.html?id=52841)

- Added patch from Steven van der Vegt, improving the reporting on validation exceptions, ref: [RT:52862](https://rt.cpan.org/Ticket/Display.html?id=52862)

- Eliminated README and migrated information into the main POD and introduced INSTALL file for the installation relevant information. README is now generated from the main POD by Build.PL

## 1.34 2010-08-06 Bug fix release, update not required

- Implemented work-around for [RT:53909](https://rt.cpan.org/Ticket/Display.html?id=53909)

  The issue demonstrated here, which can be observed in perl versions newer than 5.10.0 seems to be related to [RT:70171](http://rt.perl.org/rt3/Public/Bug/Display.html?id=70171):

  [RT:53909](https://rt.cpan.org/Public/Bug/Display.html?id=53909) is based on blead perl, in which also a fix has now been implemented, but we still have issues with a lot of perl releases currently out there, see [tests of release 1.33_1](http://matrix.cpantesters.org/?dist=Workflow+1.33)

  So this work-around seems to fix the issue, since I can no longer replicate the error. The problem seem to be the clearing of a package scoped variable, the array @observations in `t/SomeObserver.pm`

- Fixed example application, it was relying on a test module in a broken way, a path processed using a regex was not reliable

## 1.33 2010-01-30 Bug fix release, update not required

- Patch from Ivan Paponov, bug in relation to action groups and use of default. Bumping up version of Workflow::Factory to 1.19 and Workflow::State to 1.15

- Patches from Alejandro Imass

  - Changed `@FIELDS` to `@PROPS` in Action.pm and InputField.pm for `mk_accesors` as FIELDS was very confusing with regard to action input fields.

  - Formalized Workflow::Action::new() as a public method with corresponding pod example.

  - Optional class property for Workflow::Action::InputField. Previously, public method new() made little sense if InputField always instantiates from Workflow::Action::InputField. Now fields can derive from custom class.

  - Updated pod to reflect the new formal abillity to add extra properties for actions and input fields.

  - With the ability to derive custom properties for classes and fields there is little need IMHO to define InputField "type" any further, but leave it implementation dependent. The rationale is that validators intrinsically define this. Updating pod accordingly.

- Patches from Thomas Erskine

  - Added 3 new accessors to Workflow::Factory:

    - `get_persister_for_workflow_type`
    - `get_persisters`
    - `get_validators`

  - Added check for existing context so context is not overwritten if existing, fixing a bug. Version bumped up to 1.19

  - Fixing bug in Workflow::Persister::File, adding context parameters to serialization. Version bumped up to 1.11

  - Added return of empty list for accessor, in Workflow::Action. Version bumped up to 1.10

- Patches from Danny Sadinoff to following classes

  - Workflow::Config, bumped up to version 1.13
  - Workflow::Persister, bumped up to version 1.10
  - Workflow::Factory, bumped up to version 1.19

  - Adding ability to control initial state name via workflow config

  - Adding ability to control initial history record details via Persister subclass code

- Addressing a bug reported by Sergei Vyshenski, related to a possible API breakage. Please refer to `t/add_config_bug.t`, which demonstrates the presence of the bug in 1.32 and it's absence in 0.31. Workflow::Factory bumped up to version: 1.19

- Applied patch from Andrew O'Brien implementing dynamic loading of config files [RT:18265](http://rt.cpan.org/Public/Bug/Display.html?id=18265). Bumped up version for Workflow::Factory to 1.19

## 1.32 2009-01-26 Bug fix release, update not required

- Bumped up version for Workflow::State to 1.14 considering patches from action_group and test_condition patches from Ivan Paponov implementing support for a group tag on actions

- Addressing [RT:40750](http://rt.cpan.org/Ticket/Display.html?id=40750)

  Removed VERSION file, this has now been obsoleted

  We are now resolving the version number for the distribution from Workflow.pm the main module, this mean a jump from 0.31 to 1.32, but it does mean that an installation can be traced back to a given distribution

- Patch to implement proper dynamic names for conditions with a 'test' attribute, ref [RT:38024](http://rt.cpan.org/Ticket/Display.html?id=38024)

- Added List::MoreUtils to requirements, we use this for test, I have moved the test related modules to the build_requires section in Build.PL, so List::MoreUtils is not mistaken for an application level requirement

- Refactored two tests, to use List::MoreUtils all method (asserting presence of numerous actions)

- Fixed minor bug in error message in: Workflow::State, reported by Robert Stockdale, [RT:38023](http://rt.cpan.org/Public/Bug/Display.html?id=38023)

- We introduce a more fine grained control of the auto commit feature, implemented by Jim Brandt

- We introduce typed condition, implemented by Jim Brandt. Typed conditions makes it possible for different workflows to hold unique methods for workflow steps even with names colliding.

  Example workflow foo and bar can have a condition baz, but baz are two different implementations in foo and bar respectively

- time_zone parameter can now be passer around for use by the Workflow DateTime objects internally

## 0.31 2007-09-26 Bug fix release, update not required

- Fixed failing tests in t/persister_dbi.t, this has only observed twice and does not seem to be consistent. This is related to execution time for the test suite and the use of now, using the debugger would demonstrate this

  Resolves: [RT:29037](https://rt.cpan.org/Public/Bug/Display.html?id=29037)

- Cleaned TODO file a bit

- Added Data::Dumper requirement to Build.PL

## 0.30 2007-09-25 Bug fix release, update not required

- Added patch from Jim Brandt improving handling of date formats for real, the merge into 0.29 (see below) was not completed

  The patch also addresses [RT:29037](https://rt.cpan.org/Public/Bug/Display.html?id=29037)

  which is related to a report on a [failing test](http://www.nntp.perl.org/group/perl.cpan.testers/2007/08/msg582727.html)

## 0.29 2007-09-24  Maintenance release, update not required

- Added new test file: t/persister.t for Workflow::Persister

- Updated t/confition.t for better coverage

- Updated t/action.t for better coverage

- Updated t/validator.t for better coverage

- Updated Workflow::Action::Mailer (stub now can be tested, this might however prove to be a bad idea)

- Added new test file: t/action_mailer.t for Workflow::Action::Mailer

- Updated t/action_null.t for better coverage

- Added some more tests t/Config.t

## 0.28 2007-07-06 Maintenance release, update not required

- Removed TODO.txt, the files contents have long gone been merged into the TODO file

- Added a new file to the doc/ directory named developing.txt. This is a collection of documentation notes on maintaining and developing the Worksflow distribution

- Renamed Action::Mailer to Workflow::Action::Mailer, this however still looks like a stub that was never finished

- Added more POD to:

  - Workflow
  - Workflow::Action::InputField
  - Workflow::Action::Mailer
  - Workflow::Condition
  - Workflow::Condition::HasUser
  - Workflow::Config::XML
  - Workflow::Factory
  - Workflow::History
  - Workflow::Persister
  - Workflow::Persister::DBI
  - Workflow::Persister::DBI::ExtraData
  - Workflow::Persister::DBI::AutoGeneratedId
  - Workflow::Persister::DBI::SequenceId
  - Workflow::Persister::RandomId
  - Workflow::Persister::File
  - Workflow::Persister::SPOPS
  - Workflow::State
  - Workflow::Validator::HasRequiredField

    We now have a POD coverage of 100%, this does however not say anything about the quality of the spelling or POD. All POD will however be revisited at some point

    Please remember to document changes and additions

- Implemented conditional tests in `t/00_load.t` for SPOPS and UUID. These are conditional in their own tests, so this should of course be reflected in `t/00_load.t`

  This should address the [report on a failing test](http://www.nntp.perl.org/group/perl.cpan.testers/2007/07/msg527994.html)

- Added missing version number to Workflow::Persister (1.09), the PAUSE indexer complained over degrading version number, investigating consequences

  No apparent consequences

## 0.27 2007-07-03 Bug fix release, update not required (see note below)

- Update not required unless you are using 0.26 or 0.25

- Fixed bug in cached condition handling (0.26 reintroduced the original race condition that was solved using the condition cache in 0.25). Condition cache is now cleared on state change and when calling get_available_action_names()

- Updated some tests, nothing serious we are just on the way to better test coverage and documentation

- Added more POD to:

  - Workflow::Action
  - Workflow::Exception
  - Workflow::Persister::RandomId.pm
  - Workflow::Persister::UUID.pm
  - Workflow::Validator::MatchesDateFormat
  - Workflow::Validator::InEnumeratedType

- Added more tests of Workflow::Validator::MatchesDateFormat to `t/validator_matches_date_format.t`

- Added more tests of Workflow::Validator::InEnumeratedType to `t/validator_in_enumerated_type.t`

- Small fix to a test on an empty array. Empty arrays evaluate to false t/config.t, cleaned some code in Workflow::Config and Workflow::Config::Perl nothing significant

- Hard coded version numbers to all modules in t/ Subversion uses different scheme so we no longer use automatically updated version numbers, added version 0.01 where no version was present

- Hard coded version numbers to all modules in `eg/`

  Subversion uses different scheme so we no longer use automatically updated version numbers, added version 0.01 where no version was present

- Eliminated warning in Workflow::Factory, in check for FACTORY parameter

- Added t/00_load.t, de facto usage syntax test catches compilation errors etc.

- Applied patch from Jim Brandt to Workflow::Config::XML, the patch helps to catch bad XML

  Updated version to 1.05

- Hard coded latest versions from CPAN to all modules, Subversion uses different scheme so we no longer use automatically updated version number.

  - Action::Mailer 1.01
  - Workflow 1.32
  - Workflow::Action 1.09
  - Workflow::Action::InputField 1.09
  - Workflow::Action::Null 1.03
  - Workflow::Base 1.08
  - Workflow::Condition 1.07
  - Workflow::Condition::Evaluate 1.02
  - Workflow::Condition::HasUser 1.05
  - Workflow::Config 1.11
  - Workflow::Config::Perl 1.02
  - Workflow::Config::XML 1.04
  - Workflow::Context 1.05
  - Workflow::Exception 1.08
  - Workflow::Factory 1.18
  - Workflow::History 1.09
  - Workflow::Persister 1.09
  - Workflow::Persister::DBI 1.19
  - Workflow::Persister::DBI::AutoGeneratedId 1.06
  - Workflow::Persister::DBI::ExtraData 1.05
  - Workflow::Persister::DBI::SequenceId 1.05
  - Workflow::Persister::File 1.10
  - Workflow::Persister::RandomId 1.03
  - Workflow::Persister::SPOPS 1.07
  - Workflow::Persister::UUID 1.03
  - Workflow::State 1.13
  - Workflow::Validator 1.05
  - Workflow::Validator::HasRequiredField 1.04
  - Workflow::Validator::InEnumeratedType 1.04
  - Workflow::Validator::MatchesDateFormat 1.06

- Fixed a problem in t/workflow.t which rely on DBI. DBI is not necessarily present, since this is not a requirement (DBD::Mock is), so I have made the test conditional as to whether DBI is installed as for some of the other tests.

  This should address the 'N/A' status of the [test report](http://www.nntp.perl.org/group/perl.cpan.testers/2007/05/msg492425.html)

- Updated MANIFEST

- Added `t/03_pod-coverage.t`, de facto POD coverage test, set the environment variable `TEST_POD` to enable the test

  Currently we have BAD POD coverage so the test fails.

- Added t/02_pod.t, de facto POD syntax test, set the environment variable TEST_POD to enable the test

## 0.26 2007-03-07 Bug fix release, update not required, see note below

- Update not required unless you are using 0.25

- Fixed bug in cached condition handling. The condition cache is now cleared before checking conditions so that the condition results are not taken from the cache when entering the same state again

- Fixed small bug in the error message when autorunning is enabled but more than one action is available (now displays the names of these actions correctly)

## 0.25 2006-12-14 Feature release, update not required

- Applied patch from Alexander Klink via [#23736](https://rt.cpan.org/Public/Bug/Display.html?id=23736). Introduces caching of the result of a condition's evaluate()

## 0.24 2006-12-14 Feature release, update not required

- Applied patch from Alexander Klink via [#23925](https://rt.cpan.org/Public/Bug/Display.html?id=23925). Introduces may_stop property for autorunning workflow

  This is why this patch introduces the "may_stop" property for a state, which means that Workflow won't complain if the state is autorun and no or too many activities are present.

## 0.23 2006-09-12 Feature release, update not required

- Applied patch from Michael Bell via [#21100](https://rt.cpan.org/Public/Bug/Display.html?id=21100). Fixes problem with handling of 0 and empty strings as parameters

- Applied patch from Michael Bell via [#21101](https://rt.cpan.org/Public/Bug/Display.html?id=21101). Fixes problem with deletion of parameters

- Applied yet another patch from Michael Bell via [#21099](https://rt.cpan.org/Public/Bug/Display.html?id=21099). The patch fixes some misinforming POD

- Applied patch from Alexander Klink via [#21422](https://rt.cpan.org/Public/Bug/Display.html?id=21422). The patch implement more powerful observers

## 0.22 2006-08-18 Feature release, update not required

- Applied patch from Michael Bell via [#20871](https://rt.cpan.org/Public/Bug/Display.html?id=20871), this patch also contains the patch mentioned below.

- Applied patch to Workflow::Action from Michael Bell, fixing two bugs

- Changed POD format to accomodate for Pod::Coverage, where `B<>` is not recognised, but `=head<1..3>` and `=item` is

  So subs are now marked with head3 instead of `B<>`, I am of the opinion that titles should be marked as titles and `B<>` (bold) should be used to emphasize important information in the POD.

## 0.21 2006-07-07 Bug fix release, update not required

- Fixed bug reported by Martin Bartosch, Workflow::Context's merge method did not work properly, applied patch from Martin

- Updated `t/context.t` to test the above fix, this got the coverage from 53.3 percent to 93.3

## 0.20 2006-07-07 Bug fix release, update not required

- Fixed bug reported by Martin Bartosch, Workflow::Factory's add_config_from_file now takes an array ref as stated in the POD.

- Updated t/factory.t to test the above fix, just using the scenarios from the SYNOPSIS. This fix did however not contribute to the coverage of Workflow::Factory, we lost 0.3 percent along the way going from 88.7 to 88.4

- Fixed two POD errors in Workflow::Config

## 0.19 2006-07-07 Bug fix release, update not required

- The 0.18 release contained a broken Makefile.PL, thanks to Randal Schwartz for sending me the feedback to get this addressed immediately.

## 0.18 2006-07-07 Maintenance release, update not required

- New maintainer, JONASBN has taken over maintenance of Workflow

- Added maintainer information to Workflow.pm

- Added new TODO file

- Added a handful of tests to `t/config.t` and added dependency on Test::Exception

- Somewhat applied patch from Chris Brown, the use of Perl as configuration was broken, in my attempt to implement tests prior to applying Chris Browns patch I accidently fixed the same problems it addressed.

  Coverage of Workflow::Config::Perl has gone from 0 to 89.0 with this release

- Added new files (for test):

  - `t/workflow.perl`
  - `t/workflow_action.perl`
  - `t/workflow_condition.perl`
  - `t/workflow_errorprone.perl`
  - `t/workflow_validator.perl`

- Added POD to Workflow::Config::Perl on parse method

- Added CVS id keywords and author information to README

- Added CVS id keywords and author information to .txt files in doc

## 0.17 2005-11-30

lib/Workflow/Persister/DBI.pm:

- fix dumb typo that resulted in PostgreSQL getting a random-ID
  generator instead of a sequence-ID generator, thanks to Michael
  Graham for pointing it out

## 0.16 2005-11-29

- META.yml

  - [RT:12360](http://rt.cpan.org/Ticket/Display.html?id=12360): Added 'no_index' section so demo modules don't get indexed; thanks to Adam Kennedy for report and fix.

- lib/Workflow.pm:

  - [RT:14413](http://rt.cpan.org/Ticket/Display.html?id=14413): Added workflow object to
     Workflow::State->get_autorun_action_name() call; thanks to Jonas
     Nielsen for report and fix.

- lib/Workflow/Factory.pm:

  - [RT:12361](http://rt.cpan.org/Ticket/Display.html?id=12361): Add documentation about return values/exceptions from add_config() and add_config_from_file(); thanks to Adam Kennedy for report.

- lib/Workflow/Persister/DBI.pm:

  - POTENTIAL BACKWARD INCOMPATIBILITY:

  - Change 'user' field in history table to 'workflow_user' so we don't collide with PostgreSQL reserved word. (It's probably reserved elsewhere too...) If you have existing workflow tables you'll want to ALTER them to the new fieldname or look at the next changeitem to customize the field names.

  - Make the workflow and history fields settable by subclassing the persister -- just define 'get_workflow_fields()' and 'get_history_fields()' and return the names you want in the order specified in the docs. Thanks to Michael Graham for the nudge.

  - Be sure to pass in the database handle to the pre_fetch ID generator in create_workflow() (related to [RT:15622](http://rt.cpan.org/Ticket/Display.html?id=15622))

  - [RT:15622](http://rt.cpan.org/Ticket/Display.html?id=15622): While we didn't apply this patch we did cleanup some of the similar code....

  - Apply patch from Frank Rothhaupt to work with Oracle sequences.

- lib/Workflow/Persister/DBI/SequenceId.pm:

  - Throw proper exception if we cannot execute the sequence SQL.

## 0.15 2004-10-17

- CPAN/Install notes:

  - You should now be able to reference the Workflow module via CPAN with 'install Workflow' and such. Thanks to Michael Schwern (RT bug #8011) and the PAUSE indexing server for the reports.

  Also thanks to Michael Roberts for releasing the 'Workflow' namespace to this module. If you're interested in workflows I strongly encourage you to check out his [wftk](http://www.vivtek.com/wftk.html) (Workflow Toolkit) project along with the Perl interface when it's released.

- Build.PL/Makefile.PL:

  - Add Class::Factory as dependency. Thanks to Michael Schwern for the pointer via [RT:8010](http://rt.cpan.org/Ticket/Display.html?id=8010)) -- during my presentation to pgh.pm on the Workflow module no less! (I added a reference to the presentation in README and Workflow.pm)

  - Add Class::Observable as dependency for new functionality.

- eg/ticket/ticket.pl:

  - Ensure we actually delete the SQLite database file if it exists.

- t/TestUtil.pm:

  - Always store the logfile from testing in the 't/' directory.

- Workflow:

  - Workflows are now observable. Big thanks to Tom Moertel <tmoertel@cpan.org> for the suggestion. See WORKFLOWS ARE OBSERVABLE in docs.

  - In previous versions most properties were read-only but it wasn't enforced. Now it is.

- Workflow::Factory:

  - Add the ability to register observers from the 'workflow' configuration and add them to workflows created from fetch_workflow() and create_workflow(). Configuration information available in Workflow.pm.

## 0.10 2004-10-12

- Workflow

  - POTENTIAL BACKWARD INCOMPATIBILITY

    - Since we've now got 'resulting_state' in a state's action that is dependent on the action results of the previous action being run (see Workflow::State change), we cannot set the 'new' workflow state before executing the action.

    - One result: you shouldn't set the 'state' property of any created Workflow::History objects -- we'll modify the state of any history objects with an empty state before saving them (see changes for Workflow::Factory)

    - Another result: the value of '$wf->state' inside your  Action now refers to the EXISTING state of the workflow not the SOON TO BE state. Earlier versions had the SOON TO BE state set into the workflow before executing the action to make things less confusing. Now that it's changed any code you have using the state of the workflow (such as in our example 'Trouble Ticket' application in eg/ticket/) will give a different value than the previous Workflow version.

    - This behavior seems more consistent, but comments/suggestions are welcome.

  - In 'execute_action()' -- once we're done executing the main action, check to see if our new state is an autorun state, and if so run it.

- Workflow::Action::Null

  - New class: use if you want to move the workflow from one state to another without actually doing anything.

- Workflow::Condition::Evaluate

  - New class: allow inline conditions expressed as Perl code in the 'test' attribution of 'condition'; has access to the values in the current workflow context in a Safe compartment.

- Workflow::Factory

  - In save_workflow(), call 'set_new_state()' with the workflow
     state on all unsaved Workflow::History objects before saving them.

- Workflow::State

  - Add 'autorun' property and 'get_autorun_action_name()' to retrieve the single valid action name available from an autorun state.

  - The 'resulting_state' property of an action within a state can now be multivalued, which means the next state depends on the return value of the action that's executed. For instance, we might have:

  ```xml
     <state name="create user">
         <action name="create">
           <resulting_state return="admin"    state="assign as admin" />
           <resulting_state return="helpdesk" state="assign as helpdesk" />
           <resulting_state return="*"        state="assign as luser" />
         </action>
        ....
  ```

  - So if the action 'create' returns 'admin', the new state will be 'assign as admin'; on 'helpdesk' it will be 'assign as helpdesk', and all other values will go to state 'assign as luser'.

  - Existing behavior (actions returning nothing for a single 'resulting_state') is unchanged.

## 0.05 2004-09-30

- Workflow::Persister::DBI

  - Trying to fetch a workflow with a non-existent ID didn't work properly, returning an empty workflow object (which blew up when you tried to call a method on it) instead of undef (as documented). Thanks to Martin Winkler <mw@arsnavigandi.de> for pointing the problem out.

## 0.04 2004-09-12

- eg (example application):

  - Add CGI interface ('ticket.cgi') to example application, and move most of the logic into App::Web, which is now a full object instead of a bunch of class methods. Both the standalone web server ('ticket_web.pl') and the CGI script use the same logic, templates, template processing, etc.

- Workflow::Config

  - Move Perl/XML configuration parsers to separate classes and make this class a factory.

  - Add class method 'parse_all_files()' to allow you to pass in a list of mixed-type files (some XML, some Perl) and have them be parsed properly.

  - Add documentation about implementing your own configuration reader

- Workflow::Config::Perl

  - New class: code moved from Workflow::Config for perl-only parsing

- Workflow::Config::XML

  - New class: code moved from Workflow::Config for XML-only parsing

- Workflow::Factory

  - Invoke class method in Workflow::Config to deal with potentially different types of configuration (e.g., mixing and matching 'xml' and 'perl' files).

- Workflow::Persister::DBI::AutoGeneratedId:

  - Fix typo bug spotted by Martin Winkler (winkler-martin@web.de)

## 0.03 2004-05-24

- Applied modified patches from Jim Smith (jgsmith@tamu.edu) to do the following:

  - Allow you to read in the XML/Perl configuration file from somewhere else and pass it to Workflow::Config as a scalar reference.

  - You can subclass Workflow::Factory and still use 'FACTORY' to import the factory of the class you want and 'instance()' to do the same.

- Added docs for these new features, and added tests for at least the factory subclassing feature.

## 0.02 2004-05-22

- Updates to test scripts and files they require from CPAN tester report -- thanks Barbie!

## 0.01 2004-05-13

- First CPAN release -- everything is new!
