%let mydir="/where/all/my/files/live";
%let outlib=public; /*Caslib where I want to put the final data in*/

/*Create a file with all filenames to be loaded/*
/*can be done through pipe function if permitted*/
data files;
infile cards missover dsd;
input fileno filename:$200.;
datalines;
1, file1.csv
2, file2.csv
3, file3.csv
;
run;

/*Bulk importing*/
data datasets;
fileno+1;
set files;
length memname $32.;
memname= cats('csv',fileno);
call execute(catx(' '
,'proc import datafile='
,quote(catx('/','&mydir',filename))
,'out=',memname,'replace'
,'dbms=csv'
,';run;'
));
run;

/*Bulk formating*/
data datasets_2;
fileno+1;
set datasets;
call execute(catx(' '
,'data'
,';set',memname
,';ID_new=put(ID,$5.)'
,';drop ID'
,';rename ID_new=ID'
,';run;'
));
run;

/*Stack all the resulting data*/
data stack;
set data1 data2 data3;
run;

/*Load and promote*/
cas;
caslib _all_ assign;

proc casutil;
load data=work.stack casout="OUTPUT" outcaslib=&outlib;
promote casdata="OUTPUT" incaslib=&outlib
casout="OUTPUT" outcaslib=&outlib;
run;

