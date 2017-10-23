#!/bin/bash
#Runs nfitis thorugh QA, topup, and eddy. Calculates Diffusion space -> Structural space affine, uses this calculations and pre-existing antsCT folder affine to template, and warp to template. 

#Prompted input: acquisition parameters a b c d (multiple rows for multiple phase encoding directions).

#[a b c d] - a, b, and c are to indicate phase encoding direction. 0 1 0 =  posterior -> anterior. -1 would indicate A>P. d is a calculation based off the echo spacing and epi factor d=((10^-3)*(echo spacing)*(epi factor). See https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/topup/Faq for detail.

#Needed inputs built-in to script: .nii, .bvecs, .bvals (unrounded)

#Needs access to following scripts: qa_clipcount_v3.sh, qa_dti_v3.sh, qa_motion_v3.sh, qa_preamble.sh, qa_tsnr_v3.sh, as well as fsl scripts (5.0.9 for all except eddy, 5.0.5 in current version)

#assumed that you're only correcting one set of volumes (A>P phase encoded in original usage)

#eddy step requires more memory than default allocation of 3 G of RAM. Use at least -l h_vmem=3.5,s_vmem=3

general=/data/joy/BBL/studies/grmpy/rawData/*/*/
scripts=/home/melliott/scripts
acqp=$1
indx=""	

# For AMICO/NODDI Running (via pcook)				
matlab -nodisplay -r "run '/data/joy/BBL/projects/multishell_diffusion/multishell_diffusionScripts/amicoSYRP/scripts/amicoGlobalInitialize.m'"		
exit		
		
#wrapper

for ((i=1; i<119; i+=1)); do indx="$indx 1"; done

for i in $general;do 
	bblIDs=$(echo ${i}|cut -d'/' -f8 |sed s@'/'@' '@g);
	SubDate_and_ID=$(echo ${i}|cut -d'/' -f9|sed s@'/'@' '@g|sed s@'x'@','@g)
	Date=$(echo ${SubDate_and_ID}|cut -d',' -f1)
	ID=$(echo ${SubDate_and_ID}|cut -d',' -f2)
	inputnifti=$(echo ${i}DTI_MultiShell_117dir/nifti/*.nii.gz)
	unroundedbval=$(echo ${i}DTI_MultiShell_117dir/nifti/*.bval)
	topupref=$(echo ${i}DTI_MultiShell_topup_ref/nifti/*.nii.gz)
	bvec=$(echo ${i}DTI_MultiShell_117dir/nifti/*.bvec)
	mkdir /data/joy/BBL/projects/multishell_diffusion/processedData/multishellPipelineFall2017/${bblIDs}/${SubDate_and_ID}/Prestats
	mkdir /data/joy/BBL/projects/multishell_diffusion/processedData/multishellPipelineFall2017/${bblIDs}/${SubDate_and_ID}/Prestats/QA
	mkdir /data/joy/BBL/projects/multishell_diffusion/processedData/multishellPipelineFall2017/${bblIDs}/${SubDate_and_ID}/Prestats/Topup
	mkdir /data/joy/BBL/projects/multishell_diffusion/processedData/multishellPipelineFall2017/${bblIDs}/${SubDate_and_ID}/Prestats/Eddy
	mkdir /data/joy/BBL/projects/multishell_diffusion/processedData/multishellPipelineFall2017/${bblIDs}/${SubDate_and_ID}/CoReg
	mkdir /data/joy/BBL/projects/multishell_diffusion/processedData/multishellPipelineFall2017/${bblIDs}/${SubDate_and_ID}/Norm
	mkdir /data/joy/BBL/projects/multishell_diffusion/processedData/multishellPipelineFall2017/${bblIDs}/${SubDate_and_ID}/AMICO
	out=/data/joy/BBL/projects/multishell_diffusion/processedData/multishellPipelineFall2017/$bblIDs/${bblIDs}/${SubDate_and_ID}
	eddy_outdir=/data/joy/BBL/projects/multishell_diffusion/processedData/multishellPipelineFall2017/${bblIDs}/${SubDate_and_ID}/Prestats/Eddy

	mkdir -p ${eddy_outdir}
	
############ QA #################

# Import bvec
	cp $unroundedbval $out/Prestats/QA/bvec.bvec	
# Round bvals up or down 5, corrects for scanner output error in bvals	
	$scripts/bval_rounder.sh $unroundedbval $out/Prestats/QA/roundedbval.bval 100
# Get quality assurance metrics on DTI data for each shell
	$scripts/qa_dti_v3.sh $inputnifti $out/Prestats/QA/roundedbval.bval $bvec $out/Prestats/QA/dwi.qa

############# DISTORTION/MOTION CORRECTION ################
# Extract b0 from anterior to posterior phase-encoded input nifti for topup calculation	
	fslroi $inputnifti $out/Prestats/Topup/nodif_AP 0 1
# Extract b0 from P>A topup ref for topup calculation
	fslroi $topupref $out/Prestats/Topup/nodif_PA 0 1
# Merge b0s for topup calculation
	fslmerge -t $out/Prestats/Topup/b0s $out/Prestats/Topup/nodif_AP $out/Prestats/Topup/nodif_PA
# Run topup to calculate correction for field distortion
	topup --imain=$out/Prestats/Topup/b0s.nii.gz --datain=$1 --out=$out/Prestats/Topup/my_topup --fout=$out/Prestats/Topup/my_field --iout=$out/Prestats/Topup/topup_iout
# Actually correct field distortion
	applytopup --imain=$inputnifti --datain=$1 --inindex=1 --topup=$out/Prestats/Topup/my_topup --out=$out/Prestats/Topup/topup_applied --method=jac
# Average MR signal over all volumes so brain extraction can work on signal representative of whole scan
	fslmaths $out/Prestats/Topup/topup_iout.nii.gz -Tmean $out/Prestats/Topup/mean_iout.nii.gz


# Brain extraction mask for eddy, -m makes binary mask
	topup_mask=$out/Prestats/Topup/bet_mean_iout_point_2.nii.gz

	bet $out/Prestats/Topup/mean_iout.nii.gz ${topup_mask} -m -f 0.2

# Create index for eddy to know which acquisition parameters apply to which volumes.(Original usage only correcting A>P, only using one set of acq params.
	echo $indx > index.txt

# Run eddy correction. Corrects for Electromagnetic-pulse induced distortions. Most computationally intensive of anything here, has taken >5 hours. More recent eddy correction available in more recent FSL versions
	/share/apps/fsl/5.0.5/bin/eddy --imain=$out/Prestats/Topup/topup_applied.nii.gz --mask=${topup_mask} --index=index.txt --acqp=$1 --bvecs=$bvec --bvals=$out/QA/roundedbval.bval --out=$eddy_outdir/eddied.nii.gz
	
	eddy_output=$eddy_outdir/eddied.nii.gz

# Mask eddy output using topup mask
	fslmaths ${eddy_output} -mas ${topup_mask} $eddy_outdir/eddied_maskedG.nii.gz

# Mask eddy output using topup mask
	fslroi $eddy_outdir/eddied_maskedG.nii.gz $eddy_outdir/eddied_masked_b0G.nii.gz 0 1
 	
 	masked_b0=$eddy_outdir/eddied_masked_b0G.nii.gz
########### COREGISTRATION ####################

# make white matter only mask from segmented T1 in prep for flirt BBR
     fslmaths /data/joy/BBL/studies/grmpy/processedData/structural/struct_pipeline_20170716/$bblIDs/{$SubDate_and_ID}/antsCT/*_BrainSegmentation.nii.gz -thr 3 -uthr 3 $out/CoReg/Struct_WM.nii.gz
# use flirt to calculate diffusion -> structural translation 
	flirt -cost bbr -wmseg $out/CoReg/Struct_WM.nii.gz -in ${masked_b0} -ref /data/joy/BBL/studies/grmpy/processedData/structural/struct_pipeline_20170716/$bblIDs/{$SubDate_and_ID}/antsCT/*ExtractedBrain0N4.nii.gz -out $out/CoReg/flirt_BBR -dof 6 -omat $out/CoReg/MultiShDiff2StructFSL.mat
# Convert FSL omat to Ras
	c3d_affine_tool -src ${masked_b0} -ref /data/joy/BBL/studies/grmpy/processedData/structural/struct_pipeline_20170716/$bblIDs/{$SubDate_and_ID}/antsCT/*ExtractedBrain0N4.nii.gz $out/CoReg/MultiShDiff2StructFSL.mat -fsl2ras -oitk $out/CoReg/MultiShDiff2StructRas.mat
# Use Subject to template warp and affine from grmpy directory after Ras diffusion -> structural space affine to put eddied_bet_2 onto pnc template
	antsApplyTransforms -e 3 -d 3 -i ${masked_b0} -r /data/joy/BBL/studies/pnc/template/pnc_template_brain.nii.gz -o $out/Norm/eddied_b0_template_spaceG.nii.gz -t /data/joy/BBL/studies/grmpy/processedData/structural/struct_pipeline_20170716/$bblIDs/{$SubDate_and_ID}/antsCT/*SubjectToTemplate1Warp.nii.gz -t /data/joy/BBL/studies/grmpy/processedData/structural/struct_pipeline_20170716/$bblIDs/{$SubDate_and_ID}/antsCT/*SubjectToTemplate0GenericAffine.mat -t $out/CoReg/MultiShDiff2StructRas.mat


################## AMICO/NODDI (as well as global initialize @ top, but only needs to be run once) ################## 

#Generate Amico scheme (edit paths for files like mask and eddy output in generateAmicoM script)
/data/joy/BBL/projects/multishell_diffusion/multishell_diffusionScripts/amicoSYRP/scripts/generateAmicoM_AP.pl {$bblIDs} {$SubDate_and_ID}

#Run Amico
/data/joy/BBL/projects/multishell_diffusion/multishell_diffusionScripts/amicoSYRP/scripts/runAmico.sh subjectsAMICO/DTI_MULTISHELL/{$bblIDs}/{$SubDate_and_ID}/runAMICO.m

done
