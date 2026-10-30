/*Initial Validation Phase*/
/*Note, the initial validation phase will take a large amount of time to fully process as the dataset
  is very large (126k rows), do remain patient as SAS processes all the data (around 15 minutes)*/
 
/*Assign a library to the folder containing the datasets*/ 
libname mydata "/path/to/your/folder";

/* Import HNP CSV file into SAS */
/*Note: Change the file location based on where you stored your datasets*/
proc import datafile="/path/to/your/folder/HNP_StatsCSV.csv" 
    out=mydata.hnp_raw       /* Output SAS dataset */
    dbms=csv                 /* Source file type */
    replace;                 /* Overwrite if dataset already exists */
    guessingrows=max;        /* Scan all rows to detect variable types */
run;

/* Import WDI CSV file into SAS */
/*Note: Change the file location based on where you stored your datasets*/
proc import datafile="/path/to/your/folder/WDICSV.csv"
    out=mydata.wdi_raw /* Output SAS dataset */
    dbms=csv           /* Source file type */ 
    replace;           /* Overwrite if dataset already exists */
    guessingrows=max;  /* Scan all rows to detect variable types */
run;

/* View variable names, types, and structure for HNP dataset */
proc contents data=mydata.hnp_raw;
run;

/* View variable names, types, and structure for WDI dataset */
proc contents data=mydata.wdi_raw;
run;

/* Create a clean working copy of HNP dataset */
data mydata.hnp_clean;
    set mydata.hnp_raw;
run;

/* Create a clean working copy of WDI dataset */
data mydata.wdi_clean;
    set mydata.wdi_raw;
run;

/* Check for missing or inconsistent country identifiers in HNP */
proc freq data=mydata.hnp_clean;
    tables "Country Name"n "Country Code"n / missing;
run;

/* Check for missing or inconsistent country identifiers in WDI */
proc freq data=mydata.wdi_clean;
    tables "Country Name"n "Country Code"n / missing;
run;

/* Preview first 10 observations of HNP dataset */
proc print data=mydata.hnp_clean (obs=10);
run;

/* Preview first 10 observations of WDI dataset */
proc print data=mydata.wdi_clean (obs=10);
run;


/*Data Cleaning and Manipulation Phase*/
/*Importing datasets into sas temporary libraries*/
DATA mydata.HealthNutriPopul;
	/*Note: Change the file location based on where you stored your datasets*/
	INFILE "/path/to/your/folder/HNP_StatsCSV.csv" 
		DSD /*Treats consecutive delimiters as missing value*/
		DLM=","  /*Treats , as the delimiter*/
		FIRSTOBS=2; /*Skip the first line that contains headers that are numeric (Avoiding usage of sas name literals)*/ 
	LENGTH /*Specifying the length of the variables based on the largest variables found*/
		CountryName $100
		CountryCode $3
		IndicatorName $150
		IndicatorCode $25;
	INPUT /*Inputting the variables*/
		CountryName $
		CountryCode $
		IndicatorName $ 
		IndicatorCode $ 
		Year1960-Year2024;
	ARRAY Rounding _NUMERIC_; /*Selecting all numeric values for Rounding process*/
	DO i=1 TO dim(Rounding); /*Creating a do loop to Round numbers to 2 decimal places*/
		Rounding[i]=ROUND(Rounding[i],0.01);
	END;
	DROP i; /*Removing i from the dataset*/
RUN;

/*Repeat process for 2nd dataset*/
DATA mydata.WorldDevelopmentInd;
	/*Note: Change the file location based on where you stored your datasets*/
	INFILE "/path/to/your/folder/WDICSV.csv" 
		DSD /*Treats consecutive delimiters as missing value*/
		DLM=","  /*Treats , as the delimiter*/
		FIRSTOBS=2; /*Skip the first line that contains headers that are numeric (Avoiding usage of sas name literals)*/ 
	LENGTH /*Specifying the length of the variables based on the largest variables found*/
		CountryName $100
		CountryCode $3
		IndicatorName $150
		IndicatorCode $25;
	INPUT /*Inputting the variables*/
		CountryName $
		CountryCode $
		IndicatorName $ 
		IndicatorCode $ 
		Year1960-Year2024;
	ARRAY Rounding _NUMERIC_; /*Selecting all numeric values for Rounding process*/
	DO i=1 TO dim(Rounding); /*Creating a do loop to Round numbers to 2 decimal places*/
		Rounding[i]=ROUND(Rounding[i],0.01);
	END;
	DROP i; /*Removing i from the dataset*/
RUN;

/*Validating Datasets for potential missing data (By comparing Countries and Indicators)*/
TITLE "Frequency Distribution of Countries and Indicators of HNP dataset";
PROC FREQ DATA=mydata.HealthNutriPopul;
TABLES CountryName CountryCode IndicatorName IndicatorCode;
RUN;

TITLE "Frequency Distribution of Countries and Indicators of WDI dataset";
PROC FREQ DATA=mydata.WorldDevelopmentInd;
TABLES CountryName CountryCode IndicatorName IndicatorCode;
RUN;

/*Question 1;
What relation does urban population and rural population of a country have on the amount
of deaths caused by health related causes (diseases, maternal, prenatal and nutrition)*/

/*Identifying Indicator names to utilize, accounting for potential different capitalization of the keywords*/
PROC PRINT DATA=mydata.HealthNutriPopul;
	WHERE 
	UPCASE(IndicatorName) LIKE '%RURAL%' OR
 	UPCASE(IndicatorName) LIKE '%URBAN%' OR
 	UPCASE(IndicatorName) LIKE '%DEATH%';
	VAR IndicatorName IndicatorCode;
RUN;

DATA mydata.FilteringUrbRurDeath;
	SET mydata.HealthNutriPopul;
	/*Filtering the dataset to only select urban population, rural population and health related deaths, all in total percentages*/
	WHERE (IndicatorCode="SP.RUR.TOTL.ZS") OR
	 	  (IndicatorCode="SH.DTH.COMM.ZS") OR 
	 	  (IndicatorCode="SP.URB.TOTL.IN.ZS");
	/*Creating a new variable consisting of averages of urban population, rural population and health related deaths*/
	AverageCount=MEAN(of Year1960-Year2024); 
	/*Rounding the new variable to 2 decimal points*/
	RoundedAvgCount=ROUND(AverageCount,0.01);
	/*Subsetting the dataset, keeping only crucial information*/
	KEEP CountryName CountryCode IndicatorName IndicatorCode RoundedAvgCount;
RUN;

/*Further subsetting Rural Population, Urban Population and Deaths Due To Health Reasons into different datasets 
  and removing country entries with all 3 variables missing*/
DATA mydata.UrbanPop mydata.RuralPop mydata.DeathHealth;
	SET mydata.FilteringUrbRurDeath;
	IF IndicatorCode="SP.RUR.TOTL.ZS" AND RoundedAvgCount>0 THEN OUTPUT mydata.RuralPop;
	IF IndicatorCode="SP.URB.TOTL.IN.ZS" AND RoundedAvgCount>0 THEN OUTPUT mydata.UrbanPop;
	IF IndicatorCode="SH.DTH.COMM.ZS" AND RoundedAvgCount>0 THEN OUTPUT mydata.DeathHealth;
	DROP IndicatorName IndicatorCode;
RUN;

/*Sorting filtered data to avoid errors when merging*/
PROC SORT DATA=mydata.UrbanPop;
	BY CountryCode;
RUN;
PROC SORT DATA=mydata.RuralPop;
	BY CountryCode;
RUN;
PROC SORT DATA=mydata.DeathHealth;
	BY CountryCode;
RUN;

/*Merging the previous datasets into 1 dataset with RoundedAvgCount from each dataset being its specific value*/
DATA mydata.MergingUrbRurDeath;
	MERGE
	mydata.UrbanPop (RENAME=(RoundedAvgCount=UrbanPopulation))
	mydata.RuralPop (RENAME=(RoundedAvgCount=RuralPopulation))
	mydata.DeathHealth (RENAME=(RoundedAvgCount=DeathDueToHealthIssues));
	BY CountryCode;
RUN;

/*Inspecting the output of the merging process*/
PROC PRINT DATA=mydata.MergingUrbRurDeath;
RUN;

/*Creating graph for Urban Population with Health Related Deaths*/
TITLE "Urban Population Vs Health Related Deaths Chart";
PROC SGPLOT DATA=mydata.MergingUrbRurDeath;
	/*Using a scatter plot to visualize the spread of data with Urban Population and Health Related Deaths*/
	SCATTER X=UrbanPopulation Y=DeathDueToHealthIssues; 
	/*Using a regression line to visualize the relationship between Urban Population and Health Related Deaths*/
	REG X=UrbanPopulation Y=DeathDueToHealthIssues;
	/*Labelling the X-axis and Y-axis*/
	XAXIS LABEL="Urban Population (Percentage)";
	YAXIS LABEL="Health Related Deaths (Percentage)";
RUN;

/*Creating graph for Rural Population with Health Related Deaths*/
TITLE "Rural Population Vs Health Related Deaths Chart";
PROC SGPLOT DATA=mydata.MergingUrbRurDeath;
	/*Using a scatter plot to visualize the spread of data with Rural Population and Health Related Deaths*/
	SCATTER X=RuralPopulation Y=DeathDueToHealthIssues;
	/*Using a regression line to visualize the relationship between Rural Population and Health Related Deaths*/
	REG X=RuralPopulation Y=DeathDueToHealthIssues;
	/*Labelling the X-axis and Y-axis*/
	XAXIS LABEL="Average Rural Population (Percentage)";
	YAXIS LABEL="Average Amount of Health Related Deaths (Percentage)";
RUN;

/*Question 2
Has the covid-19 pandemic (begun circa 2020) affected the immunisation
coverage (BCG, DPT, measles, etc.) in countries worldwide?*/

/*Identifying documented immunities in the dataset and the range of the available years (limited to 10 years) */
PROC PRINT DATA=mydata.HealthNutriPopul;
WHERE UPCASE(IndicatorName) LIKE "IMMUN%";
VAR IndicatorName IndicatorCode Year2014-Year2024;
RUN;

DATA mydata.ImmunizationCovid;
	SET mydata.HealthNutriPopul;
	/*Selecting Indicators related to Immunization*/
	WHERE
	(IndicatorCode="SH.IMM.IBCG") OR
	(IndicatorCode="SH.IMM.IDPT") OR
	(IndicatorCode="SH.IMM.HEPB") OR
	(IndicatorCode="SH.IMM.HIB3") OR
	(IndicatorCode="SH.IMM.MEAS") OR
	(IndicatorCode="SH.IMM.MEA2") OR
	(IndicatorCode="SH.IMM.POL3");
	/*Creating an Array function to count the immunization coverage for each type of immunity for each country*/
	ARRAY SelectedYears[*] Year2016-Year2023;
		DO i=1 to dim(SelectedYears);
		Year=2015+i;
		ImmunityCoverage=SelectedYears[i];
		IF NOT MISSING(ImmunityCoverage) THEN OUTPUT;
	END;
	/*Keeping only crucial variables to use for the graph*/
	KEEP IndicatorName Year ImmunityCoverage;
RUN;

/*Finding the averages for each immunization coverage of all countries*/
PROC MEANS DATA=mydata.ImmunizationCovid;
	CLASS IndicatorName Year;
	VAR ImmunityCoverage;
	OUTPUT OUT=mydata.ImmunizationGlobal /*Outputs the results in a new dataset*/
	MEAN=GlobalCoverage; /*Saves the means into a new variable GlobalCoverage*/ 
RUN;

/*Inspecting the output of proc means*/
PROC PRINT DATA=mydata.ImmunizationGlobal;
RUN;

/*Using SGPANEL to create graphs for all Immunity Coverage against Year*/
TITLE "Graphs of Immunization Coverage of Varying Immunities Globally";
PROC SGPANEL DATA=mydata.ImmunizationGlobal;
	PANELBY IndicatorName / COLUMNS=1; /*Displaying only 1 column to make Indicators Text fit*/
	SERIES x=Year y=GlobalCoverage;
	REFLINE 2020 / AXIS=X LABEL="Beginning Of Covid-19"; /*Creating a reference line to indicate the beginning of covid*/
	/*Labelling X-axis and Y-axis*/
	COLAXIS LABEL="Year";
	ROWAXIS LABEL="Immunisation Coverage (Percentage)";
RUN;

/*Using SGPLOT to create a singular graph of all immunities for comparison*/
TITLE "Overall Graph of Immunization Coverage Globally";
PROC SGPLOT DATA=mydata.ImmunizationGlobal;
	SERIES x=Year y=GlobalCoverage / group=IndicatorName;
	REFLINE 2020 / AXIS=X LABEL="Beginning Of Covid-19"; /*Creating a reference line to indicate the beginning of covid*/
	/*Labelling X-axis and Y-axis*/
	XAXIS LABEL="Year";
	YAXIS LABEL="Immunisation Coverage (Percentage)";
RUN;

/*Question 3
Does a country's population access to electricity influence the life expectancy of its population?*/

/*Identifying documented data regarding electricity to use, accounting for potential different capitalization of the keywords*/
PROC PRINT DATA=mydata.WorldDevelopmentInd;
WHERE UPCASE(IndicatorName) LIKE '%ELECTR%';
/*Keeping only relevant variables*/
VAR CountryName CountryCode IndicatorName IndicatorCode;
RUN;

/*Identifying documented data regarding life expectancy to use, accounting for potential different capitalization of the keywords*/
PROC PRINT DATA=mydata.HealthNutriPopul;
WHERE UPCASE(IndicatorName) LIKE '%EXPECT%';
/*Keeping only relevant variables and similar to previous dataset to avoid issues when merging*/
VAR CountryName CountryCode IndicatorName IndicatorCode;
RUN;

/*Filtering dataset to include only data regarding access to electricity*/
DATA mydata.ElectricityAccess;
	SET mydata.WorldDevelopmentInd;
	WHERE IndicatorCode = "EG.ELC.ACCS.ZS";
	/*Creating a new variable of the average access to electricity from 1960-2024*/
	AverageElectricity=MEAN(of Year1960-Year2024);
	/*Rounding the new variable to 2 decimal points*/
	RoundedAvgElec=ROUND(AverageElectricity,0.01);
	/*Removing the individual Year values and pre-rounded values*/
	DROP Year1960-Year2024 AverageElectricity;
RUN;

/*Repeating the process for the other dataset
  Filtering dataset to include only data regarding life expectancy*/
DATA mydata.LifeExpectancy;
	SET mydata.HealthNutriPopul;
	WHERE IndicatorCode = "SP.DYN.LE00.IN";
	/*Creating a new variable of the average life expectancy from 1960-2024*/
	AverageLifeExpect=MEAN(of Year1960-Year2024);
	/*Rounding the new variable to 2 decimal points*/
	RoundedLifeExpect=ROUND(AverageLifeExpect);
	/*Removing the individual Year values and pre-rounded values*/
	DROP Year1960-Year2024 AverageLifeExpect;
RUN;

/*Sorting filtered data to avoid errors when merging*/
PROC SORT DATA=mydata.ElectricityAccess;
	BY CountryCode;
RUN;
PROC SORT DATA=mydata.LifeExpectancy;
	BY CountryCode;
RUN;

/*Merging the previous datasets into 1 dataset*/
DATA mydata.ElecAccessLifeExpect;
	MERGE 
	mydata.ElectricityAccess
	mydata.LifeExpectancy;
	BY CountryCode;
RUN;

/*Creating a graph comparing countries access to electricity against average life expectancy*/
TITLE "Country's Population Access Electricity and Average Life Expectancy";
PROC SGPLOT DATA=mydata.ElecAccessLifeExpect;
	/*Using Scatter Plot to visualize the distribution of access to electricity against average life expectancy*/
	SCATTER X=RoundedAvgElec Y=RoundedLifeExpect;
	/*Using a regression line to visualize the relationship between access to electricity against average life expectancy*/
	REG X=RoundedAvgElec Y=RoundedLifeExpect;
	/*Labelling the X-axis and Y-axis*/
	XAXIS LABEL="Population Access to Electricity (Percent)";
	YAXIS LABEL="Average Life Expectancy";
RUN;