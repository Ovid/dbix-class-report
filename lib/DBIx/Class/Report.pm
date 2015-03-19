package DBIx::Class::Report;

use Moose;
use Carp;
use Digest::MD5 qw/md5_hex/;

has 'columns' => (
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    required => 1,
);

has 'sql' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'schema' => (
    is       => 'ro',
    isa      => 'DBIx::Class::Schema',
    required => 1,
);
has '_resultset' => (
    is  => 'rw',
    isa => 'DBIx::Class::ResultSet',
);

sub BUILD {
    my $self         = shift;
    my $schema_class = ref $self->schema;   # XXX There has to be a better way

    my $md5         = md5_hex( $self->sql );
    my $columns     = join ', ' => map {"'$_'"} @{ $self->columns };
    my $table       = "table_$md5";
    my $source_name = "View$md5";
    my $view_class  = $schema_class . "::$source_name";

    # XXX Again, I'll figure out something better after this hack
    eval <<"END_VIEW";
package $view_class;
use base 'DBIx::Class::Core';
$view_class->table_class('DBIx::Class::ResultSource::View');
$view_class->table("$table");
$view_class->add_columns($columns);
$view_class->result_source_instance->is_virtual(1);
$view_class->result_source_instance->view_definition(<<'END_SQL');
@{[$self->sql]}
END_SQL
END_VIEW
    croak $@ if $@;

    $self->schema->register_class( $source_name => $view_class );
    $self->_resultset( $self->schema->resultset($source_name) )
      ;    #->search({}, {bind => [2]})
}

sub fetch {
    my ( $self, @bind_params ) = @_;
    return $self->_resultset->search( {}, { bind => [@bind_params] } );
}

our $VERSION = '0.01';

=head1 NAME

DBIx::Class::Report - The great new DBIx::Class::Report!

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use DBIx::Class::Report;

    my $foo = DBIx::Class::Report->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

sub function1 {
}

=head2 function2

=cut

sub function2 {
}

=head1 AUTHOR

Curtis "Ovid" Poe, C<< <ovid at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dbix-class-report at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-Class-Report>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::Class::Report


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-Class-Report>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBIx-Class-Report>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx-Class-Report>

=item * Search CPAN

L<http://search.cpan.org/dist/DBIx-Class-Report/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 Curtis "Ovid" Poe.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1;    # End of DBIx::Class::Report
