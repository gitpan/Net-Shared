package main;
$VERSION = '0.17';
use Net::Shared::Local;
use Net::Shared::Remote;
use Net::Shared::Handler;


"JAPH";

__END__

=pod

=head1 NAME

Net::Shared - Shared variables across processes that are either local or remote.

=head1 ABSTRACT

Share data across local and remote processes.

=head1 SYNOPSIS

=for html <pre><tt>
use Net::Shared;
<br>
my $listen         = new Net::Shared::Handler;
<br>
my $new_shared     = new Net::Shared::Local
                                          (
                                           name=>"new_shared",
                                           accept=>['127.0.0.1','164.107.70.126']
                                          );
<br>
my $old_shared     = new Net::Shared::Local (name=>"old_shared");
<br>
my $remote_shared  = new Net::Shared::Remote
                                           (
                                            name=>"remote_shared",
                                            ref=>"new_shared",
                                            port=>$new_shared->port,
                                            address=>'127.0.0.1'
                                           );
<br>
$listen->add(\$new_shared, \$old_shared, \$remote_shared);
<br>
$listen->store($new_shared, "One ");
print $listen->retrieve($new_shared);
$listen->store($old_shared, "two ");
print $listen->retrieve($old_shared);
$listen->store($old_shared, [qw(three four)]);
print @{$listen->retrieve($old_shared)};
$listen->store($remote_shared, " and five.");
print $listen->retrieve($remote_shared);
<br>
$listen->destroy_all;
<br>
</tt></pre>

=head1 DESCRIPTION

B<Net::Shared> gives you the ability to share variables across processes that are either local or
remote.  No functions are exported by Net::Shared; the interface is entirely OO.
C<Net::Shared::Local> and C<Net::Shared::Remote> objects are created and interfaced with a
C<Net::Shared::Handler> object.  Here is a description of the objects:

=head2 Net::Shared

Net::Shared itself is just a holder module.  Using it will bring in Net::Shared::Local,
Net::Shared::Remote, and Net::Shared::Handler.  Just use it.

=head2 Net::Shared::Local

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

=head2 Net::Shared::Remote

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

There are no methods that you can access with C<Net::Shared::Remote>.

=head2 Net::Shared::Handler

C<Net::Shared::Handler> is the object with which you will use to interface
with C<Net::Shared::Local> and C<Net::Shared::Remote> objects.  You can think of
C<Net::Shared::Handler> as the class that actually all of the work: storing
the data, retrieving the data, and managing the objects.  It has 5 methods
available for you to use: add, remove, store, retrieve, and destroy_all
(see method descriptions below for more info).  New accepts 1 argument,
and when set to a true value debugging is turned on (only for the
Handler object, however).  Methods:

=over 3

=item C<add(@list)>

Adds a list of C<Net::Shared::Local> / C<Net::Shared::Remote> objects so that they
can be "managed."  Nothing (storing/retrieving/etc) can be done with the
objects until they have been added, so don't forget to do it!

=item C<remove(@list)>

Remove effectively kills any objects in C<@list> and all data in them, as
well as remove them from the management scheme.

=item C<store($object, \$data)>

Stores the data in C<$object>, whether it be a C<Net::Shared::Local> object or
C<Net::Shared::Remote> object.  The data needs to be a reference so that it can
be serialized and shipped away.  Returns the number of bytes sent.

=item C<retrieve($object)>

Grabs the data out of C<$object>, and returns the value.  Note that it
will be the derefferenced value of the data that you stored (in other words,
you pass C<\$data> to store, and retrieve returns C<$data>).

=item C<destroy_all()>

Your standard janitorial method.  Call it at the end of every program in
which you use I<Net::Shared>, or else you will have legions of zombie process
lurking, waiting to eat you and your children...

=back

=head1 CAVEATS

As of right now, there is no default encryption on the data, so if you
want to make sure your data is secure you should encrypt it prior to storage.
There still is address and name checking, so its not like your data is waving in
the wind, but the data won't be protected during transmission.

=head1 TODO

=over 3

=item Testing

This module is brand new and needs LOTS of testing. :)

=item Encryption

It would be nice for the user to be able to pass a subroutine defining an
encryption scheme to use, or even to use C<Crypt::RC5> to automatically
encrypt the data if a flag is turned on.  However, as of now, data is still sent
in plaintext
(if you would call data that has been C<Storable>ified and then serialized
for transmission plaintext), so it is up to you to encrypt the data if you are
paranoid about security.

=back

=head1 AUTHOR

Joseph F. Ryan, ryan.311@osu.edu

=head1 COPYRIGHT

Copyright (C) 2002 Joseph F. Ryan

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.