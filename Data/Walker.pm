#---------------------------------------------------------------------------

package Data::Walker;

# Copyright (c) 1999 John Nolan. All rights reserved.
# This program is free software.  You may modify and/or
# distribute it under the same terms as Perl itself.
# This copyright notice must remain attached to the file.
#
# You can run this file through either pod2man or pod2html
# to produce pretty documentation in manual or html file format
# (these utilities are part of the Perl 5 distribution).

use Carp;
use Data::Dumper;
use overload;

use strict;

use vars qw( $VERSION @ISA $AUTOLOAD );
use vars qw( %Config );

$VERSION = '0.14';
sub Version { $VERSION };

####################################################################
# ---{ B E G I N   P O D   D O C U M E N T A T I O N }--------------
#

=head1  NAME

B<Data::Walker> - A tool for navigating through Perl data structures

=head1 SYNOPSIS

  use Data::Walker;
  Data::Walker->walk( $data_structure );
  # see below for details

=head1 DESCRIPTION

This module allows you to "walk" an arbitrary Perl data
structure in the same way that you can walk a directory tree
from the command line.   It is meant to be used interactively
with a live user. 


=head1 INSTALLATION

To install this package, just change to the directory which
you created by untarring the package, and type the following:

	perl Makefile.PL
	make test
	make
	make install

This will copy Walker.pm to your perl library directory for
use by all perl scripts.  You probably must be root to do this,
unless you have installed a personal copy of perl or you have
write access to a Perl lib directory.


=head1 USAGE

You open a command-line interface by invoking the walk function. 

	use Data::Walker;
	Data::Walker->walk( $data_structure );

You can customize certain features of the session, like so:

	use Data::Walker;
	$Data::Walker::Config{'skipdoublerefs'} = 0;
	Data::Walker->walk( $data_structure );

If you prefer to use object-style notation, then you 
can use this syntax to customize the settings:

	use Data::Walker;
	my $w1 = new Data::Walker;
	$w1->walk( $data_structure );

	my $w2 = new Data::Walker( 'skipdoublerefs' => 0 );
	$w2->walk( $data_structure );
	
	$w2->showrecursion(0);
	$w2->walk( $data_structure );

Imagine a data structure like so:  

	my $s = {

        a => [ 10, 20, "thirty" ],
        b => {
                "w" => "forty",
                "x" => "fifty",
                "y" => 60,
                "z" => \70,
        },
        c => sub { print "I'm a data structure!\n"; },
        d => 80,
	};
	$s->{e} = \$s->{d};


Here is a sample interactive session examining this structure ('/>' is the prompt):


	/> 
	/> ls -l
	a               ARRAY                     (3)
	b               HASH                      (4)
	c               CODE                      
	d               scalar                    80
	e               SCALAR                    80
	/> cd a
	/->{a}> ls -al
	..              HASH                      (5)
	.               ARRAY                     (3)
	0               scalar                    10
	1               scalar                    20
	2               scalar                    'thirty'
	/->{a}> cd ../b
	/->{b}> ls -al
	..              HASH                      (5)
	.               HASH                      (4)
	w               scalar                    'forty'
	x               scalar                    'fifty'
	y               scalar                    60
	z               SCALAR                    70
	/->{b}> cd ..
	/> dump b
	dump--> 'b'
	$b = {
	  'x' => 'fifty',
	  'y' => 60,
	  'z' => \70,
	  'w' => 'forty'
	};
	/> ls -al
	..              HASH                      (5)
	.               HASH                      (5)
	a               ARRAY                     (3)
	b               HASH                      (4)
	c               CODE                      
	d               scalar                    80
	e               SCALAR                    80
	/> ! $ref->{d} += 3
	eval--> $ref->{d} += 3
	
	83
	/> ls -al
	..              HASH                      (5)
	.               HASH                      (5)
	a               ARRAY                     (3)
	b               HASH                      (4)
	c               CODE                      
	d               scalar                    83
	e               SCALAR                    83
	/> 
	
	
The following commands are available from within the
command-line session.  With these commands, you can 
navigate around the data structure as if it
were a directory tree.

	cd <target>          like UNIX cd
	ls                   like UNIX ls (also respects options -a, -l)
	print <target>       prints the item as a scalar
	dump <target>        invokes Data::Dumper
	set <key> <value>    set configuration variables
	show <key>           show configuration variables
	! or eval            eval arbitrary perl (careful!)
	help                 this help message
	help set             lists the available config variables


For each session, the following items can be configured:

	rootname        (default:  '/'    ) how the root node is displayed 
	refname         (default:  'ref'  ) how embedded refs are listed
	scalarname      (default: 'scalar') how simple scalars are listed
	undefname       (default: 'undef' ) how undefined scalars are listed

	maxdepth        (default:   1  )  maximum dump-depth (Data::Dumper)
	indent          (default:   1  )  amount of indent (Data::Dumper)
	lscol1width     (default:  15  )  column widths for 'ls' displays
	lscol2width     (default:  25  )  column widths for 'ls' displays

	showrecursion   (default:   1  )  note recursion in the prompt
	showids         (default:   0  )  show ref id numbers in ls lists
	skipdoublerefs  (default:   1  )  hop over ref-to-refs during walks
	skipwarning     (default:   1  )  warn when hopping over ref-to-refs
	truncatescalars (default:  37  )  truncate scalars in 'ls' displays

	promptchar      (default:  '>' )  customize the session prompt
	arrowshaft      (default:  '-' )  ('-' in '->')
	arrowhead       (default:  '>' )  ('>' in '->')


This is an alpha release of this module.  Future releases
will include better documentation and tests.  

=head1 CHANGES

Version 0.13

	Added some installation tests.  
	Numerous internal changes; one or two bug fixes.

Version 0.12

	Blessed references to non-hashes are now handled correctly.
	Modified the output of "ls" commands (looks different).
	Added new options:  
	   showids, lscol2width, scalarname, undefname,
	   skipwarning
	Numerous internal changes.

Version 0.11

	Fixed some misspellings in the help information.
	Modified the pretty-print format of scalars.
	Added some new comments to the source code.
	Various other small updates.

=head1 AUTHOR

John Nolan  jpnolan@op.net  August-November 1999.
A copyright statment is contained within the source code itself. 

=cut                  


#---------------------------------------------------------------------------
# Default values - these can be overridden, either when an object
# is instantiated or during an interactive session.
#
%Config = (

	rootname        =>  '/' ,    # Any string
	refname         => 'ref',    # Any string
	scalarname      => 'scalar', # Any string
	undefname       => 'undef',  # Any string

	maxdepth        =>   1  ,  # Any integer, gets passed right to Data::Dumper
	indent          =>   1  ,  # 1,2 or 3, gets passed right to Data::Dumper
	lscol1width     =>  13  ,  # Any integer 
	lscol2width     =>  25  ,  # Any integer 

	showrecursion   =>   1  ,  # Boolean
	showids         =>   0  ,  # Boolean
	skipdoublerefs  =>   1  ,  # Boolean
	skipwarning     =>   1  ,  # Boolean
	warning         =>   1  ,  # Boolean

	truncatescalars =>  35  ,  # Truncate to how many chars; use 0 for no truncation

	promptchar      =>  '>' ,  # Any string
	arrowshaft      =>  '-' ,  # Any string
	arrowhead       =>  '>' ,  # Any string
);

$Config{arrow} = $Config{arrowshaft} . $Config{arrowhead}; 


#---------------------------------------------------------------------------
# Set up a new Data::Walker object
#
sub new {

	my $class = shift;
	my %ARGS  = @_;

	my $self = { (%Config) };

	bless $self,$class;

	foreach (keys %ARGS) {

		if (exists $Config{$_}) {

			$self->{$_} = $ARGS{$_};

		} else {

			carp "$_ is not a configuration variable for $class.";
		} 
	}
	return $self;

} #End sub new

#---------------------------------------------------------------------------
# Find out what a reference actually points to
#
sub reftype {

	my ($ref) = @_;

	return unless ref($ref);

	my($realpack, $realtype, $id) =
		(overload::StrVal($ref) =~ /^(?:(.*)\=)?([^=]*)\(([^\(]*)\)$/);

	# For some reason, stringified version of a ref-to-ref gives a
	# type of "SCALAR" rather than "REF".  Go figure.
	#
	$realtype = 'REF' if $realtype eq 'SCALAR' and ref($$ref);

	wantarray ? return ($realtype,$realpack,$id) : return $realtype;

} #End sub reftype



#---------------------------------------------------------------------------
# Print out a short string describing the type of thing
# this reference is pointing to.   Follow ref-to-refs if necessary.
#
sub printref {

	my ($self,$ref,$recurse) = @_;

	$recurse = {} unless defined $recurse;

	my ($type, $value) = ("error: type is empty","error: value is empty");

	if (not defined $ref) {

		$type  = $self->{scalarname};
		$value = $self->{undefname};

	} elsif (ref $ref) {

		my ($reftype,$refpackage,$id) = reftype($ref);

		$type = $reftype;
		$type = $refpackage . "=" . $type if defined($refpackage) and $refpackage ne "";
		$type .= "($id)" if $self->{showids};

		if ($reftype eq "REF") {                                

			# If this is a ref-to-ref, then recurse until we find 
			# what it ultimately points to.  
			#
			# Check to make sure that we are not in a reference loop.
			# If so, don't recurse.
			#
			if (exists $recurse->{$ref}) {

				my $hops = (scalar keys %$recurse) - $recurse->{$ref};
				$value = "(recurses in $hops " . ($hops > 1 ? "hops" : "hop") . ")";

			} else {

				$recurse->{$ref} = scalar keys(%$recurse);	
				my ($nexttype, $nextvalue, $nextid) = $self->printref($$ref,$recurse);
				$type  .= $self->{arrow} . $nexttype;
				$value = $nextvalue;
			}

		} else {

			$recurse = {};

			if ($reftype eq "HASH") {                           

				$value = "(" . scalar keys(%$ref) . ")";

			} elsif ($reftype eq "ARRAY") {                          

				$value = "(" . scalar @$ref . ")";

			} elsif ($reftype eq "SCALAR" and not defined($$ref) ) { 

				$value = $self->{undefname};

			} elsif ($reftype eq "SCALAR" and     defined $$ref  ) { 

				$value = $$ref;

			} else { 

				$value = "";   # We decline to displey other data types.  :)

			} #End if ($reftype eq ...) 

		} #End if ($reftype eq "REF") 


	} else {

		# It's not a reference, so it must actually be a scalar. 
		#
		$type  = $self->{scalarname};
		$value = $ref;

		if ($self->{truncatescalars} > 0 and length($ref) > $self->{truncatescalars} - 2) {

			$value = substr($ref,0,$self->{truncatescalars} - 5) . "..." ;
		}

		# Quote anything that's not a decimal value.
		#
		unless ($value =~ /^(?:0|-?[1-9]\d{0,8})$/) {

			$value = '\'' . $value . '\'';
		}

	} #End if (not defined $ref) -- elsif (ref $ref) 


	wantarray ? return ($type,$value) : return $type;

} #End sub printref 



#---------------------------------------------------------------------------
# This function is used for "chdir'ing" down a reference.
#
sub down {

	my ($self,$name,$ref,$recurse) = @_;
	$recurse = {} unless defined $recurse;

	my $what_is_it = ref($ref) ? reftype($ref) .  " reference" : "scalar";

	unless ($what_is_it =~ /(ARRAY|HASH|REF)/) {

		warn "'$name' is a $what_is_it, can't cd into it.\n" 
			if $self->{warning};
		return;
	}

	$name = "{$name}" if reftype($self->{refpath}[-1]) eq "HASH";
	$name = "[$name]" if reftype($self->{refpath}[-1]) eq "ARRAY";

	push @{$self->{namepath}}, $name;
	push @{$self->{refpath}}, $ref;

	#------------------------------
	# If the 'skipdoublerefs' config value is set,
	# and if the reference itself refers to a reference, 
	# then skip it and go down further.  This is recursive, 
	# so we will keep skipping until we come to 
	# something which is not a ref-to-ref. 
	#
	# We need to watch out for reference loops. 
	# Keep track of already-seen references in %$recurse.
	# Pass $recurse to this function, recursively. 
	#
	if ($self->{skipdoublerefs} and ref($ref) eq "REF") {

		# Remember that we have seen the current reference.
		$recurse->{$ref} = scalar keys(%$recurse);	

		warn "Skipping down ref-to-ref.\n" if $self->{skipwarning} and $self->{warning};

		if (exists $recurse->{$$ref}) {

			#------------------------------
			# At this point, $ref is the current reference, and $$ref is 
			# the reference it points to.  But if $recurse->{$$ref} exists,
			# then we must have seen it before.  This means we have detected a 
			# reference loop!
			#
			# The value of $recurse->{$ref} is the number of reference-hops 
			# to the current reference, and the value of $recurse->{$$ref} 
			# the number of hops to $$ref, which is a smaller number,
			# because we saw it before, on a previous hop. 
			#
			# To get the size of the reference loop, get the number of hops between them,
			# and add one hop (to count the final hop back to the beginning of the loop).
			#
			my $hops = 1 + $recurse->{$ref} - $recurse->{$$ref};
			warn "Reference loop detected: $hops ". ($hops > 1 ? "hops" : "hop") . ".\n";

		} else {

			$ref = $self->down($self->{refname},$$ref,$recurse);

			#------------------------------
			# The call to the down() method in the previous line will fail
			# if the target happens to be a SCALAR or some other item which
			# we can't cd into.  In this case, we need to cd back up, 
			# until the current ref is no longer a ref-to-ref.
			#
			# The following lines of code will be executed one time 
			# for each *successful* call to the down() method, 
			# which is what we want.  We back out just like we backed in.
			#
			if (ref($ref) eq 'REF' and scalar @{$self->{refpath}} > 1) {
				warn "Skipping up ref-to-ref.\n" if $self->{skipwarning} and $self->{warning};
				$ref = $self->up();
			}

		} #End if (exists $recurse->{$$ref}) 

	} #End if ($self->{skipdoublerefs} and ref($ref) eq "REF") 

	# If 'skipdoublerefs' is not set, then we will be able to cd into
	# ref-to-refs and run ls from within them.

	return $ref;

} #End sub down



#---------------------------------------------------------------------------
# This function is used for "chdir'ing" up a reference.
#
sub up {

	my ($self) = @_;

	return $self->{refpath}[0] if scalar @{$self->{refpath}} == 1;

	my $name = pop @{$self->{namepath}};
	           pop @{$self->{refpath}};

	# We don't need to watch out for recursion here, 
	# because we can only go back up the way we came down.  
	#
	if ($self->{skipdoublerefs} and $name eq $self->{refname} and $#{$self->{refpath}} > 0) {

		warn "Skipping up ref-to-ref.\n" if $self->{skipwarning} and $self->{warning};
		$self->up();
	}
	my $ref = $self->{refpath}[-1];
	return $ref;

} #End sub up



#---------------------------------------------------------------------------
sub DESTROY {

	# Intentionally empty
}



#---------------------------------------------------------------------------
# Use AUTOLOAD for accessor methods to config variables
#
sub AUTOLOAD {

	my ($self,$value) = @_;
	(my $key = $AUTOLOAD) =~ s/^.*:://;

	my $msg = $self->validate_config($key,$value);

	carp $msg if ($msg);

	return $self->{$key};
}

#---------------------------------------------------------------------------
# Check the values assigned to configuration variables,
# and accept them if they are OK. 
#
sub validate_config {

	my ($self,$key,$value) = @_;

	return "Attempt to assign to undefined key" 
		unless defined $key;
	return "Attempt to assign undefined value to key '" . lc($key) . "'" 
		unless defined $value;

	my $msg = "";

	for ($key) {

		/(truncatescalars|lscol?width|maxdepth)/i
			and do { 
				my $key = $1;
				unless ($value =~ /\d+/ and $value >= 0) { 
					$msg = lc($key) . " must be a positive integer"; last; 
				}
				$self->{lc $key} = $value; 
				last; 
			};
		/indent/i
			and do { 
				unless ($value =~ /(1|2|3)/) { 
					$msg = "indent must be a either 1, 2 or 3"; last; 
				}
				$self->{indent} = $value; 
				last; 
			};
		/rootname/i
			and do { 
				$self->{rootname}         = $value; 
				$self->{namepath}[0]      = $value if defined $self->{namepath};
				$self->{prev_namepath}[0] = $value if defined $self->{prev_namepath};
				last; 
			};
		/^arrow$/i
			and do { 
				$msg = "Can't modify arrow directly.  Instead, modify arrowshaft and arrowhead";
				last;
			};

		# We check this here, so that we can handle exceptional strings beforehand
		#
		unless (exists $Config{$key}) {

			$msg = "No such config variable as '" . lc($key) . "'";
			return $msg;
		}

		# Otherwise, just accept whatever value. 
		#
		$self->{$key} = $value if exists $self->{$key};

	} #End for ($key) 

	$self->{arrow} = $self->{arrowshaft} . $self->{arrowhead};

	return $msg;

} #End sub validate_config


#---------------------------------------------------------------------------
# Implement chdir logic
#
sub walker_chdir {

	my ($self,$dirspec,$ref) = @_;

	#------------------------------
	# Handle cd -
	#
	if ($dirspec =~ m#^\s*-\s*$#) {

		# Swap swap, fizz fizz.....
		#
		   @{$self->{tmp_namepath}} =      @{$self->{namepath}};
		       @{$self->{namepath}} = @{$self->{prev_namepath}};
		  @{$self->{prev_namepath}} =  @{$self->{tmp_namepath}};

		    @{$self->{tmp_refpath}} =       @{$self->{refpath}};
		        @{$self->{refpath}} =  @{$self->{prev_refpath}};
		   @{$self->{prev_refpath}} =   @{$self->{tmp_refpath}};

		# Use the last ref in the (now) current refpath
		#
		$ref = $self->{refpath}[-1];

		next COMMAND;

	} else {

		# Remember our current paths into the structure, 
		# in case we have to abort for some reason.
		#
		@{$self->{tmp_refpath}}  = @{$self->{refpath}};
		@{$self->{tmp_namepath}} = @{$self->{namepath}};

	} #End if ($dirspec =~ m#^\s*-\s*$#) {

	#------------------------------
	# Handle dirspec's relative to the root
	#
	my $leading_slash = "";

	if ($dirspec =~ m#^/#) {

		# Set the paths back to the beginning
		$#{$self->{namepath}} = 0;
		$#{$self->{refpath}} = 0;

		# Set ref to the first item in the refpath
		$ref = $self->{refpath}[0];

		# Strip any leading '/' chars from $dirspec
		#
		$dirspec =~ s#^/+##g;

		$leading_slash = '/';
	}

	#------------------------------
	# Handle all other dirspec's
	#
	my @dirs = split /\//, $dirspec;

	foreach (@dirs) {

		# The actual value of $ref may be modified within this loop,
		# so we have to re-check it each time through
		#
		my ($reftype,$refpackage) = reftype($ref);

		my $dir = $_;

		if ($dir eq '.') {

			# Do nothing

		} elsif ($_ eq '..') {

			$ref = $self->up();

		} elsif ($reftype eq "REF") {

			unless ($dirspec eq $self->{refname}) {
				warn "'$dirspec' does not exist.  " .
						"Type 'cd $self->{refname}' to descend into reference.\n"
					if $self->{warning};
				return $ref;
			}
			$ref = $self->down($dir,$$ref);

		} elsif ($reftype eq "HASH") {

			unless (exists $ref->{$dir}) {

				warn "No such element as '$leading_slash$dirspec'.\n" if $self->{warning};
				@{$self->{refpath}}  = @{$self->{tmp_refpath}};
				@{$self->{namepath}} = @{$self->{tmp_namepath}};
				return $ref;

			} else {

				$ref = $self->down($dir,$ref->{$dir});
			}

		} elsif ($reftype eq "ARRAY") {

			unless ($dir =~ /^\d+$/ and scalar(@$ref) > $dir) {

				warn "No such element as '$leading_slash$dirspec'.\n" if $self->{warning};
				@{$self->{refpath}}  = @{$self->{tmp_refpath}};
				@{$self->{namepath}} = @{$self->{tmp_namepath}};
				return $ref;

			} else {

				$ref = $self->down($dir,$ref->[$dir]);
			}

		} else {

			#------------------------------
			# If $ref points to a SCALAR, CODE or something else, then the
			# 'cd' command is ignored within it.  We should never have chdir'ed
			# there in the first place, so this message will only be printed
			# if the author of this module has made an error.  ;) 
			#
			warn "Don't know how to chdir from current directory ($reftype) into '$dirspec'.\n" 
				if $self->{warning};
			@{$self->{refpath}}  = @{$self->{tmp_refpath}};
			@{$self->{namepath}} = @{$self->{tmp_namepath}};
			$ref = $self->{refpath}[-1];
			return $ref;

		} #End if ($dir eq ...

		#------------------------------
		# If the calls to down() or up() have failed for some reason,
		# then return to wherever were to begin with. 
		# Don't even bother to parse the rest of the path.
		#
		if (not defined $ref) {

			@{$self->{refpath}}  = @{$self->{tmp_refpath}};
			@{$self->{namepath}} = @{$self->{tmp_namepath}};
			$ref = $self->{refpath}[-1];
			return $ref;
		}

	} #End foreach (@dirs) 


	# Looks like we successfully chdir'd from one place into another.
	# Save our previous location in the structure into the "prev_" variables.
	# The previous previous variables (meta-previous?) are now forgotton.
	#
	@{$self->{prev_refpath}}  = @{$self->{tmp_refpath}};
	@{$self->{prev_namepath}} = @{$self->{tmp_namepath}};

	return $ref;

} #End sub walker_chdir


#---------------------------------------------------------------------------
# Implement "ls" formatting logic
#
sub walker_ls {

	my ($self,$ref,$option) = @_;
	my ($reftype,$refpackage) = reftype($ref);

	if ($option =~ /l/) {

		my $dots = "";
		my $format = "%-$self->{lscol1width}s\t%-$self->{lscol2width}s %s\n";

		if ($option =~ /a/) {

			my ($type,$value);
	
			if (scalar @{$self->{namepath}} >  1) {
	
				($type,$value) = $self->printref($self->{refpath}[-2]);
				$dots = sprintf( $format, '..', $type, $value );
				($type,$value) = $self->printref($self->{refpath}[-1]);

			} else {

				($type,$value) = $self->printref($self->{refpath}[-1]);
				$dots = sprintf( $format, '..', $type, $value );
			}

			$dots .= sprintf( $format , '.', $type, $value );
		}

		if ($reftype eq "REF") {

			print $dots;
			my ($type,$value) = $self->printref($$ref);
			printf( $format, $self->{refname}, $type, $value );

		} elsif ($reftype eq "HASH") {

			print $dots;
			foreach (sort keys %$ref) {

				my ($type,$value) = $self->printref($ref->{$_});
				printf( $format, $_, $type, $value );
			}

		} elsif ($reftype eq "ARRAY") {

			print $dots;
			my $i = 0;
			foreach (@$ref) {

				my ($type,$value) = $self->printref($_);
				printf( $format, $i++, $type, $value );
			} 

		} else {

	 		print "Current ref is a ref to " . $reftype . 
				", don't know how to emulate ls -l in it.\n";
		}

	} else {

		my $dots = ($option =~ /a/) ? "..\t.\t" : "";

		if ($reftype eq "REF") {

			print $dots,$self->{refname},"\n";

		} elsif ($reftype eq "HASH") {

			print $dots;
			foreach (sort keys %$ref) {

				print $_, "\t";
			}
			print "\n";

		} elsif ($reftype eq "ARRAY") {

			print $dots;
			my $i = 0;
			foreach (@$ref) {

				print $self->printref($_), "\t";
			}

		} else {

			print "Current ref is a $reftype, don't know how to emulate ls in it.\n";
		}

	}


} #End sub walker_ls


#---------------------------------------------------------------------------
# Implement "cat" formatting logic
#
sub walker_cat {

	my ($self,$ref,$target) = @_;
	my ($reftype,$refpackage) = reftype($ref);


	# Prints "print--> "...
	print "print$self->{arrowshaft}$self->{arrow} '",$target,"'\n";
			
	if ($target eq ".") {

		print $ref;

	} elsif ($target eq '..') {

		print ${$self->{refpath}[-2]} if (scalar @{$self->{namepath}} >  1);
		print ${$self->{refpath}[-1]} if (scalar @{$self->{namepath}} <= 1);

	} elsif ($reftype eq "HASH") {

		print $ref->{$target};

	} elsif ($reftype eq "ARRAY") {

		print $ref->[$target];

	} else {

		warn "Current ref is a $reftype, don't know how to print from it."
			if $self->{warning};
	}
	print "\n";

} #End sub walker_cat


#---------------------------------------------------------------------------
# Invoke Data::Dumper::dump
#
sub walker_dump {

	my ($self,$ref,$target) = @_;
	my ($reftype,$refpackage) = reftype($ref);

	# Pass config values directly to Data::Dumper
	#
	local $Data::Dumper::Indent   = $self->{indent};
	local $Data::Dumper::Maxdepth = $self->{maxdepth};

	# Prints "dump--> "...
	print "dump$self->{arrowshaft}$self->{arrow} '",$target,"'\n";
			
	if ($target eq ".") {

		print Data::Dumper->Dump( [ $ref ] );

	} elsif ($target eq '..') {

		print Data::Dumper->Dump([ $self->{refpath}[-2] ],[ $self->{namepath}[-2] ]) 
			if (scalar @{$self->{namepath}} >  1);
		print Data::Dumper->Dump([ $self->{refpath}[-1] ],[ $self->{namepath}[-1] ]) 
			if (scalar @{$self->{namepath}} <= 1);

	} elsif ($reftype eq "REF") {

		print Data::Dumper->Dump( [ $$ref ], [ $target ] );

	} elsif ($reftype eq "HASH") {

		print Data::Dumper->Dump( [ $ref->{$target} ], [ $target ] );

	} elsif ($reftype eq "ARRAY") {

		print Data::Dumper->Dump( [ $ref->[$target] ], [ $target ] );

	} else {

		warn "Current ref is a $reftype, don't know how to dump things from it."
			if $self->{warning};
	}

} #End sub walker_dump


#---------------------------------------------------------------------------
# "Walk" a data structure.  This function implements the CLI.
#
sub walk {

	my $class = __PACKAGE__;

	# We expect exactly 2 parameters:  
	# 1. the object or class; 
	# 2. the target ref.
	#
	if (scalar @_ != 2) {

		carp "Usage:  ${class}->walk(\$ref) or \$p->(\$ref), where \$p is \n" .
			"a $class object, and \$ref is the target data structure.\n";
		return;
	}

	# The first parameter is either the name of the class or 
	# a reference to the object on which this method was invoked.  
	# If it's the name of the class, then create an object on the fly. 
	#
	my $self = ref($_[0]) eq $class ? $_[0] : new($class);
	my $ref  = $_[1];

	unless (defined $ref and ref $ref) {

		carp "Parameter is either undefined or is not a reference";
		return;
	}

	$self->{namepath} = [$self->{rootname}];
	$self->{refpath}  = [$ref];

	$self->{prev_namepath} = [];
	$self->{prev_refpath}  = [];
	$self->{tmp_namepath}  = [];
	$self->{tmp_refpath}   = [];

	printf "%s$self->{promptchar} ",join $self->{arrow},@{$self->{namepath}};

	#------------------------------------------------------------
	# Command loop.  We loop through here once for each command
	# that the user enters at the prompt.
	#
	COMMAND: while(<>) {

		chomp;
		next COMMAND unless /\S/;               # Ignore empty commands
		return if m/^\s*(q|qu|quit|ex|exi|exti|exit)\s*$/i;    # 50 ways to leave your CLI

##		my ($reftype,$refpackage) = reftype($ref);

		#------------------------------------------------------------
		# Things we'd like to do, but don't do yet
		#
		if (/^(pwd)$/) {

			print "Command '$_' is not yet implemented\n";

		#------------------------------------------------------------
		# Small help utility
		#
		} elsif (/^\s*(help|h)\s*$/) {

			(my $blurb =<<"			EOM") =~ s/^\s+//gsm;
			The following commands are supported:

			cd <target>          like UNIX cd
			ls                   like UNIX ls (also respects options -a, -l)
			print <target>       prints the item as a scalar
			dump <target>        invokes Data::Dumper
			set <key> <value>    set configuration variables
			show <key>           show configuration variables
			! or eval            eval arbitrary perl (careful!)
			help                 this help message
			help set             lists the availabe config variables
			EOM

			print $blurb;

		#------------------------------------------------------------
		# Small help utility, continued
		#
		} elsif (/^\s*help\s+(set|show)\s*$/) {

			(my $blurb =<<"			EOM") =~ s/^\t+//gm;
			The following items can be configured
			(current value is in parenthesis):

			rootname        how the root node is displayed ("$$self{rootname}")
			refname         how embedded refs are listed ("$$self{refname}")
			scalarname      how simple scalars are listed ("$$self{scalarname}")
			undefname       how unefined scalars are listed ("$$self{undefname}")
			promptchar      customize the session prompt ("$$self{promptchar}")
			arrowshaft      first part of session prompt ("$$self{arrowshaft}")
			arrowhead       last part of session prompt ("$$self{arrowhead}")

			maxdepth        maximum dump-depth (Data::Dumper) ($$self{maxdepth})
			indent          amount of indent (Data::Dumper) ($$self{indent})
			lscol1width     column widths for 'ls' displays ($$self{lscol1width})
			lscol2width     column widths for 'ls' displays ($$self{lscol2width})

			showrecursion   note recursion in the prompt ($$self{showrecursion})
			showids         show ref id numbers in ls lists ($$self{showids})
			skipdoublerefs  hop over ref-to-refs during walks ($$self{skipdoublerefs})
			skipwarning     warn when hopping over ref-to-refs ($$self{skipwarning})
			truncatescalars truncate scalars in 'ls' displays ($$self{truncatescalars})
			                (use 0 for no truncation)

			type "show <configname>" to display a value
			type "set <configname> <value>" to assign a new value
			EOM

			print $blurb;

		#------------------------------------------------------------
		# Emulate cd
		#
		} elsif (/^\s*(cd|chdir)\s+(.+)$/) {

			$ref = $self->walker_chdir($2,$ref);

		#------------------------------------------------------------
		# Emulate ls -l
		#
		} elsif (/^\s*(ll\s+-a|ls\s+-al|ls\s+-la|dir|ls\s+-a\s+-l|ls\s+-l\s+-a|la\s+-l)\s*$/) {

			$self->walker_ls($ref,"la");
			
		} elsif (/^\s*(ll|ls\s+-l|ls\s+-l)\s*$/) {

			$self->walker_ls($ref,"l");
			
		} elsif (/^\s*(ls\s+-a|la)\s*$/) {

			$self->walker_ls($ref,"a");

		} elsif (/^\s*(l|ls)\s*$/) {

			$self->walker_ls($ref,"");

		#------------------------------------------------------------
		# Emulate cat 
		#
		} elsif (/^\s*(cat|type|print|p)\s+(.+?)\s*$/) {

			my $target = $2;
			$self->walker_cat($ref,$target);


		#------------------------------------------------------------
		# Invoke dump
		#
		} elsif (/^\s*(dump|d)\s+(.+?)\s*(\d*)$/) {

			my $target = $2;
			$self->walker_dump($ref,$target);

		#------------------------------------------------------------
		# Adjust config settings ("set indent 2")
		#
		} elsif (/^\s*set\s+(\S+?)\s+(.+)$/i) {

			my ($key,$value) = (lc($1),$2);
			$value =~ s/^[=\s]*//;
			$value =~ s/[\s]*$//;

			my $msg = $self->validate_config($key,$value);
			print "$msg.\n" if $msg;


		#------------------------------------------------------------
		# Show config settings  ("show indent" etc.)
		#
		} elsif (/^\s*show\s*$/i or /^\s*show all\s*$/i) {

			foreach (sort { $a cmp $b } keys %Config) {

				# Print out the variable key and value.
				# Quote anything that's not a decimal value.
				#
				if ($self->{$_} =~ /^(?:0|-?[1-9]\d{0,8})$/) {
					printf "%-15s = %s\n", lc($_), $self->{$_};
				} else {
					printf "%-15s = '%s'\n", lc($_), $self->{$_};
				}
			}

		} elsif (/^\s*show\s+(\S+?)\s*$/i) {

			next COMMAND unless defined $1;

			my $key = lc($1);

			unless (exists $self->{$key}) {

				print "No such config variable as '$key'\n";
				next COMMAND;
			}

			# Print out the variable key and value.
			# Quote anything that's not a decimal value.
			#
			if ($self->{$key} =~ /^(?:0|-?[1-9]\d{0,8})$/) {
				print "$key = $self->{$key}\n";
			} else {
				print "$key = '$self->{$key}'\n";
			}

		#------------------------------------------------------------
		# eval:  Take whatever the user typed in and eval it
		#
		} elsif (/^\s*(\!|eval)\s/) {

			s/^\s*(\!|eval)\s//;

			# prints "eval--> "...
			print "eval$self->{arrowshaft}$self->{arrow} ",$_,"\n";
			my $res = eval;

			unless (defined $res) {

				print "\nundef\n";

			} else {

				print "\n$res\n";
			}

		} else {

				print "Ignoring command '$_', could not parse. (Type 'help' for help.)\n";
		}

	} continue {  #continuing COMMAND: while(<>) {

		#------------------------------
		# At the end of each loop, we might be inside a new directory.  
		# Figure out what the prompt should look like. 
		#
		$self->{temp_namepath} = $self->{namepath};
		my (%seen,%seen_twice);
		my $count = 1;

		for (my $i = 0; $i < scalar @{$self->{refpath}}; $i++) {

			# Check to see if we are seeing this ref for the *second* time.
			# If so, define it in the %seen_twice hash. 
			#
			if (
				exists $seen{ $self->{refpath}[$i] } 
				and 
				not exists $seen_twice{ $self->{refpath}[$i] } 
			) {

				$seen_twice{ $self->{refpath}[$i] } = $count++;
			}

			$seen{ $self->{refpath}[$i] } = 1;
		}

		for (my $i = 0; $i < scalar @{$self->{refpath}}; $i++) {

			$self->{temp_namepath}[$i] .= "-" . $seen_twice{ $self->{refpath}[$i] } . "-"
				if exists $seen_twice{ $self->{refpath}[$i] };
		}

		printf "%s$self->{promptchar} ",join $self->{arrow},@{$self->{temp_namepath}};


	} #End COMMAND: while(<>) {


} #End sub walk

1;


