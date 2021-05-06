/* apologies for the line-wrapping of the URI to fit the page */
%let URI=%str(/decisions/flows/d9da3040-38fb-44c2-be46-858c0b7eff6e/revisions/212c2f02-2820-4a44-b4a3-43750626269d);

%let mylib=CASUSER;
cas mysess sessopts=(caslib=&mylib.);

%if %sysfunc(exist(&mylib..QUOTE_FIF_ID_RESULTS)) %then %do;
proc delete data=&mylib..QUOTE_FIF_ID_RESULTS;
run;
%end;

%dcm_execute_decision(
 URI=&URI,
 inputTable=&mylib..QUOTE_SUBMIT_FIF3,
 outputTable=&mylib..QUOTE_FIF_ID_RESULTS);
quit;

cas mysess terminate;