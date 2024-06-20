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
    parser.add_argument('--regressor', type=str, help='which data as regressor',default=None)
    parser.add_argument('--model', type=str, help='which parameters to regress on',default='v')
    parser.add_argument('--outdir', type=str, help='outpu directory to save results',default='/scratch/hyang336/working_dir/HDDM_HSSM/resp_binarized/')
    parser.add_argument('--TA', type=str, help='target_accept for NUTS sampler',default=0.8)
    args = parser.parse_args()

    samples=int(args.samples)
    burnin=int(args.burnin)
    ncores=int(args.cores)
    signalname=args.signal
    regressor=args.regressor
    modelname=args.model #v, a, z, t, va, vz, vt, az, at, zt, vaz, vat, vzt, azt, vazt
    outdir=args.outdir
    TA=float(args.TA)

    # make the output directory if it doesn't exist
    if not os.path.exists(outdir):
        os.makedirs(outdir)
###################################################################    # load the data###################################################################
    if signalname == 'recent':
        # load the csv
        fam_data = pd.read_csv('/scratch/hyang336/working_dir/HDDM_HSSM/HSSM_freq_bin_data.csv')
    elif signalname == 'lifetime':
        # load the csv
        fam_data = pd.read_csv('/scratch/hyang336/working_dir/HDDM_HSSM/HSSM_life_bin_data.csv')
########################################################################################################################################################   

#####################################################   # subset the dataframe ###################################################################    
    sim_data = fam_data[['subj_idx','rt','bin_rating','bin_scheme']]
    # rename the rating column to response
    sim_data = sim_data.rename(columns={'bin_rating':'response'})
########################################################################################################################################################
    
################    ## Define model, null model is a special case since it doesn't have regressor###################################################################
    if regressor is None:
        # format data to be fed into the model, NOTE that "rt" and "response" are reserved keywords
        data = pd.DataFrame({
            'rt':sim_data['rt'],
            'response':sim_data['response'],
            'subj_idx':sim_data['subj_idx']
        })
        
        # define the model
        model= hssm.HSSM(
            data=data,
            model='ddm',
            prior_settings="safe",
            include=[
                {
                    "name": "v",
                    "formula": "v ~ 1 + (1|subj_idx)",
                    "link": "identity",
                },
                {
                    "name": "a",
                    "formula": "a ~ 1 + (1|subj_idx)",
                    "link": "identity",
                },
                {
                    "name": "z",
                    "formula": "z ~ 1 + (1|subj_idx)",
                    "link": "identity",
                },
                {
                    "name": "t",
                    "formula": "t ~ 1 + (1|subj_idx)",
                    "link": "identity",
                }
            ],
        )
    else:
        match regressor: #select the regressor based on model name
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


        # format data to be fed into the model, NOTE that "rt" and "response" are reserved keywords
        data = pd.DataFrame({
            'rt':sim_data['rt'],
            'response':sim_data['response'],
            'x':sim_data['x'],
            'subj_idx':sim_data['subj_idx']
        })

        match modelname:
            case 'v':
                # define model fomula
                v_fomula= "v ~ 1 + x + (1 + x|subj_idx)"
                a_fomula= "a ~ 1 + (1|subj_idx)"
                z_fomula= "z ~ 1 + (1|subj_idx)"
                t_fomula= "t ~ 1 + (1|subj_idx)"
            case 'a':
                # define model fomula
                v_fomula= "v ~ 1 + (1|subj_idx)"
                a_fomula= "a ~ 1 + x + (1 + x|subj_idx)"
                z_fomula= "z ~ 1 + (1|subj_idx)"
                t_fomula= "t ~ 1 + (1|subj_idx)"
            case 'z':
                # define model fomula
                v_fomula= "v ~ 1 + (1|subj_idx)"
                a_fomula= "a ~ 1 + (1|subj_idx)"
                z_fomula= "z ~ 1 + x + (1 + x|subj_idx)"
                t_fomula= "t ~ 1 + (1|subj_idx)"
            case 't':
                # define model fomula
                v_fomula= "v ~ 1 + (1|subj_idx)"
                a_fomula= "a ~ 1 + (1|subj_idx)"
                z_fomula= "z ~ 1 + (1|subj_idx)"
                t_fomula= "t ~ 1 + x + (1 + x|subj_idx)"
            case 'va':
                # define model fomula
                v_fomula= "v ~ 1 + x + (1 + x|subj_idx)"
                a_fomula= "a ~ 1 + x + (1 + x|subj_idx)"
                z_fomula= "z ~ 1 + (1|subj_idx)"
                t_fomula= "t ~ 1 + (1|subj_idx)"
            case 'vz':
                # define model fomula
                v_fomula= "v ~ 1 + x + (1 + x|subj_idx)"
                a_fomula= "a ~ 1 + (1|subj_idx)"
                z_fomula= "z ~ 1 + x + (1 + x|subj_idx)"
                t_fomula= "t ~ 1 + (1|subj_idx)"
            case 'vt':
                # define model fomula
                v_fomula= "v ~ 1 + x + (1 + x|subj_idx)"
                a_fomula= "a ~ 1 + (1|subj_idx)"
                z_fomula= "z ~ 1 + (1|subj_idx)"
                t_fomula= "t ~ 1 + x + (1 + x|subj_idx)"
            case 'az':
                # define model fomula
                v_fomula= "v ~ 1 + (1|subj_idx)"
                a_fomula= "a ~ 1 + x + (1 + x|subj_idx)"
                z_fomula= "z ~ 1 + x + (1 + x|subj_idx)"
                t_fomula= "t ~ 1 + (1|subj_idx)"
            case 'at':
                # define model fomula
                v_fomula= "v ~ 1 + (1|subj_idx)"
                a_fomula= "a ~ 1 + x + (1 + x|subj_idx)"
                z_fomula= "z ~ 1 + (1|subj_idx)"
                t_fomula= "t ~ 1 + x + (1 + x|subj_idx)"
            case 'zt':
                # define model fomula
                v_fomula= "v ~ 1 + (1|subj_idx)"
                a_fomula= "a ~ 1 + (1|subj_idx)"
                z_fomula= "z ~ 1 + x + (1 + x|subj_idx)"
                t_fomula= "t ~ 1 + x + (1 + x|subj_idx)"
            case 'vaz':
                # define model fomula
                v_fomula= "v ~ 1 + x + (1 + x|subj_idx)"
                a_fomula= "a ~ 1 + x + (1 + x|subj_idx)"
                z_fomula= "z ~ 1 + x + (1 + x|subj_idx)"
                t_fomula= "t ~ 1 + (1|subj_idx)"
            case 'vat':
                # define model fomula
                v_fomula= "v ~ 1 + x + (1 + x|subj_idx)"
                a_fomula= "a ~ 1 + x + (1 + x|subj_idx)"
                z_fomula= "z ~ 1 + (1|subj_idx)"
                t_fomula= "t ~ 1 + x + (1 + x|subj_idx)"
            case 'vzt':
                # define model fomula
                v_fomula= "v ~ 1 + x + (1 + x|subj_idx)"
                a_fomula= "a ~ 1 + (1|subj_idx)"
                z_fomula= "z ~ 1 + x + (1 + x|subj_idx)"
                t_fomula= "t ~ 1 + x + (1 + x|subj_idx)"
            case 'azt':
                # define model fomula
                v_fomula= "v ~ 1 + (1|subj_idx)"
                a_fomula= "a ~ 1 + x + (1 + x|subj_idx)"
                z_fomula= "z ~ 1 + x + (1 + x|subj_idx)"
                t_fomula= "t ~ 1 + x + (1 + x|subj_idx)"
            case 'vazt':
                # define model fomula
                v_fomula= "v ~ 1 + x + (1 + x|subj_idx)"
                a_fomula= "a ~ 1 + x + (1 + x|subj_idx)"
                z_fomula= "z ~ 1 + x + (1 + x|subj_idx)"
                t_fomula= "t ~ 1 + x + (1 + x|subj_idx)"

        # define the model
        model= hssm.HSSM(
            data=data,
            model='ddm',
            prior_settings="safe",
            include=[
                {
                    "name": "v",
                    "formula": v_fomula,
                    "link": "identity",
                },
                {
                    "name": "a",
                    "formula": a_fomula,
                    "link": "identity",
                },
                {
                    "name": "z",
                    "formula": z_fomula,
                    "link": "identity",
                },
                {
                    "name": "t",
                    "formula": t_fomula,
                    "link": "identity",
                }
            ],
        )   
            
########################################################################################################################################################

    #sample from the model and save the results
    infer_data_race4nba_v = model.sample(sampler="nuts_numpyro", chains=4, cores=ncores, draws=samples, tune=burnin, idata_kwargs = {'log_likelihood': True}, target_accept=TA)
    #save trace
    az.to_netcdf(infer_data_race4nba_v,outdir +'sample_' + str(burnin) + '_' + str(samples) + '_trace_binarized_' + signalname + '_' + modelname + '_on_' + regressor + '.nc4')
    #save trace plot
    az.plot_trace(
        infer_data_race4nba_v,
        var_names="~log_likelihood",  # we exclude the log_likelihood traces here
    )
    plt.savefig(outdir+'posterior_diagnostic_' + str(burnin) + '_' + str(samples) + '_trace_binarized_' + signalname + '_' + modelname + '_on_' + regressor + '.png')
    #save summary
    res_sum=az.summary(model.traces)
    res_sum.to_csv(outdir+'summary_' + str(burnin) + '_' + str(samples) + '_trace_binarized_' + signalname + '_' + modelname + '_on_' + regressor + '.csv')