ue 5.006;
use strict;
use warnings FATAL => 'all';
use inc::Module::Install;

name 'DBIx-Class-Report';
all_from 'lib/DBIx/Class/Report.pm';
author q{Curtis "Ovid" Poe <ovid@cpan.org>};
license 'artistic2';

perl_version 5.006;

tests_recursive('t');

resources(
    #homepage   => 'http://yourwebsitehere.com',
    #IRC        => 'irc://irc.perl.org/#DBIx-Class-Report',
    license => 'http://www.perlfoundation.org/artistic_license_2_0',

    #repository => 'git://github.com/Curtis "Ovid" Poe/DBIx-Class-Report.git',
    bugtracker =>
      'http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-Class-Report',
);

configure_requires(
    'Module::Install' => 0,
);

build_requires(
    'Test::More' => 0,
);

requires(
    'DBIx::Class' => '0.08210',
);

install_as_cpan;
auto_install;
WriteAll;
