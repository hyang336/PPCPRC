# posterior diagnostics and results for HSSM model
import numpy as np
import pandas as pd
import hssm
import arviz as az
from matplotlib import pyplot as plt
import os
import argparse

#parse arguments, NEED TO MATCH THE FITTING SCRIPT other than "--run"
parser = argparse.ArgumentParser(description='fit HSSM model with real data')
parser.add_argument('--samples', type=str, help='how many samples to draw from MCMC chains',default=10000)
parser.add_argument('--burnin', type=str, help='how many samples to burn in from MCMC chains',default=10000)
parser.add_argument('--cores', type=str, help='how many CPU/GPU cores to use for sampling',default=4)
parser.add_argument('--binscheme', type=str, help='how responses were binned',default='median')
parser.add_argument('--signal', type=str, help='which familiarity signal to model',default='recent')
parser.add_argument('--regressor', type=str, help='which data as regressor',default='null')
parser.add_argument('--model', type=str, help='which parameters to regress on',default='v')
parser.add_argument('--outdir', type=str, help='outpu directory to save results',default='/scratch/hyang336/working_dir/HDDM_HSSM/resp_binarized/')
parser.add_argument('--TA', type=str, help='target_accept for NUTS sampler',default=0.8)
parser.add_argument('--tstrat', type=str, help='how to handle issue on the t paramter',default='prior')

parser.add_argument('--run', type=str, help='whether to run the diagnostics or inference',default='diagnostics')

args = parser.parse_args()

samples=int(args.samples)
burnin=int(args.burnin)
ncores=int(args.cores)
binscheme=args.binscheme
signalname=args.signal
regressor=args.regressor
modelname=args.model #v, a, z, t #t cause convergence problem when it has random effect in HSSM 0.2.2
outdir=args.outdir
TA=float(args.TA)
tstrat=args.tstrat

run=args.run

netfile=outdir +'sample_' + str(burnin) + '_' + str(samples) + '_TA_' + str(TA) + '_trace_' + str(binscheme) + '-binarized_' + 't-strat_' + str(tstrat) + '_' + signalname + '_' + modelname + '_on_' + regressor + '.nc4'

#load the netcdf file
print(f'loading netcdf file: {netfile}')
for m in models:
    
inf_data=az.from_netcdf(netfile)

if run=='diagnostics':
    print('running diagnostics')
elif run=='inference':
    print('running inference')


