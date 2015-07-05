# Akamai_CCU_RESTAPI_Client
REST API client to submit CCU(Purge) request to Akamai
##
#Author
#Vishnu Ram Gopal
#vishnuraamg@gmail.com
##

README.txt - Akamai RESTfull service CCU API perl sample code.

Module Requirements
----------------------------------------------------

For proper operation of the sample scripts, the following perl modules are recommended.

 * LWP
 * JSON
 * HTTP::Responses
 * Term::ReadKey;
 * Getopt::Long 
----------------------------------------------------
The API code contains the 3 major Modules

"Purge Request" : Submits a request to purge Edge content represented by one or more ARLs/URLs or one or more CP codes.
"Purge Status"  : Returns the status of the given purgeId.
"Queue Length"  : Returns the number of outstanding objects in the user's queue.

----------------------------------------------------

For details on usage 

	$ perl REST_CCU_Purge.pl --usage

For documentation page

	$ perl REST_CCU_Purge.pl --help

	
----------------------------------------------------
	
Sample Output of the API code:

$ perl REST_CCU_Purge.pl
Akamai Luna Control Center Username: <test>
Akamai Luna Control Center Password:

please choose the method you want to run?
1.submit_Purge()
2.get_Purge_Status()
3.get_Q_Length()
4.exit
which do you choose?(a number)


*************************************************
Option #1: to make a purge request;
This option will prompt for  following:
	filename - file that contains the list of ARLs/URLs or cpcodes
	type	 - arl /cpcode

*************************************************
Option #2: to get the status on the purge request submitted .
This option prompts for "purgeId".
PurgeId  is obtained from successful purge request submission.

For easy access, this API stores the purgeId along with the time of submission to a separate file named purge_reqid.txt, placed in same directory.

**************************************************
option #3: to get the Q length status of the logged user.
No input required.

**************************************************

sample successful purge submission:

---------------------------------------------------------------------------------------
 _REQUEST_SUCCESS_

 Details

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

estimatedSeconds        :420
 progressUri    :/ccu/v2/purges/d6c4f2dd-ba90-11e3-a2fe-e28522fee285
 purgeId        :d6c4f2dd-ba90-11e3-a2fe-e28522fee285
 supportId      :17PY1396461698365120-310707296
 httpStatus     :201
 detail :Request accepted.
 pingAfterSeconds       :420

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

PurgeId stored to file 'purge_reqid.txt'

---------------------------------------------------------------------------------------


Sample Error on a Q request status:

---------------------------------------------------------------------------------------
 _ERROR_

 Details

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
401 Unauthorized
401 Unauthorized

You are not authorized to access that resource

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
---------------------------------------------------------------------------------------


For troubleshooting purposes if the Response headers are needed, we can uncomment the print statement in the module printheaders();
