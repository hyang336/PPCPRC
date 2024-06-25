#!/bin/bash
#SBATCH --time=4:00:00
#SBATCH --account=ctb-akhanf
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=3
#SBATCH --gres=gpu:1
#SBATCH --mem=64G
#SBATCH --job-name=HSSM_binary_fit
#SBATCH --output=/home/hyang336/jobs/HSSM_binary_fit%j.out

#set up environment
module load gcc cuda cudnn python/3.11
source ~/HSSM022_tempENV/bin/activate

PYTENSOR_FLAGS='blas__ldflags=-lflexiblas -lgfortran' python /home/hyang336/PPCPRC/analyses/test_phase/HSSM/HSSM_fit022_binary.py --signal $1 --regressor $2 --model $3 --TA $4 --tstrat $5
