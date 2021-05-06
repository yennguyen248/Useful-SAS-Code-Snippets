
/*--- First two macro variable are required. The last three are optional with
      default values specified below. */
%macro GEOBASE2GEOCODE(GEOBASEPATH=\enable01-export\enable01-aks\homes\Yen.Nguyen@sas.com\OTHERS,
                       DATASETPATH=\enable01-export\enable01-aks\homes\Yen.Nguyen@sas.com\OTHERS\Geo Lookup,
                       LIBNAME=LOOKUP,
                       DATASETNAME=CANADA_,
                       LABEL=Canada lookup data for PROC GEOCODE from GeoBase National Road Network (&CURDATE))
       / des='Import Canadian GeoBase National Road Network files for PROC GEOCODE street method lookup data';

  /*--- Initialize global variables, check for required and optional input
        vars, determine operating system, set librefs and create directories. */
  %InitializeImport
  %if &IMPORTERROR=yes %then %goto MacroExit;

  /*--- List names of all files in the GEOBASEPATH folder and use a
        pipe to transfer that list to SAS. The host command to
        list files depends on the operating system. 
        NOTE: Do not remove the %do-%end from the %if-%else conditions. */
  %if &OSNAME=UNIX %then %do;
    /*--- Use Unix 'ls' command to list files. */
    filename filelist pipe %unquote(%str(%'ls "&GEOBASEPATH"%'));
  %end;
  %else %if &OSNAME=WINDOWS %then %do;
    /*--- Use Windows 'dir' command to list files. */
    filename filelist pipe %unquote(%str(%'dir "&GEOBASEPATH\*" /b%'));
  %end;

  /*--- Loop through the piped list of file names and put each ROADSEG 
        file into sequential macro variables, e.g. &FNAME1, &FNAME2,
        ... &FNAMEn. Each &FNAMEi variable contains a GEOBASE ROADSEG.shp,
        e.g. 'NRN_PE_10_0_ROADSEG.shp'. The number of macro vars
        containing file names is stored in &FILETOTAL. */
  data _null_;
    infile filelist truncover end=finalObs;
    length fname $50;
    input fname;      /* GeoBase file name from pipe */
    retain i 1;
    /*--- Import only files needed for street geocoding and ignore others. */
	fname = upcase(fname);
    if index(fname, '_ADDRANGE.DBF ') |
       index(fname, '_ROADSEG.SHP ')  |
       index(fname, '_STRPLANAME.DBF ') then do;
      /*--- File is required. Put name in numbered FNAMEi macro
            var and increment file counter. */
      call symputx('FNAME' || trim(left(put(i,8.))), trim(fname));
      i+1;
    end;
    /*--- If last file, put final count into FILETOTAL macro variable. */
    if finalObs then
      call symput('FILETOTAL', trim(left(put(i-1,8.))));
  run;

  /*--- If no GeoBase geocoding files found, exit. */
  %if &FILETOTAL=0 %then %do;
     %put ERROR: There are no GeoBase National Road Network ROADSEG.shp;
     %put ERROR- files in the GEOBASEPATH location:;
     %put ERROR-   &GEOBASEPATH;
     %let IMPORTERROR=yes;
     %goto MacroExit;
  %end;

  /*--- Loop through the filenames in the &FNAMEi macro variables and put
        them into a data set. These will be the GeoBase files to import. */
  data &LIBNAME..geobase_files_&CURDATE
       (label="Canadian GeoBase National Road Network (NRN) files imported with GEOBASE2GEOCODE macro (&CURDATE)"
        keep=path addrangeFile roadsegFile strplanameFile province);
    length path $ 260 curFile addrangeFile roadsegFile strplanameFile $ 50 
           province prevProvince$ 2;
    label path           = 'Path to GeoBase file'
          addrangeFile   = 'GeoBase Address Range file'
          roadsegFile    = 'Geobase Road Segment file'
          strplanameFile = 'Geobase Street and Place Name file'
          province       = 'Province';
    %do i=1 %to &FILETOTAL;
      path     = symget('GEOBASEPATH');
      varname  = resolve('FNAME' || trim(left(put(&i, 8.))));
      curFile  = upcase(symget(varname));
      province = scan(curFile, 2, '_');
      if index(curFile, 'ADDRANGE')   then addrangeFile   = curFile;
      if index(curFile, 'ROADSEG')    then roadsegFile    = curFile;
      if index(curFile, 'STRPLANAME') then strplanameFile = curFile;
	  if province ^= prevProvince and index(curFile, 'ROADSEG') then do;
        /*--- Province provided only the road segment file and no
              address range data. */
        output;
        addrangeFile   = '';
        roadsegFile    = '';
        strplanameFile = '';
      end;
	  else if index(curFile, 'STRPLANAME') then do;
	    /*--- We have all three files. */
        output;
        addrangeFile   = '';
        roadsegFile    = '';
        strplanameFile = '';
      end;
	  prevProvince = province;
    %end;
  run;

  /*--- Generate Canadian versions of SASHELP geocoding data sets. */
  %CreateGCtype    /* Street type prefixes/suffixes      */
  %CreateGCdirect  /* Street direction prefixes/suffixes */

  /*--- Import all province GeoBase files. */
  %ImportFiles
  %if &IMPORTERROR=yes %then %goto MacroExit;

  /*--- Generate the three lookup data sets for street geocoding
        and the lookup data set for the city method. */
  %CreateLookupData

%MacroExit:
  /*--- Get elapsed time of import process. */
  data _null_;
    start    = symgetn('STARTDATETIME');
    end      = datetime();
    duration = put(end-start, time.);
    call symput('DURATION', left(duration));
  run;

  /*--- Print summary to log. */
  %if &IMPORTERROR=no %then %do;
    /*--- Lookup data sets were created successfully. */
    %put NOTE: GEOBASE2GEOCODE macro was successful.;
    %put NOTE- Provinces imported : &IMPORTEDNUM;
    %put NOTE- Elapsed time       : &DURATION (hh:mm:ss);
    %put NOTE- Date imported      : &CURDATE;
    %put NOTE- GeoBase files      : &GEOBASEPATH;
    %put NOTE- GeoBase files read : &FILETOTAL;
    %put;
    %put NOTE: Listing of GeoBase files imported and the PROC GEOCODE;
    %put NOTE- lookup data sets are in DATASETPATH location:;
    %put NOTE-   &DATASETPATH;
    %put NOTE- Street method lookup data sets for Canada:;
    %put NOTE-   &LIBNAME..&DATASETNAME.M;
    %put NOTE-   &LIBNAME..&DATASETNAME.S;
    %put NOTE-   &LIBNAME..&DATASETNAME.P;
    %put NOTE- Canada data sets (superceded SASHELP data set):;
    %put NOTE-   &LIBNAME..GCTYPE_CAN    (SASHELP.GCTYPE);
    %put NOTE-   &LIBNAME..GCDIRECT_CAN  (SASHELP.GCDIRECT);
  %end;
  %else %do;
    /*--- Errors occurred. */
    %put ERROR: GEOBASE2GEOCODE macro failed. See log for errors.;
    %put ERROR- Macro parameters:;
    %put ERROR-   GEOBASEPATH=&GEOBASEPATH;
    %put ERROR-   DATASETPATH=&DATASETPATH;
    %put ERROR-   LIBNAME=&LIBNAME;
    %put ERROR-   DATASETNAME=&DATASETNAME;
    %put ERROR-   LABEL=&LABEL;
  %end;
%mend GEOBASE2GEOCODE;

/*------------------------------------------------------------------------------*
 | Name:    InitializeImport
 | Purpose: Verify required macro variables are present, check for optional
 |          macro variables, determine operating system, set librefs, and
 |          create needed directories.
 | Input:   Macro vars specified by user with require parameters.
 *------------------------------------------------------------------------------*/
%macro InitializeImport / des='Setup vars and perform error checks';
  /*--- Declare global macro variables.                             */
  %global OSNAME          /* Is operating system Windows or Unix?   */
          IMPORTERROR     /* Did fatal error occur?                 */
          FILETOTAL       /* Number of GeoBase files imported       */
          IMPORTEDNUM     /* Number of provinces imported           */
          DURATION        /* Runtime for import process             */
          STARTDATETIME   /* Date/time at beginning of import       */
          CURDATE         /* Current date of import                 */
          MAXCITY         /* Min length needed for CITY var         */
          MAXCITY2        /* Min length needed for CITY2 var        */
          MAXNAME         /* Min length needed for NAME var         */
          MAXNAME2        /* Min length needed for NAME2 var        */
          MAXPLACETYPE    /* Min length needed for PLACETYPE var    */
          MAXMAPIDNAME    /* Min length needed for MAPIDNAME var    */
          MAXPREDIRABRV   /* Min length needed for PREDIRABRV var   */
          MAXPRETYPABRV   /* Min length needed for PRETYPABRV var   */
          MAXSUFDIRABRV   /* Min length needed for SUFDIRABRV var   */
          MAXSUFTYPABRV   /* Min length needed for SUFTYPABRV var   */
          MAXROADCLASS;   /* Min length needed for MAXROADCLASS var */

  /*--- Initialize global vars. */
  %let IMPORTERROR = no;
  %let FILETOTAL   = 0;
  %let IMPORTEDNUM = 0;

  /*--- GEOCODE can use Canadian data only in SAS 9.4 or later. */
  %if %eval(&sysver < 9.4) %then %do;
    %put ERROR: The GEOBASE2GEOCODE macro runs only on SAS 9.4 or later.;
	%put ERROR- PROC GEOCODE in your SAS release (&sysver) does not;
	%put ERROR- support Canadian street method geocoding.;
	%let IMPORTERROR = yes;
    %return;
  %end;

  /*--- Get system date and time for start of elapsed time computation. */
  data _null_;
    call symput('STARTDATETIME', put(datetime(), 20.4));
    call symput('CURDATE', put(date(), date9.));
  run;

  /*--- Determine operating system. */
  %if %index(&sysscpl, HP)    = 1 |
      %index(&sysscpl, Linux) = 1 |
      %index(&sysscpl, AIX)   = 1 |
      %index(&sysscpl, Sun)   = 1 |
      %index(&sysscpl, OSF1)  = 1 %then
    /*--- Running some type of Unix. */
    %let OSNAME = UNIX;
  %else %if %index(&sysscp, WIN) = 1 |
            %index(&sysscp, DNT) = 1 %then
    /*--- Running a version of Windows. */
    %let OSNAME = WINDOWS;
  %else %do;
    /*--- Operating system is not supported. */
    %put ERROR: GEOBASE2GEOCODE macro runs only on Windows or Unix.;
    %put ERROR: SYSSCPL=&sysscpl is not supported.;
    %let IMPORTERROR = yes;
    %return;
  %end;

  /*--- Was empty GEOBASEPATH specified? */
  %if %length(&GEOBASEPATH)=0 %then %do;
    %put ERROR: Use macro variable GEOBASEPATH to specify location;
    %put ERROR- where downloaded GeoBase National Road Network (NRN);
    %put ERROR- files were unzipped.;
    %let IMPORTERROR = yes;
    %return;
  %end;
  /*--- GEOBASEPATH cannot contain a comma. It will break prxchange() below. */
  %else %if %sysfunc(indexc(&GEOBASEPATH, ',')) %then %do;
    %put ERROR: GEOBASEPATH location cannot contain a comma (',').;
    %put ERROR- Remove all commas from that directory path.;
    %let IMPORTERROR = yes;
    %return;
  %end;

  /*--- Make sure Windows path uses backslashes (C:\Temp) and Unix path
        uses forward slashes (/usr/data). Then check the last character in
        GEOBASEPATH. If not a slash, append correct slash because we later
        append file names to that path. */
  %if &OSNAME=UNIX %then %do;
    %let GEOBASEPATH = %sysfunc(prxchange(s/\\/\//, -1, &GEOBASEPATH));
    %if %qsubstr(&GEOBASEPATH,%length(&GEOBASEPATH),1)^=%str(/) %then
      %let GEOBASEPATH = %qtrim(&GEOBASEPATH)/;
  %end;
  %else %do;
    %let GEOBASEPATH = %sysfunc(prxchange(s/\//\\/, -1, &GEOBASEPATH));
    %if %qsubstr(&GEOBASEPATH,%length(&GEOBASEPATH),1)^=%str(\) %then
      %let GEOBASEPATH = %qtrim(&GEOBASEPATH)\;
  %end;

  /*--- If required GEOBASEPATH location does not exist, nothing to import. */
  %if %sysfunc(fileexist("&GEOBASEPATH"))=0 %then %do;
    %put ERROR: Location specified by macro variable GEOBASEPATH not found:;
    %put ERROR-   &GEOBASEPATH;
    %let IMPORTERROR = yes;
    %return;
  %end;

  /*--- Was required DATASETPATH specified? */
  %if ^%symexist(DATASETPATH) %then %do;
    %put ERROR: Use macro variable DATASETPATH to specify location;
    %put ERROR- to write PROC GEOCODE lookup data sets created;
    %put ERROR- by GEOBASE2GEOCODE macro.;
    %let IMPORTERROR = yes;
    %return;
  %end;

 /*--- If required DATASETPATH directory does not exist, create it.
        Set SAS options to close OS shell and return to SAS afterwards. */
  %if %sysfunc(fileexist("&DATASETPATH"))=0 %then %do;
    %if &OSNAME=WINDOWS %then %do;
      option noxwait xsync;
    %end;
    x "%str(mkdir %"&DATASETPATH%")";
    /*--- Make sure directory was actually created. */
    %if %sysfunc(fileexist("&DATASETPATH"))=0 %then %do;
      %put ERROR: DATASETPATH directory to write PROC GEOCODE lookup data;
      %put ERROR- sets could not be created:;
      %put ERROR-   &DATASETPATH;
      %put ERROR- Specify a writeable location with macro variable DATASETPATH.;
      %let IMPORTERROR = yes;
      %return;
    %end;
  %end;

  /*--- If empty DATASETNAME specified, set default name prefix. */
  %if %length(&DATASETNAME)=0 %then %do;
    %let DATASETNAME = CANADA;
    %put NOTE: Default data set name prefix "CANADA" used for lookup data;
    %put NOTE- sets. An alternate prefix can be specified with macro;
    %put NOTE- variable DATASETNAME.;
  %end;

  /*--- If empty LIBNAME var specified, set default. */
  %if %length(&LIBNAME)=0 %then %do;
    %let LIBNAME = LOOKUP;
    %put NOTE: Default libname &LIBNAME assigned to PROC GEOCODE;
    %put NOTE- lookup data sets in DATASETPATH location. An alternate;
    %put NOTE- library name can be specified with macro variable LIBNAME.;
  %end;
  %else
    %let LIBNAME = %upcase(&LIBNAME);

  /*--- Set libref to DATASETPATH location. */
  libname &LIBNAME "&DATASETPATH";
  %if &syslibrc %then %do;
    %put ERROR: Cannot set libref &LIBNAME to location specified;
    %put ERROR- by macro varible DATASETPATH:;
    %put ERROR-   &DATASETPATH;
    %let IMPORTERROR = yes;
    %return;
  %end;

  /*--- The all_provinces_roads and all_provinces_xy data sets accumulate
        data for multiple provinces. Clean out old data sets from prior
        runs so new data is not appended to them. */
  proc datasets lib=work nowarn nolist; 
    delete all_provinces_roads;
    delete all_provinces_xy;
  run;
%mend InitializeImport;

/*------------------------------------------------------------------------------*
 | Name:    ImportFiles
 | Purpose: Calls macro programs to import individual GEOBASE files.
 | Input:   Data set listing all GEOBASE province files to be imported.
 *------------------------------------------------------------------------------*/
%macro ImportFiles / des='Import GeoBase province files';
  /*--- Loop thru all GeoBase files in GEOBASEPATH location. */
  data &LIBNAME..geobase_files_&CURDATE 
       (label='Canadian GeoBase files imported for PROC GEOCODE');
    set &LIBNAME..geobase_files_&CURDATE end=finalObs;
    retain importedNum 0;   /* Count number of GeoBase files imported */
	length status $8;       /* Was province imported or skipped?      */
	label  importedNum = 'Incremental number of provinces imported'
	       status      = 'Imported or skipped?';

    if ^missing( addrangeFile ) and ^missing( strplanameFile ) then do;
      /*--- Import ADDRANGE, ROADSEG and STRPLANAME. */
      call execute('%ImportProvince(' || province       || ',' 
                                      || path           || ',' 
                                      || addrangeFile   || ',' 
                                      || roadsegFile    || ',' 
                                      || strplanameFile || ')');
      importedNum + 1;
	  status = 'Imported';
    end;
    else do;
      /*--- Import ROADSEG only. */
      call execute('%ImportRoadseg(' || province    || ',' 
                                     || path        || ','  
                                     || roadsegFile || ')');
      status = 'Skipped';
    end;
    /*--- Check for problems and then increment province counter. */
    if symget('IMPORTERROR')='yes' then stop;
    if finalObs then do;
      /*--- If no province files imported, get out. */
      if importedNum=0 then do;
        call symput('IMPORTERROR', 'yes');
        put 'ERROR: ImportFiles() macro did not create any province data sets.';
      end;
      /*--- Otherwise save the number of imported provinces. */
      else
        call symput('IMPORTEDNUM', trim(left(importedNum)));
    end;
  run;
%mend ImportFiles;

/*------------------------------------------------------------------------------*
 | Name:    ImportRoadseg
 | Purpose: Imports only the ROADSEG.SHP file for the specified province.
 |          The ADDRANGE.DBF and STRPLANAME.DBF files were not provided for
 |          that province. 
 | Note:    If province files include the ADDRANGE and STRPLANAME files,
 |          ImportProvince() is called to import those plus the ROADSEG file.
 | Input:   Province name, path to ROADSEG file and its name.
 | Output:  roadseg2            - Data set created by importing specified 
 |                                province. It is reused with each
 |                                subsequent province import.
 |          all_provinces_roads - Accumulated road names, places, address
 |                                ranges of all provinces imported.
 |          xy                  - Coordinates of streets created by
 |                                importing specified province. Data set
 |                                reused importing subsequent provinces.
 |          all_provinces_xy    - Accumulated coordinates of all provinces.
 *------------------------------------------------------------------------------*/
%macro ImportRoadseg(province,       /* Two-char province abbreviation */
                     path,           /* Path to three target files     */
                     roadsegFile)    /* ROADSEG.SHP filename           */
                     / des='Import GeoBase ROADSEG file for specific province';

  /*--- Import road segment shapefile. */
  proc mapimport out=roadseg datafile="&path&roadsegFile";
    /*--- X, Y and SEGMENT imported by default. Specify additional vars. 
          Since this province does not have ADDRANGE or STRPLANAME files, we
          also import the street name and house number vars here unlike
          ImportProvince() which gets those values from ADDRANGE and STRPLANAME. */
    select NID AdRangeNID roadclass l_placenam r_placenam l_adddirfg r_adddirfg
           l_stname_c r_stname_c l_hnumf r_hnumf l_hnuml r_hnuml;
  run;

  /*--- Separate street coordinates from road segment data. */
  data roadseg2 (keep=l_placenam l_adddirfg AdRangeNID NID roadclass 
                      r_placenam r_adddirfg)
       xy (keep=NID AdRangeNID x y);
    set roadseg end=finalObs;
	retain valid_l_stname_c valid_r_stname_c valid_l_placenam valid_r_placenam 0;
    /*--- Unknown house numbers have a -1 value. A 0 is used when no
	      value applies to this segment. If numbers at both ends of the
	      segment are invalid (0 or -1), set both ends to missing values.
	      But if only one end is invalid and the other end has a valid
	      house number, set both ends equal to the valid house number. */
    if l_hnumf in (-1, 0) then do;
	  if l_hnuml > 0 then l_hnumf = l_hnuml;
	  else                l_hnumf = .;
	end;
    if l_hnuml in (-1, 0) then do;
	  if l_hnumf > 0 then l_hnuml = l_hnumf;
	  else                l_hnuml = .;
	end;
    if r_hnumf in (-1, 0) then do;
	  if r_hnuml > 0 then r_hnumf = r_hnuml;
	  else                r_hnumf = .;
	end;
    if r_hnuml in (-1, 0) then do;
	  if r_hnumf > 0 then r_hnuml = r_hnumf;
	  else                r_hnuml = .;
	end;
    /*--- Remember if non-missing street or place name is encountered. */ 
    if ^valid_l_stname_c & l_stname_c ^in ('Unknown', 'None') then
      valid_l_stname_c = 1;
    if ^valid_r_stname_c & r_stname_c ^in ('Unknown', 'None') then
      valid_r_stname_c = 1;
    if ^valid_l_placenam & l_placenam ^in ('Unknown', 'None') then
      valid_l_placenam = 1;
    if ^valid_r_placenam & r_placenam ^in ('Unknown', 'None') then
      valid_r_placenam = 1;
    /*--- Output initial road segment NID. */
    if _n_ = 1 then
      output roadseg2;
    /*--- Output at beginning of each new NID segment. */
    NIDPrev = lag1(NID);
    if NID ^= NIDPrev & _n_ ^= 1 then
      output roadseg2;
    /*--- Output coordinates for each obs. */
    output xy;
    /*--- Advise user of limitations caused by having only the ROADSEG file. */
    if finalObs then do;
      /*--- Did ROADSEG file contain street and place names? */
      if valid_l_stname_c | valid_r_stname_c |
	     valid_l_placenam | valid_r_placenam then do;
        /*--- When the GEOBASE2GEOCODE macro was first released for SAS 9.4, all
	          Canadian provinces included a complete set of ROADSEG, ADDRANGE
	          and STRPLANAME files --- except Newfoundland and Labrador (NL).
	          The NL ROADSEG file at that time (March 2013) did contain vars for
		      left/right street names, place names, and house number ranges. 
		      However, all the street and place name values were 'Unknown' and 
		      the house number range values were all -1. Without street and place
		      names and house numbers, street level geocoding is impossible.
 
	          So when the NL ROADSEG file was imported with the initial release of
		      GEOBASE2GEOCODE, it fell into the 'else' below because of the missing
		      values. However, if these values were added to a later version of the
		      NL ROADSEG file, then this 'if' may be triggered. In that case, the 
		      support developer needs to look at the street names in the current
		      NL ROADSEG file. If the full street name is in l_placenam/r_placenam,
		      then the street type prefix/suffix and direction prefix/suffix needs to
		      be pulled out into separate vars to match what we get when the
		      STRPLANAME file is imported. 

		      Also, the street and place name values may have to be cleaned as
		      done in the ImportProvince() macro below. It just did not make sense
              to write that code for a situation that may never occur, and should
		      it, we have no idea at this time exactly what may be in those vars.
		      There, if this case is ever encountered, we can deal with it then. */
        put "WARNING: No ADDRANGE or STRPLANAME files found for province &province";
	    put "WARNING- but the ROADSEG file contains limited street and place names.";
        put 'WARNING- Please let SAS Technical Support know of this message and';
        put 'WARNING- which GeoBase files you are importing so we can verify.';
        put 'WARNING- that the street and place names are sufficient for geocoding.';
        call execute('%AppendRoadseg');
      end;
      /*--- But some ROADSEG files do not have street or place names. 
            Street geocoding is not possible in that province, so drop it. */
      else do;
        put "WARNING: No ADDRANGE or STRPLANAME files found for province &province";
        put 'WARNING- and ROADSEG file does not include valid street or place names.';
	    put 'WARNING- Street geocoding is not possible, so streets in province &province';
	    put "WARNING- were omitted from lookup data.";
      end;
    end;  /* if finalObs */
  run;
%mend ImportRoadseg;

/*------------------------------------------------------------------------------*
 | Name:    AppendRoadseg
 | Purpose: Adds the road segments and centerline coordinates for the current
 |          province to the data sets of accumulated segments and coordinates.
 | Note:    Only called when current province lacks ADDRANGE and STRPLANAME files.
 |          See comment block for this call in ImportRoadseg() macro above.
 | Input:   roadseg2 - Data set of street segments created for current province. 
 |                     It is reused with each subsequent province import.
 |          xy       - Coordinates of streets created by importing specified 
 |                     province. Data set reused importing subsequent provinces.
 | Output:  all_provinces_roads - Accumulated road names, places, address
 |                                ranges of all provinces imported.
 |          all_provinces_xy    - Accumulated coordinates of all provinces.
 *------------------------------------------------------------------------------*/
%macro AppendRoadseg /des='Appends ROADSEG and XY files to summation data sets';
  /*--- Add current province data to data from other provinces. */
  proc append data=roadseg2 out=all_provinces_roads;
  run;
  proc append data=xy out=all_provinces_xy;
  run;
%mend AppendRoadseg;

/*------------------------------------------------------------------------------*
 | Name:    ImportProvince
 | Purpose: Imports three required files (ADDRANGE.DBF, ROADSEG.SHP, and 
 |          STRPLANAME.DBF) for specified province. Then it cleans up the data
 |          and finally appends it to a data set of accumulated province data.
 | Note:    If province lacks the ADDRANGE and STRPLANAME files, ImportRoadseg()
 |          is called to import only the ROADSEG shapefile.
 | Input:   Province name, path to GeoBase files and names of the files.
 | Output:  roadseg_addrange_placename - Data set created by importing specified 
 |                                       province. It is reused with each
 |                                       subsequent province import.
 |          all_provinces_roads        - Accumulated road names, places, address
 |                                       ranges of all provinces imported.
 |          xy                         - Coordinates of streets created by
 |                                       importing specified province. Data set
 |                                       reused importing subsequent provinces.
 |          all_provinces_xy           - Accumulated coordinates of all provinces.
 *------------------------------------------------------------------------------*/
%macro ImportProvince(province,       /* Two-char province abbreviation */
                      path,           /* Path to three target files     */
                      addrangeFile,   /* ADDRANGE.DBF                   */
                      roadsegFile,    /* ROADSEG.SHP                    */
                      strplanameFile) /* STRPLANAME.DBF                 */
					  / des='Imports GeoBase files for specific province';

  /*--- Import address range file. ---------------------------------------------*/
  proc mapimport out=addrange datafile="&path&addrangeFile";
    /*--- X, Y and SEGMENT imported by default. Specify additional vars. */
    select l_offnaNID l_hnumf l_hnuml l_digdirfg
           r_offnaNID r_hnumf r_hnuml r_digdirfg NID; 
  run;
  
  /*--- Split address ranges into left/right files. */
  data addrange_left  (keep=l_hnumf l_hnuml l_offnaNID l_digdirfg NID)
       addrange_right (keep=r_hnumf r_hnuml r_offnaNID r_digdirfg NID);
    set addrange;
    /*--- Unknown house numbers have a -1 value. A 0 is used when no
	      value applies to this segment. If numbers at both ends of the
	      segment are invalid (0 or -1), set both ends to missing values.
	      But if only one end is invalid and the other end has a valid
	      house number, set both ends equal to the valid house number. */
    if l_hnumf in (-1, 0) then do;
	  if l_hnuml > 0 then l_hnumf = l_hnuml;
	  else                l_hnumf = .;
	end;
    if l_hnuml in (-1, 0) then do;
	  if l_hnumf > 0 then l_hnuml = l_hnumf;
	  else                l_hnuml = .;
	end;
    if r_hnumf in (-1, 0) then do;
	  if r_hnuml > 0 then r_hnumf = r_hnuml;
	  else                r_hnumf = .;
	end;
    if r_hnuml in (-1, 0) then do;
	  if r_hnumf > 0 then r_hnuml = r_hnumf;
	  else                r_hnuml = .;
	end;
  run;

  /*--- Import road segment file. ----------------------------------------------*/
  proc mapimport out=roadseg datafile="&path&roadsegFile";
    /*--- X, Y and SEGMENT imported by default. Specify additional vars.
          Note that we do not import the l_stname_c, r_stname_c, l_hnumf,
          r_hnumf, l_hnuml or r_hnuml vars from ROADSEG. Those values are
          acquired from the accompanying ADDRANGE and STRPLANAME files. */
    select NID AdRangeNID roadclass l_placenam r_placenam l_adddirfg r_adddirfg;
  run;

  /*--- Separate street coordinates from road segment data. */
  data roadseg2 (keep=l_placenam l_adddirfg AdRangeNID NID roadclass 
                      r_placenam r_adddirfg)
       xy (keep=NID AdRangeNID x y);
    set roadseg;
    if _n_ = 1 then
      output roadseg2;
    /*--- Get previous NID value to see if it changed. */
    NIDPrev   = lag1(NID);
    /*--- At start of next NID segment, output and reinitialize counter. */
    if NID ^= NIDPrev & _n_ ^= 1 then
      output roadseg2;
    /*--- Output coordinates for each obs. */
    output xy;
  run;

  /*--- Import street name/place file. -----------------------------------------*/
  proc mapimport out=strplaname datafile="&path&strplanameFile";
    select dirprefix dirsuffix NID province placename placetype
           starticle namebody strtypre strtysuf;
  run;

  /*--- GeoBase street names can contain a direction prefix and/or suffix
        in the NAMEBODY field, e.g. 'North Fork East' in the Yukon Terr.
        Convert those direction strings into abbreviations and put them
        into PreDirAbrv and SufDirAbrv. */
  data strplaname2;
    set strplaname;
	length first last $20;
    /*--- If no street name, cannot use it for street level lookups. */
    if namebody ^= 'None' & namebody ^= 'Unknown';
	/*--- Normalize for merging. */
	dirprefix = upcase(dirprefix);
    dirsuffix = upcase(dirsuffix);
	/*--- Get first and last word of street name string. */
    first = upcase(scan(namebody,  1));
	last  = upcase(scan(namebody, -1));
  run;

  proc sort;
    by dirprefix;
  run;

  /*--- Convert dirprefix from full direction name to abbreviation. */
  data strplaname3 (drop=dirprefix rename=(dirabrv=PreDirAbrv));
    merge strplaname2 (in=a)
          &LIBNAME..GCdirect_CAN (rename=(direction=dirprefix));
    by dirprefix;
    if a;
    label dirabrv=;
  run;

  proc sort;
    by dirsuffix;
  run;

  /*--- Convert dirsuffix from full direction name to abbreviation. */
  data strplaname4 (drop=dirsuffix rename=(dirabrv=SufDirAbrv));
    merge strplaname3 (in=a)
          &LIBNAME..GCdirect_CAN (rename=(direction=dirsuffix));
    by dirsuffix;
    if a;
    label dirabrv=;
  run;

  proc sort;
    by first;
  run;

  /*--- Add abbreviation if first word in street name is a direction. */
  data strplaname5;
    merge strplaname4 (in=a)
          &LIBNAME..GCdirect_CAN (rename=(direction=first));
    by first;
    if a;
  run;

  /*--- If first word in street name is a direction word 
        (i.e. East Point Road), put its abbreviation into the prefix var. */
  data strplaname5 (drop=dirabrv);
    set strplaname5;
    if ^missing(dirabrv) & first ^= last then do;
      /*--- Street name is more than one word and first word is a
            direction name. Move the prefix abbreviation into the var
            and remove the direction word from the street name. */ 
      PreDirAbrv = dirabrv;
      namebody   = substr(namebody, length(first)+2);
	  /*--- If first remaining character is punctuation, drop it. */
	  if findc(namebody, , 'ps') = 1 then
        namebody = substr(namebody, 2);
    end;
  run;

  proc sort;
    by last;
  run;

  /*--- Add abbreviation if last word in street name is a direction. */
  data strplaname6;
    merge strplaname5 (in=a)
          &LIBNAME..GCdirect_CAN (rename=(direction=last));
    by last;
    if a;
  run;

%macro original;
  /*--- If last word in street name is a direction word 
        (i.e. Down East Crescent), put its abbreviation into the suffix var. */
  data strplaname6 (drop=dirabrv first last len pos);
    set strplaname6;
    if ^missing(dirabrv) & first ^= last then do;
      /*--- Street name is more than one word and last word is a
            direction name. Move the suffix abbreviation into the var
            and remove the direction word from end of the street name. */ 
      len = length(namebody)-length(last)-1;
      if len > 0 then do;
        SufDirAbrv = dirabrv;
        namebody   = substr(namebody, 1, len);
      end;
      /*--- If last remaining character is a hyphen, comma or
            underscore, drop it. */
      pos = findc(namebody, '-,_', 'b');
      if pos then do;
        len = length(namebody);
        if pos = len then
          namebody = substr(namebody, 1, pos-1);
      end;
    end;
  run;

  /*--- Convert suftypabrv from full name to abbreviation. */
  proc sort data=strplaname6 (rename=(strtysuf=suftypabrv));
    by suftypabrv;
  run;

  data strplaname6 (drop=suftypabrv);
    set strplaname6;
  run;
%mend;

  /*--- If last word in street name is a direction word 
        (i.e. Down East Crescent), put its abbreviation into the suffix var. */
  data strplaname6 (drop=dirabrv first last len pos);
    set strplaname6;
    if ^missing(dirabrv) & first ^= last then do;
      /*--- Street name is more than one word and last word is a
            direction name. Move the suffix abbreviation into the var
            and remove the direction word from end of the street name. */ 
      len = length(namebody)-length(last)-1;
      if len > 0 then do;
        SufDirAbrv = dirabrv;
        namebody   = substr(namebody, 1, len);
      end;
      /*--- If last remaining character is a hyphen, comma or
            underscore, drop it. */
      pos = findc(namebody, '-,_', 'b');
      if pos then do;
        len = length(namebody);
        if pos = len then
          namebody = substr(namebody, 1, pos-1);
      end;
    end;
    /*--- Normalize for sorting below. */
    strtysuf = upcase(strtysuf);
    strtypre = upcase(strtypre);
  run;

  proc sort data=strplaname6;
    by strtysuf;
  run;

  data strplaname7 (drop=type name);
    merge strplaname6 (in=a rename=(strtysuf=name))
          &LIBNAME..GCtype_can;
    by name;
    if a;
	SufTypAbrv=propcase(type);
  run;

  /*--- Convert strtypre from full name to abbreviation. */
  proc sort data=strplaname7; /* ggg */
    by strtypre;
  run;

  data strplaname8 (drop=type name namebodyUp);
    merge strplaname7 (in=a rename=(strtypre=name))
          &LIBNAME..GCtype_can;
    by name;
    if a;
    PreTypAbrv=propcase(type);
    output;
    namebodyUp = upcase(namebody);
    /*--- If street name includes 'Saint', output an extra obs to
          cover 'St'. Original namebody was output earlier. */
    if findw(namebodyUp, 'SAINT') then do;
      namebody = tranwrd(namebody, 'Saint', 'St');
      output;
    end;
    /*--- If street name includes 'St', output an extra obs to cover
          'Saint'. Original namebody was output earlier. */
    if findw(namebodyUp, 'ST.') then do;
      namebody = tranwrd(namebody, 'St.', 'Saint');
      output;
    end;
    if findw(namebodyUp, 'ST-') then do;
      namebody = tranwrd(namebody, 'St-', 'Saint-');
      output;
    end;
    if findw(namebodyUp, 'ST') then do;
      namebody = tranwrd(namebody, 'St', 'Saint');
      output;
    end;
    /*--- If street name includes 'Sainte', output an extra obs to
          cover 'Ste'. Original namebody was output earlier. */
    if findw(namebodyUp, 'SAINTE') then do;
      namebody = tranwrd(namebody, 'Sainte', 'Ste');
      output;
    end;
    /*--- If street name includes 'Ste', output an extra obs to cover
          'Sainte'. Original namebody was output earlier. */
    if findw(namebodyUp, 'STE.') then do;
      namebody = tranwrd(namebody, 'Ste.', 'Sainte');
      output;
    end;
    if findw(namebodyUp, 'STE-') then do;
      namebody = tranwrd(namebody, 'Ste-', 'Sainte-');
      output;
    end;
    if findw(namebodyUp, 'STE') then do;
      namebody = tranwrd(namebody, 'Ste', 'Sainte');
      output;
    end;
    /*--- If street name includes 'Mount', output an extra obs to
          cover 'Mt'. Original namebody was output at top. */
    if findw(namebodyUp, 'MOUNT') then do;
      namebody = tranwrd(namebodyUp, 'Mount', 'Mt');
      output;
    end;
	/*--- Check French spelling, too. */
    if findw(namebodyUp, 'MONT') then do;
      namebody = tranwrd(namebodyUp, 'Mont', 'Mt');
      output;
    end;
    /*--- If street name includes 'Mt.', output an extra obs to
          cover 'Mount'. Original namebody was output at top. */
    if findw(namebodyUp, 'MT.') then do;
      namebody = tranwrd(namebodyUp, 'Mt.', 'Mount');
      output;
    end;
    if findw(namebodyUp, 'MT-') then do;
      namebody = tranwrd(namebodyUp, 'Mt-', 'Mount-');
      output;
    end;
    /*--- If street name includes 'Mt', output an extra obs to
          cover 'Mount'. Original namebody was output at top. */
    if findw(namebodyUp, 'MT') then do;
      namebody = tranwrd(namebodyUp, 'Mt', 'Mount');
      output;
    end;
  run;

  /*--- Rename the NID link var to match the road segment link
        var name and sort left/right address ranges for merging. */
  proc sort data=addrange_left (rename=(NID=AdRangeNID));
    by AdRangeNID;
  run;
  
  proc sort data=addrange_right (rename=(NID=AdRangeNID));
    by AdRangeNID;
  run;

  /*--- Sort road segments with place names by address range data set link var. */
  proc sort data=roadseg2;
    by AdRangeNID;
  run;

  /*--- Add left/right address ranges to place names on the road segments. */
  data roadseg_addrange;
    merge roadseg2 (in=a) addrange_left;
    by AdRangeNID;
    if a & ^missing(NID);
  run;
  
  data roadseg_addrange;
    merge roadseg_addrange (in=a) addrange_right;
    by AdRangeNID;
    if a & ^missing(NID);
  run;
  
  /*--- Sort road segments for merging with left side place name data set. */
  proc sort data=roadseg_addrange;
    by l_offnaNID;
  run;

  /*--- Rename place name data set link var to match var from road
        segment data and sort for merging with that data set. Also rename 
        GeoBase var to match lookup name expected by PROC GEOCODE. */
  proc sort data=strplaname8 (rename=(NID = offnaNID))
    out=strplaname8;
    by offnaNID;
  run;
  
  /*--- Although most street segments imported from the roadseg file 
        contained place names, the strplaname file has a few more.
        Fill in left side place names missing from the roadseg data
        with place names imported from the strplaname file. */
  data roadseg_addrange_placename (drop=placename l_offnaNID);
    merge roadseg_addrange (in=a) 
          strplaname8 (rename=(offnaNID=l_offnaNID));
    by l_offnaNID;

    /*--- Keep only road segments with valid names. Since the GeoBase
	      files do not have Canadian post codes, we can geocode only
	      using the street+city+province combination. */
    if a                                       &        /* Keep first data set obs  */
       namebody ^= 'None' & ^missing(namebody) &        /* With valid street names  */
       upcase(placename) ^= 'UNKNOWN'          &        /* Valid city names and     */
       upcase(scan(placename,-1,' ')) ^= 'UNORGANIZED'; /* Not unincorporated areas */

    /*--- Is original left side placename from roadseg_addrange missing? */
    if missing(l_placenam) | upcase(l_placenam) = 'UNKNOWN' then do;
      /*--- If placename from strplaname data set is valid, use it. */
      if ^missing(placename) then
        l_placenam = placename;
      /*--- Otherwise we have no left-side placename at all, so dump obs. */
      else 
        delete;
    end;
  run;
  
  /*--- Sort street segments for merging with right side place names. */
  proc sort data=roadseg_addrange_placename;
    by r_offnaNID;
  run;

  /*--- Fill in right side place names missing from the roadseg data
        with place names imported from the strplaname file. This also
        cleans the city names for geocoding. */
  data roadseg_addrange_placename (keep=NID AdRangeNID RoadClass City2
                                        Name FromAdd ToAdd PreDirAbrv
                                        SufDirAbrv PreTypAbrv SufTypAbrv 
                                        MapIDName MapIDNameAbrv Side PlaceType);
    merge roadseg_addrange_placename (in=a) 
          strplaname8 (rename=(offnaNID=r_offnaNID province=MapIDName));
    by r_offnaNID;
    length Name $70 City2 $100 MapIDNameAbrv $2;
    retain MapIDNameAbrv;
    if _n_=1 then 
      MapIDNameAbrv = "&province";
    if a;

    /*--- If street segment is a freeway ramp, roundabout, rotary or 
	      service lane (a crossover on a limited access roadway), drop it. */
    namebodyUp = upcase(namebody);
    if upcase(roadclass) in('RAMP', 'SERVICE LANE') |
       indexw(namebodyUp, 'RAMP')                   | 
       indexw(namebodyUp, 'ROTARY')                 |
       indexw(namebodyUp, 'ROUNDABOUT') then
      delete;

    /*--- If original right side placename from roadseg_addrange is
	      missing, use placename from strplaname data set. */
    if missing(r_placenam) | upcase(r_placenam) = 'UNKNOWN' then
      r_placenam = placename;

    /*--- Is original right side placename from roadseg_addrange missing? */
    if missing(r_placenam) | upcase(r_placenam) = 'UNKNOWN' then do;
      /*--- If placename from strplaname data set is valid, use it. */
	  if ^missing(placename) then
        r_placenam = placename;
      /*--- Otherwise we have no right-side placename at all, so dump obs. */
      else 
        delete;
    end;

    /*--- GeoBase uses 'None' for missing strings. Reset to SAS missing. */
    if PreTypAbrv = 'None' then PreTypAbrv = ' ';
    if SufTypAbrv = 'None' then SufTypAbrv = ' ';
    if StrTypPre  = 'None' then StrTypPre  = ' ';
    if StrTypSuf  = 'None' then StrTypSuf  = ' ';
    if StArticle  = 'None' then StArticle  = ' ';

    /*--- Concatenate strings to construct street name . */
    Name = left(trim(left(starticle)) || trim(left(namebody)));

    /*--- Some street segments are just exits with no address numbers. */
    if indexw(Name, 'Exit') & 
       l_hnumf=0 & l_hnuml=0 & r_hnumf=0 & r_hnuml=0 then
      delete;

    /*--- If street name has 'Highway' in front, move to proper var
          where the geocode parser expects it. */
    if indexw(Name, 'Highway') = 1 then do;
      PreTypAbrv = 'Highway';
      Name       = substr(Name, 9);
    end;

    /*--- Some street names include 'WB', 'EB', 'NB', 'SB' or a combination. */
    pos = indexw(Name, 'WB');
    if pos > 1 then do;
      Name = substr(Name, 1, pos-1) || substr(Name, pos+3);
      SufDirAbrv = 'West';
    end;
    pos = indexw(Name, 'EB');
    if pos > 1 then do;
      Name = substr(Name, 1, pos-1) || substr(Name, pos+3);
      SufDirAbrv = 'East';
    end;
    pos = indexw(Name, 'NB');
    if pos > 1 then do;
      Name = substr(Name, 1, pos-1) || substr(Name, pos+3);
      SufDirAbrv = 'North';
    end;
    pos = indexw(Name, 'SB');
    if pos > 1 then do;
      Name = substr(Name, 1, pos-1) || substr(Name, pos+3);
      SufDirAbrv = 'South';
    end;
    pos = indexw(Name, 'EB-WB');
    if pos > 1 then
      Name = substr(Name, 1, pos-1) || substr(Name, pos+6);
    pos = indexw(Name, 'WB-EB');
    if pos > 1 then
      Name = substr(Name, 1, pos-1) || substr(Name, pos+6);

    /*--- Some obs have descriptors encased in parenthesis in front of
          the street name, e.g. '(B.M.P.C) Broad River Street' in
          Port Mouton, NS. Strip off the parenthetical descriptor. */
    pos = indexc(Name, '(');
    if pos = 1 then do;
      pos  = indexc(Name, ')');
      Name = left(substr(Name, pos+1));
    end;

    /*--- If after cleaning there is no street name, drop the obs. */
    if missing(Name) then
      delete;

    /*--- Keep first part of placetype value and drop second (French) part. */
    placetype = trim(scan(placetype, 1, '/'));

    /*--- If left/right placenames are identical, clean only once. */
    if l_placenam = r_placenam then do;
      /*--- Make case-insensitive comparisions. */
      City2 = upcase(l_placenam);
      link CleanCity;
      /*--- Output left side street values. */
      FromAdd = l_hnumf;
      ToAdd   = l_hnuml;
      side    = 'L';
      output;
      /*--- If house number ranges differ, output right side segment. */
      if r_hnumf ^= l_hnumf | r_hnuml ^= l_hnuml then do;
        FromAdd = r_hnumf;
        ToAdd   = r_hnuml;
        side    = 'R';
        output;
      end;
    end;
  
    /*--- Otherwise left/right city names are different
          and must be cleaned separately. */
    else do;
      /*--- Clean the left city name. */
      City2 = upcase(l_placenam);
      link CleanCity;
      /*--- Output left side segment. */
      FromAdd = l_hnumf;
      ToAdd   = l_hnuml;
      side    = 'L';
      output;
  
      /*--- Clean the right city name. */
      City2 = upcase(r_placenam);
      link CleanCity;
      /*--- Output right side street segment. */
      FromAdd = r_hnumf;
      ToAdd   = r_hnuml;
      side    = 'R';
      output;
    end;
    return;

    /*--- City names are from the L_PLACENAM/R_PLACENAM vars from the 
          roadseg shapefile or the PLACENAME var in the strplaname dbf 
          file and must be scrubbed for more consistant address parsing. */
  CleanCity:
    /*--- Dirty: City of Toronto
          Clean: Toronto */
    pos = index(City2, 'CITY OF ');
    if pos = 1 then
      City2 = substr(City2, 9);
  
    /*--- Dirty: Village of Severn
          Clean: Severn */
    pos = index(City2, 'VILLAGE OF ');
    if pos = 1 then
      City2 = substr(City2, 12);
  
    /*--- Dirty: Town of Minto
          Clean: Minto */
    pos = index(City2, 'TOWN OF ');
    if pos = 1 then
      City2 = substr(City2, 9);
  
    /*--- Dirty: Municipality of The Nation
          Clean: The Nation */
    pos = index(City2, 'MUNICIPALITY OF ');
    if pos = 1 then
      City2 = substr(City2, 17);
  
    /*--- Dirty: District of Algoma
          Clean: Algoma */
    pos = index(City2, 'DISTRICT OF ');
    if pos = 1 then
      City2 = substr(City2, 13);
  
    /*--- Dirty: Township of Southgate
          Clean: Southgate */
    pos = index(City2, 'TOWNSHIP OF ');
    if pos = 1 then
      City2 = substr(City2, 13);
  
    /*--- Dirty: Big Lakes, M.D. of
          Clean: Big Lakes */
    pos = index(City2, ', M.D.');
    if pos then
      City2 = substr(City2, 1, pos-1);
  
    /*--- Dirty: Thorhild No. 7, County of
          Clean: Thorhild No. 7 */
    pos = index(City2, ', COUNTY OF');
    if pos then
      City2 = substr(City2, 1, pos-1);
  
    /*--- Dirty: Lac Ste. Anne County
          Clean: Lac Ste. Anne */
    pos = index(City2, ' COUNTY');
    if pos then
      City2 = substr(City2, 1, pos-1);
  
    /*--- Dirty: Reg Mun of Wood Buffalo
          Clean: Wood Buffalo */
    pos = index(City2, 'REG MUN OF ');
    if pos then
      City2 = substr(City2, pos+11);
  
    /*--- Dirty: Kikino (Metis Settlement)
          Clean: Kikino */
    pos = index(City2, ' (METIS SETTLEMENT)');
    if pos then
      City2 = substr(City2, 1, pos-1);
  
    /*--- Dirty: I.D. No. 12 Jasper Park
          Clean: Jasper Park */
    pos = index(City2, 'I.D. NO. ');
    if pos = 1 then do;
      /*--- Hack 'I.D. No. ' off the front of the name. */
      City2 = substr(City2, 10);
      /*--- Get position of first blank after the ID number (12)
            and hack that off the front end too. */
      pos = index(City2, ' ');
      if pos then
        City2 = substr(City2, pos+1);
    end;
    else if pos > 1 then
      /*--- 'I.D. No. ' is on end of string. */
      City2 = substr(City2, 1, pos-1);
  
    /*--- Dirty: Kananaskis I.D.
          Clean: Kananaskis */
    pos = index(City2, ' I.D.');
    if pos then
      City2 = substr(City2, 1, pos-1);
  
    /*--- Dirty: Bighorn No. 8
          Clean: Bighorn */
    pos = index(City2, 'NO. ');
    if pos = 1 then do;
      /*--- Hack 'No. ' off the front of the name. */
      City2 = substr(City2, pos+5);
      /*--- Get position of first blank after the ID number (8)
            and hack that off the front end too. */
      pos = index(City2, ' ');
      if pos then
        City2 = substr(City2, pos+1);
    end;
    else if pos > 1 then
      /*--- 'No. ' is on end of string. Truncate it. */
      City2 = substr(City2, 1, pos-1);
  
    /*--- Dirty: Minburn No 27
          Clean: Minburn */
    pos = index(City2, ' NO ');
    if pos > 1 then
      /*--- ' No ' is on end of string. Truncate it. */
      City2 = substr(City2, 1, pos-1);
  
    /*--- Dirty: Jasper, Municipality of
          Clean: Jasper */
    pos = index(City2, ', MUNICIPALITY OF');
    if pos then
      City2 = substr(City2, 1, pos-1);
  
    /*--- Dirty: Beaver Lake #131
          Clean: Beaver Lake 131 */
    City2 = tranwrd(City2, ' #', ' ');
    return; /* End of CleanCity link */
  run;

  /*--- Transcode non-English characters into latin1. */
  data roadseg_addrange_placename2;
    set roadseg_addrange_placename (encoding=utf8);
    /*--- Make a more readable city name using proper case. */
    city = propcase(city2);
    /*--- Clean city var for where clause use. compress() options are:
	        'p' - punctuation marks
            'h' - horizontal tab */
    city2 = compress(upcase(city2), ' ', 'ph');
    /*--- Normalize a street name string for where clause use. */
    Name2 = upcase(compress(Name, " -.`'_"));
  run;

  /*--- Add current province data to data from other provinces. */
  proc append data=roadseg_addrange_placename2 out=all_provinces_roads;
  run;
  proc append data=xy out=all_provinces_xy;
  run;
%mend ImportProvince;

/*------------------------------------------------------------------------------*
 | Name:    CreateGCtype
 | Purpose: Creates data set of street type names and abbreviations. 
 | Input:   CSV values for street types and abbreviations in the
 |          initial data step.
 | Output:  GCtype_CAN - Data set of street types and abbreviations.
 | Usage:   The resulting data set is used in place of SASHELP.GCTYPE when
 |          geocoding Canadian street addresses. Use the TYPE= option in
 |          PROC GEOCODE to specify this data set.
 | Note:    If additional street type abbreviations are needed, add them
 |          to the CSV values in the initial DATA step. If adding a new 
 |          abbreviation to an existing street type, make sure to use the same
 |          GROUP value as the original abbreviations. But if adding a 
 |          new street type and abbreviation, use a new GROUP value.
 *------------------------------------------------------------------------------*/
%macro CreateGCtype / des='Create street type data set with Canadian types';

  /*--- Write flat file to the lookup data set location. */
  filename GCtype "&DATASETPATH/GCtype.txt";

  /*--- Create flat file of street types and abbreviations used in addresses.
        We cannot just use a data step to create the street type data set 
        directly because a macro cannot contain a CARDS/DATALINES statement.
        The numbers are values for the GROUP variable which identify equivalent
        English and French street types. */
  data _null_;
    file GCtype;
    put "Abbey, ABBEY, 2, Acres, ACRES, 4, Allée, ALLÉE, 6, Alley, ALLEY, 6";
    put "Autoroute, AUT, 8, Avenue, AVE, 10, Avenue, AV, 10, Bay, BAY, 12";
    put "Beach, BEACH, 14, Bend, BEND, 16, Boulevard, BLVD, 18";
    put "Boulevard, BOUL, 18, By-pass, BYPASS, 20, Byway, BYWAY, 22";
    put "Campus, CAMPUS, 24, Cape, CAPE, 26, Carré, CAR, 28, Carrefour, CARREF, 30";
    put "Centre, CTR, 32, Centre, C, 32, Cercle, CERCLE, 34, Circle, CIR, 34";
    put "Chase, CHASE, 36, Chemin, CH, 38, Circuit, CIRCT, 40, Close, CLOSE, 42";
    put "Common, COMMON, 44, Concession, CONC, 46, Corners, CRNRS, 48, Côte, CÔTE, 50";
    put "Cour, COUR, 52, Court, CRT, 52, Cours, COURS, 54, Cove, COVE, 58";
    put "Crescent, CRES, 60, Croissant, CROIS, 60, Crossing, CROSS, 62";
    put "Cul-de-sac, CDS, 64, Dale, DALE, 66, Dell, DELL, 68, Diversion, DIVERS, 70";
    put "Downs, DOWNS, 72, Drive, DR, 74, Échangeur, ÉCH, 76, End, END, 78";
    put "Esplanade, ESPL, 80, Estates, ESTATE, 82, Expressway, EXPY, 84";
    put "Extension, EXTEN, 86, Extension, EXT, 86, Farm, FARM, 88, Field, FIELD, 90";
    put "Forest, FOREST, 92, Freeway, FWY, 94, Front, FRONT, 96, Gardens, GDNS, 98";
    put "Gate, GATE, 100, Glade, GLADE, 102, Glen, GLEN, 104, Green, GREEN, 106";
    put "Grounds, GRNDS, 108, Grove, GROVE, 110, Harbour, HARBR, 112, Heath, HEATH, 114";
    put "Heights, HTS, 116, Highlands, HGHLDS, 118, Highway, HWY, 120, Hill, HILL, 122";
    put "Hollow, HOLLOW, 124, Île, ÎLE, 126, Island, ISLAND, 126, Impasse, IMP, 128";
    put "Inlet, INLET, 130, Key, KEY, 132, Knoll, KNOLL, 134, Landing, LANDNG, 136";
    put "Lane, LANE, 138, Limits, LMTS, 140, Line, LINE, 142, Link, LINK, 144";
    put "Lookout, LKOUT, 146, Loop, LOOP, 148, Mall, MALL, 150, Manor, MANOR, 152";
    put "Maze, MAZE, 154, Meadow, MEADOW, 156, Mews, MEWS, 158, Montée, MONTÉE, 160";
    put "Moor, MOOR, 162, Mount, MOUNT, 164, Mountain, MTN, 166, Orchard, ORCH, 168";
    put "Parade, PARADE, 170, Parc, PARC, 172, Park, PK, 172, Parkway, PKY, 174";
    put "Passage, PASS, 176, Path, PATH, 178, Pathway, PTWAY, 180, Pines, PINES, 182";
    put "Place, PL, 184, Place, PLACE, 184, Plateau, PLAT, 186, Plaza, PLAZA, 188";
    put "Point, PT, 190, Pointe, POINTE, 190, Port, PORT, 192, Private, PVT, 194";
    put "Promenade, PROM, 196, Quai, QUAI, 198, Quay, QUAY, 198";
    put "Ramp, RAMP, 200, Rang, RANG, 200, Range, RG, 200, Ridge, RIDGE, 202";
    put "Rise, RISE, 204, Road, RD, 206, Rond-point, RDPT, 208, Route, RTE, 210";
    put "Row, ROW, 212, Rue, RUE, 214, Ruelle, RLE, 216, Run, RUN, 218";
    put "Sentier, SENT, 220, Square, SQ, 222, Street, ST, 224, Subdivision, SUBDIV, 226";
    put "Terrace, TERR, 228, Terrasse, TSSE, 228, Thicket, THICK, 230, Towers, TOWERS, 232";
    put "Townline, TLINE, 234, Trail, TRAIL, 236, Turnabout, TRNABT, 238, Vale, VALE, 240";
    put "Via, VIA, 242, View, VIEW, 244, Village, VILLGE, 246, Villas, VILLAS, 248";
    put "Vista, VISTA, 250, Voie, VOIE, 252, Walk, WALK, 254, Way, WAY, 256";
    put "Wharf, WHARF, 258, Wood, WOOD, 260, Wynd, WYND, 262";
run;

  /*--- Read the street type flat file into a data set. */
  data gctype;
    infile GCtype dlm=',';
	/*--- Use var names expected by PROC GEOCODE. */
    length NAME $20 TYPE $10 GROUP 3;
    input name type group @@;
    /*--- Normalize the values for case-insensitive comparisons. */
    name = upcase( compress(name, ' ', 'aik') );
    type = upcase( compress(type, ' ', 'aik') );
	output;
  run;

  /*--- Sort is required before using the lag1() function in next step. */
  proc sort;
    by type;
  run;

  /*--- The GCtype data set observations include street types with their
        abbreviations (ROAD and RD). There must also be an observation
        of the abbreviation and the abbreviation (RD and RD). If the 
        input address obs includes 'Road' or 'Rd' as the street type, 
        then the GCTYPE data needs to cover both. For example, the NAME
        var in the GCTYPE data set must contain observations for both 
        'ROAD' and 'RD' to handle either '8000 Smith Road' and 
        '8000 Smith Rd'. Some selected examples are:
           NAME       TYPE    GROUP
           ----       ----    -----
           BEND       BEND     16   
           BLVD       BLVD     18  <- English abbreviation for both values
           BOUL       BOUL     18  <- French abbreviation for both values
           BOULEVARD  BLVD     18  <- English street type with abbreviation
           BOULEVARD  BOUL     18  <- French street type with abbreviation
           BY-PASS    BYPASS   20
        So, read the street types imported from the CSV file and add
        the observations for the type abbreviations. */
  data &LIBNAME..GCtype_CAN;
    set gctype;
	label name  = 'Common prefix/suffix or abbreviation'
              type  = 'Standard abbreviation'
              group = 'Equivalent grouping';
    /*--- Write obs with the full length type and its abbreviation. */
    output;
    /*--- If we are at a new abbreviation, write an obs with the
          abbreviation twice, one for NAME and one for TYPE. */
    if type ^= lag1(type) & name ^= type then do;
      name = type;
      output;
    end;
  run;

  /*--- Re-sort for binary search order. */
  proc sort;
    by name;
  run;

  /*--- Add index and label to the street type data set. 
        NOTE: This is only needed for GEOCODE in 9.4 SAS. 
              Beginning in 9.4M1 the type data set is read with a binary search. 
              After 9.5 is released, we can likely stop creating the index. */
  proc datasets lib=&LIBNAME nolist;
    modify GCtype_CAN (label="Street type abbreviations for Canadian geocoding, Updated &CURDATE");
    index create name;
  run;
%mend CreateGCtype;

/*------------------------------------------------------------------------------*
 | Name:    CreateGCdirect
 | Purpose: Creates data set of street directions and abbreviations. 
 | Input:   CSV values for street directions and abbreviations in the
 |          initial data step.
 | Output:  GCdirect_CAN - Data set of street directions and abbreviations.
 | Usage:   The resulting data set is used in place of SASHELP.GCDIRECT when
 |          geocoding Canadian street addresses. Use the DIRECTION= option in
 |          PROC GEOCODE to specify this data set.
 | Note:    If additional street type directions are needed, add them
 |          to the CSV values in the initial DATA step.
 *------------------------------------------------------------------------------*/
%macro CreateGCdirect / des='Create street direction data set with Canadian directions';

  /*--- Write flat file to the lookup data set location. */
  filename GCdirect "&DATASETPATH/GCdirect.txt";

  /*--- Create flat file of street directions and abbreviations used in addresses.
        We cannot just use a data step to create the street direction data set 
        directly because a macro cannot contain a CARDS/DATALINES statement.
        Place asterisk (*) as first character in comment lines. */
  data _null_;
    file GCdirect;
	put "* CSV file of street directions and abbreviations for Canadian geocoding";
	put "* created by the GEOBASE2GEOCODE SAS macro program (&CURDATE)";
    put "North, N, East, E, South, S, West, W";
    put "Northeast, NE, Southeast, SE, Southwest, SW, Northwest, NW";
	put "Nord, N, Est, E, Sud, S, Ouest, O";
	put "Nord-Est, NE, Sud-Est, SE, Sud-Ouest, SO, Nord-Ouest, NO";
run;

  /*--- Read the street direction flat file into a data set. */
  data GCdirect;
    infile GCdirect dlm=',';
    /*--- Use var names expected by PROC GEOCODE. */
    length DIRECTION $10 DIRABRV $5;
    input direction dirabrv @@;
    /*--- Ignore comment lines. */
    if indexc( direction, '*' ) = 1 then return;
    /*--- Normalize the values for case-insensitive comparisons. */
    direction = upcase( compress(direction, ' ', 'aik') );
    dirabrv   = upcase( compress(dirabrv,   ' ', 'aik') );
    output;
  run;

  /*--- Sort is required before using the lag1() function in next step. */
  proc sort;
    by direction;
  run;

  /*--- The GCdirect data set observations include street directions with their
        abbreviations (NORTH and N). There must also be an observation
        of the abbreviation and the abbreviation (N and N). If the 
        input address obs includes 'North' or 'N' as the street direction, 
        then the GCDIRECT data needs to cover both. For example, the DIRECTION
        var in the GCDIRECT data set must contain observations for both 
        'N' and 'N' to handle both '8000 North Smith Road' and 
        '8000 N Smith Rd'. An example is:
           DIRECTION    DIRABRV
           ---------    -------
           NORTHWEST      NW   <- English street direction with abbreviation
           NORDOUEST      NO   <- French street direction with abbreviation
           NW             NW   <- English abbreviation for both values
           NO             NO   <- French abbreviation for both values
        So, read the street directions imported from the CSV file and add
        the observations for the direction abbreviations. */
  data GCdirect;
    set GCdirect;
	/*--- Write obs with the full length direction and its abbreviation. */
    output;
	/*--- If we are at a new abbreviation, write a second obs with the
	      abbreviation twice. */
    if direction ^= lag1(direction) & direction ^= dirabrv then do;
      direction = dirabrv;
      output;
    end;
  run;

  /*--- Sort again to place dup obs in sequence. */
  proc sort;
    by direction;
  run;

  data &LIBNAME..GCdirect_CAN;
    set GCdirect;
	label direction = 'Street direction prefix/suffix or abbreviation'
              dirabrv   = 'Standard direction abbreviation';
    /*--- If at a duplicate obs, drop it. */
    if direction = lag1(direction) & direction = dirabrv then delete;
  run;

  /*--- And sort once more to set internal sort flag. */
  proc sort;
    by direction;
  run;

  /*--- Add index and label to the street type data set. */
  proc datasets lib=&LIBNAME nolist;
    modify GCdirect_CAN (label="Street direction abbreviations for Canadian geocoding, Updated &CURDATE");
    index create direction;
  run;
%mend CreateGCdirect;


/*------------------------------------------------------------------------------*
 | Name:    CreateLookupData
 | Purpose: Uses the street data accumulated for all imported provinces and
 |          generates three lookup data sets for PROC GEOCODE street method.
 | Input:   all_provinces_roads - Data set of names, places, addresses, etc. 
 |                                for all streets in all provinces.
 |          all_provinces_xy    - Data set of coordinates for all streets.
 | Output:  LIBNAME.DATASETNAMEm - Primary street lookup data set.
 |          LIBNAME.DATASETNAMEs - Secondary street lookup data set.
 |          LIBNAME.DATASETNAMEp - Tertiary street lookup data set.
 *------------------------------------------------------------------------------*/
%macro CreateLookupData / des='Creates PROC GEOCODE street method lookup data sets';

  /*--- Sort combined data. */
  proc sort data=all_provinces_roads;
    by Name2 MapIDName City2 NID;
  run;

  /*--- Create the 'M' and 'S' lookup data sets. */
  data &LIBNAME..&DATASETNAME.m (keep=Name Name2 City City2 MapIDName
                                      MapIDNameAbrv First)
       &LIBNAME..&DATASETNAME.s (keep=NID AdRangeNID RoadClass PreDirAbrv
                                      SufDirAbrv PreTypAbrv SufTypAbrv 
                                      FromAdd ToAdd Side Sorder)
       last (keep=last);
    set all_provinces_roads end=finalObs;
    length Name2Prev $70 City2Prev $100 MapIDNameAbrv $2;
    retain First MaxCity MaxCity2 MaxName MaxName2 MaxMapIDName
           MaxPreDirAbrv MaxPreTypAbrv MaxSufDirAbrv
           MaxSufTypAbrv MaxRoadclass MaxPlaceType 0
           Sorder 1 Last MapIDNameAbrv;
    Name2Prev         = lag1(Name2);
    City2Prev         = lag1(City2);
    MapIDNameAbrvPrev = lag1(MapIDNameAbrv);

	/*--- Find longest actual string lengths for long character vars.
	      We'll use the max lengths to create new vars below just
	      long enough to hold the strings. */
    MaxCity       = max(MaxCity,       length(City));
    MaxCity2      = max(MaxCity2,      length(City2));
    MaxName       = max(MaxName,       length(Name));       
    MaxName2      = max(MaxName2,      length(Name2));     
    MaxMapIDName  = max(MaxMapIDName,  length(MapIDName));   
    MaxPreDirAbrv = max(MaxPreDirAbrv, length(PreDirAbrv)); 
    MaxPreTypAbrv = max(MaxPreTypAbrv, length(PreTypAbrv)); 
    MaxSufDirAbrv = max(MaxSufDirAbrv, length(SufDirAbrv)); 
    MaxSufTypAbrv = max(MaxSufTypAbrv, length(SufTypAbrv)); 
    MaxRoadclass  = max(MaxRoadclass,  length(Roadclass));
    MaxPlaceType  = max(MaxPlaceType,  length(PlaceType)); 

    /*--- Output obs in 'S' data set. */
    output &LIBNAME..&DATASETNAME.s;
    First + 1;
	/*--- Remember original order of 'S' data set obs so we can restore it. */
    Sorder + 1;
    /*--- If street changed, output previous street to 'M' data set. */
    if Name2 ^= Name2Prev | 
       City2 ^= City2Prev | 
       MapIDNameAbrv ^= MapIDNameAbrvPrev then do;
      Last = _n_ - 1;
      output &LIBNAME..&DATASETNAME.m;
      if _n_ > 1 then
        output last;
    end;
    if finalObs then do;
      Last = _n_;
      output last;
      /*--- Save max string lengths to create shorter vars in next data step. */
      call symput('MAXCITY',       put(MaxCity,       best.));
      call symput('MAXCITY2',      put(MaxCity2,      best.));
      call symput('MAXNAME',       put(MaxName,       best.));              
      call symput('MAXNAME2',      put(MaxName2,      best.));          
      call symput('MAXMapIDName',  put(MaxMapIDName,  best.));      
      call symput('MAXPREDIRABRV', put(MaxPreDirAbrv, best.));  
      call symput('MAXPRETYPABRV', put(MaxPreTypAbrv, best.));  
      call symput('MAXSUFDIRABRV', put(MaxSufDirAbrv, best.));  
      call symput('MAXSUFTYPABRV', put(MaxSufTypAbrv, best.)); 
      call symput('MAXROADCLASS',  put(MaxRoadclass,  best.));  
      call symput('MAXPLACETYPE',  put(MaxPlaceType,  best.));  
    end;
  run;

  /*--- Add 'last' var to 'M' data set to provide link to 'S' observations. 
        Shorten character vars to minimum required lengths. Turn off log messages
        warning of possible data truncation. We know the new lengths are sufficient. */
  options varlenchk=nowarn;
  data &LIBNAME..&DATASETNAME.m (label="&LABEL" drop=accents clean writeIt
                                 index=(Name2_MapIDNameAbrv_City2=(NAME2 MAPIDNAMEABRV CITY2)
                                        Name2_MapIDName_City2=(NAME2 MAPIDNAME CITY2)));
    length City      $ &MAXCITY
           City2     $ &MAXCITY2
           Name      $ &MAXNAME
           Name2     $ &MAXNAME2
           MapIDName $ &MAXMapIDName;
    merge &LIBNAME..&DATASETNAME.m last;
    label City          = 'City name'
          City2         = 'City name (normalized)'
          Name          = 'Street name'
          Name2         = 'Street name (normalized)'
          MapIDName     = 'Province name'
          MapIDNameAbrv = 'Province abbreviation'
          First         = "First obs in &DATASETNAME.S data set"
          Last          = "Last obs in &DATASETNAME.S data set";
    /*--- Write the primary street name obs. */
    output;
	/*--- Characters with accents and clean equivalents. */
    retain accents 'àâçéèêëîïôùûüÿÀÂÇÉÈÊËÎÏÔÙÛÜŸ' 
           clean   'aaceeeeiiouuuyAACEEEEIIOUUUY'; 
	/*--- Replace accented characters in province name. */
    if indexc( MapIDName, accents ) then do;
      MapIDName = translate( MapIDName, clean, accents );
      writeIt   = 1;
    end;
	/*--- Replace accented characters in street name. */
    if indexc( name, accents ) then do;
      name    = translate( name,  clean, accents );
      name2   = translate( name2, clean, accents );
      writeIt = 1;
    end;
	/*--- Replace accented characters in city name. */
    if indexc( city, accents ) then do;
      city    = translate( city,  clean, accents );
      city2   = translate( city2, clean, accents );
      writeIt = 1;
    end;
    /*--- Output an extra obs with the clean strings. */
	if writeIt then output;
  run;

  /*--- Temporarily reorder 'S' data set. */
  proc sort data=&LIBNAME..&DATASETNAME.s;
    by NID AdRangeNID;
  run;
  
  /*--- Reorder coordinates for merging. */
  proc sort data=all_provinces_xy;
    by NID AdRangeNID;
  run;
  
  /*--- Begin processing coordinates to create 'P' data set.
        Create START and N vars that link 'S' obs to 'P' data set.*/
  data startN (keep=NIDPrev AdRangeNIDPrev Start N
               rename=(NIDPrev=NID AdRangeNIDPrev=AdRangeNID));
    set all_Provinces_xy end=finalObs;
    retain Start 1 N 0;
    NIDPrev        = lag1(NID);
    AdRangeNIDPrev = lag1(AdRangeNID);
    if _n_ > 1 & (NID ^= NIDPrev | AdRangeNID ^= AdRangeNIDPrev) then do;
      output;
      start + n;
      n     = 0;
    end;
    n+1;
    if finalObs then 
      output;
  run;
  
  /*--- Add the linking START and N vars to 'S' data set. */
  data &LIBNAME..&DATASETNAME.s (label="&LABEL");
    /*--- Shorten character vars to minimum required lengths. 
          Log warning for unequal var lengths is still off. */
	length PreDirAbrv $ &MAXPREDIRABRV
           PreTypAbrv $ &MAXPRETYPABRV
           SufDirAbrv $ &MAXSUFDIRABRV
           SufTypAbrv $ &MAXSUFTYPABRV
           RoadClass  $ &MAXROADCLASS;
    merge &LIBNAME..&DATASETNAME.s (in=a) startN;
    /*--- Specify merge vars and keep only obs from 'S' data set. */
    by NID AdRangeNID;
    if a;
	label PreDirAbrv = 'Street name direction prefix'
	      PreTypAbrv = 'Street name type prefix'
		  SufDirAbrv = 'Street name direction suffix'
		  SufTypAbrv = 'Street name type suffix'
		  RoadClass  = 'Street classification'
		  AdRangeNID = 'Unique ID for street address range'
		  NID        = 'Unique national ID for street name'
          FromAdd    = 'Beginning house number'
		  ToAdd      = 'Ending house number'
		  side       = 'Side of street'
		  start      = "First obs in &DATASETNAME.P data set"
		  n          = "Number of obs in &DATASETNAME.P data set";
  run;

  /*--- Restore 'S' data set to original order. */
  proc sort data=&LIBNAME..&DATASETNAME.s 
            out=&LIBNAME..&DATASETNAME.s (drop=Sorder);
    by Sorder;
  run;
  
  /*--- Create 'P' data set. */
  data &LIBNAME..&DATASETNAME.p (label="&LABEL");
    set all_provinces_xy (keep=x y);
	label x = 'Longitude (degrees)'
	      y = 'Latitude (degrees)';
  run;

  /*--- Re-enable log warnings for unequal variable lengths. */
  options varlenchk=warn;
  quit;
%mend CreateLookupData;

%GEOBASE2GEOCODE(GEOBASEPATH=/enable01-export/enable01-aks/homes/Yen.Nguyen@sas.com/OTHERS,
                       DATASETPATH=/enable01-export/enable01-aks/homes/Yen.Nguyen@sas.com/OTHERS/Geo Lookup,
                       LIBNAME=LOOKUP,
                       DATASETNAME=CANADA_,
                       LABEL=Canada lookup data for PROC GEOCODE from GeoBase National Road Network (&CURDATE))

