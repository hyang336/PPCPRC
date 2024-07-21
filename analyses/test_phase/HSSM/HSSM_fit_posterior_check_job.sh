#!/bin/bash
#SBATCH --time=2:00:00
#SBATCH --account=ctb-akhanf
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=128G
#SBATCH --job-name=HSSM_fit_posterior_check
#SBATCH --output=/home/hyang336/jobs/HSSM_fit_posterior_check%j.out

#set up environment
module load gcc cuda cudnn python/3.11
source ~/HSSM022_tempENV/bin/activate

PYTENSOR_FLAGS='blas__ldflags=-lflexiblas -lgfortran' python /home/hyang336/PPCPRC/analyses/test_phase/HSSM/HSSM_fit_posterior_check.py
