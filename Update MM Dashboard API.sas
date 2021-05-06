/* Server and Credentials */
%let protocol= http;
%let server= sseviya.demo.sas.com;
%let authUri=/SASLogon/oauth/token;
%let casSession =/cas/sessions;
%let user= canyzn;
%let password= Messier49*****; /*this env doesn't have userID, how to log in using API?*/;
%let Basic= c2FzLmVjOg==;
%let port = 80;
/* options mlogic mprint symbolgen; */

/* Name of Model Project */
%let modelRepoProjects = /modelRepository/projects;
%let modelRepoModels = /modelRepository/models;

/* Get Authorization Token */
filename resp temp;
proc http
	method="GET"
	url="&protocol.://&server:&port.&authUri.?grant_type=password%nrstr(&username)=&user.%nrstr(&password)=&password"
	out=resp;
	headers
		"Authorization"="Basic &Basic."
;
run;

/* Assign JSON libname to parse response (resp) from API */
libname test JSON fileref=resp;

/* Assign access_token as macro variable, token */
data _null_;
set test.ROOT;
call symputx( "token", access_token);
run;

data _null_;
put "&token.";
run;

/* Clear and re-assign filename to parse next API responses */
filename resp clear;


/* Get all models by GET all models */
filename resp temp;
proc http
	method="GET"
 	url="&protocol.://&server:&port.&modelRepoModels"
	OUT=resp;
	headers
		"Authorization"="Bearer &token."
;
run;

libname test JSON fileref=resp;

data _null_ ;
infile resp lrecl=40000;
input;
put _infile_;
run;

/* Save as CAS Table */
cas mysession;
caslib _all_ assign;
%let mylib=casuser;

/*Drop the target result table in the destination library if the file already exists*/
%if %sysfunc(exist(&mylib..MM_MODEL_ALL)) %then %do;
proc delete data=&mylib..MM_MODEL_ALL;
run;
%end;

/*Promote the table*/
data &mylib.. MM_MODEL_ALL;
set test.items;
run;

proc casutil;
promote incaslib="&mylib" casdata="MM_MODEL_ALL" outcaslib="&mylib" casout="MM_MODEL_ALL";
run;

/* Clear and re-assign filename to parse next API responses */
filename resp clear;
filename resp temp;

/* Get ALL champions by GET all models?properties=(role,champion)  */
proc http
	method="GET"
 	url="&protocol.://&server:&port.&modelRepoModels?properties=(role,champion)"
	OUT=resp;
	headers
		"Authorization"="Bearer &token."
;
run;

libname test JSON fileref=resp;

data _null_;
infile resp;
input;
put _infile_;
run;

/*Drop the target result table in the destination library if the file already exists*/
%if %sysfunc(exist(&mylib..MM_MODEL_CHAMPION)) %then %do;
proc delete data=&mylib..MM_MODEL_CHAMPION;
run;
%end;

/*Promote the table*/
data &mylib.. MM_MODEL_CHAMPION;
set test.items;
run;

proc casutil;
promote incaslib="&mylib" casdata="MM_MODEL_CHAMPION" outcaslib="&mylib" casout="MM_MODEL_CHAMPION";
run;


/* Clear and re-assign filename to parse next API responses */
filename resp clear;
filename resp temp;

/* Get ALL by all models from DMRepository */
proc http
	method="GET"
 	url="https://demo.sasdemo.ca/folders/folders/7c56bdd8-697c-44a9-b510-3f6e30a01a2a/members"
	OUT=resp;
	headers
		"Authorization"="Bearer &token."
;
run;

libname test JSON fileref=resp;

data _null_;
infile resp;
input;
put _infile_;
run;

/*Drop the target result table in the destination library if the file already exists*/
%if %sysfunc(exist(&mylib..MM_MODEL_DM)) %then %do;
proc delete data=&mylib..MM_MODEL_DM;
run;
%end;

/*Promote the table*/
data &mylib.. MM_MODEL_DM;
set test.items;
run;

proc casutil;
promote incaslib="&mylib" casdata="MM_MODEL_DM" outcaslib="&mylib" casout="MM_MODEL_DM";
run;

/*Terminate cas session*/;
cas mysession terminate;

