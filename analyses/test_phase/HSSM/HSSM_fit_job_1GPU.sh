#!/bin/bash
#SBATCH --time=48:00:00
#SBATCH --account=ctb-akhanf
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=3
#SBATCH --gres=gpu:v100:1
#SBATCH --mem=64G
#SBATCH --job-name=race4nb_fit
#SBATCH --output=/home/hyang336/jobs/race4nb_fit%j.out

#set up environment
module load gcc cuda cudnn python/3.11
virtualenv --no-download $SLURM_TMPDIR/ENV 
source $SLURM_TMPDIR/ENV/bin/activate
pip install --no-index --upgrade pip
pip install --no-index -r /home/hyang336/PPCPRC/analyses/test_phase/HSSM/hssm-0.2.1-reqs.txt

PYTENSOR_FLAGS='blas__ldflags=-lflexiblas -lgfortran' python /home/hyang336/PPCPRC/analyses/test_phase/HSSM/Simulations.py --signal $1 --model $2