package DBIx::Class::Report;

use Moose;
use Carp;
use Digest::MD5 qw/md5_hex/;
use namespace::autoclean;

our $VERSION = '0.01';

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

    my $md5             = md5_hex( $self->sql );
    my $table           = "table_$md5";
    my $source_name     = "View$md5";
    my $view_class      = $schema_class . "::$source_name";

    # XXX Again, I'll figure out something better after this hack
    eval <<"END_VIEW";
package $view_class;
use base 'DBIx::Class::Core';
END_VIEW
    croak $@ if $@;

    $view_class->table_class('DBIx::Class::ResultSource::View');
    $view_class->table($table);
    $view_class->add_columns( @{ $self->columns } );
    $view_class->result_source_instance->is_virtual(1);
    $view_class->result_source_instance->view_definition( $self->sql );

    $self->schema->register_class( $source_name => $view_class );
    $self->_resultset($self->schema->resultset($source_name));
}

sub fetch {
    my ( $self, @bind_params ) = @_;
    return $self->_resultset->search( {}, { bind => [@bind_params] } );
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

DBIx::Class::Report - Ad-Hoc reporting from DBIx::Class

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use DBIx::Class::Report;

    my $report = DBIx::Class::Report->new(
        schema  => $dbic_schema_object,
        sql     => $complicated_sql,
        columns => \@accessor_names,
    );
    my $resultset = $report->fetch(@bind_params_for_complicated_sql);
    while ( my $result = $resultset->next ) {
        # use like a normal dbic result, but it's read only
    }

=head1 DESCRIPTION

B<NOTE:> Experimental ALPHA code.

Sometimes it's nice to be able to run ad-hoc SQL and get back a L<DBIx::Class>
resultset. We can use L<DBIx::Class::ResultSource::View>, but that requires we
hard-code our SQL ahead of time. C<DBIx::Class::Report> allows you to create
your SQL on the fly and generate ad-hoc, read-only dbic resultsets which act
just like normal dbic objects.

    my $sql = <<'SQL';
      SELECT var.name, ce.event_type, count(*)
        FROM tracking_conversion_event ce
        JOIN tracking_visitor visitor      ON visitor.tracking_visitor_id      = ce.tracking_visitor_id
        JOIN tracking_version_variant curr ON curr.tracking_version_variant_id = visitor.tracking_version_variant_id
        JOIN tracking_version ver          ON ver.tracking_version_id          = curr.tracking_version_id
        JOIN tracking_variant var          ON var.tracking_variant_id          = curr.tracking_variant_id
       WHERE ver.tracking_id = ?
         AND ver.version     = ?
    GROUP BY 1, 2
    SQL

    my $events_per_name = DBIx::Class::Report->new(
       schema  => $schema,
       sql     => $sql,
       columns => [qw/name event_type total/],
    );

    my $resultset = $events_per_name->fetch( $tracking_id, $version );
    say $resultset->count; # yeah, it behaves just like a normal dbic resultset

    while ( my $result = $resultset->next ) {
       say $result->name;
       say $result->event_type;
       say $result->total;
    }

=head1 AUTHOR

Curtis "Ovid" Poe, C<< <ovid at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to through the web interface at
L<https://github.com/Ovid/dbix-class-report/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::Class::Report

You can also look for information at:

=over 4

=item * Bugs

L<https://github.com/Ovid/dbix-class-report/issues>

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
