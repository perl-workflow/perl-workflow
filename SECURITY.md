# Security Policy for the Workflow distribution

Report security issues privately via GitHub's "Report a vulnerability" button on
<https://github.com/perl-workflow/perl-workflow/security>, or by e-mail to
`<SECURITY-CONTACT-EMAIL>`.

This is the Security Policy for the CPAN distribution `Workflow`.

The latest version of this policy can be found in the
[repository](https://github.com/perl-workflow/perl-workflow/blob/master/SECURITY.md).

This text is based on the CPAN Security Group's Guidelines for Adding a Security
Policy to Perl Distributions (version 1.5.0)
<https://security.metacpan.org/docs/guides/security-policy-for-authors.html>

## How to Report a Security Vulnerability

Security vulnerabilities can be reported to the current project maintainers in
one of two ways:

- **GitHub private vulnerability reporting (preferred):** go to the
  [Security Advisories](https://github.com/perl-workflow/perl-workflow/security/advisories)
  page and click the "Report a vulnerability" button.
- **E-mail:** `<SECURITY-CONTACT-EMAIL>`, if you do not have, or do not
  want to use, a GitHub account.

Please include as many details as possible, including code samples or test
cases, so that we can reproduce the issue. Check that your report does not
expose any sensitive data, such as passwords, tokens, or personal information.

If you would like any help with triaging the issue, or if the issue is being
actively exploited, please copy the report to the CPAN Security Group (CPANSec)
at <cpan-security@security.metacpan.org>.

Please *do not* use the public issue tracker on GitHub for reporting security
vulnerabilities.

Please do not disclose the security vulnerability in public forums until past
any proposed date for public disclosure, or it has been made public by the
maintainers or CPANSec. That includes patches or pull requests.

For more information, see
[Report a Security Issue](https://security.metacpan.org/docs/report.html)
on the CPANSec website.

## Response to Reports

The maintainers are volunteers and aim to acknowledge your security report as
soon as possible. If you have not received a response within one week, please
send a reminder to the maintainers and copy the report to CPANSec at
<cpan-security@security.metacpan.org>.

Please note that the initial response to your report will be an acknowledgement,
with a possible query for more information. It will not necessarily include any
fixes for the issue.

The project maintainers may forward this issue to the security contacts for
other projects where we believe it is relevant. This may include embedded
libraries, system libraries, prerequisite modules or downstream software that
uses this software.

They may also forward this issue to CPANSec.

Vulnerabilities that are confirmed will be fixed in a new release to CPAN,
published as a [GitHub Security Advisory](https://github.com/perl-workflow/perl-workflow/security/advisories),
and a CVE will be requested via CPANSec where appropriate. Reporters will be
credited in the advisory and in `Changes.md`, unless they ask not to be.

## What Software This Policy Applies To

Any security vulnerabilities in `Workflow` are covered by this policy. This
includes all modules in the `Workflow` namespace shipped in this distribution,
such as the configuration parsers (`Workflow::Config::*`), the persisters
(`Workflow::Persister::*`), conditions, validators and actions.

Security vulnerabilities are considered anything that allows users to execute
unauthorised code, access unauthorised resources, or to have an adverse impact
on accessibility or performance of a system. For this distribution, that
includes, but is not limited to:

- Actions being executed although their guarding conditions should have
  prevented it.
- Injection via data handled by the persisters (e.g. SQL injection in
  `Workflow::Persister::DBI`, or path traversal in `Workflow::Persister::File`).
- Code execution through workflow configuration or condition evaluation
  beyond what is documented.

Security vulnerabilities in upstream software (prerequisite modules or system
libraries, or in Perl), are not covered by this policy unless they affect
`Workflow`, or `Workflow` can be used to exploit vulnerabilities in them.

Security vulnerabilities in downstream software (any software that uses
`Workflow`, or plugins to it that are not included with the `Workflow`
distribution, such as `Workflow::Persister::SPOPS`) are not covered by this
policy.

### Supported Versions of Workflow

Only the latest release of `Workflow` will be supported for security fixes.

The maintainers only commit to supporting versions of Perl that are tested in
the project's continuous integration, currently Perl 5.14 and newer. Note that
the maintainers may raise the minimum required Perl version (or the minimum
version of a prerequisite module) in order to fix a security issue.

## Installation and Usage Issues

The distribution metadata specifies minimum versions of prerequisites that are
required for `Workflow` to work. However, some of these prerequisites may have
security vulnerabilities, and you should ensure that you are using up-to-date
versions of these prerequisites.

Where security vulnerabilities are known, the metadata may indicate newer
versions as recommended.

Workflow configurations (XML, YAML or Perl) and custom action, condition,
validator and persister classes are treated as trusted code: they are written by
the application developer and loaded with the privileges of the application.
Loading configurations from untrusted sources is outside the scope of this
policy. `Workflow::Condition::Evaluate`, in particular, evaluates Perl
expressions from the configuration. It uses a `Safe` compartment, but `Safe` is
not a security boundary, so its `test` expressions must never come from
untrusted input.

Values passed into a workflow `Context` from end users should be validated with
validators before they are used by actions or persisted.
