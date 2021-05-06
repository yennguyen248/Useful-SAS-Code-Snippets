/*Macro to remove special characters*/;
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