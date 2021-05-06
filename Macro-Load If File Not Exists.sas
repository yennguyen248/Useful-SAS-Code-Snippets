/* load data in memory - Macro*/
%macro IfFileExists(caslib=,libref=,file=);
%if not %sysfunc(exist(&libref..&file)) %then %do;
proc cas;
session mysession;
table.loadTable/
path="&file..sashdat"
caslib="&caslib"
casout={name="&file",caslib="&caslib"}
promote=True
importoptions={filetype="hdat"};
run;
%end;
%if %sysfunc(exist(&libref..&file)) %then %do;
%put This file already exists;
%end;
%mend IfFileExists;
