#!/bin/bash
#SBATCH --time=24:00:00
#SBATCH --account=ctb-akhanf
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=3
#SBATCH --gres=gpu:v100:1
#SBATCH --mem=64G
#SBATCH --job-name=ddm_ParRec
#SBATCH --output=/home/hyang336/jobs/ddm_ParRec%j.out

#set up environment
module load gcc cuda cudnn python/3.11
source ~/HSSM022_tempENV/bin/activate

# whether to run the simple simulations (only v depends on regressor) or the full simulations
if [ $1 == "simple" ]; then
    PYTENSOR_FLAGS='blas__ldflags=-lflexiblas -lgfortran' python /home/hyang336/PPCPRC/analyses/test_phase/HSSM/Simulations_binary022_simple.py --model $2 --outdir '/scratch/hyang336/working_dir/HDDM_HSSM/simulations022/'
elif [ $1 == "frankmj" ]; then
    PYTENSOR_FLAGS='blas__ldflags=-lflexiblas -lgfortran' python /home/hyang336/PPCPRC/analyses/test_phase/HSSM/Simulations_binary022_frankmj.py --outdir '/scratch/hyang336/working_dir/HDDM_HSSM/simulations022/'
else
    PYTENSOR_FLAGS='blas__ldflags=-lflexiblas -lgfortran' python /home/hyang336/PPCPRC/analyses/test_phase/HSSM/Simulations_binary022.py --model $2 --tstrat $3
fi

