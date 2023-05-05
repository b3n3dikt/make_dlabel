## Relevant links
#DCAN pipeline vol to surface mapping https://github.com/DCAN-Labs/dcan-macaque-pipeline/blob/master/fMRISurface/scripts/RibbonVolumeToSurfaceMapping.sh
#DCAN pipeline overview https://github.com/DCAN-Labs/nhp-abcd-bids-pipeline/blob/master/dcan-macaque-pipeline_v0_1_0_stages_summary.pdf
#wb command vol to surface mapping https://www.humanconnectome.org/software/workbench-command/-volume-to-surface-mapping
# combing left right metric.func.nii files into a dense scalar https://www.humanconnectome.org/software/workbench-command/-cifti-create-dense-scalar

## Overview 1) split vol into left and right hem, 2) map left and right hemp to metric.func.gii files 3) combine metric files into dense scalar file.
## Bene notes on game plan
#Step 1) test how label export and import works. Look at /Users/bene.ramirez/projects/ROI_sets/RheMAP/CHARM-SARM_converted2YRK/vol2surf/surfmaps/Markov_with_SARM_1_in_YRK_sym_05mm_label.${mesh}k.dscalar.nii
#then, create sarm ROI labels for left and right hemisphere. 
## done with notes

#scripts_path=/Users/bene.ramirez/projects/ROI_sets/RheMAP/CHARM-SARM_converted2YRK/scripts
base_dir=/Users/bene.ramirez/projects/ROI_sets/make_dlabel/
scripts_path=${base_dir}/scripts

cAtlas=CHARM
sAtlas=SARM
subcortical_base_intensity_L=1000
subcortical_base_intensity_R=2000
cortical_base_intensity_L=3000
cortical_base_intensity_R=4000
mesh=10
use_template_mask=1
if [ "$use_template_mask" -eq 1 ]; then
  outpath=${base_dir}/dlabel_${mesh}k_masked
else
  outpath=${base_dir}/dlabel_${mesh}k
fi
#outpath=${base_dir}/dlabel_${mesh}k
mkdir -p ${outpath}
#mesh=32


for i in $(seq 1 6); do
    level=${i}
    #level=1

    
    python3 ${scripts_path}/modify_lables_to_left_and_right.py ${base_dir}/${sAtlas}_level-${level}_names_abrv.txt --output_dir ${outpath}
    python3 ${scripts_path}/modify_lables_to_left_and_right.py ${base_dir}/${cAtlas}_level-${level}_names_abrv.txt --output_dir ${outpath}

    #add to subcortical intensities 
    cp ${base_dir}/${sAtlas}_level-${level}_intensities.txt ${outpath}/${sAtlas}_level-${level}_intensities_LeftHem.txt
    cp ${base_dir}/${sAtlas}_level-${level}_intensities.txt ${outpath}/${sAtlas}_level-${level}_intensities_RightHem.txt
    python3 ${scripts_path}/modify_intensities.py ${outpath}/${sAtlas}_level-${level}_intensities_LeftHem.txt ${subcortical_base_intensity_L} --output_dir ${outpath}
    python3 ${scripts_path}/modify_intensities.py ${outpath}/${sAtlas}_level-${level}_intensities_RightHem.txt ${subcortical_base_intensity_R} --output_dir ${outpath}
    #add to cortical intensities 
    cp ${base_dir}/${cAtlas}_level-${level}_intensities.txt ${outpath}/${cAtlas}_level-${level}_intensities_LeftHem.txt
    cp ${base_dir}/${cAtlas}_level-${level}_intensities.txt ${outpath}/${cAtlas}_level-${level}_intensities_RightHem.txt
    python3 ${scripts_path}/modify_intensities.py ${outpath}/${cAtlas}_level-${level}_intensities_LeftHem.txt ${cortical_base_intensity_L} --output_dir ${outpath}
    python3 ${scripts_path}/modify_intensities.py ${outpath}/${cAtlas}_level-${level}_intensities_RightHem.txt ${cortical_base_intensity_R} --output_dir ${outpath}
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
    if [ "$use_template_mask" -eq 1 ]; then
        fslmaths ${base_dir}/${sAtlas}_${level}_in_YRK_sym_05mm.nii.gz -mas ${base_dir}/templates/${mesh}k_fs_LR/MacaqueYerkes19_T1w_0.5mm_brain_mask.nii.gz ${outpath}/volume_masked.nii.gz
    else
        cp ${base_dir}/${sAtlas}_${level}_in_YRK_sym_05mm.nii.gz ${outpath}/volume_masked.nii.gz
    fi
    3dcalc -a ${outpath}/volume_masked.nii.gz -expr 'step(x)' -prefix ${outpath}/mask_left.nii.gz
    #use mask to mask out right hem
    fslmaths ${outpath}/volume_masked.nii.gz -mas ${outpath}/mask_left.nii.gz ${outpath}/volume_masked.L.nii.gz
    #do same for right hem
    #create right hem mask
    3dcalc -a ${outpath}/volume_masked.nii.gz -expr 'step(-x)' -prefix ${outpath}/mask_right.nii.gz
    #use mask to mask out right hem
    fslmaths ${outpath}/volume_masked.nii.gz -mas ${outpath}/mask_right.nii.gz ${outpath}/volume_masked.R.nii.gz
    fslmaths ${outpath}/volume_masked.L.nii.gz -add ${subcortical_base_intensity_L} -thr $((subcortical_base_intensity_L + 1)) ${outpath}/sub_volume_masked.L.nii.gz
    fslmaths ${outpath}/volume_masked.R.nii.gz -add ${subcortical_base_intensity_R} -thr $((subcortical_base_intensity_R + 1)) ${outpath}/sub_volume_masked.R.nii.gz
    fslmaths ${outpath}/sub_volume_masked.L.nii.gz -add ${outpath}/sub_volume_masked.R.nii.gz ${outpath}/sub_volume_masked.nii.gz
    flirt -in ${outpath}/sub_volume_masked.nii.gz -ref ${outpath}/sub_volume_masked.nii.gz -applyisoxfm 1.25 -out ${outpath}/sub_volume_masked.1.25.nii.gz -interp nearestneighbour 
    wb_command -volume-label-import ${outpath}/sub_volume_masked.L.nii.gz ${outpath}/${sAtlas}_level-${level}_label_LeftHem.txt ${outpath}/sub_volume_masked.L.nii.gz
    wb_command -volume-label-import ${outpath}/sub_volume_masked.R.nii.gz ${outpath}/${sAtlas}_level-${level}_label_RightHem.txt ${outpath}/sub_volume_masked.R.nii.gz
    wb_command -volume-label-import ${outpath}/sub_volume_masked.1.25.nii.gz ${outpath}/${sAtlas}-${cAtlas}_level-${level}_label.txt ${outpath}/sub_volume_masked.1.25.nii.gz

    rm ${outpath}/mask_right.nii.gz
    rm ${outpath}/mask_left.nii.gz
    rm ${outpath}/volume_masked.*nii.gz
    fslmaths ${base_dir}/${cAtlas}_${level}_in_YRK_sym_05mm.nii.gz -mas ${base_dir}/templates/${mesh}k_fs_LR/MacaqueYerkes19_T1w_0.5mm_brain_mask.nii.gz ${outpath}/volume_masked.nii.gz
    3dcalc -a ${outpath}/volume_masked.nii.gz -expr 'step(x)' -prefix ${outpath}/mask_left.nii.gz
    #use mask to mask out right hem
    fslmaths ${outpath}/volume_masked.nii.gz -mas ${outpath}/mask_left.nii.gz ${outpath}/volume_masked.L.nii.gz
    #do same for right hem
    #create right hem mask
    3dcalc -a ${outpath}/volume_masked.nii.gz -expr 'step(-x)' -prefix ${outpath}/mask_right.nii.gz
    #use mask to mask out right hem
    fslmaths ${outpath}/volume_masked.nii.gz -mas ${outpath}/mask_right.nii.gz ${outpath}/volume_masked.R.nii.gz
    fslmaths ${outpath}/volume_masked.L.nii.gz -add ${cortical_base_intensity_L} -thr $((cortical_base_intensity_L + 1)) ${outpath}/cort_volume_masked.L.nii.gz
    fslmaths ${outpath}/volume_masked.R.nii.gz -add ${cortical_base_intensity_R} -thr $((cortical_base_intensity_R + 1)) ${outpath}/cort_volume_masked.R.nii.gz
    wb_command -volume-label-import ${outpath}/cort_volume_masked.L.nii.gz ${outpath}/${cAtlas}_level-${level}_label_LeftHem.txt ${outpath}/cort_volume_masked.L.nii.gz
    wb_command -volume-label-import ${outpath}/cort_volume_masked.R.nii.gz ${outpath}/${cAtlas}_level-${level}_label_RightHem.txt ${outpath}/cort_volume_masked.R.nii.gz
    #flirt -in ${outpath}/cort_volume_masked.L.nii.gz -ref ${outpath}/cort_volume_masked.L.nii.gz -applyisoxfm 1.25 -out ${outpath}/cort_volume_masked.L.nii.gz -interp nearestneighbour
    #flirt -in ${outpath}/cort_volume_masked.R.nii.gz -ref ${outpath}/cort_volume_masked.R.nii.gz -applyisoxfm 1.25 -out ${outpath}/cort_volume_masked.R.nii.gz -interp nearestneighbour
    rm ${outpath}/mask_right.nii.gz
    rm ${outpath}/mask_left.nii.gz
    rm ${outpath}/volume_masked.*nii.gz
    
    wb_command -volume-label-to-surface-mapping ${outpath}/cort_volume_masked.L.nii.gz ${base_dir}/templates/${mesh}k_fs_LR/MacaqueYerkes19.L.midthickness.${mesh}k_fs_LR.surf.gii  ${outpath}/Left_hem.label.gii -ribbon-constrained ${base_dir}/templates/${mesh}k_fs_LR/MacaqueYerkes19.L.white.${mesh}k_fs_LR.surf.gii ${base_dir}/templates/${mesh}k_fs_LR/MacaqueYerkes19.L.pial.${mesh}k_fs_LR.surf.gii 
    # -volume-roi volume_masked.L.nii.gz #leaving sub cortical out for now until I figure it out.
    #Right Hem
    wb_command -volume-label-to-surface-mapping ${outpath}/cort_volume_masked.R.nii.gz ${base_dir}/templates/${mesh}k_fs_LR/MacaqueYerkes19.R.midthickness.${mesh}k_fs_LR.surf.gii  ${outpath}/Right_hem.label.gii -ribbon-constrained ${base_dir}/templates/${mesh}k_fs_LR/MacaqueYerkes19.R.white.${mesh}k_fs_LR.surf.gii ${base_dir}/templates/${mesh}k_fs_LR/MacaqueYerkes19.R.pial.${mesh}k_fs_LR.surf.gii 
    
    wb_command -cifti-create-dense-scalar ${outpath}/${cAtlas}_${level}_in_YRK.${mesh}k_with_${sAtlas}_${level}.dscalar.nii -volume ${outpath}/sub_volume_masked.1.25.nii.gz ${base_dir}/templates/${mesh}k_fs_LR/Atlas_ROIs.1.25.nii.gz -left-metric ${outpath}/Left_hem.label.gii -roi-left ${base_dir}/templates/${mesh}k_fs_LR/MacaqueYerkes19.L.atlasroi.${mesh}k_fs_LR.shape.gii -right-metric ${outpath}/Right_hem.label.gii -roi-right ${base_dir}/templates/${mesh}k_fs_LR/MacaqueYerkes19.R.atlasroi.${mesh}k_fs_LR.shape.gii

    #wb_command -cifti-label-import ${outpath}/${cAtlas}_${level}_in_YRK.${mesh}k_with_${sAtlas}_${level}.dscalar.nii ${outpath}/${sAtlas}-${cAtlas}_level-${level}_label.txt ${outpath}/${cAtlas}_${level}_in_YRK.${mesh}k_with_${sAtlas}_${level}.dlabel.nii
    #wb_command -metric-label-import ${outpath}/Right_hem.func.gii ${outpath}/${cAtlas}_level-${level}_label_RightHem.txt ${outpath}/Right_hem.label.gii
    wb_command -cifti-create-label ${outpath}/Left_hem.dlabel.nii -left-label ${outpath}/Left_hem.label.gii 
    wb_command -cifti-create-label ${outpath}/Right_hem.dlabel.nii -right-label ${outpath}/Right_hem.label.gii
    #wb_command -cifti-create-label ${outpath}/Subcortical.dlabel.nii -volume ${outpath}/sub_volume_masked.1.25.nii.gz

    #wb_command -cifti-create-label ${outpath}/${cAtlas}_${level}_in_YRK.${mesh}k_with_${sAtlas}_${level}.dlabel.nii -volume ${outpath}/sub_volume_masked.1.25.nii.gz -left-label ${outpath}/Left_hem.label.gii -right-label ${outpath}/Right_hem.label.gii
    wb_command -cifti-merge-dense COLUMN ${outpath}/${cAtlas}_${level}_in_YRK.${mesh}k.dlabel.nii -cifti ${outpath}/Left_hem.dlabel.nii -cifti ${outpath}/Right_hem.dlabel.nii
     
     wb_command -cifti-create-dense-scalar ${outpath}/${cAtlas}_${level}_in_YRK.${mesh}k_with_${sAtlas}_${level}.dscalar.nii -volume ${outpath}/sub_volume_masked.1.25.nii.gz ${base_dir}/templates/${mesh}k_fs_LR/Atlas_ROIs.1.25.nii.gz -left-metric ${outpath}/Left_hem.label.gii -roi-left ${base_dir}/templates/${mesh}k_fs_LR/MacaqueYerkes19.L.atlasroi.${mesh}k_fs_LR.shape.gii -right-metric ${outpath}/Right_hem.label.gii -roi-right ${base_dir}/templates/${mesh}k_fs_LR/MacaqueYerkes19.R.atlasroi.${mesh}k_fs_LR.shape.gii
     wb_command -cifti-label-import ${outpath}/${cAtlas}_${level}_in_YRK.${mesh}k_with_${sAtlas}_${level}.dscalar.nii ${outpath}/${sAtlas}-${cAtlas}_level-${level}_label.txt ${outpath}/${cAtlas}_${level}_in_YRK.${mesh}k_with_${sAtlas}_${level}.dlabel.nii
    ## Add SARM to MARKOV
     wb_command -cifti-create-dense-scalar ${outpath}/MarkovCC12_M132_91.${mesh}k_with_${sAtlas}_${level}.dscalar.nii -volume ${outpath}/sub_volume_masked.1.25.nii.gz ${base_dir}/templates/${mesh}k_fs_LR/Atlas_ROIs.1.25.nii.gz -left-metric ${base_dir}/templates/${mesh}k_fs_LR/L.MarkovCC12_M132_91-area.${mesh}k_fs_LR.label.gii -roi-left ${base_dir}/templates/${mesh}k_fs_LR/MacaqueYerkes19.L.atlasroi.${mesh}k_fs_LR.shape.gii -right-metric ${base_dir}/templates/${mesh}k_fs_LR/L.MarkovCC12_M132_91-area.${mesh}k_fs_LR.label.gii -roi-right ${base_dir}/templates/${mesh}k_fs_LR/MacaqueYerkes19.R.atlasroi.${mesh}k_fs_LR.shape.gii
     cat "${base_dir}/templates/${mesh}k_fs_LR/MarkovCC12_M132_182-area.${mesh}k_fs_LR.txt" > "${outpath}/Markov_CC12_M132_182_${sAtlas}_level-${level}_label.txt"
     cat "${outpath}/${sAtlas}-${cAtlas}_level-${level}_label.txt" >> "${outpath}/Markov_CC12_M132_182_${sAtlas}_level-${level}_label.txt"

     wb_command -cifti-label-import ${outpath}/MarkovCC12_M132_91.${mesh}k_with_${sAtlas}_${level}.dscalar.nii ${outpath}/Markov_CC12_M132_182_${sAtlas}_level-${level}_label.txt ${outpath}/MarkovCC12_M132_91.${mesh}k_with_${sAtlas}_${level}.dlabel.nii


done
