/***************************DELETING NON-Q CHARGES IN Q FILES***************************************/
data have;
set COVID.charges_q2;
/* drop 'Case COC'n 'Resolve Days'n 'First Trial_Set to Schedule'n 'First Prelim_Set to Schedule'n  */
/* 'First Trial_Latest Trial'n 'Accused Count'n 'Charge Count'n TotalWarrantTime */
/* CaseFile_Month CaseFile_Year trial_flag log_ResolveDays; */
run;

/*Macro to remove sepcial character '-'*/
%macro rename_vars(table);
	%local rename_list sqlobs;

	proc sql noprint;
		select catx('=', nliteral(name), nliteral(translate(trim(name), '_', '-'))) 
			into :rename_list separated by ' ' from sashelp.vcolumn where 
			libname=%upcase("%scan(work.&table,-2,.)") and 
			memname=%upcase("%scan(&table,-1,.)") and indexc(trim(name), '-') and 
			type="num";
	quit;

	%if &sqlobs %then
		%do;

			proc datasets lib=%scan(WORK.&table, -2);
				modify %scan(&table, -1);
				rename &rename_list;
				run;
			quit;

		%end;
%mend rename_vars;
%rename_vars(have);

/*Delete Charges with no 1s in Q files*/
proc sql noprint;
	select catx(' ', 'sum(', nliteral(name), ') as', nliteral(name)) into : list separated by ',' from 
		dictionary.columns where libname='WORK' and memname='HAVE' and type='num';
	create table temp as select &list from have;
quit;

data _null_;
	set temp;
	length _list $ 4000;
	array _x{*} _numeric_;

	do i=1 to dim(_x);

		if _x{i} = 0 then
			_list=catx(' ', _list, nliteral(vname(_x{i})));
	end;
	call symputx('drop', _list);
run;

data want;
	set have(drop=&drop);
run;
