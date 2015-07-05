#!/usr/bin/perl

##
#Author
#Vishnu Ram Gopal
#vishnuraamg@gmail.com
##


use strict;
use warnings;
use HTTP::Headers;
use JSON;
use LWP::UserAgent;
use Term::ReadKey;
use Getopt::Long qw(GetOptions);


###
# Global variables 
####
my $request = LWP::UserAgent->new;
my $response;
my $output;  # hold the json params received in response.
my $url = 'https://api.ccu.akamai.com/ccu/v2/queues/default';
my $status_url = 'https://api.ccu.akamai.com/ccu/v2/purges/';
my @url; #Array to hold the arls from file
my $type;
my $filename;
my $pending_url_count;
my $req_date;
my $help_option;
my $usage_option;
##
#Methods
##
sub OptionPrompt();
sub preliminary_check();
sub get_q_length();
sub output_display();


###
#command line arguments
###
GetOptions( "help" =>  \$help_option, "usage" => \$usage_option);


###
#Usage & help display
####
sub usage()
{
    print "\n";
    print "Usage:\n";
    print "\n";
    print "perl REST_CCU_Purge.pl\n";
    print "\nThe program offers three functions\n";
    print "\t\t#1.Submit_Purge requests through RESTFUL service\n";
    print "\t\t#2.Check the purge status\n";
    print "\t\t#3.Check the pending purge request\n";
    print "\n";
    print "- Username, password, filename and type of input(arl/cpcode) will be prompted during execution.\n";
    print "\n";
	print "-PurgeId  is needed to get the Status of the Purge. The purgeId ,received on successful purge request, will be stored in the file \'purge_reqid.txt\'\n";
    print "- Examples:\n";
    print "\nTo execute the program:\n\tperl REST_CCU_Purge.pl\n";
    print "\nTo get documentation details :\n\tperl REST_CCU_Purge.pl --help";
    print "\nTo get usage details :\n\tperl REST_CCU_Purge.pl --usage";
    print "\n";
exit (0);
}
if ($help_option && $usage_option){
print "\n Enter either --help or --usage\n";
exit (0);
}

if ($help_option) {
    exec("perldoc $0");
}
if ($usage_option) {
 usage();
}
###
#Prompt Username & Password
###

print "Akamai Luna Control Center Username: ";
my $username =<STDIN>;
$username =~ s/\s+//g;

print "Akamai Luna Control Center Password: ";

ReadMode('noecho');
my $password = ReadLine(0);
$password =~ s/\s+//g;
ReadMode('restore');

if(!($username && $password))
{print "\n Check Username and password \n";
exit (0);
}
##
#Auth setup
##
$request->credentials('api.ccu.akamai.com:443','Luna Control Center',$username,$password);

##
#Loop to get the option from user
##
 LOOP: while ( 1 ) {
        OptionPrompt();    
        $_ = <STDIN>;
        chomp($_);
		#option 1 for purge request
        if($_ eq 1){
            print "\nEnter the filename (with its location)\nThis file should contain a list of URLs (or CP codes) to be purged: ";
            $filename=<STDIN>;
			$filename=~ s/\s+//g;
			my $flag=1;
			do {
				print "\nEnter the type of purge[arl/cpcode]:  ";
				$type=<STDIN>;
				$type=~ s/\s+//g;
				if ($type) {
						if ($type eq "cpcode" or $type eq "arl") {
						$flag=0;
							} else {
						print "\nERROR: Invalid type option: [$type]\n";
						$flag=1;
					}
					}
			}while($flag);	
			
			if(preliminary_check())
				{
				print "\nPreliminary checks passed..";
				my $json = JSON->new;
				my $post_data_json = JSON->new;
				my $post_data = {'objects' => \@url,'type'=> $type};
				$post_data_json  = $json->encode($post_data);
				print "\nSubmitting purge Request .... \n";
				$response = $request->post($url,'Content-Type' => 'application/json','Content' => $post_data_json);
				output_display();
				if ($response->is_success)
					{	$response->scan(\&printheaders);
						purge_req_id_store();
					}	
			}
			next LOOP;
        }
		#option 2 for Purge status
		if($_ eq 2){
			print "\nYou can refer file \'purge_reqid.txt\' to get  previous purgeId\n";
			print "\nEnter the PurgeId to get the status :\n";
			my $upurgeID=<STDIN>;
			$upurgeID=~ s/\s+//g;
			my $full_status_url = $status_url.$upurgeID;
			print "\nChecking Status...";
			$response = $request->get($full_status_url);
			output_display();
			next LOOP;
		}
		#option 3 for Queue Length 
		if($_ eq 3){
				print "\nChecking Queue Length for user $username ...\n";
				$response = $request->get($url);
				output_display();					
			next LOOP;
		}
		#option 4 to exit
		if($_ eq 4  || $_ eq 'exit' || $_ eq 'quit') {
            print "\n...Program Terminated...\n";
			last ; 
        }

	print "\nIncorrect selection: '$_'. Please try again.\n";
     }
#Method to display output details		
sub output_display(){
	$response->scan(\&printheaders);
	my $q_output = $response->content;
	$q_output =~ s/\<\/*[head|p]\>/\n/g;
	$q_output =~ s/\<\/*[a-zA-Z0-9]*\>|\"//g;
	$q_output =~ s/\{|\}|\,/\n/g;
	$q_output =~ s/\:\s/\t\:/g;
		if ($response->is_success)
					{
					$output = decode_json($response->content);
					#
					#This "$output" variable contains the json output for the rest call, so other necessary details can be retrieved from this variable;
					#
					print "\n _REQUEST_SUCCESS_\n";
					}
				else
					{
					print "\n _ERROR_ \n";					
					}
			print "\n Details \n";
			print "\n%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n";
			print $q_output;
			print "\n%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n";		
#exit from code, since the client has received 401 error, so asking for other option is not needed;
if ($response->status_line =~ '401 Unauthorized')
	{exit(0);}
}		
#Method to perform the preliminary checks to avoid errors due to purge limitation
sub preliminary_check(){
	
	my $url_max_count_deny=0;
	#check whether the file exists
	unless(open(FILE, $filename)){ 
	print "Cannot open: $!\n"; 
	return (0);
	}
	#checking file size to avoid empty files;
	my $filesize = -s $filename;
		unless($filesize)
				{
				print "\n The input file is Empty ..Please check...\n";
				return (0);
				}
		my $url_count=0;
		#imposing the 10K limit;
		print "\nReading $type from file $filename...\n";
		while (<FILE>) {
			chomp;
			push(@url,split(' ',$_));
			$url_count++;
			if(($#url+1)>10000)
				{
				$url_max_count_deny=1;
				print "\nThe total no of URLS is greater than 10000. Please submit purge in batches with less urls..\n";
				last;
				}
		}
		
		close(FILE);
		if($url_max_count_deny)
				{return (0);}
		#imposing the 25K limit 
		if($filesize>=25600)
				{
				print "\nThe input file $filename  is greater than the allowed limit (25KB). Please try again with smaller file size\n";
				return (0);
				}
		#checking the pending URL count to avoid 10K limit error;		
		print "\nChecking no of pending purge requests....\n";
		get_q_length();
		
		unless($response->is_error)
			{
			my $get_q_output=decode_json($response->content);
			$pending_url_count=$get_q_output->{queueLength};
			print "\nPending Objects\t\t: $pending_url_count\n";
			print "Current request count\t: ".($#url+1) ;
			if($pending_url_count+$#url+1>10000)
				{
				print "\nThis request cannot be completed since pending_request + current_request exceeds threshold 10K ";
				print "\nPlease try again later..\n";
				return (0);
				}
			else
				{return (1);
				}
			}
		
		print "\n Unable to fetch the pending purge requests details ... Skippig this check and proceeding with new purge request...\n";	
	return (1);
}
#Method to get the Q length
sub get_q_length(){
$response = $request->get($url);
}		
#method to write the received purgeIds along with the time frames.
sub purge_req_id_store{
open( REQ_ID_FILE,'+>>purge_reqid.txt') || die "\n Unable to access purge_reqid.txt file to store request_id\n";
print REQ_ID_FILE "\n$req_date\t$output->{purgeId}";
close(REQ_ID_FILE);
print "\nPurgeId stored to file \'purge_reqid.txt\'\n";
}
sub OptionPrompt(){
     print "\n\n";
     print "please choose the method you want to run?";
     print "\n1.submit_Purge()";
     print "\n2.get_Purge_Status()";
     print "\n3.get_Q_Length()";
     print "\n4.exit";
     print "\nwhich do you choose?(a number) ";
}
#Optional Method to print headers  and used to extract the date value from response to store to purge_reqid.txt file;
sub printheaders{
    my $h = shift;
    my $v = shift;
	if ($h eq "Date"){$req_date=$v;}
	#Uncomment the below print statement to view the complete HTTP Response headers.
    #print ("$h:\t$v\n");
}


###
# Documentation
###

=for comment

=head1 NAME

B<REST_CCU_Purge.pl> - Helps in making purge requests via RESTful services to clear cached contents in Akamai Network.

=head1 SYNOPSIS

S<usage: B<REST_CCU_Purge.pl> >

=head1 DESCRIPTION

Akamai sample perl code, a RESTful, HTTP-based API with simple JSON objects and informative HTTP messages for customers needing programmatic purge control of Edge content. the API supports these three type of requests: 

"Purge Request" : Submits a request to purge Edge content represented by one or more ARLs/URLs or one or more CP codes.

"Purge Status"  : Returns the status of the given purgeId.

"Queue Length"  : Returns the number of outstanding objects in the user's queue.

For more details you may refer the CCU REST API Developer guide : https://api.ccu.akamai.com/ccu/v2/docs/

To use this API code, you need Akamai Luna Control Center credentials.

For security reasons you will always be prompted to enter the username and password at execution time.

=head1 PREREQUISITES

To use the CCU REST API effectively, you must be familiar with your Akamai content model and the ARLs, URLs, and CP codes used to identify your content. Beyond that, this CCU REST API is a simple API for automating content purge requests.

For an overview on how content gets refreshed on the Akamai network, including using CCU on Luna, view the following video:
https://control.akamai.com/dl/training/ccutility.htm

=head1 OPTIONS

Optional command line arguments include:

=head1 AUTHOR

Vishnu Ram Gopal

Akamai Technologies.
=cut
