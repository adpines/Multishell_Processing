#!/bin/bash

#GRMPY Version

general=/data/joy/BBL/studies/grmpy/rawData/*/*/

for i in $general;do 
	bblIDs=$(echo ${i}|cut -d'/' -f8 |sed s@'/'@' '@g);
	SubDate_and_ID=$(echo ${i}|cut -d'/' -f9|sed s@'/'@' '@g|sed s@'x'@'x'@g)
	Date=$(echo ${SubDate_and_ID}|cut -d',' -f1)
	ID=$(echo ${SubDate_and_ID}|cut -d',' -f2)

	## Setup AMICO/NODDI (via pcook)				
	matlab -nodisplay -r 'run /data/joy/BBL/projects/multishell_diffusion/multishell_diffusionScripts/amicoSYRP/scripts/amicoGlobalInitialize.m' -r 'exit' 

	# Remove old output
	
	rm -r /data/joy/BBL/projects/multishell_diffusion/processedData/multishellPipelineFall2017/${bblIDs}/
	
	## Create log directory

	logDir=/data/joy/BBL/projects/multishell_diffusion/processedData/multishellPipelineFall2017/${bblIDs}/${SubDate_and_ID}/logfiles
	mkdir -p ${logDir}

	## Write subject-specific script for qsub
	var0="pushd /data/joy/BBL/projects/multishell_diffusion/multishell_diffusionScripts/; ./MultiShell_PreProc.sh ${bblIDs} ${SubDate_and_ID}; popd"

	echo -e "${var0}" > ${logDir}/run_MultiShell_PreProc_"${bblIDs}"_"${SubDate_and_ID}".sh

	subject_script=${logDir}/run_MultiShell_PreProc_"${bblIDs}"_"${SubDate_and_ID}".sh
	
	# chmod 775 ${subject_script}
 	
	## Execute qsub job for probtrackx2 runs for each subject 
	qsub -q all.q,basic.q -wd ${logDir} -l h_vmem=8G,s_vmem=7G ${subject_script}

done
