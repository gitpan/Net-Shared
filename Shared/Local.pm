use strict;
use warnings;
use vars qw($VERSION);
$VERSION = "0.15";

package Net::Shared::Local;
use IO::Socket;
use Storable qw(freeze thaw);
use Carp;

sub REAPER
{
    my $waitedpid = wait;
    $SIG{CHLD} = \&REAPER;
}
$SIG{CHLD} = \&REAPER;

sub new
{
    my ($proto, %config) = @_;

    my $class = ref($proto) || $proto;
    my $self  = {};

    $self->{debug}  = exists($config{debug}) ? $config{name} : 0;
    $self->{name}   = crypt($config{name}, $config{name});
    $self->{ref}    = $config{name};
    $self->{data}   = ();
    $self->{port}   = 0;
    $self->{lock}   = 0;

    $self->{accept} = defined(@{$config{accept}}) ? [@{$config{accept}}] : [qw(127.0.0.1)];

    my $sock = IO::Socket::INET->new
                                 (
                                  LocalAddr => 'localhost',
                                  Listen    => SOMAXCONN,
                                  Reuse     => 1,
                                  Proto     => 'tcp'
                                 );

    $sock->sockopt (SO_REUSEADDR, 1);
    $sock->sockopt (SO_LINGER, 0);

    $self->{port} = $sock->sockport;
    $self->{port} = $config{port} if exists($config{port});
    $sock->close;
    undef $sock;
    $sock = IO::Socket::INET->new
                                 (
                                  LocalPort => $self->{port},
                                  Listen    => SOMAXCONN,
                                  Reuse     => 1,
                                  Proto     => 'tcp'
                                 );
    $sock->autoflush(1);
    if ($config{debug})
    {
        print "Constructor for ", $config{name}, ":\n";
        print "\tType of class: ", $class, "\n";
        print "\tListening on port: ", $self->{port}, "\n";
        print "\tAccepting from addresses:\n";
        foreach my $address (@{$self->{accept}})
        {
            print "\t\t", $address, "\n";
        }
        print "\n";
    }
    croak "Can't fork: $!" unless defined ($self->{child} = fork());
    if ($self->{child} == 0)
    {
        while (my $connection = $sock->accept)
        {
            if ($config{debug})
            {
                print $config{name}, " recieved a connection:\n";
                print "\tPeerhost: ", $connection->peerhost, "\n";
                print "\tPeerport: ", $connection->peerport, "\n";
                print "\tLocalhost: ", $connection->sockhost, "\n";
                print "\tLocalport: ", $connection->sockport, "\n\n";
            }
            do
            {
                my $incoming = <$connection>;
                my $check = crypt($self->{name}, $config{name});
                if (substr($incoming, 0, length $check) ne $check)
                {
                    $connection->close;
                    last;
                }
                if ($self->{lock} > 1)
                {
                    $connection->close;
                    last;
                }
                redo if ($self->{lock} > 0);

                $self->{lock} = 1;
                last unless verify(\@{$self->{accept}}, \$connection);

                my $real_data = substr($incoming, length $check, length($incoming) - length($check));
                if ($real_data ne "\bl\b")
                {
                    $self->{data} = $real_data;
                }
                else
                {
                    send_data($self, \$connection);
                }
                $self->{lock} = 0;
                $connection->close if $connection;
            }
        }
        $sock->close if defined $sock;
        exit 0;
    }
    bless ($self, $class);
}

sub send_data
{
    my ($self, $connection) = @_;
    my $address = eval{$$connection->peerhost};
    my $port = eval{$$connection->peerport};
    $$connection->close;
    my $sock;
    while()
    {
         $sock = IO::Socket::INET->new(
                                      Proto    => 'tcp',
                                       PeerAddr => $address,
                                       PeerPort => $port
                                      );
        eval{$sock->connected};
        last unless $@;
    }
    $sock->autoflush(1);

    if ($self->{debug})
    {
        print $self->{debug},  " is sending data...\n";
        print "\tPeerhost: ",  $sock->peerhost, "\n";
        print "\tPeerport: ",  $sock->peerport, "\n";
        print "\tLocalhost: ", $sock->sockhost, "\n";
        print "\tLocalport: ", $sock->sockport, "\n\n";
    }

    syswrite($sock, $self->{data}, length($self->{data}));
    $sock->close;

}

sub destroy_variable
{
    my $self = shift;
    kill (9, $self->{child});
    undef $self;
}

sub verify
{
    my ($accept_ref, $connection) = @_;
    my $check = 0;
    foreach my $accept (@$accept_ref)
    {
        $check = 1 if ($accept eq $$connection->peeraddr || $accept eq $$connection->peerhost);
    }
    return $check;
}

sub cleanup
{
    my ($self, $error_value) = @_;
    $self->destroy_variable;
    return $error_value;
}

sub lock
{
    my ($self, $status) = @_;
    $$self->{lock} = $status;
}

sub port
{
    my $self = shift;
    return $self->{port};
}

sub DESTROY
{
    my $self = shift;
    $self->destroy_variable;
}

"JAPH";

__END__

=pod

=head1 NAME
Net::Shared::Local

=head1 DESCRIPTION

C<Net::Shared::Local> is the initial class that is used to share the data; it
is also the object that actually stores the data as well.  You'll almost
never have to interface with C<Net::Shared::Local> objects; most interfacing will be
done with C<Net::Shared::Handler>.  However, C<Net::Shared::Local> does provide 2
useful methods: lock and port.  Lock functions like a file lock, and port
returns the port number that the object is listening on.  See the methods
section for more details.  The constructor to C<Net::Shared::Local> takes 1
argument: a hash.  The hash can be configured to provide a number of
options:

=over 3

=item C<name>

The name that you will use to refer to the variable; it is the only
required option.  It can be anything; it does not have to be the same as the
variable itself.  However, note that if C<Net::Shared::Remote> is going to be used on
another machine, it will have to know the name of the variable it needs in order
to access it.

=item C<access>

access is an optional field used to designate which address to allow
access to the variable.  Assign either a reference to an array or an anyonomous
array to access.  access will default to localhost if it is not defined.

=item C<port>

If you really want to, you can specify which port to listen from; however,
its probably best to let the OS pick on unless you are going to use
C<Net::Shared::Remote> at some other Location.

=item C<debug>

Set to a true value to turn on debuging for the object, which makes it
spew out all sorts of possibly useful info.

=back

As stated earlier, there are also 2 methods that can be called: port and
lock.

=over 3

=item c<port()>

Returns the port number that the Net::Shared::Local object is listening on.

=item c<lock()>

Works like a file lock; 0=not locked; 1=temp lock used during storage,
and 2=completely lock.

=back

=head1 MORE

See Net::Shared's pod for more info.

=cut