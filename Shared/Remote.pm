use strict;
use warnings;
use vars qw($VERSION);
$VERSION = "0.17";

package Net::Shared::Remote;
use IO::Socket;

sub new
{
    my ($proto, %config) = @_;
    my $class = ref($proto) || $proto;
    my $self  = {};
    $self->{name}    = crypt($config{name}, $config{name});
    $self->{ref}     = $config{ref};
    $self->{port}    = exists($config{port})    ? $config{port}    : 0;
    $self->{address} = exists($config{address}) ? $config{address} : '127.0.0.1';
    $self->{debug}   = exists($config{debug})   ? $config{name}    : 0;

    if ($config{debug})
    {
        print "Constructor for ", $config{name}, ":\n";
        print "\tType of class: ", $class, "\n";
        print "\tReferring to Variable: ", $config{ref}, "\n";
        print "\tAddress ", $config{address}, "\n";
        print "\tPort: ", $self->{port}, "\n";
        print "\n";
    }

    bless ($self, $class);
}

sub set_port
{
    my ($self, $port) = @_;
    $self->{port} = $port;
}

sub set_addr
{
    my ($self, $addr) = @_;
    $self->{addr} = $addr;
}

sub destroy_variable
{
    my $self = shift;
    undef $self;
}

"JAPH";

__END__

=pod

=head1 NAME

Net::Shared::Remote

=head1 DESCRIPTION

C<Net::Shared::Remote> is basically a front end to accessing data stored by
Shared::Local objects on remote machines.  C<Net::Shared::Remote> also takes
a hash as an argument, similarily to C<Net::Shared::Local>.  However,
C<Net::Shared::Remote> can take many more elements, and all of which are
required (except debug).

=over 3

=item C<name>

The name that you will be using to reference this object.

=item C<ref>

Ref will be the name of the Net::Shared::Local object on the machine that
you are accessing.  You B<MUST> correctly specify ref (think of it as
a "password") or you will be unable to access the data.

=item C<address>

The address of the machine where the data that you want to access is
located.

=item C<port>

The port number where the data is stored on the machine which you are
accessing

=item C<debug>

Set to a true value to turn on debuging for the object, which makes it
spew out all sorts of possibly useful info.

=back

=head1 MORE

See Net::Shared's pod for more info.

=cut
