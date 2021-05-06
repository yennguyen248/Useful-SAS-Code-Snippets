cas;
caslib _all_ assign;

data public.input_table_tmp;
	infile cards missover dsd;
	input ID Year Value1 Value2 Value3;
	datalines;
1,1999,,270
1,1999,,,350
1,1999,200,,
2,2000,20
2,2000,,300
2,2000,,,320
3,2001,,122
3,2001,300,,
3,2001,,,500
;
run;

proc casutil;
promote casdata="input_table_tmp" incaslib="public" outcaslib="public" casout="input_table";
run;

data output2;
set public.input_table;
by id;
retain max_year max_1 max_2 max_3;
if not missing(Year) then max_year=max(Year); 
if not missing(Value1) then max_1=max(Value1);
if not missing(Value2) then max_2=max(Value2);
if not missing(Value3) then max_3=max(Value3);
drop year value1 value2 value3;
if not missing(max_year) and not missing(max_1) and not missing(max_2) and not missing(max_3) then output;
rename max_year=year max_1=value1 max_2=value2 max_3=value3;
run;