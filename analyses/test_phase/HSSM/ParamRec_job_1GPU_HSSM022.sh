#!/bin/bash
#SBATCH --time=48:00:00
#SBATCH --account=ctb-akhanf
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=3
#SBATCH --gres=gpu:v100:1
#SBATCH --mem=64G
#SBATCH --job-name=race4nb_ParRec
#SBATCH --output=/home/hyang336/jobs/race4nb_ParRec%j.out

#set up environment
module load gcc cuda cudnn python/3.11
source ~/HSSM022_tempENV/bin/activate

PYTENSOR_FLAGS='blas__ldflags=-lflexiblas -lgfortran' python /home/hyang336/PPCPRC/analyses/test_phase/HSSM/Simulations.py --model $1 --outdir '/scratch/hyang336/working_dir/HDDM_HSSM/simulations022/'
