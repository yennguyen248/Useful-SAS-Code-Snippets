/** TEST ABORT**/

/*Create CAS connection and assign libraries*/
cas mySession;
caslib _all_ assign;

/*Generate files in a PG2 caslib*/
%include "/enable01-export/enable01-aks/homes/Yen.Nguyen@sas.com/OTHERS/Stome_CreateData.sas";

/*Define my file to test*/
%Let myfile=pg2.storm_summary;

/*Create a macro to run append if file exists, else terminate session and abort*/
%macro StopIfNoFile(dir);
%if %sysfunc(exist(&myfile)) %then %do;
data storm_complete;
set &myfile pg2.storm_2017 (rename=(Year=Season));
Basin=upcase(Basin);
drop Location;
run;
%end;
%IF not %SYSFUNC(exist(&myfile)) %then %do;
%put The file is not there;
cas mySession terminate; /*this is optional if you want to terminate your session*/
%abort cancel;
%end;
%mend StopIfNoFile;

/*Execute the above macro with my defined file*/
%StopIfNoFile(&myfile);

/*Test if abortion falls through a sequential code*/
proc sort data=storm_complete;
by descending StartDate;
run;

/*Terminate CAS session*/;
cas mySession terminate;