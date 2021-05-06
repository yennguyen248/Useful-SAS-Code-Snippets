/*Connect to a CAS session*/
cas mysession;

/* Get the astore file name from the score code generated in Model Studio. In this example, the astore 
file name is _BVXIAE95Y42CCSRVADFJROKXF_ast*/

%let scorecode=_BVXIAE95Y42CCSRVADFJROKXF_ast; 
%let scorepath=_BVXIAE95Y42CCSRVADFJROKXF_ast.sashdat; /*this macro will be used for Proc CAS*/
%let inscore=hmeq_score;
%let outscore=scoredHMEQ_V2;

libname _outlib cas caslib=CASUSER sessref=mysession;
libname _mstore cas caslib=MODELS sessref=mysession;
libname _inlib cas caslib=CASUSER sessref=mysession;

caslib _all_ assign;

/*Drop the score code file in the models library if the file already exists*/
%if %sysfunc(exist(_mstore.&scorecode)) %then %do;
proc delete data=_mstore.&scorecode;
run;
%end;

/*Promote the astore file using proc casutil*/ /*NOTICE: need to use global libname here as we're loading the data into a global scope*/
proc casutil;
load casdata="&scorepath" incaslib="models"
casout="&scorecode" outcaslib="models";
quit;

/*Drop the scored output in the destination library if the file already exists*/
%if %sysfunc(exist(_outlib.&outscore)) %then %do;
proc delete data=_outlib.&outscore;
run;
%end;

/*NOTE: Make sure you already load the score table into the library*/

/*Use proc astore to activate the score code*/
proc astore;
score data=_inlib.&inscore out=_outlib.&outscore
rstore=_mstore.&scorecode
epcode="/enable01-export/enable01-aks/homes/Yen.Nguyen@sas.com/OTHERS/dmcas_epscorecode.sas";
run;

/*Double check the contents*/
proc contents data=_outlib.&outscore;
run;

=======
/* APPROACH 2: /*Promote the astore file using proc cas */
/* proc cas; */
/* session mysession; */
/* table.tableExists result=e / */
/* name="&scorecode"; */
/* haveTable = dictionary(e, "exists"); */
/* if haveTable < 1 then do; */
/* table.loadTable result=r / */
/* caslib="MODELS" */
/* casOut={caslib="MODELS", name="&scorecode"} */
/* path="&scorepath"; */
/* end; */
/* run; */