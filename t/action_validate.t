# -*-perl-*-

# Test validation of additional action attributes during parse-time.

use strict;
use warnings;
use lib 't';
use TestUtil;
use Test::Exception;
use Test::More tests => 13;

my $config_invalid;         # Drives behavior of validation function
my $validation_called;
my @config_args;

{
    package My::Action::Validate;
    use base qw(Workflow::Action);
    use Workflow::Exception qw(configuration_error);
    sub execute {
        1;
    }
    sub validate_config {
        $validation_called++;
        @config_args = @_;
        my $config = shift;
        if ($config_invalid) {
            configuration_error "$config_invalid";
        }
    }
    $INC{'My/Action/Validate.pm'} = 1;
}

{
    package My::Action::Simple;
    use base qw(Workflow::Action);
    sub execute {
        1;
    }
    $INC{'My/Action/NoValidate.pm'} = 1;
}

my $factory = TestUtil->init_factory();
TestUtil->init_mock_persister();

# Create a simple workflow with a single action.  This action has an extra
# parameter which is validated at parse-time.

my %config = (
    workflow => {
        type            => 'TEST1',
        persister       => 'TestPersister',
        state           => [
            {
                name    => 'INITIAL',
                action  => [
                    {
                        name => 'begin',
                        resulting_state => 'END',
                    },
                ],
            },
            {
                name    => 'END',
            },
        ],
    },
    action => {
        action => [
            {
                name    => 'begin',
                class   => 'My::Action::Validate',
                param   => 123,       # Extra configuration parameter
            },
        ],
    },
);

# Don't catch exceptions for this method, let the whole test file fail
# if we cannot add_config.
$factory->add_config( %config );

# Sanity test first:
{
    my $wf = $factory->create_workflow('TEST1');
    ok($wf, "created workflow");
    lives_ok {
        $wf->execute_action('begin');
    } "successfully executed `begin'";
    is($wf->state, "END", "reached end state");
}

$Workflow::Factory::VALIDATE_ACTION_CONFIG = 1;

# Action is validated and validation routine returns OK
#
$config{workflow}{type}++;
lives_ok {
    $factory->add_config( %config );
} 'action config is valid';
ok($validation_called, 'validation routine called');
is($config_args[0]{param}, 123, "correct value passed to validation function");

# Action is validated and validation routine throws
#
undef $validation_called;
$config_invalid = "some funky error";
$config{workflow}{type}++;
throws_ok {
    $factory->add_config( %config );
} 'Workflow::Exception::Configuration', 'action config is in valid';
like($@, qr/$config_invalid/, "expected error string");
ok($validation_called, 'validation routine called');
is($config_args[0]{param}, 123, "correct value passed to validation function");

$Workflow::Factory::VALIDATE_ACTION_CONFIG = 0;

# Action is not validated
#
undef $validation_called;
$config{workflow}{type}++;
lives_ok {
    $factory->add_config( %config );
} 'action config is valid';
ok(not(defined($validation_called)), 'validation routine not called');

$Workflow::Factory::VALIDATE_ACTION_CONFIG = 1;

# Config loaded when VALIDATE_ACTION_CONFIG and validate_config() does
# not exist.
#
$config{action}{action}[0]{class} = 'My::Action::NoValidate';
lives_ok {
    $factory->add_config( %config );
} 'action config is valid';
