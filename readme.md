# Example Simulated Power Analysis from Black, Hollingsworth, Nunes, and Simon (2019)

This is an example of the type of simulated power analysis done in Black et al. (2019). This example is done with publicly available data. 

This set-up is designed to mimic a typical DiD setting. Here we will compare 23 randomly chosen treated states to 18 randomly chosen control states. We will impose a series of treatment effects that gradually increase in magnitude and report whether or not these imposed treatment effects are detectable. We will vary the set of randomly chosen treated states. We will calculate the minimum detectable effect size at various power and significance levels. We will also explore a measure of believability, which is based upon Gelman and Carlin (2014) measures of sign and magnitude error.

In this simple design we used 5 years of pre-expansion data and 3 years of post-expansion data. Both state and year fixed-effects are included. Regressions are weighted by state-population and standard errors will be clustered at the state-level. The dependent variable will be the natural log of the all-cause non-elderly mortality rate per 100,000.

This code is simply an example of our simulated power analysis and is not an attempt to identify the impact of Medicaid expansion on mortality. Importantly, changing the research design (e.g. adding control variables, shifting to the county-level, changing the cause of death, using propensity score weights, or using a synthetic control estimator) will impact power. Our approach could be easily modified to accommodate any of these alternative research designs. Any improvements to the research design will very likely increase power and decrease the minimum detectable effect size.

## Web friendly version of the example

[Github's default rendering of html files is to show you the source-code, by clicking this link you can see our example rendered in a web-friendly version](http://htmlpreview.github.io/?https://github.com/hollina/health_insurance_and_mortality/blob/master/state_level_public_data_example/scripts/markdown/simple_power_example_markdown.html).

This html file was created directly from stata using the [markstat package created by Germán Rodríguez](https://data.princeton.edu/stata/markdown/gettingStarted).

## Stata friendly version of the example
[You can find a stata do file that runs the same code as in our example here](https://github.com/hollina/health_insurance_and_mortality/blob/master/state_level_public_data_example/scripts/simple_power_example.do).