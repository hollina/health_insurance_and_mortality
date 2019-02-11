// Clear memory
clear all

// Create HTML file for simple power example
cd "$dropbox/health_insurance_and_mortality/state_level_public_data_example/scripts/markdown"
markstat using simple_power_example_markdown

// Move results from scripts folder, which is where the markstat package puts them to the output folder
!mv "$dropbox/health_insurance_and_mortality/state_level_public_data_example/scripts/markdown/believable.png" ///
	"$dropbox/health_insurance_and_mortality/state_level_public_data_example/output/believable.png"
	
!mv "$dropbox/health_insurance_and_mortality/state_level_public_data_example/scripts/markdown/m_error.png" ///
	"$dropbox/health_insurance_and_mortality/state_level_public_data_example/output/m_error.png"

!mv "$dropbox/health_insurance_and_mortality/state_level_public_data_example/scripts/markdown/s_error.png" ///
	"$dropbox/health_insurance_and_mortality/state_level_public_data_example/output/s_error.png"

!mv "$dropbox/health_insurance_and_mortality/state_level_public_data_example/scripts/markdown/simulated_power_analysis.png" ///
	"$dropbox/health_insurance_and_mortality/state_level_public_data_example/output/simulated_power_analysis.png"


!mv "$dropbox/health_insurance_and_mortality/state_level_public_data_example/scripts/markdown/simple_power_example_markdown.html"
	"$dropbox/health_insurance_and_mortality/state_level_public_data_example/output/simple_power_example_markdown.html"

