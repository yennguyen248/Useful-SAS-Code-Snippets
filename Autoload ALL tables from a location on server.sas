cas mysession;
caslib _all_ assign;

libname data '/global/home/ivy_ynguyen/ivey-hack-share/data_final';

ods output Members=Members;
proc datasets library=data memtype=data;
run;
quit;

data fileinfo;
set members;
fileno=_n_;
keep name fileno;
run;

%macro IfFileExists(caslib=,inlib=,filename=);
%if %sysfunc(exist(&caslib..&filename))=0 %then %do;
proc casutil;
load data=&inlib..&filename outcaslib="&caslib";
run;
%end;
%else %if %sysfunc(exist(&caslib..&filename)) %then %do;
%put This &filename table exists in &caslib already;
%end;
%mend IfFileExists;

%let mycas=public;
%let inlib=data;


data datasets;
fileno+1;
set fileinfo;
call execute(catx(' '
,'%IfFileExists(caslib=&mycas,inlib=&inlib,filename='
,name
,');'
));
run;
