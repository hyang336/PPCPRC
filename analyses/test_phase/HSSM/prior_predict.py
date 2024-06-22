## run prior predictive checks on various HSSM models
import numpy as np
import pandas as pd
import hssm
import arviz as az
from matplotlib import pyplot as plt
import multiprocessing as mp
import os
import argparse

#parse arguments
parser = argparse.ArgumentParser(description='run prior predictive checks on various HSSM models')
parser.add_argument('--model', type=str, help='which HSSM model to use',default='ddm')
parser.add_argument('--outdir', type=str, help='outpu directory to save results',default='/scratch/hyang336/working_dir/HDDM_HSSM/prior_predict/')
parser.add_argument('--realdata', type=str, help='csv file containing real data',default='/scratch/hyang336/working_dir/HDDM_HSSM/HSSM_freq_bin_data.csv')
args = parser.parse_args()

modelname=args.model
outdir=args.outdir
readata=args.realdata

# make the output directory if it doesn't exist
if not os.path.exists(outdir):
    os.makedirs(outdir,exist_ok=True)
##############################################DDM model############################################################################################################

















###########################################Race 4 no bias model############################################################################################################