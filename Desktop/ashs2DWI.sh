#!/bin/bash

### Extract individual subfields of hippocampi, move ASHS atlases to DWI space

IDs=$1	

adir=/data/jux/daviska/apines/3T_Subjects_NODDI/${IDs}/ashs
subdir=/data/jux/daviska/apines/3T_Subjects_NODDI/${IDs}/ashs/HippoSubfields
list=/data/jux/daviska/apines/3T_Subjects_NODDI/${IDs}/ashs/HippoSubfields/*
out=/data/jux/daviska/apines/3T_Subjects_NODDI/${IDs}
mkdir ${subdir}

# use flirt to calculate T1 -> T2 
flirt -cost bbr -wmseg $out/coreg/${IDs}_Struct_WM.nii.gz -in ${adir}/tse.nii.gz -ref ${adir}/mprage.nii.gz -out $out/coreg/${IDs}_T2-T1_BBR -dof 6 -omat $out/coreg/${IDs}_T2toT1.mat

# Convert FSL omat to Ras
c3d_affine_tool -src ${adir}/tse.nii.gz -ref ${adir}/mprage.nii.gz $out/coreg/${IDs}_T2toT1.mat -fsl2ras -oitk ${adir}/flirt_t2_to_t1/T2toT1Ras.mat


## Left Hippocampus
# Extract CA1
fslmaths ${adir}/final/ashs_left_lfseg_corr_usegray.nii.gz -thr 1 -uthr 1 ${subdir}/${IDs}_LCA1.nii.gz
# Extract CA2
fslmaths ${adir}/final/ashs_left_lfseg_corr_usegray.nii.gz -thr 2 -uthr 2 ${subdir}/${IDs}_LCA2.nii.gz
# Extract DG
fslmaths ${adir}/final/ashs_left_lfseg_corr_usegray.nii.gz -thr 3 -uthr 3 ${subdir}/${IDs}_LDG.nii.gz
# Extract CA3
fslmaths ${adir}/final/ashs_left_lfseg_corr_usegray.nii.gz -thr 4 -uthr 4 ${subdir}/${IDs}_LCA3.nii.gz
# Extract head
fslmaths ${adir}/final/ashs_left_lfseg_corr_usegray.nii.gz -thr 5 -uthr 5 ${subdir}/${IDs}_Lhead.nii.gz
# Extract tail
fslmaths ${adir}/final/ashs_left_lfseg_corr_usegray.nii.gz -thr 6 -uthr 6 ${subdir}/${IDs}_Ltail.nii.gz
# Extract misc
fslmaths ${adir}/final/ashs_left_lfseg_corr_usegray.nii.gz -thr 7 -uthr 7 ${subdir}/${IDs}_Lmisc.nii.gz
# Extract SUB
fslmaths ${adir}/final/ashs_left_lfseg_corr_usegray.nii.gz -thr 8 -uthr 8 ${subdir}/${IDs}_LSUB.nii.gz
# Extract ERC
fslmaths ${adir}/final/ashs_left_lfseg_corr_usegray.nii.gz -thr 10 -uthr 10 ${subdir}/${IDs}_LERC.nii.gz
# Extract BA35
fslmaths ${adir}/final/ashs_left_lfseg_corr_usegray.nii.gz -thr 11 -uthr 11 ${subdir}/${IDs}_LBA35.nii.gz
# Extract BA36
fslmaths ${adir}/final/ashs_left_lfseg_corr_usegray.nii.gz -thr 12 -uthr 12 ${subdir}/${IDs}_LBA36.nii.gz
# Extract PHC
fslmaths ${adir}/final/ashs_left_lfseg_corr_usegray.nii.gz -thr 13 -uthr 13 ${subdir}/${IDs}_LPHC.nii.gz
# Extract Sulcus
fslmaths ${adir}/final/ashs_left_lfseg_corr_usegray.nii.gz -thr 14 -uthr 14 ${subdir}/${IDs}_LSulcus.nii.gz

echo "---left hippocampus subfielded---"

##Right Hippocampus
# Extract CA1
fslmaths ${adir}/final/ashs_right_lfseg_corr_usegray.nii.gz -thr 1 -uthr 1 ${subdir}/${IDs}_RCA1.nii.gz
# Extract CA2
fslmaths ${adir}/final/ashs_right_lfseg_corr_usegray.nii.gz -thr 2 -uthr 2 ${subdir}/${IDs}_RCA2.nii.gz
# Extract DG
fslmaths ${adir}/final/ashs_right_lfseg_corr_usegray.nii.gz -thr 3 -uthr 3 ${subdir}/${IDs}_RDG.nii.gz
# Extract CA3
fslmaths ${adir}/final/ashs_right_lfseg_corr_usegray.nii.gz -thr 4 -uthr 4 ${subdir}/${IDs}_RCA3.nii.gz
# Extract head
fslmaths ${adir}/final/ashs_right_lfseg_corr_usegray.nii.gz -thr 5 -uthr 5 ${subdir}/${IDs}_Rhead.nii.gz
# Extract tail
fslmaths ${adir}/final/ashs_right_lfseg_corr_usegray.nii.gz -thr 6 -uthr 6 ${subdir}/${IDs}_Rtail.nii.gz
# Extract misc
fslmaths ${adir}/final/ashs_right_lfseg_corr_usegray.nii.gz -thr 7 -uthr 7 ${subdir}/${IDs}_Rmisc.nii.gz
# Extract SUB
fslmaths ${adir}/final/ashs_right_lfseg_corr_usegray.nii.gz -thr 8 -uthr 8 ${subdir}/${IDs}_RSUB.nii.gz
# Extract ERC
fslmaths ${adir}/final/ashs_right_lfseg_corr_usegray.nii.gz -thr 10 -uthr 10 ${subdir}/${IDs}_RERC.nii.gz
# Extract BA35
fslmaths ${adir}/final/ashs_right_lfseg_corr_usegray.nii.gz -thr 11 -uthr 11 ${subdir}/${IDs}_RBA35.nii.gz
# Extract BA36
fslmaths ${adir}/final/ashs_right_lfseg_corr_usegray.nii.gz -thr 12 -uthr 12 ${subdir}/${IDs}_RBA36.nii.gz
# Extract PHC
fslmaths ${adir}/final/ashs_right_lfseg_corr_usegray.nii.gz -thr 13 -uthr 13 ${subdir}/${IDs}_RPHC.nii.gz
# Extract Sulcus
fslmaths ${adir}/final/ashs_right_lfseg_corr_usegray.nii.gz -thr 14 -uthr 14 ${subdir}/${IDs}_RSulcus.nii.gz

for i in ${list}; do
	echo ${i}
	a=$(echo ${i}|cut -d'/' -f10)
	echo $a
	antsApplyTransforms -e 0 -d 3 -i ${i} -r ${out}/coreg/${IDs}_DWISpaceT1.nii.gz -o $out/coreg/${a}.nii.gz -t [$out/coreg/${IDs}_MultiShDiff2StructRas.mat,1] -t ${adir}/flirt_t2_to_t1/T2toT1Ras.mat -n MultiLabel
done  
