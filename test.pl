# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; }
END {print "\n\nTest failed, could not load module.\n\n" unless $loaded;}
use Data::Walker;
$loaded = 1;
print "Module Data::Walker was loaded OK.\n\n";
print "Running individual tests ";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

#
# testsuite for Data::Walker
#

use Data::Dumper;
my $TMAX;
my $TNUM = 0;
my $WANT = '';
my $NUM_PASSED = 0;
my ($s);

my $WALKER = new Data::Walker;

sub TEST {
  my $string = shift;
  my $ret = eval $string;
  ++$TNUM;
  if($ret =~ /^$WANT$/) {

    print "ok $TNUM\n";
    $NUM_PASSED++;

  } else {
    print "not ok $TNUM\n--Returned string '$ret' does not match regex '/$WANT/'--\n"
  }
}

$LAST_TEST = 27; 

print "1..$LAST_TEST\n";

#------------------------------------------------------
$s = {

        a => [ 10, 20, "thirty" ],
        b => {
                "w" => "forty",
                "x" => "fifty",
                "y" => 60,
                "z" => \70,
        },
        c => sub { return "function"; },
        d => 80,
	e => \[ "m", "n" ],
};
$s->{f} = \$s->{d};
$s->{g} = \[ "m", "n" ];
$s->{b}->{v} = $s->{b};   #recursive
bless $s, Data::Walker;
#------------------------------------------------------
# 1-5  - Test basic formatting
#
$WANT = 'ARRAY';              TEST q( $WALKER->printref( $s->{a} ) ); 
$WANT = 'HASH';               TEST q( $WALKER->printref( $s->{b} ) );
$WANT = 'CODE';               TEST q( $WALKER->printref( $s->{c} ) );
$WANT = 'scalar';             TEST q( $WALKER->printref( $s->{d} ) );
$WANT = 'Data::Walker=HASH';  TEST q( $WALKER->printref( $s      ) );

# 6-10  - Test ref-to-refs
#
$WANT = 'REF->ARRAY';         TEST q( $WALKER->printref(\$s->{a} ) );
$WANT = 'REF->HASH';          TEST q( $WALKER->printref(\$s->{b} ) );
$WANT = 'REF->CODE';          TEST q( $WALKER->printref(\$s->{c} ) );
$WANT = 'SCALAR';             TEST q( $WALKER->printref(\$s->{d} ) );
$WANT = 'REF->Data::Walker=HASH';  
                              TEST q( $WALKER->printref(\$s      ) );

$WALKER->showids(1);
my $id = '\(0x.{6}\)';  # Regex to match the id of stringified refs

# 11-16  - Test formatting with ids
#
$WANT = "ARRAY$id";              TEST q( $WALKER->printref( $s->{a} ) );
$WANT = "HASH$id";               TEST q( $WALKER->printref( $s->{b} ) );
$WANT = "CODE$id";               TEST q( $WALKER->printref( $s->{c} ) );
$WANT = "Data::Walker=HASH$id";  TEST q( $WALKER->printref( $s      ) );
$WANT = "REF$id->ARRAY$id";      TEST q( $WALKER->printref(\$s->{a} ) );
$WANT = "SCALAR$id";             TEST q( $WALKER->printref(\$s->{d} ) );

$WALKER->showids(0);

# 17-23  - Test walking up and down trees
# 
$WALKER->warning(0);      # Hide warnings during tests
$WALKER->{namepath} = ['/'];
$WALKER->{refpath} = [$s];
#
$WANT = "ARRAY$id";              TEST q( $WALKER->down("a", $s->{a}) );
$WANT = "Data::Walker=HASH$id";  TEST q( $WALKER->up() );
$WANT = "HASH$id";               TEST q( $WALKER->down("b", $s->{b}) );
$WANT = "Data::Walker=HASH$id";  TEST q( $WALKER->up() );
$WANT = "";                      TEST q( $WALKER->down("c", $s->{c}) );
$WANT = "Data::Walker=HASH$id";  TEST q( $WALKER->up() );
$WANT = "";                      TEST q( $WALKER->down("d", $s->{d}) );


# 24-27  - Test walking up and down trees with ref-to-refs
# 
$WALKER->skipdoublerefs(1);
$WANT = "ARRAY$id";              TEST q( $WALKER->down("e", $s->{e}) );
$WANT = "Data::Walker=HASH$id";  TEST q( $WALKER->up() );
$WALKER->skipdoublerefs(0);
$WANT = "SCALAR$id";             TEST q( $WALKER->down("e", $s->{e}) );
$WANT = "Data::Walker=HASH$id";  TEST q( $WALKER->up() );

print $NUM_PASSED == $LAST_TEST ? "" : "****WARNING: " ;
print "$NUM_PASSED of $LAST_TEST tests passed.\n";
1;

