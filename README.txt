This repository holds the code, data, and plots for "Schelling segregation dynamics in densely-connected social network graphs" by Sage Anastasi & Giulio Dalla Riva.

The plots and data used in the paper are in the folder "ABM Data".

The scripts for generating the data are "tolerance-change-testing", "asymmetric-tolerance-testing", "group-size-change-testing", and "weak-minority-preferences". Please pay attention to the commented code in each script for specifics such as if parameters need to be changed manually. 

Scripts are written in Julia, and use a Manifest.toml and Project.toml for package management. Due to significant changes to the Agents.jl package, these scripts will only run with Agents.jl version 5.12 and Julia version 1.10.

For "group-size-change-testing" and "weak-minority-preferences", the script opens the "data.csv" folder and writes a new row at the end of each run. Blank spreadsheets "minority_data_blank.csv" and "size_data_blank" with headings are provided for this purpose and should be saved as "data.csv" before proceeding. The filled "data.csv" file should be renamed after the script is finished to avoid adding data from one script to the results of the other. The scripts "tolerance-change-testing" and "asymmetric-tolerance-testing" save the data in a dataframe and output a completed CSV at the end.

Please note that running "ABM_graphing.R" will overwrite the plots with new versions based on the data that is in the local folder with it.