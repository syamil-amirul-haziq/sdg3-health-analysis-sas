# Global Health & Population Analysis (SDG 3: Good Health & Well-Being)

A SAS Studio analysis of World Bank health and development data, built for a university group assignment (Group 18, Analytics Engineering). I wrote all of the SAS code in this repository.

The project cleans and merges two large World Bank datasets, then answers three research questions linked to UN Sustainable Development Goal 3.

## Research questions and key findings

| # | Question | Key finding |
|---|----------|-------------|
| 1 | How do a country's urban and rural population shares relate to deaths from communicable diseases and maternal, prenatal and nutritional causes? | A higher urban share goes with a lower share of these deaths (correlation **-0.65**, 227 countries and regions). Rural share shows the mirror image (**+0.66**, 226). |
| 2 | Did the COVID-19 pandemic affect immunisation coverage worldwide? | Global average coverage fell after 2019 for every vaccine studied and had not fully recovered by 2023. DPT dropped from 88.2% (2019) to 84.6% (2021) and was 85.6% in 2023. First-dose measles dropped from 87.1% to 83.0%, then 84.8%. |
| 3 | Does access to electricity relate to life expectancy? | Strong positive relationship (correlation **0.86**, 260 countries and regions). Each extra percentage point of electricity access goes with about 0.28 more years of average life expectancy. |

These are associations, not proof of cause. Electricity access, for example, is also tied to income and healthcare quality.

### Immunisation coverage, global average (%)

| Vaccine | 2019 | 2020 | 2021 | 2023 |
|---------|------|------|------|------|
| BCG | 89.4 | 87.7 | 86.3 | 88.3 |
| DPT | 88.2 | 85.8 | 84.6 | 85.6 |
| Hepatitis B (3 doses) | 87.3 | 85.0 | 83.9 | 84.9 |
| Hib (3 doses) | 86.1 | 83.6 | 82.8 | 84.2 |
| Measles (1st dose) | 87.1 | 84.6 | 83.0 | 84.8 |
| Measles (2nd dose) | 78.7 | 77.1 | 74.8 | 76.3 |
| Polio (3 doses) | 88.1 | 85.2 | 83.6 | 85.2 |

## Data

Both datasets come from the World Bank Open Data catalogue and are not stored in this repository, because of their size.

| Dataset | File | Rows | Content |
|---------|------|------|---------|
| Health, Nutrition and Population Statistics | `HNP_StatsCSV.csv` | 126,084 | 474 indicators |
| World Development Indicators | `WDICSV.csv` | 403,256 | 1,516 indicators |

Both cover 266 countries and regions, with yearly values from 1960 to 2024.

## Approach

1. **Import and validate.** Import both CSV files, inspect their structure with `PROC CONTENTS`, and check country identifiers with `PROC FREQ`.
2. **Clean.** Read each file with a `DATA` step using explicit variable lengths, then round every numeric value to 2 decimal places using an array and a `DO` loop.
3. **Filter indicators.** Search indicator names with `UPCASE(...) LIKE` to find the right codes, then subset the required indicators.
4. **Summarise.** Average yearly values per country (Questions 1 and 3), or reshape the years 2016 to 2023 into long format with an array (Question 2).
5. **Merge.** Sort by country code and merge the subsets with a `MERGE ... BY` statement.
6. **Visualise.** Use `PROC SGPLOT` (scatter plots with regression lines, series plots) and `PROC SGPANEL` (one panel per vaccine, with a reference line at 2020).

## Repository contents

```
.
├── Group18_GA-SAS_Code.sas   # full analysis script
└── README.md
```

## How to run

1. Download `HNP_StatsCSV.csv` and `WDICSV.csv` from the World Bank Open Data catalogue.
2. Upload them to your SAS Studio folder.
3. In the script, change the `libname` path and the three `datafile` and `INFILE` paths to match your folders.
4. Run the script. The first import reads about 126,000 and 403,000 rows, so allow around 15 minutes.

## Limitations

- The World Bank files include regional and income-group aggregates (for example "Africa Eastern and Southern") as well as individual countries, so counts are stated as "countries and regions". Excluding the aggregates would change the figures slightly.
- Questions 1 and 3 use each country's average across 1960 to 2024, which hides change over time and treats countries with fewer years of data the same as those with more.
- Question 2 compares global averages that are not weighted by population. Coverage data also depends on each country's reporting.
- Life expectancy in Question 3 is rounded to a whole year before plotting, while electricity access is rounded to 2 decimal places.

## Tools

SAS Studio (`PROC IMPORT`, `DATA` step, `PROC SORT`, `PROC MEANS`, `PROC FREQ`, `PROC SGPLOT`, `PROC SGPANEL`)

## Data source

World Bank Open Data, Health, Nutrition and Population Statistics and World Development Indicators (CC BY 4.0).
