/*
%Example Simulated Power Analysis from Black, Hollingsworth, Nunes, and Simon (2019)
%Alex Hollingsworth
%3 January 2019

This is an example of the type of simulated power analysis done in Black et al. (2019). This example is done with publicly available data. You can find the code, data, and output for this example hosted on Alex’s GitHub page <https://github.com/hollina/health_insurance_and_mortality>.

This set-up is designed to mimic a typical DiD setting. Here we will compare 23 randomly chosen treated states to 18 randomly chosen control states. We will impose a series of treatment effects that gradually increase in magnitude and report whether or not these imposed treatment effects are detectable. We will vary the set of randomly chosen treated states. We will calculate the minimum detectable effect size at various power and significance levels. We will also explore a measure of believability, which is based upon Gelman and Carlin (2014) measures of sign and magnitude error.

In this simple design we used 5 years of pre-expansion data and 3 years of post-expansion data. Both state and year fixed-effects are included. Regressions are weighted by state-population and standard errors will be clustered at the state-level. The dependent variable will be the natural log of the all-cause non-elderly mortality rate per 100,000.

This code is simply an example of our simulated power analysis and is not an attempt to identify the impact of Medicaid expansion on mortality. Importantly, changing the research design (e.g. adding control variables, shifting to the county-level, changing the cause of death, using propensity score weights, or using a synthetic control estimator) will impact power. Our approach could be easily modified to accommodate any of these alternative research designs. Any improvements to the research design will very likely increase power and decrease the minimum detectable effect size.
*/

// Initial Set-up
// ====================

// Here we will set-up the power analysis and choose various required parameters/options.

// First we clear the memory
	clear all

// Choose the number of datasets we want to compose each estimate. For example, if we choose 2, then two sets of psuedo-treated states will be drawn and the power analysis will be conducted twice for each effect size; once for each set of pseudo-treated states and effect size pair. 
	local max_dataset_number  = 1000

// Pick the number of psuedo-post-expansion years
	local number_post_years = 3
	local last_year = 2013-`number_post_years'+1

// Set number of psuedo-pre-expansion years
	local number_pre_years = 5
	local first_year = `last_year'-`number_pre_years'

// Set effect size step and max value in percent terms (0-1)
	local step_size = .0025 // Quarter of a percent
	local end_value = .05 // End at 5%

// Create a local macro from the choices above
	local step_macro 
	forvalues x = 0(`step_size')`end_value' {
		local step_macro `step_macro'  `x'
	}

// Determine the length of the macro above, so percent complete can be displayed later
	local num :  word count `step_macro'
	local num = `num'

// Calculate the max number of rows so percent complete can be displayed later
	local max_row = `max_dataset_number'*`num'

// Create excel sheet to store results from simulation. Note: I have $dropbox set via my profile.do to point to my Dropbox folder.
	putexcel set "$dropbox/health_insurance_and_mortality/state_level_public_data_example/output/power_simulation_results.xlsx", replace

// Initialize cells names in excel sheet
	putexcel A1 = ("dependent_variable")
	putexcel B1 = ("controls")
	putexcel C1 = ("weight")
	putexcel D1 = ("treated_states")
	putexcel E1 = ("effect_size")
		
	putexcel F1 = ("deaths_reduced_per_year")
	putexcel G1 = ("total_deaths_reduced")

	putexcel H1 = ("coef")
	putexcel I1 = ("se")
	putexcel J1 = ("df")

// Import and clean mortality data
// ====================
			
// Import data extracted from [CDC wonder](https://wonder.cdc.gov/). All cause mortality 0-64 by state and year. The data were gathered on 1 January 2019. 
	import delimited "$dropbox/health_insurance_and_mortality/state_level_public_data_example/data/Multiple Cause of Death, 1999-2017.txt"

// Drop total variables
	drop if missing(year)

// Drop unneeded variables from CDC Wonder
	drop notes

// Drop years after expansion
	drop if year>=2014

// Drop if year before first desired year
	drop if year<`first_year'

// Change state name to be state postal code
	replace state ="AL" if state=="Alabama"
	replace state ="AK" if state=="Alaska"
	replace state ="AZ" if state=="Arizona"
	replace state ="AR" if state=="Arkansas"
	replace state ="CA" if state=="California"
	replace state ="CO" if state=="Colorado"
	replace state ="CT" if state=="Connecticu "
	replace state ="DE" if state=="Delaware"
	replace state ="DC" if state=="District of Columbia"
	replace state ="FL" if state=="Florida"
	replace state ="GA" if state=="Georgia"
	replace state ="HI" if state=="Hawaii"
	replace state ="ID" if state=="Idaho"
	replace state ="IL" if state=="Illinois"
	replace state ="IN" if state=="Indiana"
	replace state ="IA" if state=="Iowa"
	replace state ="KS" if state=="Kansas"
	replace state ="KY" if state=="Kentucky"
	replace state ="LA" if state=="Louisiana"
	replace state ="ME" if state=="Maine"
	replace state ="MD" if state=="Maryland"
	replace state ="MA" if state=="Massachusetts"
	replace state ="MI" if state=="Michigan"
	replace state ="MN" if state=="Minnesota"
	replace state ="MS" if state=="Mississippi"
	replace state ="MO" if state=="Missouri"
	replace state ="MT" if state=="Montana"
	replace state ="NE" if state=="Nebraska"
	replace state ="NV" if state=="Nevada"
	replace state ="NH" if state=="New Hampshire"
	replace state ="NJ" if state=="New Jersey"
	replace state ="NM" if state=="New Mexico"
	replace state ="NY" if state=="New York"
	replace state ="NC" if state=="North Carolina"
	replace state ="ND" if state=="North Dakota"
	replace state ="OH" if state=="Ohio"
	replace state ="OK" if state=="Oklahoma"
	replace state ="OR" if state=="Oregon"
	replace state ="PA" if state=="Pennsylvania"
	replace state ="RI" if state=="Rhode Island"
	replace state ="SC" if state=="South Carolina"
	replace state ="SD" if state=="South Dakota"
	replace state ="TN" if state=="Tennessee"
	replace state ="TX" if state=="Texas"
	replace state ="UT" if state=="Utah"
	replace state ="VT" if state=="Vermont"
	replace state ="VA" if state=="Virginia"
	replace state ="WA" if state=="Washington"
	replace state ="WV" if state=="West Virginia"
	replace state ="WI" if state=="Wisconsin"
	replace state ="WY" if state=="Wyoming"

// Add expansion status to each state
	gen expansion4=0
	label define expansion4 0 "0. Non-expansion" 1 "1. Full expansion" ///
		2 "2. Mild expansion" 3 "3. Substantial expansion" 
	label values expansion4 expansion4

	local full AZ AR CO IL IA KY MD NV NM NJ ND OH OR RI WV  WA
	foreach x in `full' {
		replace expansion4=1 if state=="`x'"
	}     
	local mild DE DC MA NY VT
	foreach x in `mild' {
		replace expansion4=2 if state=="`x'"
	}
	local medium CA CT HI MN WI
	foreach x in `medium' {
		replace expansion4=3 if state=="`x'"
	}

// Account for mid-year expansions
	replace expansion4=1 if state=="MI"  //MI expanded in April 2014
	replace expansion4=1 if state=="NH"  //NH expanded in August 2014
	replace expansion4=1 if state=="PA"  //PA expanded in Jan 2015
	replace expansion4=1 if state=="IN"  //IN expanded in Feb 2015
	replace expansion4=1 if state=="AK"  //AK expanded in Sept 2015
	replace expansion4=1 if state=="MT"  //MT expanded in Jan 2016
	replace expansion4=1 if state=="LA"  //LA expanded in July 2016

// Keep only full or non-expansion states
	drop if expansion4==2 | expansion4==3

// Store number of expansion states
	distinct statecode  if expansion4==1 
	scalar number_expand = r(ndistinct)	

// Save data to be called in power analysis
// ====================
// Save temporary dataset to be called 
	compress
	save "$dropbox/health_insurance_and_mortality/state_level_public_data_example/temp/temp_data.dta", replace


// Run simulated power analysis
// ====================
// Start a timer to show how long this takes
	timer on 1

// Set row number for excel sheet
	local row =2 

// Run a loop. Performing the power analysis once for each of the desired number of datasets. The following output is supressed for the html document even though it runs. This is to ensure the document is not too long.
	forvalues dataset_number = 1(1)`max_dataset_number'	{
		// Display the dataset number
		qui di "`dataset_number'"
		
		// Open main dataset for analysis
		qui use "$dropbox/health_insurance_and_mortality/state_level_public_data_example/temp/temp_data.dta", clear

		// Set seed for reproducibility. We want the seed to be the same within a dataset. 
		qui local rand_seed = 1234 + `dataset_number'
		qui set seed   `rand_seed'

		///////////////////////////////////////////////////////////////////////////////			
		// Generate a random variable for each state, then the first N in rank will be 
		// considered expansion states. Where N is # of expansion states
		qui bysort statecode: gen random_variable = runiform() if _n==1
		qui bysort statecode: carryforward random_variable, replace

		// Rank the states
		qui egen rank = group(random_variable)

		// Given this random ordering of states, assign expansion status to the # set above
		qui gen expansion = 0 
		qui replace expansion=1 if rank <=number_expand

		// Do this same thing for the treatment variable
		qui gen treatment = 0 
		qui replace treatment = 1 if expansion==1 & year>=`last_year' 

		// Create Post variable
		qui gen post = 0
		qui replace post =1 if year>=`last_year' 

		// Store basic data from regression in excel sheet
		qui putexcel A`row' = ("all_deaths")
		qui putexcel B`row' = ("no controls")
		qui putexcel C`row' = ("population")
		
		// Add list of states to excel sheet
		qui capture drop test
		qui gen test = ""

		qui levelsof state if treatment ==1, local(treated_states)
		foreach x in `treated_states' {
			qui replace test = test + ", " + "`x'"
		}
				
		qui local state_list `=test[1]'
		qui putexcel D`row' = ("`state_list'")
				

		// Generate a death rate with no effect
		qui gen death_rate = (deaths/population)*100000
		
		// Gen order variable 
		qui gen order = _n
		
		/////////////////////////////////////////////////////////////////////////////
		// Create a reduced deaths variable by a given percentage using the binomial for each effect size
		qui local counter = 1

		foreach x in `step_macro' {
			qui gen reduced_deaths_`counter' = 0 
			qui replace reduced_deaths_`counter' = rbinomial(deaths,`x') if treatment==1
			qui replace reduced_deaths_`counter'=0 if missing(reduced_deaths_`counter')
				
			qui gen deaths_`counter' = deaths - reduced_deaths_`counter'
			qui replace deaths_`counter'=0 if missing(deaths_`counter')
				
			qui gen death_rate_`counter'= ln((deaths_`counter'/population)*100000+1)
				
				
			// Store the effect size in excel sheet
			qui putexcel E`row' = (`x')
				
			// Store the number of reduced deaths in excel sheet
			qui sum reduced_deaths_`counter' if year>=`last_year'
			qui putexcel F`row' = (`r(sum)'/`number_post_years')
			qui putexcel G`row' = (`r(sum)')
				
			// Move the row and counter one forward
			qui local counter = `counter' + 1 
			qui local row = `row' + 1
		}	
			
		// Move the row counter back to the top
		qui local row = `row' - `num' 
			
		
		/////////////////////////////////////////////////////////////////////////////
		// Run regression of treatment on reduced deaths variable for each effect size

		// Reset the counter
		qui local counter = 1

		forvalues counter = 1(1)`num' {
					
			qui reghdfe death_rate_`counter' ///
				treatment ///
				i.post i.expansion ///
				[aweight=population] ///
				,  absorb(statecode year)  vce(cluster statecode) 
				
			// Store results
			qui putexcel H`row' =(_b[treatment])
			qui putexcel I`row' = (_se[treatment])
			qui putexcel J`row' =(`e(df_r)')
			
			// Display Percent Complete
			qui di "///////////////////////////////////////////////////////////////////////"
			qui di "///////////////////////////Percent Complete///////////////////////////"
			qui di ((`row'-1)/`max_row')*100
			qui di "///////////////////////////////////////////////////////////////////////"
				
			qui local row = `row' + 1
			qui local counter = `counter' + 1
		}
	}

// Stop timer
	timer off 1
	timer list

// Erase temporary dataset used for analysis
	erase "$dropbox/health_insurance_and_mortality/state_level_public_data_example/temp/temp_data.dta"

// Import and clean results from simulated power analysis
// ====================

// Import simulation results
	import excel "$dropbox/health_insurance_and_mortality/state_level_public_data_example/output/power_simulation_results.xlsx", sheet("Sheet1") firstrow clear	

// Calculate z-scores and p-values
	gen z_score = abs(((coef - 0)/se))
	gen p_value =  2*ttail(df,z_score)

// Calculate indicator for power threshold for each observation
	gen power_10 = 0
	gen power_05 = 0
	gen power_01 = 0
	gen power_001 = 0
			
	replace power_10 =  1 if p_value<= .1
	replace power_05 =  1 if p_value<= .05
	replace power_01 =  1 if p_value<= .01
	replace power_001 = 1 if p_value<= .001

// Calculate a count variable
	gen count = 1


// Make sign error 
	gen s_error_10 = 0
	replace s_error_10 =1 if power_10==1 & coef>=0
	gen s_error_05 = 0
	replace s_error_05 =1 if power_05==1 & coef>=0
	gen s_error_01 = 0
	replace s_error_01 =1 if power_01==1 & coef>=0
	gen s_error_001 = 0
	replace s_error_001 =1 if power_001==1 & coef>=0

	replace s_error_10 =. if effect_size==0
	replace s_error_05 =. if effect_size==0
	replace s_error_01 =. if effect_size==0
	replace s_error_001 =. if effect_size==0

// Make magnitude error 
	gen m_error = abs(coef/effect_size)
	gen m_error_10 = m_error
	replace m_error_10 = . if power_10==0
	gen m_error_05 = m_error
	replace m_error_05 = . if power_05==0
	gen m_error_01 = m_error
	replace m_error_01 = . if power_01==0
	gen m_error_001 = m_error
	replace m_error_001 = . if power_001==0

// Generate Beliveabilitiy 
	gen believe_10 = 0 
	replace  believe_10 = 1 if power_10 ==1 & s_error_10==0 & m_error_10<=2

	gen believe_05 = 0 
	replace  believe_05 = 1 if power_05 ==1 & s_error_05==0 & m_error_05<=2

	gen believe_01 = 0 
	replace  believe_01 = 1 if power_01 ==1 & s_error_01==0 & m_error_01<=2

	gen believe_001 = 0 
	replace  believe_001 = 1 if power_001 ==1 & s_error_001==0 & m_error_001<=2

// Collapse by effect size to calculate power, % sign error, average magnitude error and % believable
	collapse (sum) count *power_* *s_error_* *believe_* (mean) *m_error_*, by(effect_size)

// Generate sign error ratio, rather than raw count
	replace s_error_10 = (s_error_10/power_10)*100
	replace s_error_05 = (s_error_05/power_05)*100
	replace s_error_01 = (s_error_01/power_01)*100
	replace s_error_001 = (s_error_001/power_001)*100

	replace s_error_10 = . if effect_size==0
	replace s_error_05 = . if effect_size==0
	replace s_error_01 = . if effect_size==0
	replace s_error_001 = . if effect_size==0

// Make power and believability out of 100
	ds *power* *believe_*
	foreach x in `r(varlist)' {
		replace `x' = (`x'/count)*100
	}

// Make effect size 0-100
	replace effect_size=effect_size*100

// Plot power curves
// ====================

// First determine closest point where the power_05 hits 80%
	gen distance_from_80 = (power_05-80)^2
	sort distance_from_80
	sum effect_size in 1
	local mde=`r(mean)'

// Add label to graph with this MDE
	capture drop mde_label
	gen mde_label = ""
	set obs `=_N+1'
	replace mde_label = "MDE" in `=_N'
	replace effect_size = `mde' in `=_N'

	capture drop full_power
	gen full_power = 102.5
		
// Plot power curve
	sort effect_size
	twoway connected power_10 effect_size ,  lpattern("l") color(sea) msymbol(none) mlabcolor(sea) mlabel("") mlabsize(3) mlabpos(11) ///
		|| connected  power_05 effect_size ,  lpattern(".._") color(turquoise) msymbol(none) mlabcolor(turquoise) mlabel("") mlabsize(3) mlabpos(3) ///
		|| connected  power_01 effect_size , lpattern("_") color(vermillion) msymbol(none) mlabcolor(vermillion) mlabel("") mlabsize(3) mlabpos(3) ///
		|| connected  power_001  effect_size ,  lpattern("l") color(black) msymbol(none) mlabcolor(black) mlabel("") mlabsize(3) mlabpos(3) ///
		|| scatter full_power effect_size , mlabel(mde_label) msymbol(none) mlabpos(12) mlabsize(3.5) ///
			xline(`mde', lpattern(dash) lcolor(gs3) lwidth(.5) noextend) ///
			ytitle("Percent with Significant Treatment Effect", size(4)) ///
			xtitle("Imposed Population Effect (Percent Reduction in Non-Elderly Mortality)", size(4) ) ///
			xscale(r(0 5)) ///
			xlabel(, nogrid labsize(4)) ///
			ylabel(0 "0%" 20 "20%"  40 "40%" 60 "60%" 80 "80%" 100 "100%",gmax noticks labsize(4)) ///
			legend(order( 1 2 3 4) pos(6) col(4) ///
				label(1 "{&alpha} =.10") label(2 "{&alpha} =.05") ///
				label(3 "{&alpha} =.01") label(4 "{&alpha} =.001") size(4)) ///
				title("Simulated Power Analysis; DD, 0-64, All Cause Mortality" " ", size(4)) 

		graph export "$dropbox/health_insurance_and_mortality/state_level_public_data_example/scripts/markdown/simulated_power_analysis.png",  replace width(800)
// ![Simulated Power Analysis; DD, 0-64, All Cause Mortality](simulated_power_analysis.png){width="100%"}
	
// Plot sign error
	sum s_error_10
	gen  s_error_label= 62.5
	twoway connected s_error_10 effect_size ,  lpattern("l") color(sea) msymbol(none) mlabcolor(sea) mlabel("") mlabsize(3) mlabpos(11) ///
		|| connected s_error_05 effect_size  ,  lpattern(".._") color(turquoise) msymbol(none) mlabcolor(turquoise) mlabel("") mlabsize(3) mlabpos(3) ///
		|| connected s_error_01 effect_size  , lpattern("_") color(vermillion) msymbol(none) mlabcolor(vermillion) mlabel("") mlabsize(3) mlabpos(3) ///
		|| connected s_error_001  effect_size  ,  lpattern("l") color(black) msymbol(none) mlabcolor(black) mlabel("") mlabsize(3) mlabpos(3) ///
		|| scatter s_error_label effect_size  , mlabel(mde_label) msymbol(none)  mlabpos(12) mlabsize(4)  ///
		ytitle("Percent", size(4)) ///
			xtitle("Imposed Population Effect (Percent Reduction in Non-Elderly Mortality)", size(4)) ///
			legend(size(4) order(1 2 3 4) pos(6) col(4) label(1 "{&alpha} =.10") label(2 "{&alpha} =.05") label(3 "{&alpha} =.01") label(4 "{&alpha} =.001")) ///
			xscale(r(0 5)) ///
			xline(`mde', lpattern(dash) lcolor(grey) noextend) ///
			xlabel( , nogrid labsize(4)) ///
			ylabel(0 "0%" 20 "20%"  40 "40%" 60 "60%",gmax noticks labsize(4)) ///
			title("Likelihood of Significant Coefficient Having Wrong Sign" "DD, 0-64, All Cause Mortality" " ", size(4))

		graph export "$dropbox/health_insurance_and_mortality/state_level_public_data_example/scripts/markdown/s_error.png", replace width(800)
// ![Likelihood of Significant Coefficient Having Wrong Sign DD, 0-64, All Cause Mortality](s_error.png){width="100%"}		

// Plot magnitude error
	sum m_error_001
	gen  height= `r(max)'*1.05
	twoway connected m_error_10 effect_size ,  lpattern("l") color(sea) msymbol(none) mlabcolor(sea) mlabel("") mlabsize(3) mlabpos(11) ///
		|| connected m_error_05 effect_size ,  lpattern(".._") color(turquoise) msymbol(none) mlabcolor(turquoise) mlabel("") mlabsize(3) mlabpos(3) ///
		|| connected m_error_01 effect_size , lpattern("_") color(vermillion) msymbol(none) mlabcolor(vermillion) mlabel("") mlabsize(3) mlabpos(3) ///
		|| connected m_error_001  effect_size ,  lpattern("l") color(black) msymbol(none) mlabcolor(black) mlabel("") mlabsize(3) mlabpos(3) ///
		|| scatter height effect_size , mlabel(mde_label) msymbol(none)  mlabpos(12) mlabsize(4)  ///
		ytitle("Mean abs(sig coef/imposed effect)", size(4)) ///
			xtitle("Imposed Population Effect (Percent Reduction in Non-Elderly Mortality)", size(4)) ///
			legend(size(4) order(1 2 3 4) pos(6) col(4) label(1 "{&alpha} =.10") label(2 "{&alpha} =.05") label(3 "{&alpha} =.01") label(4 "{&alpha} =.001")) ///
			xscale(r(0 5)) ///
			xline(`mde', lpattern(dash) lcolor(grey) noextend) ///
			xlabel(, nogrid labsize(4)) ///
			ylabel(, gmax noticks labsize(4)) ///
			title("Exaggeration Ratio; DD, 0-64, All Cause Mortality"  " ", size(4))

			graph export "$dropbox/health_insurance_and_mortality/state_level_public_data_example/scripts/markdown/m_error.png", replace width(800)
// ![Exaggeration Ratio; DD, 0-64, All Cause Mortality](m_error.png){width="100%"}

// Plot believability
	twoway connected believe_10 effect_size ,  lpattern("l") color(sea) msymbol(none) mlabcolor(sea) mlabel("") mlabsize(3) mlabpos(11) ///
		|| connected believe_05 effect_size ,  lpattern(".._") color(turquoise) msymbol(none) mlabcolor(turquoise) mlabel("") mlabsize(3) mlabpos(3) ///
		|| connected believe_01 effect_size , lpattern("_") color(vermillion) msymbol(none) mlabcolor(vermillion) mlabel("") mlabsize(3) mlabpos(3) ///
		|| connected believe_001  effect_size ,  lpattern("l") color(black) msymbol(none) mlabcolor(black) mlabel("") mlabsize(3) mlabpos(3) ///
		|| scatter full_power effect_size , mlabel(mde_label) msymbol(none) mlabpos(12) mlabsize(4)  ///
		xtitle("Imposed Population Effect (Percent Reduction in Non-Elderly Mortality)", size(4)) ///
			legend(size(4) order(1 2 3 4) pos(6) col(4) label(1 "{&alpha} =.10") label(2 "{&alpha} =.05") label(3 "{&alpha} =.01") label(4 "{&alpha} =.001")) ///
					ytitle("Probability", size(4)) ///
			xscale(r(0 5)) ///
			xline(`mde', lpattern(dash) lcolor(grey) noextend) ///
			xlabel(, nogrid labsize(4)) ///
			ylabel(0 "0%" 20 "20%"  40 "40%" 60 "60%" 80 "80%" 100 "100%",gmax noticks labsize(4)) ///
			title("Likelihood of believable coefficient; DD, 0-64, All Cause Mortality" " ", size(4)) 

		graph export  "$dropbox/health_insurance_and_mortality/state_level_public_data_example/scripts/markdown/believable.png", replace width(800)
		
// ![Likelihood of believable coefficient; DD, 0-64, All Cause Mortality](believable.png){width="100%"}

// Conclusion
// ====================
// Using this simple example, we can see that for this simple research design the minimum mortality reduction that is believable, well-powered, and significant at the 5% level is around `s `mde'`%. Changing the research design (e.g. adding control variables, shifting to the county-level, changing the cause of death) would certainly impact power. 

// This simple research design is a DiD comparing 23 random treated states to 18 random control states. In this simple design we used 5 years of pre-expansion data and 3 years of post-expansion data. Both state and year fixed-effects were included. Regressions were weighted by state-population and standard errors were clustered at the state-level. The dependent variable was the natural log of the all-cause non-elderly mortality rate per 100,000.


