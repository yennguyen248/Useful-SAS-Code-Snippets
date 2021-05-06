cas mysession;
caslib _all_ assign;

%let mycas=CASUSER;
libname outlib "/enable01-export/enable01-aks/homes/Yen.Nguyen@sas.com/COVID_CANADA";


/*Learning: no need to go through WORK to do this*/
/*Aggregate table*/;
data COVID_CAN_AGG;
set &mycas..CAN_AGG_COVID_NEW;
run;

/*Esri Table*/;
data COVID_CAN_ESRI;
set &mycas..COVID_19_CANADA_CASE_ESRI(datalimit=10000M);
run;

/*Case Raw 20 from Github*/;
data COVID_CAN_Case20Raw;
set &mycas..COVID_19_CANADA_CASE(datalimit=10000M);
run;

/*Case Raw 21 from Github*/;
data COVID_CAN_Case21Raw;
set &mycas..COVID_19_CANADA_CASE21(datalimit=10000M);
run;

/*Case by Day*/;
data COVID_CAN_CaseByDay;
set &mycas..COVID_19_CAN_CASEBYDAY_FINAL(datalimit=10000M);
run;

/*Case Raw 20 from Github*/;
data COVID_CAN_Death20Raw;
set &mycas..COVID_19_CANADA_DEATHS(datalimit=10000M);
run;

/*Case Raw 21 from Github*/;
data COVID_CAN_Death21Raw;
set &mycas..COVID_19_CANADA_DEATHS21(datalimit=10000M);
run;

/*Death by Day*/;
data COVID_CAN_DeathByDay;
set &mycas..COVID_19_CAN_DEATHBYDAY_FINAL(datalimit=10000M);
run;

/*Geo&ICU*/;
data COVID_CAN_GEOICU;
set &mycas..COVID_CAN_PROV_GEO(datalimit=10000M);
run;

/*Copy onto the server*/
proc copy in=work out=outlib;
	select COVID_CAN_AGG COVID_CAN_ESRI COVID_CAN_Case20Raw COVID_CAN_Case21Raw 
		COVID_CAN_Death20Raw COVID_CAN_Death21Raw COVID_CAN_CaseByDay 
		COVID_CAN_DeathByDay COVID_CAN_GEOICU;
run;

quit;

proc copy in=maps out=outlib;
	select CANADA2;
run;

quit;

