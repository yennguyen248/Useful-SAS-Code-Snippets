cas mysession sessopts=(metrics=true);
caslib _all_ assign;
 
options dscas;
 
data CASUSER.AutoAuctionInput (promote=yes);
length Make $20 Model $20 state $2 Year 8 BlueBookPrice 8 CurrentBid 8 Miles 8 OriginalInvoice 8 OriginalMSRP 8 Miles 8 VIN $17;
Make="Honda"; Model="Accord"; State="LA"; Year=2009; BlueBookPrice=5000; CurrentBid=3000; OriginalInvoice=30000; OriginalMSRP=35000; Miles=50000; vin="12345678901234567"; output;
Make="Kia";   Model="Soul";   State="CA"; Year=2016; BlueBookPrice=8000; CurrentBid=9000; OriginalInvoice=18000; OriginalMSRP=19500; Miles=68000; vin="12345678901234568"; output;
Make="Honda"; Model="Civic";  State="AR"; Year=2017; BlueBookPrice=28000; CurrentBid=20000; OriginalInvoice=32000; OriginalMSRP=34000; Miles=20000; vin="12345678901234569"; output;
Make="Ford";  Model="Fusion"; State="CA"; Year=2012; BlueBookPrice=9000; CurrentBid=9000; OriginalInvoice=18000; OriginalMSRP=19500; Miles=70000; vin="12345678901234560"; output;
Make="Honda"; Model="Pilot";  State="MN"; Year=2012; BlueBookPrice=10000; CurrentBid=3000; OriginalInvoice=45000; OriginalMSRP=50000; Miles=100000; vin="12345678901234561"; output;
Make="Tesla"; Model="X100D";  State="CA"; Year=2017; BlueBookPrice=80000; CurrentBid=90000; OriginalInvoice=100000; OriginalMSRP=100000; Miles=5000; vin="12345678901234562"; output;
Make="Honda"; Model="CRV";    State="PA"; Year=2009; BlueBookPrice=12000; CurrentBid=8000; OriginalInvoice=30000; OriginalMSRP=35000; Miles=270000; vin="12345678901234563"; output;
Make="Buick"; Model="Regal";  State="NJ"; Year=2012; BlueBookPrice=8000; CurrentBid=7000; OriginalInvoice=35000; OriginalMSRP=40500; Miles=82000; vin="12345678901234564"; output;
Make="BMW";   Model="328i";   State="NY"; Year=2015; BlueBookPrice=35000; CurrentBid=40000; OriginalInvoice=55000; OriginalMSRP=60000; Miles=4000; vin="12345678901234565"; output;
Make="Scion"; Model="TC";     State="PA"; Year=2016; BlueBookPrice=10000; CurrentBid=9000; OriginalInvoice=18000; OriginalMSRP=19500; Miles=20000; vin="12345678901234566"; output;
Make="Honda"; Model="Accord"; State="MA"; Year=2010; BlueBookPrice=12000; CurrentBid=11000; OriginalInvoice=34000; OriginalMSRP=35000; Miles=80000; vin="12345678901234571"; output;
Make="Ford";  Model="F150";   State="FL"; Year=2016; BlueBookPrice=45000; CurrentBid=46000; OriginalInvoice=68000; OriginalMSRP=79500; Miles=90000; vin="12345678901234572"; output;
Make="GMC";   Model="Terrain";State="SC"; Year=2015; BlueBookPrice=40000; CurrentBid=30000; OriginalInvoice=60000; OriginalMSRP=65000; Miles=40000; vin="12345678901234573"; output;
Make="Ford";  Model="Fusion"; State="CA"; Year=2012; BlueBookPrice=8000; CurrentBid=9000; OriginalInvoice=18000; OriginalMSRP=19500; Miles=59000; vin="12345678901234574"; output;
run;

cas mysession terminate;