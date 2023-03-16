#!/bin/bash
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32000
#SBATCH --time=24:00:00
#SBATCH --job-name=beta_plots
#SBATCH --account=ctb-akhanf
#SBATCH --output=/scratch/hyang336/working_dir/PPC_MD/jobs/beta_plots.%A.out

#Dumb script to compile data for beta plots (for PrC only)

#test task-relevant lifetime and recent
echo CMD: matlab -nosplash -nodisplay -r "addpath(genpath('/home/hyang336/matlab/')); addpath(genpath('/home/hyang336/PPCPRC/')); beta_plots('/scratch/hyang336/working_dir/PPC_MD/GLM_avgMask_4mmSmooth/test_1stlvl_softAROMA/','/home/hyang336/scratch/working_dir/PPC_MD/sub_list_libmotion.txt','/scratch/hyang336/working_dir/PPC_MD/masks/abovethreshold_PrC_masks/testphase_conjunction_both_dec/','lPrC75_SVC_global_null_abovethreshold_mask.nii','/scratch/hyang336/working_dir/PPC_MD/plots_abovethreshold/'); exit;"
echo START_TIME: `date`
cd /home/hyang336/scratch/working_dir/PPC_MD
matlab -nosplash -nodisplay -r "addpath(genpath('/home/hyang336/matlab/')); addpath(genpath('/home/hyang336/PPCPRC/')); beta_plots('/scratch/hyang336/working_dir/PPC_MD/GLM_avgMask_4mmSmooth/test_1stlvl_softAROMA/','/home/hyang336/scratch/working_dir/PPC_MD/sub_list_libmotion.txt','/scratch/hyang336/working_dir/PPC_MD/masks/abovethreshold_PrC_masks/testphase_conjunction_both_dec/','lPrC75_SVC_global_null_abovethreshold_mask.nii','/scratch/hyang336/working_dir/PPC_MD/plots_abovethreshold/'); exit;"

#test task-relevant recent
#echo CMD: matlab -nosplash -nodisplay -r "addpath(genpath('/home/hyang336/matlab/')); addpath(genpath('/home/hyang336/PPCPRC/')); beta_plots('/scratch/hyang336/working_dir/PPC_MD/GLM_avgMask_4mmSmooth/test_1stlvl_softAROMA/','/home/hyang336/scratch/working_dir/PPC_MD/sub_list_libmotion.txt','/scratch/hyang336/working_dir/PPC_MD/masks/abovethreshold_PrC_masks/testphase_conjunction_both_dec/','lPrC75_SVC_global_null_abovethreshold_mask.nii','/scratch/hyang336/working_dir/PPC_MD/plots_abovethreshold/'); exit;"
#echo START_TIME: `date`
#cd /home/hyang336/scratch/working_dir/PPC_MD
#matlab -nosplash -nodisplay -r "addpath(genpath('/home/hyang336/matlab/')); addpath(genpath('/home/hyang336/PPCPRC/')); beta_plots('/scratch/hyang336/working_dir/PPC_MD/GLM_avgMask_4mmSmooth/test_1stlvl_softAROMA/','/home/hyang336/scratch/working_dir/PPC_MD/sub_list_libmotion.txt','/scratch/hyang336/working_dir/PPC_MD/masks/abovethreshold_PrC_masks/testphase_conjunction_both_dec/','lPrC75_SVC_global_null_abovethreshold_mask.nii','/scratch/hyang336/working_dir/PPC_MD/plots_abovethreshold/'); exit;"

#test task-irrelevant lifetime
echo CMD: matlab -nosplash -nodisplay -r "addpath(genpath('/home/hyang336/matlab/')); addpath(genpath('/home/hyang336/PPCPRC/')); beta_plots('/scratch/hyang336/working_dir/PPC_MD/GLM_avgMask_pscan020022exclude/test_1stlvl_postscan_softAROMA_const-epoch/','/home/hyang336/scratch/working_dir/PPC_MD/sub_list_libmotion.txt','/scratch/hyang336/working_dir/PPC_MD/masks/abovethreshold_PrC_masks/testphase_life-irr_conjunction_both_dec/','lPrC75_SVC_global_null_abovethreshold_mask.nii','/scratch/hyang336/working_dir/PPC_MD/plots_abovethreshold/'); exit;"
echo START_TIME: `date`
cd /home/hyang336/scratch/working_dir/PPC_MD
matlab -nosplash -nodisplay -r "addpath(genpath('/home/hyang336/matlab/')); addpath(genpath('/home/hyang336/PPCPRC/')); beta_plots('/scratch/hyang336/working_dir/PPC_MD/GLM_avgMask_pscan020022exclude/test_1stlvl_postscan_softAROMA_const-epoch/','/home/hyang336/scratch/working_dir/PPC_MD/sub_list_libmotion.txt','/scratch/hyang336/working_dir/PPC_MD/masks/abovethreshold_PrC_masks/testphase_life-irr_conjunction_both_dec/','lPrC75_SVC_global_null_abovethreshold_mask.nii','/scratch/hyang336/working_dir/PPC_MD/plots_abovethreshold/'); exit;"

#study task-irrelevant recent
echo CMD: matlab -nosplash -nodisplay -r "addpath(genpath('/home/hyang336/matlab/')); addpath(genpath('/home/hyang336/PPCPRC/')); beta_plots('/scratch/hyang336/working_dir/PPC_MD/GLM_avgMask_4mmSmooth/repetition_suppression_softAROMA/','/home/hyang336/scratch/working_dir/PPC_MD/sub_list_libmotion.txt','/scratch/hyang336/working_dir/PPC_MD/masks/abovethreshold_PrC_masks/studyphase_pres1vs789_dec/','lPrC75_SVC_abovethreshold_mask.nii','/scratch/hyang336/working_dir/PPC_MD/plots_abovethreshold/'); exit;"
echo START_TIME: `date`
cd /home/hyang336/scratch/working_dir/PPC_MD
matlab -nosplash -nodisplay -r "addpath(genpath('/home/hyang336/matlab/')); addpath(genpath('/home/hyang336/PPCPRC/')); beta_plots('/scratch/hyang336/working_dir/PPC_MD/GLM_avgMask_4mmSmooth/repetition_suppression_softAROMA/','/home/hyang336/scratch/working_dir/PPC_MD/sub_list_libmotion.txt','/scratch/hyang336/working_dir/PPC_MD/masks/abovethreshold_PrC_masks/studyphase_pres1vs789_dec/','lPrC75_SVC_abovethreshold_mask.nii','/scratch/hyang336/working_dir/PPC_MD/plots_abovethreshold/'); exit;"

#study task-irrelevant lifetime all trial
echo CMD: matlab -nosplash -nodisplay -r "addpath(genpath('/home/hyang336/matlab/')); addpath(genpath('/home/hyang336/PPCPRC/')); beta_plots('/scratch/hyang336/working_dir/PPC_MD/GLM_avgMask_pscan020022exclude/postscan_lifetime_softAROMA_const-epoch/','/home/hyang336/scratch/working_dir/PPC_MD/sub_list_libmotion.txt','/scratch/hyang336/working_dir/PPC_MD/masks/abovethreshold_PrC_masks/studyphase_lifetime_alltrial/','lPrC75_SVC_abovethreshold_mask.nii','/scratch/hyang336/working_dir/PPC_MD/plots_abovethreshold/'); exit;"
echo START_TIME: `date`
cd /home/hyang336/scratch/working_dir/PPC_MD
matlab -nosplash -nodisplay -r "addpath(genpath('/home/hyang336/matlab/')); addpath(genpath('/home/hyang336/PPCPRC/')); beta_plots('/scratch/hyang336/working_dir/PPC_MD/GLM_avgMask_pscan020022exclude/postscan_lifetime_softAROMA_const-epoch/','/home/hyang336/scratch/working_dir/PPC_MD/sub_list_libmotion.txt','/scratch/hyang336/working_dir/PPC_MD/masks/abovethreshold_PrC_masks/studyphase_lifetime_alltrial/','lPrC75_SVC_abovethreshold_mask.nii','/scratch/hyang336/working_dir/PPC_MD/plots_abovethreshold/'); exit;"

#study task-irrelevant lifetime first pres
echo CMD: matlab -nosplash -nodisplay -r "addpath(genpath('/home/hyang336/matlab/')); addpath(genpath('/home/hyang336/PPCPRC/')); beta_plots_study_lifetime('/scratch/hyang336/working_dir/PPC_MD/GLM_avgMask_nosmooth/study_1stlvl_LSS-pres_softAROMA_const-epoch_pmod/','/home/hyang336/scratch/working_dir/PPC_MD/sub_list_libmotion.txt','/scratch/hyang336/working_dir/PPC_MD/masks/abovethreshold_PrC_masks/studyphase_lifetime_pres1/','lPrC75_SVC_abovethreshold_mask.nii','/scratch/hyang336/working_dir/PPC_MD/plots_abovethreshold/'); exit;"
echo START_TIME: `date`
cd /home/hyang336/scratch/working_dir/PPC_MD
matlab -nosplash -nodisplay -r "addpath(genpath('/home/hyang336/matlab/')); addpath(genpath('/home/hyang336/PPCPRC/')); beta_plots_study_lifetime('/scratch/hyang336/working_dir/PPC_MD/GLM_avgMask_nosmooth/study_1stlvl_LSS-pres_softAROMA_const-epoch_pmod/','/home/hyang336/scratch/working_dir/PPC_MD/sub_list_libmotion.txt','/scratch/hyang336/working_dir/PPC_MD/masks/abovethreshold_PrC_masks/studyphase_lifetime_pres1/','lPrC75_SVC_abovethreshold_mask.nii','/scratch/hyang336/working_dir/PPC_MD/plots_abovethreshold/'); exit;"


RETURNVAL=$?
echo RETURNVAL=$RETURNVAL
echo END_TIME: `date`
exit $RETURNVAL

#