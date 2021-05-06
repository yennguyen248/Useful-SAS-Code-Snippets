cas newsess;
caslib _all_ assign;

proc cas;
   session newsess;
simple.compare /                                           
      table={caslib="Public" name="transactions"},                                         
      inputs={"SubscriberKey"},                                     
      casOut={name="Transactions_comp", replace=true},                  
      table2={caslib="Public" name="trans_all"} ,                                        
      table2Inputs={"SubscriberKey"},                            
      casOut2={name="trans_all_comp", replace=true},                
      generatedColumns={"groupID", "frequency", "cumfreq"},   
      freqOut={name="freq", replace=true},                   
      fullOutput={"freqout"},                                 
      noVars=true,                                            
      noVars2=true;
run;
   title "Table Trans Compare";                                   
   table.fetch / table="Transactions_comp";
run;
   title "Table Trans_All Compare";
   table.fetch / table="trans_all_comp";
run;
   title "Table Freq";
   table.fetch / table="freq";
run;
quit;

cas newsess terminate;
