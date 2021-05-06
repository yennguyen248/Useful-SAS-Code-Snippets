cas mysession;
caslib _all_ assign;

/*Getting the data*/
data casuser.dmagecr;
    set sampsio.dmagecr;
    keep age amount coapp duration foreign job good_bad;
run;

/*Create a query data table >> instance*/
data casuser.query;
   set sampsio.dmagecr;
   keep age amount coapp duration foreign job good_bad;
   if _N_ = 20;
run;

/*Create a forest model on the dmagecr data*/
proc cas;
   loadactionset "decisionTree";
   decisionTree.forestTrain   result    = r
                            / table     = 'DMAGECR'
                              seed      = 1234
                              saveState = {name    = 'FOREST_ASTORE',
                                           replace = True}
                              target    = 'good_bad'
                              maxLevel  = 5
                              inputs    = {{name   = "age"},
                                           {name   = "amount"},
                                           {name   = "coapp"},
                                           {name   = "duration"},
                                           {name   = "foreign"},
                                           {name   = "job"}}
                              nominals  = {{name   = "coapp"},
                                           {name   = "foreign"},
                                           {name   = "job"}}
                              ;
   run;
quit;

/*Apply KernelSHAP - linear Explainer to the selected instance*/
proc cas;
   loadactionset "explainModel";
   explainModel.linearExplainer / table            = "DMAGECR"
                                  query            = "QUERY"
                                  modelTable       = "FOREST_ASTORE"
                                  modelTableType   = "ASTORE"
                                  predictedTarget  = "P_good_badbad"
                                  seed             = 1234
                                  preset           = "KERNELSHAP"
                                  inputs           = {{name = "age"},
                                                      {name = "amount"},
                                                      {name = "coapp"},
                                                      {name = "duration"},
                                                      {name = "foreign"},
                                                      {name = "job"}}
                                  nominals         = {{name = "coapp"},
                                                      {name = "foreign"},
                                                      {name = "job"}}
                                  ;
   run;
quit;
