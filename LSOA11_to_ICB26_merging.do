
/**Do-file for merging death data from LSOA11 level deaths to 2021 LSOA21 to 2026 ICB level**
*created by R. DeBruyn 09.21.2026
						
				

* ------------------------------------------------------------------------------
*	DATA SOURCES with WEB LINKS
*	
*File 1 - Deaths by LSOA(2011), England and Wales, 2022 = https://www.ons.gov.uk/peoplepopulationandcommunity/birthsdeathsandmarriages/deaths/adhocs/1919deathsbylsoaenglandandwales2022 
*
*File 2 - LSOA11 to LSOA21 lookup (best fit file)= https://geoportal.statistics.gov.uk/datasets/b684a0dbf786473f9563ec0616da2f8b_0/explore 
*
*File 3 - LSOA21 area codes to ICB 2026 Names = https://geoportal.statistics.gov.uk/datasets/ons::lsoa-2021-to-sicbl-to-icb-to-nhser-to-lad-april-2026-lookup-in-en/about 
*
*-------------------------------------------------------------------------------

*Estimation process:										
Step 1. Link File1 (Deaths in 2022 by LSOA2011 area) to File2 (lookup file for LSOA2011 area -> LSOA2021 area) 										
Step 2. Link merged file from step 1 with File 3 (lookup file for LSOA2021 areas  -> ICB 2026 areas) 										
									
Author note:  										
The geography match between LSOA11 (n=32,844) and LSOA2021 (n=33,755) boundaries is unchanged for 96.9% of the LSOA11s.  The remaining LSOA11s were either merged (0.3%, n=97), split (2.5%, n=834), or fragmented (<0.0%, n=7) into LSOA21 boundaries.										
If an LSOA11 was split or fragmented into multiple LSOA21s that were then split across different ICB2026 boundaries, the estimates for that ICB will be affected. 								
However, the calculated # of deaths/ICB for all the unchanged ICBs (n=29) match the ONS data exactly (https://www.ons.gov.uk/peoplepopulationandcommunity/birthsdeathsandmarriages/deaths/datasets/deathsregisteredsummarystatisticsenglandandwales (2025 dataset ed. accessed 07.20.2026)). 

*/


*	STEP 1: import & prep LSOA11 deaths dataset

*import 2022 deaths by LSOA (only found file with 2011 code), shown by age group
import excel "deathslsoa2022final.xlsx", sheet("1") cellrange(A6:Q34726) firstrow clear

*rename LSOA column to match next dataset for merging.
rename LSOA11code LSOA11CD

*calculate total deaths per LSOA11 by summing across all age groups
egen total_deaths = rowtotal(Under30-andover)

save LSOA11CD_deaths_2022.dta, replace



* 	STEP 2: import LSOA11 to LSOA21 lookup file

import excel "LSOA11_LSOA21_LAD22_EW_LU_v2_1754507175673141678.xlsx", sheet("LSOA11_LSOA21_LAD22_EW_LU_v2_17") firstrow clear

save LSOA11_to_LSOA21.dta, replace



*STEP 3: merge LSOA21 codes to death dataset

use LSOA11CD_deaths_2022.dta, clear
merge m:m  LSOA11CD using "LSOA11_to_LSOA21.dta"
drop _merge

save LSOA_deaths_2022.dta, replace



*STEP 4: import LSOA21 to ICB look up file

import excel "LSOA21_SICBL26_ICB26_NHSER26_LAD26.xlsx", sheet("LSOA21_SICBL26_ICB26_NHSER26_LA") firstrow clear

save LSOA21_to_ICB26.dta, replace



*STEP 5: merge ICB info to newly merged LSOA deaths dataset from step 3

use LSOA_deaths_2022, clear
merge m:m LSOA21CD using "LSOA21_to_ICB26.dta"
drop _merge

save LSOA_to_ICB_deaths_2022.dta, replace



*STEP 6: keep only helpful variables and calculate deaths for each ICB:
keep LSOA11CD LSOA11NM LSOA21CD LSOA21NM ICB26CD ICB26NM total_deaths

bysort ICB26NM: egen ICB_deaths = total(total_deaths)
drop total_deaths
egen tag_ICB = tag(ICB26NM)
list ICB26NM ICB_deaths if tag_ICB==1
total(ICB_deaths) if tag_ICB==1


*Export to excel file:
keep if tag_ICB==1
drop tag_ICB

export excel using "2022_deaths_by_ICB_2026", firstrow(variables) replace






