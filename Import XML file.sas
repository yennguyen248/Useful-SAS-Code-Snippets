/*Connect to a CAS session*/
cas mysession;
caslib _all_ assign;

/*Create libname for the XML file*/
libname trans xmlv2 '/users/yen/sasuser.viya/';

libname myfiles cas caslib=public sessref=mysession;

/*Convert from XML markup to SAS table using XML engine*/
/*Import an XML file (real XML format)*/
data myfiles.chronic_xml_datadict;
   set trans.datadictionary;
run;

proc print data=myfiles.chronic_xml_datadict;
run;
