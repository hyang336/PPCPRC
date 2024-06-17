from ssms.basic_simulators import simulator
import numpy as np
import pandas as pd
from scipy.special import softmax
from scipy.special import beta
import hssm
import bambi as bmb
import arviz as az
from matplotlib import pyplot as plt
import pymc as pm
import multiprocessing as mp
import os
import argparse

if __name__ == '__main__':
    mp.freeze_support()    
    mp.set_start_method('spawn', force=True)

    #parse arguments
    parser = argparse.ArgumentParser(description='fit HSSM model with real data')
    parser.add_argument('--samples', type=str, help='how many samples to draw from MCMC chains',default=5000)
    parser.add_argument('--burnin', type=str, help='how many samples to burn in from MCMC chains',default=5000)
    parser.add_argument('--cores', type=str, help='how many CPU/GPU cores to use for sampling',default=4)
    parser.add_argument('--signal', type=str, help='which familiarity signal to model',default='recent')
    parser.add_argument('--model', type=str, help='which model to run')
    parser.add_argument('--outdir', type=str, help='outpu directory to save results',default='/scratch/hyang336/working_dir/HDDM_HSSM/ROIs/')
    parser.add_argument('--bin', type=str, help='which two responses to bin together',default='12')
    parser.add_argument('--TA', type=str, help='target_accept for NUTS sampler',default=0.8)
    args = parser.parse_args()

    samples=int(args.samples)
    burnin=int(args.burnin)
    ncores=int(args.cores)
    signalname=args.signal
    modelname=args.model
    outdir=args.outdir
    bin_ver=args.bin
    TA=float(args.TA)

    # make the output directory if it doesn't exist
    if not os.path.exists(outdir):
        os.makedirs(outdir)
###################################################################    # load the data###################################################################
    if signalname == 'recent':
        # load the csv
        fam_data = pd.read_csv('/scratch/hyang336/working_dir/HDDM_HSSM/HSSM_freq_data.csv')
    elif signalname == 'lifetime':
        # load the csv
        fam_data = pd.read_csv('/scratch/hyang336/working_dir/HDDM_HSSM/HSSM_life_data.csv')
########################################################################################################################################################   

#####################################################   # subset the dataframe based on binning version###################################################################
    match bin_ver:
        case '12':
            # subset the dataframe by selecting relevant columns
            sim_data = fam_data[['subj_idx','rt','bin12_rating']]
            # rename the rating column to response
            sim_data = sim_data.rename(columns={'bin12_rating':'response'})
            
        case '23':
            # subset the dataframe by selecting relevant columns
            sim_data = fam_data[['subj_idx','rt','bin23_rating']]
            # rename the rating column to response
            sim_data = sim_data.rename(columns={'bin23_rating':'response'})

        case '34':
            # subset the dataframe by selecting relevant columns
            sim_data = fam_data[['subj_idx','rt','bin34_rating']]
            # rename the rating column to response
            sim_data = sim_data.rename(columns={'bin34_rating':'response'})

        case '45':
            # subset the dataframe by selecting relevant columns
            sim_data = fam_data[['subj_idx','rt','bin45_rating']]
            # rename the rating column to response
            sim_data = sim_data.rename(columns={'bin45_rating':'response'})
########################################################################################################################################################
    
################    ## Define model, null model is a special case since it doesn't have regressor###################################################################
    if modelname == 'null':
        # format data to be fed into the model, NOTE that "rt" and "response" are reserved keywords
        data = pd.DataFrame({
            'rt':sim_data['rt'],
            'response':sim_data['response'],
            'subj_idx':sim_data['subj_idx']
        })
        
        # define the model
        model= hssm.HSSM(
            data=data,
            model='race_no_bias_angle_4',
            a=2.0,
            z=0.0,
            include=[
                {
                    "name": "v0",
                    "prior":{"name": "Uniform", "lower": 0, "upper": 2.5},
                    "formula": "v0 ~ 1 + (1|subj_idx)",
                    "link": "log",
                },
                {
                    "name": "v1",
                    "prior":{"name": "Uniform", "lower": 0, "upper": 2.5},
                    "formula": "v1 ~ 1 + (1|subj_idx)",
                    "link": "log",
                },
                {
                    "name": "v2",
                    "prior":{"name": "Uniform", "lower": 0, "upper": 2.5},
                    "formula": "v2 ~ 1 + (1|subj_idx)",
                    "link": "log",
                },
                {
                    "name": "v3",
                    "prior":{"name": "Uniform", "lower": 0, "upper": 2.5},
                    "formula": "v3 ~ 1 + (1|subj_idx)",
                    "link": "log",
                }
            ],
        )
    else:
        match modelname: #select the regressor based on model name
            case 'rand':# control model with regression on randomly generated data
                # extract another column from the fam_data and add to the sim_data based on modelname
                sim_data['x'] = fam_data['random_z']
            case 'hippo_pos':
                # extract another column from the fam_data and add to the sim_data based on modelname
                sim_data['x'] = fam_data['hippo_z_pos']
            case 'hippo_neg':
                # extract another column from the fam_data and add to the sim_data based on modelname
                sim_data['x'] = fam_data['hippo_z_neg']
            case 'PrC_neg':
                # extract another column from the fam_data and add to the sim_data based on modelname
                sim_data['x'] = fam_data['PrC_z']
            case 'mPFC_pos':
                # extract another column from the fam_data and add to the sim_data based on modelname
                sim_data['x'] = fam_data['mPFC_z']
            case 'mPPC_pos':
                # extract another column from the fam_data and add to the sim_data based on modelname
                sim_data['x'] = fam_data['mPPC_z']
            case 'lAnG_pos':
                # this model is only defined for lifetime familiarity signal, throw an error if the wrong signal is passed
                if signalname != 'lifetime':
                    raise ValueError('This model is only defined for lifetime familiarity signal')
                # extract another column from the fam_data and add to the sim_data based on modelname
                sim_data['x'] = fam_data['lAnG_z']
            case 'lSFG_pos':
                # this model is only defined for lifetime familiarity signal, throw an error if the wrong signal is passed
                if signalname != 'lifetime':
                    raise ValueError('This model is only defined for lifetime familiarity signal')
                # extract another column from the fam_data and add to the sim_data based on modelname
                sim_data['x'] = fam_data['lSFG_z']

        # rescale the regressor to be between 0 and 1 since that is what teh beta distribution is defined on
        sim_data['x'] = (sim_data['x'] - np.min(sim_data['x']))/(np.max(sim_data['x']) - np.min(sim_data['x']))
        # add the other regressor
        sim_data['y'] = 1-sim_data['x']

        # format data to be fed into the model, NOTE that "rt" and "response" are reserved keywords
        data = pd.DataFrame({
            'rt':sim_data['rt'],
            'response':sim_data['response'],
            'x':sim_data['x'],
            'y':sim_data['y'],
            'subj_idx':sim_data['subj_idx']
        })

        # define the model
        model= hssm.HSSM(
            data=data,
            model='race_no_bias_angle_4',
            a=2.0,
            z=0.0,
            include=[
                {
                    "name": "v0",
                    "prior":{"name": "Uniform", "lower": 0, "upper": 2.5},
                    "formula": "v0 ~ 1 + x + y + (1|subj_idx)",
                    "link": "log",
                },
                {
                    "name": "v1",
                    "prior":{"name": "Uniform", "lower": 0, "upper": 2.5},
                    "formula": "v1 ~ 1 + x + y + (1|subj_idx)",
                    "link": "log",
                },
                {
                    "name": "v2",
                    "prior":{"name": "Uniform", "lower": 0, "upper": 2.5},
                    "formula": "v2 ~ 1 + x + y + (1|subj_idx)",
                    "link": "log",
                },
                {
                    "name": "v3",
                    "prior":{"name": "Uniform", "lower": 0, "upper": 2.5},
                    "formula": "v3 ~ 1 + x + y + (1|subj_idx)",
                    "link": "log",
                }
            ],
        )
########################################################################################################################################################

    #sample from the model and save the results
    infer_data_race4nba_v = model.sample(sampler="nuts_numpyro", chains=4, cores=ncores, draws=samples, tune=burnin, idata_kwargs = {'log_likelihood': True}, target_accept=TA)
    #save trace
    az.to_netcdf(infer_data_race4nba_v,outdir +'sample_5000_5000_trace_Fixed_az_' + signalname + '_' + modelname + '_bin' + bin_ver + '.nc4')
    #save trace plot
    az.plot_trace(
        infer_data_race4nba_v,
        var_names="~log_likelihood",  # we exclude the log_likelihood traces here
    )
    plt.savefig(outdir+'posterior_diagnostic_5000_5000_trace_Fixed_az_' + signalname + '_' + modelname + '_bin' + bin_ver + '.png')
    #save summary
    res_sum=az.summary(model.traces)
    res_sum.to_csv(outdir+'summary_5000_5000_trace_Fixed_az_' + signalname + '_' + modelname + '_bin' + bin_ver + '.csv')