#!/usr/local/bin/perl5

# Getopt takes a string with ":" indicating a value to be set.
sub Getopt
{
    my($control) = shift;
    my($ok) = 1;
    my $flag;
    while( @ARGV && $ARGV[0] =~ /^-(.*)/ )
    {
	my $parm = $1;
	shift @ARGV;
	last if $parm eq '-';
	while( length $parm )
	{
	    ($flag, $parm) = split(//,$parm,2);
	    if ( $control =~ /$flag:/ )
		{ $opt{$flag} = length($parm) ? $parm : shift @ARGV; $parm='' }
	    elsif ( $control =~ /$flag/ )
		{ $opt{$flag}++ }
	    else
		{ warn "$0: Unknown flag $flag\n"; $ok = 0 }
	}
    }
    $ok;
}

$usage = "usage: $0 [-H] [-v RE] [-t to] [-c cc] subject\n";

# extract recipient addresses from header.
$opt{'m'} = '/usr/lib/sendmail -t';

Getopt('Hc:m:v:t:') || die $usage;

$opt{'H'} && die <<"End"
$usage
This reads standard input, and exits silently unless there is some
material on it which doesn't match the regular expression.

-t name		Mail "To" address. Default is the owner of the effective uid.
-c name		Mail "Cc" addresses. None by default.
-v re		Regular expression to ignore. You probably want to anchor this.
		Default is not to ignore any lines.
-m command	Mail command to use. Default is $opt{'m'}.
		Null value means write to stdout.
-H		You're reading it.

The arguments are concatenated to form the Subject line of the mail.
End
;

if( defined $opt{'v'} )
    { do { $_=<STDIN> } while defined $_ and (/$opt{'v'}/o or /^\s*$/) }
else
    { $_ = <STDIN> }

exit 0 unless defined $_;

$me = (getpwuid($>))[0] || 'root';

open( STDOUT, "|$opt{'m'}" ) || die "$0: Cannot open $opt{'m'}: $!"
    if $opt{'m'};

print "Subject: @ARGV\n";
print "To: ",$opt{'t'} || $me, "\n";
print "From: $me\n";
print "Cc: $opt{'c'}\n" if $opt{'c'};
print "\n";

print $_;
print $_ while(<STDIN>);
