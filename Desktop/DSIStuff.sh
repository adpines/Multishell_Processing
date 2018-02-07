#grmpy-wide variables

general=/data/joy/BBL/studies/grmpy/rawData/*/*

dsiBin="/share/apps/dsistudio/2016-01-25/bin/dsi_studio"

for i in $general;do 
	bblIDs=$(echo ${i}|cut -d'/' -f8 |sed s@'/'@' '@g);
	SubDate_and_ID=$(echo ${i}|cut -d'/' -f9|sed s@'/'@' '@g|sed s@'x'@'x'@g)

#subject variables

out=/data/joy/BBL/projects/multishell_diffusion/processedData/multishellPipelineFall2017/${bblIDs}/${SubDate_and_ID}

general=/data/joy/BBL/studies/grmpy/rawData/$bblIDs/$SubDate_and_ID

eddy_outdir=/data/joy/BBL/projects/multishell_diffusion/processedData/multishellPipelineFall2017/${bblIDs}/${SubDate_and_ID}/prestats/eddy

bvecs=/data/joy/BBL/projects/multishell_diffusion/processedData/multishellPipelineFall2017/${bblIDs}/${SubDate_and_ID}/prestats/eddy/${bblIDs}_${SubDate_and_ID}_eddied.eddy_rotated_bvecs

eddy_output=$eddy_outdir/${bblIDs}_${SubDate_and_ID}_eddied.nii.gz

#make directory for dsi stuff

#mkdir $out/dsi

#remask eddy output using T1 space generated mask

	fslmaths ${eddy_output} -mas $out/prestats/eddy/${bblIDs}_${SubDate_and_ID}_seqSpaceT1Mask.nii.gz $eddy_outdir/${bblIDs}_${SubDate_and_ID}_eddied_t1Masked.nii.gz

#eddy to normal space
antsApplyTransforms -e 3 -d 3 -i $eddy_outdir/${bblIDs}_${SubDate_and_ID}_eddied_t1Masked.nii.gz -r /data/joy/BBL/studies/pnc/template/pnc_template_brain_2mm.nii.gz -o $out/norm/${bblIDs}_${SubDate_and_ID}_Eddy_Std.nii.gz -t /data/joy/BBL/studies/grmpy/processedData/structural/struct_pipeline_20170716/$bblIDs/$SubDate_and_ID/antsCT/*SubjectToTemplate1Warp.nii.gz -t /data/joy/BBL/studies/grmpy/processedData/structural/struct_pipeline_20170716/$bblIDs/$SubDate_and_ID/antsCT/*SubjectToTemplate0GenericAffine.mat -t $out/coreg/${bblIDs}_${SubDate_and_ID}_MultiShDiff2StructRas.mat

#convert remasked normal eddy to dsi format

${dsiBin} --action=src --source=$out/norm/${bblIDs}_${SubDate_and_ID}_Eddy_Std.nii.gz --bval=${out}/prestats/qa/${bblIDs}_${SubDate_and_ID}_roundedbval.bval --bvec=${bvecs} --output=$out/dsi/${bblIDs}_${SubDate_and_ID}t1_maskedEddied.src.gz

done 
