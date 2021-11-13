#!/usr/bin/env perl

use strict;
use lib qw(t);
use Test::Exception;
use DateTime;
use Test::More;



require_ok( 'Workflow::Validator::MatchesDateFormat');

my $validator;
my $wf;

dies_ok { $validator = Workflow::Validator::MatchesDateFormat->new({}) } 'Constructor without parameters, we die';

dies_ok { $validator = Workflow::Validator::MatchesDateFormat->new({ date_format => bless {} }) } 'Constructor with bad parameters, we die';

lives_ok { $validator = Workflow::Validator::MatchesDateFormat->new({ date_format => '%Y-%m-%d' }) } 'Constructor with date_format provided, should succeed';

if (! $validator) {
    BAIL_OUT 'validator construction failed';
}

isa_ok($validator, 'Workflow::Validator');

lives_ok { $validator->validate($wf, '2005-05-13') } 'validating a legal date';

lives_ok { $validator->validate($wf, '2005-05-13') } 'validating a legal date';

lives_ok { $validator->validate($wf) } 'Validation without parameters, we live';

dies_ok { $validator->validate($wf, bless {}) } 'Validation with bad object, we die';

my $dt = DateTime->new(
    year   => 1964,
    month  => 10,
    day    => 16,
    hour   => 16,
    minute => 12,
    second => 47,
    nanosecond => 500000000,
    time_zone => 'Asia/Taipei',
);

lives_ok { $validator->validate($wf, $dt) } 'Validation of DateTime parameter, we live';

throws_ok( sub { $validator->validate($wf, '13-05-2005'); }, qr/Date '13-05-2005' does not match required pattern '%Y-%m-%d'/,
  'Exception, validation with non-conformant date parameter',
);

done_testing();
