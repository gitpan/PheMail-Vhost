package PheMail::Vhost;

use 5.006;
use strict;
use warnings;
use DBI;
use vars qw($sth $dbh $sname $sadmin $droot $id $extensions @sextensions
	    $soptions $i $htaccess $sdomain $servername $users %SQL);

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use PheMail::Vhost ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
LoadVhosts	
);
our $VERSION = '0.01';


# SQL Setup
$SQL{'user'} = "foo";
$SQL{'pass'} = "bar";
# Preloaded methods go here.
sub LoadVhosts($) {
    my $VirtualHost = shift;
    $i = 0;
    $dbh = DBI->connect("DBI:mysql:mail",$SQL{'user'},$SQL{'pass'});
    $sth = $dbh->prepare("SELECT * FROM vhosts");
    $sth->execute();
    while (($id,$sname,$droot,$sadmin,$sdomain,$soptions,$htaccess,$users,$extensions) = $sth->fetchrow_array()) {
	$i++;
	$droot =~ s/^\///;
	if (-d "/home/customers/$sdomain/wwwroot/$droot") {
	    if ($htaccess) {
		open(HT,"> /home/customers/$sdomain/wwwroot/$droot/.htaccess") or die("Couldn't open: $!");
		print HT $htaccess;
		close(HT);
	    } else {
		system("/bin/rm /home/customers/$sdomain/wwwroot/$droot/.htaccess") if (-e "/home/customers/$sdomain/wwwroot/$droot/.htaccess");
	    }
	} else {
	    next;
	}
	$servername = $sname ? $sname.".".$sdomain : $sdomain;
        @sextensions = split("\n",$extensions);
	my $lamext; 
	push @$lamext, [ "image/x-icon", ".ico" ]; # just to have something for default AddType so it won't fail.
	use Data::Dumper;
	foreach my $grasp (@sextensions) {
	    chomp($grasp); # remove the latter \n
	    my($dotext,$handler) = split(/:/,$grasp);
	    $handler =~ s/\r//g if $handler; # obviously this created some errors in the arrayref push
	    push @$lamext, [ $handler, $dotext ] if ($dotext && $handler); # push in the new extensions
	}
	push @{$VirtualHost->{'*'}}, {
	    ServerName       => $servername,
	    ServerAdmin      => $sadmin,
	    DocumentRoot     => "/usr/home/customers/$sdomain/wwwroot/$droot",
	    ErrorLog         => "/usr/home/customers/$sdomain/log/httpd-error.log",
	    TransferLog      => "/usr/home/customers/$sdomain/log/httpd-access.log",
	    AddType          => $lamext,
	    php_admin_value  => [ [ "open_basedir", "/usr/home/customers/$sdomain/wwwroot/$droot" ], # basedir restriction
				  [ "include_path", "/usr/home/customers/$sdomain/wwwroot/$droot" ], # include path
				  [ "sendmail_from", $sadmin ] ],                                    # sendmail from
	    Directory	 => {
		"/usr/home/customers/$sdomain/wwwroot/$droot" => {
		    Options => $soptions,
		    AllowOverride => "All",
		},
	    },
	};
    }
    printf("PheMail: Done loading %d vhosts.\n",$i);
    $sth->finish();
    $dbh->disconnect();
}
1;
__END__
# Below is stub documentation for your module. You better edit it! I did you friggin program.

=head1 NAME

PheMail::Vhost - Perl extension for Apache MySQL Vhost loading

=head1 SYNOPSIS

  use PheMail::Vhost;
  PheMail::LoadVhosts();

=head1 DESCRIPTION

PheMail::Vhost loads vhosts into httpd.conf (Apache 1.3.x) collected from
a MySQL database. Used in Project PheMail.
That's about all that's to it.

=head2 EXPORT

None by default.


=head1 AUTHOR

Jesper Noehr, E<lt>jesper@noehr.orgE<gt>

=head1 SEE ALSO

L<perl>, L<DBI>

=cut
