#!/bin/bash


IDs=$1
cdir=/data/joy/BBL/applications/camino/bin
ddir=/share/apps/dsistudio/2016-01-25/bin
general=/data/jux/daviska/apines/3T_Subjects_NODDI/*/
#for i in $general;do 
	#IDs=$(echo ${i}|cut -d'/' -f8 |sed s@'/'@' '@g);
	#SubDate_and_ID=$(echo ${i}|cut -d'/' -f9|sed s@'/'@' '@g|sed s@'x'@'x'@g)
	#Date=$(echo ${SubDate_and_ID}|cut -d',' -f1)
	#ID=$(echo ${SubDate_and_ID}|cut -d',' -f2)
###mkdir /data/jux/daviska/apines/3T_Subjects_NODDI/${IDs}/tractography
out=/data/jux/daviska/apines/3T_Subjects_NODDI/${IDs}
in=/data/jux/daviska/apines/3T_Subjects_NODDI/${IDs}/AMICO/
MNI=/data/jux/daviska/apines/atlases/MNI152_T1_1mm_brain.nii.gz
AAL=/data/jux/daviska/apines/atlases/AAL_MNI.nii

# re-mask DWI_t1Warp_BWarped

fslmaths $out/prestats/${IDs}_eddied_undistort_warped.nii.gz -mas $out/prestats/eddy/${IDs}_seqSpaceT1Mask.nii.gz  $out/prestats/${IDs}_eddied_undistort_warped_t1Masked.nii.gz

# Make CSF and High ISO into an exclusion path for tractography
fslmaths /data/jux/daviska/apines/3T_Subjects_NODDI/${IDs}/coreg/${IDs}_T1_betted_seg.nii.gz -thr 1 -uthr 1 $out/coreg/${IDs}_CSF.nii.gz
fslmaths /data/jux/daviska/apines/3T_Subjects_NODDI/${IDs}/AMICO/NODDI/FIT_ISOVF.nii.gz -thr .8 -uthr 1 $out/coreg/${IDs}_8ISO.nii.gz
csf=${out}/coreg/${IDs}_CSF.nii.gz

#csf to seq space
antsApplyTransforms -e 0 -d 3 -i ${csf} -r ${out}/coreg/${IDs}_DWISpaceT1.nii.gz -o $out/coreg/DWISpace_csf.nii.gz -t [$out/coreg/${IDs}_MultiShDiff2StructRas.mat,1] -n MultiLabel

#Combine with highest ISO values in NODDI output
fslmaths $out/coreg/DWISpace_csf.nii.gz -add $out/coreg/${IDs}_8ISO.nii.gz -bin ${out}/coreg/CSFandISO.nii.gz

#wm to seq space
antsApplyTransforms -e 3 -d 3 -i $out/coreg/${IDs}_Struct_WM.nii.gz -r $out/coreg/${IDs}_DWISpaceT1.nii.gz -o $out/coreg/${IDs}_seqspaceWM.nii.gz -t [$out/coreg/${IDs}_MultiShDiff2StructRas.mat,1] -n NearestNeighbor

#dilate seqspace wm
ImageMath 3 $out/coreg/${IDs}_seqspaceWM_dil.nii.gz GD $out/coreg/${IDs}_seqspaceWM.nii.gz 1

#dilate hippocamp region
##ImageMath 3 $out/coreg/BinarizedHippo_dil.nii.gz GD $out/coreg/BinarizedHippo.nii.gz 1

# Convert FSL omat to Ras
	
###c3d_affine_tool -src ${MNI} -ref ${out}/coreg/${IDs}_T1_betted.nii.gz $out/coreg/${IDs}_MNI2StructFSL.mat -fsl2ras -oitk $out/coreg/${IDs}_MNIStructRas.mat

# Calculate non-affine

#####/data/jux/daviska/apines/ANTs/Scripts/antsRegistrationSyN.sh -d 3 -f $out/coreg/${IDs}_T1_betted.nii.gz -m ${MNI} -o /data/jux/daviska/apines/3T_Subjects_NODDI/${IDs}/coreg/${IDs}_MNI_T1_Warp

antsApplyTransforms -d 3 -e 0 -i ${AAL} -r /data/jux/daviska/apines/3T_Subjects_NODDI/${IDs}/coreg/${IDs}_DWISpaceT1.nii.gz -o  $out/coreg/${IDs}_DWISpace_AAL.nii.gz -t /data/jux/daviska/apines/3T_Subjects_NODDI/${IDs}/coreg/${IDs}_MNI_T1_Warp1Warp.nii.gz -t  $out/coreg/${IDs}_MNI_T1_Warp0GenericAffine.mat -n NearestNeighbor

### Weird combination of fslmaths to distinguish left and right hippo, remove ashs-generated rois from AAL (or other atlas if subbed in)

#distinguish
fslmaths ${out}/coreg/RBinarizedHippo.nii.gz -mul 2 ${out}/coreg/RBinarizedHippoPlus1.nii.gz
fslmaths ${out}/coreg/RBinarizedHippoPlus1.nii.gz -add ${out}/coreg/LBinarizedHippo.nii.gz ${out}/coreg/RLBinHippo.nii.gz

# remove ashs-generated rois from AAL (or other atlas if subbed in)
fslmaths $out/coreg/BinarizedHippo.nii.gz -sub 1 $out/coreg/sub1.nii.gz
fslmaths $out/coreg/sub1.nii.gz -mul -1 $out/coreg/0ed.nii.gz
fslmaths $out/coreg/${IDs}_DWISpace_AAL.nii.gz -mul $out/coreg/0ed.nii.gz $out/coreg/${IDs}_DWISpace_AAL_noH.nii.gz
fslmaths ${out}/coreg/RLBinHippo.nii.gz -add $out/coreg/${IDs}_DWISpace_AAL_noH.nii.gz $out/coreg/${IDs}_DWISpace_AAL_ASH.nii.gz

subAAL=$out/coreg/${IDs}_DWISpace_AAL_ASH.nii.gz

###fslmaths ${subAAL} -thr 6301 -uthr 6302 $out/tractography/${IDs}_Precun.nii.gz


#get convergence of ROIs and dilated wm
##fslmaths ${subAAL} -mas $out/coreg/${IDs}_seqspaceWM_dil.nii.gz $out/coreg/${IDs}_seqspaceWM_AAL_Intersect.nii.gz
###fslmaths $out/tractography/${IDs}_Precun.nii.gz -mas $out/coreg/${IDs}_seqspaceWM.nii.gz $out/coreg/${IDs}_seqspaceWM_Precun_Intersect.nii.gz

#fitTensorsinCamino
mkdir $out/tractography

export CAMINO_HEAP_SIZE=10000

$cdir/fsl2scheme -bvecfile $in/bvecs -bvalfile $in/bvals > $out/tractography/${IDs}.scheme
$cdir/image2voxel -4dimage $out/prestats/${IDs}_eddied_undistort_warped_t1Masked.nii.gz -outputfile $out/tractography/${IDs}_i2v.Bfloat

#wdt reconstruction
$cdir/wdtfit $out/tractography/${IDs}_i2v.Bfloat $out/tractography/${IDs}.scheme -bgmask $in/brainMask.nii -outputfile $out/tractography/${IDs}_WdtModelFit.Bdouble
#mv $out/coreg/${bblIDs}_${SubDate_and_ID}_Schaef_WM_intersect.nii.gz  $out/coreg/${bblIDs}_${SubDate_and_ID}_SchaefPNC_200_WM_intersect.nii.gz

seed_path=${out}/coreg/RLBinHippo.nii.gz
atlas_path=${subAAL}
model_fit_path=$out/tractography/${IDs}_WdtModelFit.Bdouble
waypoint_path=$out/coreg/${IDs}_seqspaceWM_dil.nii.gz
exclusion_path=${out}/coreg/CSFandISO.nii.gz

dsource=$out/prestats/${IDs}_eddied_undistort_warped_t1Masked.nii.gz
tractography_output=$out/tractography/${IDs}_HippoTract.Bdouble

#dilate intersect
##ImageMath 3 $out/coreg/${bblIDs}_${SubDate_and_ID}_SchaefPNC_200_WM_intersect_Dil1.nii.gz GD $seed_path 1

##dilSeed_path=$out/coreg/${bblIDs}_${SubDate_and_ID}_SchaefPNC_200_WM_intersect_Dil1.nii.gz

## Merge ROIs for endpointfile, to find streamlines between them.
fslmaths ${out}/coreg/RBinarizedHippo.nii.gz -mul 2 ${out}/coreg/RBinarizedHippoPlus1.nii.gz
fslmaths ${out}/coreg/RBinarizedHippoPlus1.nii.gz -add ${out}/coreg/LBinarizedHippo.nii.gz ${out}/coreg/RLBinHippo.nii.gz
##fslmaths ${out}/coreg/RLBinHippo.nii.gz -add $out/tractography/${IDs}_Precun.nii.gz ${out}/tractography/endpoint.nii.gz

$cdir/analyzeheader -datadims 96 96 50 -voxeldims 2.5 2.5 2.5 -datatype double > $out/tractography/${IDs}_Camino_FA.hdr

# Generate FA from camino
$cdir/fa < $out/tractography/${IDs}_WdtModelFit.Bdouble > $out/tractography/${IDs}_Camino_FA.img

#hdr/img to nii.gz
c3d $out/tractography/${IDs}_Camino_FA.img -o $out/tractography/${IDs}_Camino_FA.nii.gz
rm $out/tractography/${IDs}_Camino_FA.hdr
rm $out/tractography/${IDs}_Camino_FA.img

#shady step to make FA and Schaef_WM_Interesect equivalent
fslcpgeom $seed_path $out/tractography/${IDs}_Camino_FA.nii.gz

#Camino tractography
cdir/track -inputmodel dt -seedfile "${seed_path}" -inputfile "${model_fit_path}" -tracker euler -interpolator linear -iterations 10 -curvethresh 60 | $cdir/procstreamlines -exclusionfile "${exclusion_path}" -truncateinexclusion -outputfile "${tractography_output}"
##$cdir/track -inputmodel dt -seedfile "${seed_path}" -inputfile "${model_fit_path}" -tracker fact -iterations 20 -curvethresh 60 | $cdir/procstreamlines -waypointfile ${waypoint_path} -exclusionfile ${exclusion_path} -endpointfile ${out}/tractography/endpoint.nii.gz -outputfile "${tractography_output}"
##$cdir/track -inputmodel dt -seedfile "${seed_path}" -inputfile "${model_fit_path}" -tracker fact -iterations 20 -curvethresh 70 | $cdir/procstreamlines -exclusionfile ${exclusion_path} -endpointfile ${out}/tractography/endpoint.nii.gz -outputfile "${tractography_output}"


### Convert camino tracts to trackvis format
/data/jux/daviska/apines/camino-trackvis-0.2.8.1/bin/camino_to_trackvis -i ${tractography_output} -o ${out}/tractography/${IDs}_streamlines.trk -l 15 --nifti $out/prestats/${IDs}_eddied_undistort_warped_t1Masked.nii.gz --phys-coords

################################################
### Generate connectivity matrices in Camino ###
################################################


#copy scalars to coreg folder so conmat can run
cp $out/AMICO/NODDI/FIT_ICVF.nii $out/coreg/
cp $out/AMICO/NODDI/FIT_OD.nii $out/coreg/
rm $out/tractography/${IDs}_Camino_FA.hdr
rm $out/tractography/${IDs}_Camino_FA.img
cp $out/tractography/${IDs}_Camino_FA.nii.gz $out/coreg

# Mean ICVF matrix
$cdir/conmat -inputfile "${tractography_output}" -targetfile ${subAAL} -scalarfile $out/coreg/FIT_ICVF.nii -tractstat mean -outputroot $out/tractography/${IDs}_ICVF_matrix

# Mean ODI matrix
$cdir/conmat -inputfile "${tractography_output}" -targetfile ${subAAL} -scalarfile $out/coreg/FIT_OD.nii -tractstat mean -outputroot $out/tractography/${IDs}_ODI_matrix

# Mean FA matrix
#shady step to make FA and AAL equivalent
fslcpgeom ${subAAL} $out/tractography/${IDs}_Camino_FA.nii.gz

$cdir/conmat -inputfile "${tractography_output}" -targetfile ${subAAL} -scalarfile $out/tractography/${IDs}_Camino_FA.nii.gz -tractstat mean -outputroot $out/tractography/${IDs}_FA_matrix

#done
