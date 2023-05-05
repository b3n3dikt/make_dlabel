## Relevant links
#DCAN pipeline vol to surface mapping https://github.com/DCAN-Labs/dcan-macaque-pipeline/blob/master/fMRISurface/scripts/RibbonVolumeToSurfaceMapping.sh
#DCAN pipeline overview https://github.com/DCAN-Labs/nhp-abcd-bids-pipeline/blob/master/dcan-macaque-pipeline_v0_1_0_stages_summary.pdf
#wb command vol to surface mapping https://www.humanconnectome.org/software/workbench-command/-volume-to-surface-mapping
# combing left right metric.func.nii files into a dense scalar https://www.humanconnectome.org/software/workbench-command/-cifti-create-dense-scalar

## Overview 1) split vol into left and right hem, 2) map left and right hemp to metric.func.gii files 3) combine metric files into dense scalar file.
## Bene notes on game plan
#Step 1) test how label export and import works. Look at /Users/bene.ramirez/projects/ROI_sets/RheMAP/CHARM-SARM_converted2YRK/vol2surf/surfmaps/Markov_with_SARM_1_in_YRK_sym_05mm_label.10k.dscalar.nii
#then, create sarm ROI labels for left and right hemisphere. 
## done with notes

scripts_path=/Users/bene.ramirez/projects/ROI_sets/RheMAP/CHARM-SARM_converted2YRK/scripts
base_dir=/Users/bene.ramirez/projects/ROI_sets/make_dlabel/
scripts_path=${base_dir}/scripts
inpath=${base_dir}/volume2convert
workpath=${base_dir}/make_dlabel
outpath=${base_dir}/final_dlabel
cAtlas=CHARM
sAtlas=SARM
subcortical_name_file=${inpath}/${sAtlas}_level-${level}_names_abrv.txt
subcortical_intensity_file=${inpath}/${sAtlas}_level-${level}_intensities.txt
cortical_name_file=${inpath}/${cAtlas}_level-${level}_names_abrv.txt
cortical_intensity_file=${inpath}/${cAtlas}_level-${level}_intensities.txt

for i in $(seq 1 6); do
    level=${i}
    #level=1

    
    python3 ${scripts_path}/modify_lables_to_left_and_right.py ${inpath}/${sAtlas}_level-${level}_names_abrv.txt --output_dir ${outpath}
    python3 ${scripts_path}/modify_lables_to_left_and_right.py ${inpath}/${cAtlas}_level-${level}_names_abrv.txt --output_dir ${outpath}

    #add to subcortical intensities 
    cp ${inpath}/${sAtlas}_level-${level}_intensities.txt ${outpath}/${sAtlas}_level-${level}_intensities_LeftHem.txt
    cp ${inpath}/${sAtlas}_level-${level}_intensities.txt ${outpath}/${sAtlas}_level-${level}_intensities_RightHem.txt
    python3 ${scripts_path}/modify_intensities.py ${outpath}/${sAtlas}_level-${level}_intensities_LeftHem.txt 1000 --output_dir ${outpath}
    python3 ${scripts_path}/modify_intensities.py ${outpath}/${sAtlas}_level-${level}_intensities_RightHem.txt 2000 --output_dir ${outpath}
    #add to cortical intensities 
    cp ${inpath}/${cAtlas}_level-${level}_intensities.txt ${outpath}/${cAtlas}_level-${level}_intensities_LeftHem.txt
    cp ${inpath}/${cAtlas}_level-${level}_intensities.txt ${outpath}/${cAtlas}_level-${level}_intensities_RightHem.txt
    python3 ${scripts_path}/modify_intensities.py ${outpath}/${cAtlas}_level-${level}_intensities_LeftHem.txt 3000 --output_dir ${outpath}
    python3 ${scripts_path}/modify_intensities.py ${outpath}/${cAtlas}_level-${level}_intensities_RightHem.txt 4000 --output_dir ${outpath}
    #subcortical label 
    python3 ${scripts_path}/convert_name_intensities_to_label.py ${outpath}/${sAtlas}_level-${level}_names_abrv_LeftHem.txt ${outpath}/${sAtlas}_level-${level}_intensities_LeftHem_modified.txt ${outpath}/${sAtlas}_level-${level}_label_LeftHem.txt
    cat "${outpath}/${sAtlas}_level-${level}_label_LeftHem.txt" > "${outpath}/${sAtlas}-${cAtlas}_level-${level}_label.txt"
    
    python3 ${scripts_path}/convert_name_intensities_to_label.py ${outpath}/${sAtlas}_level-${level}_names_abrv_RightHem.txt ${outpath}/${sAtlas}_level-${level}_intensities_RightHem_modified.txt ${outpath}/${sAtlas}_level-${level}_label_RightHem.txt
    cat "${outpath}/${sAtlas}_level-${level}_label_RightHem.txt" >> "${outpath}/${sAtlas}-${cAtlas}_level-${level}_label.txt"
    
    #cortical label
    python3 ${scripts_path}/convert_name_intensities_to_label.py ${outpath}/${cAtlas}_level-${level}_names_abrv_LeftHem.txt ${outpath}/${cAtlas}_level-${level}_intensities_LeftHem_modified.txt ${outpath}/${cAtlas}_level-${level}_label_LeftHem.txt
    cat "${outpath}/${cAtlas}_level-${level}_label_LeftHem.txt" >> "${outpath}/${sAtlas}-${cAtlas}_level-${level}_label.txt"
   
    python3 ${scripts_path}/convert_name_intensities_to_label.py ${outpath}/${cAtlas}_level-${level}_names_abrv_RightHem.txt ${outpath}/${cAtlas}_level-${level}_intensities_RightHem_modified.txt ${outpath}/${cAtlas}_level-${level}_label_RightHem.txt
    cat "${outpath}/${cAtlas}_level-${level}_label_RightHem.txt" >> "${outpath}/${sAtlas}-${cAtlas}_level-${level}_label.txt"

    #mask and split into left and right hem
    fslmaths ${inpath}/${sAtlas}_${level}_in_YRK_sym_05mm.nii.gz -mas ${base_dir}/vol2surf/templates/MacaqueYerkes19_T1w_0.5mm_brain_mask.nii.gz ${outpath}/volume_masked.nii.gz
    3dcalc -a ${outpath}/volume_masked.nii.gz -expr 'step(x)' -prefix ${outpath}/mask_left.nii.gz
    #use mask to mask out right hem
    fslmaths ${outpath}/volume_masked.nii.gz -mas ${outpath}/mask_left.nii.gz ${outpath}/volume_masked.L.nii.gz
    #do same for right hem
    #create right hem mask
    3dcalc -a ${outpath}/volume_masked.nii.gz -expr 'step(-x)' -prefix ${outpath}/mask_right.nii.gz
    #use mask to mask out right hem
    fslmaths ${outpath}/volume_masked.nii.gz -mas ${outpath}/mask_right.nii.gz ${outpath}/volume_masked.R.nii.gz
    fslmaths ${outpath}/volume_masked.L.nii.gz -add 1000 -thr 1001 ${outpath}/sub_volume_masked.L.nii.gz
    fslmaths ${outpath}/volume_masked.R.nii.gz -add 2000 -thr 2001 ${outpath}/sub_volume_masked.R.nii.gz
    fslmaths ${outpath}/sub_volume_masked.L.nii.gz -add ${outpath}/sub_volume_masked.R.nii.gz ${outpath}/sub_volume_masked.nii.gz
    flirt -in ${outpath}/sub_volume_masked.nii.gz -ref ${outpath}/sub_volume_masked.nii.gz -applyisoxfm 1.25 -out ${outpath}/sub_volume_masked.1.25.nii.gz -interp nearestneighbour 
    wb_command -volume-label-import ${outpath}/sub_volume_masked.L.nii.gz ${outpath}/${sAtlas}_level-${level}_label_LeftHem.txt ${outpath}/sub_volume_masked.L.nii.gz
    wb_command -volume-label-import ${outpath}/sub_volume_masked.R.nii.gz ${outpath}/${sAtlas}_level-${level}_label_RightHem.txt ${outpath}/sub_volume_masked.R.nii.gz
    wb_command -volume-label-import ${outpath}/sub_volume_masked.1.25.nii.gz ${outpath}/${sAtlas}-${cAtlas}_level-${level}_label.txt ${outpath}/sub_volume_masked.1.25.nii.gz

    rm ${outpath}/mask_right.nii.gz
    rm ${outpath}/mask_left.nii.gz
    rm ${outpath}/volume_masked.*nii.gz
    fslmaths ${inpath}/${cAtlas}_${level}_in_YRK_sym_05mm.nii.gz -mas ${base_dir}/vol2surf/templates/MacaqueYerkes19_T1w_0.5mm_brain_mask.nii.gz ${outpath}/volume_masked.nii.gz
    3dcalc -a ${outpath}/volume_masked.nii.gz -expr 'step(x)' -prefix ${outpath}/mask_left.nii.gz
    #use mask to mask out right hem
    fslmaths ${outpath}/volume_masked.nii.gz -mas ${outpath}/mask_left.nii.gz ${outpath}/volume_masked.L.nii.gz
    #do same for right hem
    #create right hem mask
    3dcalc -a ${outpath}/volume_masked.nii.gz -expr 'step(-x)' -prefix ${outpath}/mask_right.nii.gz
    #use mask to mask out right hem
    fslmaths ${outpath}/volume_masked.nii.gz -mas ${outpath}/mask_right.nii.gz ${outpath}/volume_masked.R.nii.gz
    fslmaths ${outpath}/volume_masked.L.nii.gz -add 3000 -thr 3001 ${outpath}/cort_volume_masked.L.nii.gz
    fslmaths ${outpath}/volume_masked.R.nii.gz -add 4000 -thr 4001 ${outpath}/cort_volume_masked.R.nii.gz
    wb_command -volume-label-import ${outpath}/cort_volume_masked.L.nii.gz ${outpath}/${cAtlas}_level-${level}_label_LeftHem.txt ${outpath}/cort_volume_masked.L.nii.gz
    wb_command -volume-label-import ${outpath}/cort_volume_masked.R.nii.gz ${outpath}/${cAtlas}_level-${level}_label_RightHem.txt ${outpath}/cort_volume_masked.R.nii.gz
    #flirt -in ${outpath}/cort_volume_masked.L.nii.gz -ref ${outpath}/cort_volume_masked.L.nii.gz -applyisoxfm 1.25 -out ${outpath}/cort_volume_masked.L.nii.gz -interp nearestneighbour
    #flirt -in ${outpath}/cort_volume_masked.R.nii.gz -ref ${outpath}/cort_volume_masked.R.nii.gz -applyisoxfm 1.25 -out ${outpath}/cort_volume_masked.R.nii.gz -interp nearestneighbour
    rm ${outpath}/mask_right.nii.gz
    rm ${outpath}/mask_left.nii.gz
    rm ${outpath}/volume_masked.*nii.gz
    
    wb_command -volume-label-to-surface-mapping ${outpath}/cort_volume_masked.L.nii.gz ${base_dir}/vol2surf/templates/MacaqueYerkes19.L.midthickness.10k_fs_LR.surf.gii  ${outpath}/Left_hem.label.gii -ribbon-constrained ${base_dir}/vol2surf/templates/MacaqueYerkes19.L.white.10k_fs_LR.surf.gii ${base_dir}/vol2surf/templates/MacaqueYerkes19.L.pial.10k_fs_LR.surf.gii 
    # -volume-roi volume_masked.L.nii.gz #leaving sub cortical out for now until I figure it out.
    #Right Hem
    wb_command -volume-label-to-surface-mapping ${outpath}/cort_volume_masked.R.nii.gz ${base_dir}/vol2surf/templates/MacaqueYerkes19.R.midthickness.10k_fs_LR.surf.gii  ${outpath}/Right_hem.label.gii -ribbon-constrained ${base_dir}/vol2surf/templates/MacaqueYerkes19.R.white.10k_fs_LR.surf.gii ${base_dir}/vol2surf/templates/MacaqueYerkes19.R.pial.10k_fs_LR.surf.gii 
    
    wb_command -cifti-create-dense-scalar ${outpath}/${cAtlas}_${level}_in_YRK.10k_with_${sAtlas}_${level}.dscalar.nii -volume ${outpath}/sub_volume_masked.1.25.nii.gz ${base_dir}/vol2surf/templates/Atlas_ROIs.1.25.nii.gz -left-metric ${outpath}/Left_hem.label.gii -roi-left ${base_dir}/vol2surf/templates/MacaqueYerkes19.L.atlasroi.10k_fs_LR.shape.gii -right-metric ${outpath}/Right_hem.label.gii -roi-right ${base_dir}/vol2surf/templates/MacaqueYerkes19.R.atlasroi.10k_fs_LR.shape.gii

    #wb_command -cifti-label-import ${outpath}/${cAtlas}_${level}_in_YRK.10k_with_${sAtlas}_${level}.dscalar.nii ${outpath}/${sAtlas}-${cAtlas}_level-${level}_label.txt ${outpath}/${cAtlas}_${level}_in_YRK.10k_with_${sAtlas}_${level}.dlabel.nii
    #wb_command -metric-label-import ${outpath}/Right_hem.func.gii ${outpath}/${cAtlas}_level-${level}_label_RightHem.txt ${outpath}/Right_hem.label.gii
    wb_command -cifti-create-label ${outpath}/Left_hem.dlabel.nii -left-label ${outpath}/Left_hem.label.gii 
    wb_command -cifti-create-label ${outpath}/Right_hem.dlabel.nii -right-label ${outpath}/Right_hem.label.gii
    #wb_command -cifti-create-label ${outpath}/Subcortical.dlabel.nii -volume ${outpath}/sub_volume_masked.1.25.nii.gz

    #wb_command -cifti-create-label ${outpath}/${cAtlas}_${level}_in_YRK.10k_with_${sAtlas}_${level}.dlabel.nii -volume ${outpath}/sub_volume_masked.1.25.nii.gz -left-label ${outpath}/Left_hem.label.gii -right-label ${outpath}/Right_hem.label.gii
    wb_command -cifti-merge-dense COLUMN ${outpath}/${cAtlas}_${level}_in_YRK.10k.dlabel.nii -cifti ${outpath}/Left_hem.dlabel.nii -cifti ${outpath}/Right_hem.dlabel.nii
     
     wb_command -cifti-create-dense-scalar ${outpath}/${cAtlas}_${level}_in_YRK.10k_with_${sAtlas}_${level}.dscalar.nii -volume ${outpath}/sub_volume_masked.1.25.nii.gz ${base_dir}/vol2surf/templates/Atlas_ROIs.1.25.nii.gz -left-metric ${outpath}/Left_hem.label.gii -roi-left ${base_dir}/vol2surf/templates/MacaqueYerkes19.L.atlasroi.10k_fs_LR.shape.gii -right-metric ${outpath}/Right_hem.label.gii -roi-right ${base_dir}/vol2surf/templates/MacaqueYerkes19.R.atlasroi.10k_fs_LR.shape.gii
     wb_command -cifti-label-import ${outpath}/${cAtlas}_${level}_in_YRK.10k_with_${sAtlas}_${level}.dscalar.nii ${outpath}/${sAtlas}-${cAtlas}_level-${level}_label.txt ${outpath}/${cAtlas}_${level}_in_YRK.10k_with_${sAtlas}_${level}.dlabel.nii
    ## Add SARM to MARKOV
     wb_command -cifti-create-dense-scalar ${outpath}/MarkovCC12_M132_91.10k_with_${sAtlas}_${level}.dscalar.nii -volume ${outpath}/sub_volume_masked.1.25.nii.gz ${base_dir}/vol2surf/templates/Atlas_ROIs.1.25.nii.gz -left-metric ${base_dir}/vol2surf/templates/L.MarkovCC12_M132_91-area.10k_fs_LR.label.gii -roi-left ${base_dir}/vol2surf/templates/MacaqueYerkes19.L.atlasroi.10k_fs_LR.shape.gii -right-metric ${base_dir}/vol2surf/templates/L.MarkovCC12_M132_91-area.10k_fs_LR.label.gii -roi-right ${base_dir}/vol2surf/templates/MacaqueYerkes19.R.atlasroi.10k_fs_LR.shape.gii
     cat "${base_dir}/vol2surf/templates/MarkovCC12_M132_182-area.10k_fs_LR.txt" > "${outpath}/Markov_CC12_M132_182_${sAtlas}_level-${level}_label.txt"
     cat "${outpath}/${sAtlas}-${cAtlas}_level-${level}_label.txt" >> "${outpath}/Markov_CC12_M132_182_${sAtlas}_level-${level}_label.txt"

     wb_command -cifti-label-import ${outpath}/MarkovCC12_M132_91.10k_with_${sAtlas}_${level}.dscalar.nii ${outpath}/Markov_CC12_M132_182_${sAtlas}_level-${level}_label.txt ${outpath}/MarkovCC12_M132_91.10k_with_${sAtlas}_${level}.dlabel.nii


done


# #first I exported the labels of the giftis you sent me
# wb_command -label-export-table L.MarkovCC12_M132_91-area.10k_fs_LR.label.gii L.MarkovCC12_M132_91-area.10k_fs_LR.txt
# wb_command -label-export-table R.MarkovCC12_M132_91-area.10k_fs_LR.label.gii R.MarkovCC12_M132_91-area.10k_fs_LR.txt
# #then I added the L_ and R_ hemisphere label to each ROI, and saved them again.
# #then imported these back in
# wb_command -metric-label-import L.MarkovCC12_M132_91-area.10k_fs_LR.label.gii L.MarkovCC12_M132_91-area.10k_fs_LR.txt L.MarkovCC12_M132_91-area.10k_fs_LR.label.gii
# wb_command -file-information L.MarkovCC12_M132_91-area.10k_fs_LR.label.gii
# wb_command -metric-label-import R.MarkovCC12_M132_91-area.10k_fs_LR.label.gii R.MarkovCC12_M132_91-area.10k_fs_LR.txt R.MarkovCC12_M132_91-area.10k_fs_LR.label.gii
# #converted them to dlabels
# wb_command -cifti-create-label R.MarkovCC12_M132_91-area.10k_fs_LR.dlabel.nii -right-label R.MarkovCC12_M132_91-area.10k_fs_LR.label.gii
# wb_command -cifti-create-label L.MarkovCC12_M132_91-area.10k_fs_LR.dlabel.nii -left-label L.MarkovCC12_M132_91-area.10k_fs_LR.label.gii
# #merged the left and the right together
# wb_command -cifti-merge-dense COLUMN MarkovCC12_M132_182-area.10k_fs_LR.dlabel.nii -cifti L.MarkovCC12_M132_91-area.10k_fs_LR.dlabel.nii -cifti R.MarkovCC12_M132_91-area.10k_fs_LR.dlabel.nii
# #exported the table in case I need it
# wb_command -cifti-label-export-table MarkovCC12_M132_182-area.10k_fs_LR.dlabel.nii 1 MarkovCC12_M132_182-area.10k_fs_LR.txt
# #and then ran this code I made (in folder) to parcellate the files inputing my smoothed 10k dtseries (example in folder) the newly made dlabel and outputting them into a new folder.
# /Users/bene.ramirez/projects/anes/MAJOM/ciftis/parcellate_10k_files.sh /Users/bene.ramirez/projects/anes/MAJOM/ciftis/10k_smoothed/ Users/bene.ramirez/projects/anes/MAJOM/ciftis/jupyter_projects/PCA/monkey_pca_sharing/MarkovCC12_M132_182-area.10k_fs_LR.dlabel.nii /Users/bene.ramirez/projects/anes/MAJOM/ciftis/10k_Markov182
# ## since I ran into that error I tried removing the ROI from the label, and importing the updated label dropping the ROI, but that just game me a new ROI with the same error.
# wb_command -cifti-label-import MarkovCC12_M132_182-area.10k_fs_LR.dlabel.nii MarkovCC12_M132_182-area.10k_fs_LR_reduced.txt -discard-others MarkovCC12_M132_182-area.10k_fs_LR_reduced.dlabel.nii


# dscalar_file="${volmap:r}.10k.dscalar.nii"
# echo $dscalar_file
# wb_command -cifti-create-dense-scalar ${main_dir}/surfmaps/${dscalar_file} -left-metric Left_hem.func.gii -roi-left ${base_dir}/vol2surf/templates/MacaqueYerkes19.L.atlasroi.10k_fs_LR.shape.gii -right-metric Right_hem.func.gii -roi-right ${base_dir}/vol2surf/templates/MacaqueYerkes19.R.atlasroi.10k_fs_LR.shape.gii

# #so here (above) is where you could include the volume data, but I think it might need to be first masked using the ${base_dir}/vol2surf/templates/templates/Atlas_ROIs.1.25.nii.gz file, i.e. get the subcortical areas from your volume file out using this mask. But right now your volume file is in 0.5mm space and the Atlas_ROI is in 1.25 space, so I think you could either downsample the volume file or the Atlas_ROI file, and then I think you would include it in the above command something like this.

# #wb_command -cifti-create-dense-scalar ${main_dir}/surfmaps/${volmap::$((${#volmap} - 0 - 7))}.10k_withvol.dscalar.nii -volume <your masked volume> ${base_dir}/vol2surf/templates/Atlas_ROIs.1.25.nii.gz -left-metric Left_hem.func.gii -roi-left ${base_dir}/vol2surf/templates/MacaqueYerkes19.L.atlasroi.10k_fs_LR.shape.gii -right-metric Right_hem.func.gii -roi-right ${base_dir}/vol2surf/templates/MacaqueYerkes19.R.atlasroi.10k_fs_LR.shape.gii

# input_file="SARM_1_in_YRK_sym_05mm.nii.gz"
# input_resolution=0.5
# target_resolution=1.25
# output_file="SARM_1_in_YRK_sym_1.25mm.nii.gz"
# flirt -in ${input_file} -ref ${input_file} -applyisoxfm ${target_resolution} -out ${output_file} -interp nearestneighbour 


# dims=$(fslinfo ${input_file} | grep ^pixdim | awk '{print int($2*'$input_resolution'/'$target_resolution'), int($3*'$input_resolution'/'$target_resolution'), int($4*'$input_resolution'/'$target_resolution')}')
# output_file="SARM_1_in_YRK_sym_1.25mm.nii.gz"
# flirt -in ${input_file} -ref ${input_file} -applyisoxfm ${target_resolution} -out ${output_file} -interp nearestneighbour 
# -newdims ${dims}

# flirt -in SARM_1_in_YRK_sym_05mm.nii.gz -ref 
# flirt -in ${main_dir}/volmaps/${volmap} -ref ${base_dir}/vol2surf/templates/Atlas_ROIs.1.25.nii.gz -out ${main_dir}/volmaps/${converted_file} -applyxfm
# /Users/bene.ramirez/projects/ROI_sets/RheMAP/CHARM-SARM_converted2YRK/CHARM_5_in_YRK_sym_05mm.nii.gz
# /Users/bene.ramirez/projects/ROI_sets/RheMAP/CHARM-SARM_converted2YRK/CHARM_level-2_names_abrv.txt
# /Users/bene.ramirez/projects/ROI_sets/RheMAP/CHARM-SARM_converted2YRK/CHARM_level-1_intensities.txt
# for i in $(seq 1 6); do
#     level=${i}
#     Atlas=SARM
#     inpath=/Users/bene.ramirez/projects/ROI_sets/RheMAP/CHARM-SARM_converted2YRK/
#     wb_command -volume-label-import ${inpath}/${Atlas}_${level}_in_YRK_sym_05mm.nii.gz ${inpath}/${Atlas}_level-${level}_label_file.txt ${inpath}/${Atlas}_${level}_in_YRK_sym_05mm_label.nii.gz
# done


# level=1
# Atlas=CHARM
# ./convert_name_intensities_to_label.py ${Atlas}_level-${level}_names_abrv.txt ${Atlas}_level-${level}_intensities.txt ${Atlas}_level-${level}_label_file.txt


# level=1
# Atlas=SARM
# #change path to where your data is.
# main_dir=/Users/bene.ramirez/projects/ROI_sets/RheMAP/CHARM-SARM_converted2YRK/vol2surf/
# #change name to whatever file you are trying to map to surf
# # level=${i}
# #     Atlas=CHARM
# #     inpath=/Users/bene.ramirez/projects/ROI_sets/RheMAP/CHARM-SARM_converted2YRK/
# #     wb_command -volume-label-import ${inpath}/${Atlas}_${level}_in_YRK_sym_05mm.nii.gz ${inpath}/${Atlas}_level-${level}_label_file.txt ${inpath}/${Atlas}_${level}_in_YRK_sym_05mm_label.nii.gz
# level=1
# Sub_atlas=SARM
# Cort_atlas=CHARM
# ## Step 1, combine subcortical with cortical 
# fslmaths ${main_dir}/volmaps/${Sub_atlas}_${level}_in_YRK_sym_05mm_label.nii.gz -add ${main_dir}/volmaps/${Cort_atlas}_${level}_in_YRK_sym_05mm_label.nii.gz ${main_dir}/volmaps/${Cort_atlas}_${Sub_atlas}_${level}_in_YRK_sym_05mm_label.nii.gz
# volmap=/${Cort_atlas}_${Sub_atlas}_${level}_in_YRK_sym_05mm_label.nii.gz
# cd ${main_dir}

# #Step 1 mask and split volmap
# #not sure if you need to mask it based onthe template, but going to do it for now because I think I remember Ting saying something about it, but feel free to take this step out if you feel it is not needed, since it looks like it is already in the right space.
# fslmaths ${main_dir}/volmaps/${volmap} -mas ${base_dir}/vol2surf/templates/MacaqueYerkes19_T1w_0.5mm_brain_mask.nii.gz ${main_dir}/intermediate_files/volume_masked.nii.gz
# ## not sure if you need to delete intermediate files between each map you want to do, but if you run into errors that might be why, as it could have issues overwriting the files.


# ##Now split into left and right hemispheres
# #create left hem mask
# #somehow 3dcalc doesn't allow for variable names i.e. ${volmap::$((${#volmap} - 0 - 7))}_masked.nii.gz so need to go into dir and give temp name
# pushd ${main_dir}/intermediate_files/
# 3dcalc -a volume_masked.nii.gz -expr 'step(x)' -prefix mask_left.nii.gz
# #use mask to mask out right hem
# fslmaths volume_masked.nii.gz -mas mask_left.nii.gz volume_masked.L.nii.gz
# rm mask_left.nii.gz
# #do same for right hem
# #create right hem mask
# 3dcalc -a volume_masked.nii.gz -expr 'step(-x)' -prefix mask_right.nii.gz
# #use mask to mask out right hem
# fslmaths volume_masked.nii.gz -mas mask_right.nii.gz volume_masked.R.nii.gz
# rm mask_right.nii.gz


# # Step 2) Now that you have a left and right hem volume, it's time to register to surface space.
# #Left Hem
# wb_command -volume-to-surface-mapping volume_masked.L.nii.gz ${base_dir}/vol2surf/templates/MacaqueYerkes19.L.midthickness.10k_fs_LR.surf.gii  Left_hem.func.gii -ribbon-constrained ${base_dir}/vol2surf/templates/MacaqueYerkes19.L.white.10k_fs_LR.surf.gii ${base_dir}/vol2surf/templates/MacaqueYerkes19.L.pial.10k_fs_LR.surf.gii #-volume-roi volume_masked.L.nii.gz
# # -volume-roi volume_masked.L.nii.gz #leaving sub cortical out for now until I figure it out.
# #Right Hem
# wb_command -volume-to-surface-mapping volume_masked.R.nii.gz ${base_dir}/vol2surf/templates/MacaqueYerkes19.R.midthickness.10k_fs_LR.surf.gii  Right_hem.func.gii -ribbon-constrained ${base_dir}/vol2surf/templates/MacaqueYerkes19.R.white.10k_fs_LR.surf.gii ${base_dir}/vol2surf/templates/MacaqueYerkes19.R.pial.10k_fs_LR.surf.gii
# # -volume-roi volume_masked.L.nii.gz #leaving sub cortical out for now until I figure it out.
# #Step 3) once you have left and right hem using command from Here to combine
# #https://www.humanconnectome.org/software/workbench-command/-cifti-create-dense-scalar
# #or here in the pipeline using time series data  https://github.com/DCAN-Labs/dcan-macaque-pipeline/blob/master/fMRISurface/scripts/CreateDenseTimeseries.sh
# dscalar_file="${volmap:r}.10k.dscalar.nii"
# echo $dscalar_file
# wb_command -cifti-create-dense-scalar ${main_dir}/surfmaps/${dscalar_file} -left-metric Left_hem.func.gii -roi-left ${base_dir}/vol2surf/templates/MacaqueYerkes19.L.atlasroi.10k_fs_LR.shape.gii -right-metric Right_hem.func.gii -roi-right ${base_dir}/vol2surf/templates/MacaqueYerkes19.R.atlasroi.10k_fs_LR.shape.gii

# #so here (above) is where you could include the volume data, but I think it might need to be first masked using the ${base_dir}/vol2surf/templates/templates/Atlas_ROIs.1.25.nii.gz file, i.e. get the subcortical areas from your volume file out using this mask. But right now your volume file is in 0.5mm space and the Atlas_ROI is in 1.25 space, so I think you could either downsample the volume file or the Atlas_ROI file, and then I think you would include it in the above command something like this.

# #wb_command -cifti-create-dense-scalar ${main_dir}/surfmaps/${volmap::$((${#volmap} - 0 - 7))}.10k_withvol.dscalar.nii -volume <your masked volume> ${base_dir}/vol2surf/templates/Atlas_ROIs.1.25.nii.gz -left-metric Left_hem.func.gii -roi-left ${base_dir}/vol2surf/templates/MacaqueYerkes19.L.atlasroi.10k_fs_LR.shape.gii -right-metric Right_hem.func.gii -roi-right ${base_dir}/vol2surf/templates/MacaqueYerkes19.R.atlasroi.10k_fs_LR.shape.gii
