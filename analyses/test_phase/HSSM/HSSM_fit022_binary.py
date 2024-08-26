import numpy as np
import pandas as pd
import hssm
import arviz as az
from matplotlib import pyplot as plt
import multiprocessing as mp
import os
import argparse

if __name__ == '__main__':
    mp.freeze_support()    
    mp.set_start_method('spawn', force=True)

    #parse arguments
    parser = argparse.ArgumentParser(description='fit HSSM model with real data')
    parser.add_argument('--samples', type=str, help='how many samples to draw from MCMC chains',default=10000)
    parser.add_argument('--burnin', type=str, help='how many samples to burn in from MCMC chains',default=10000)
    parser.add_argument('--cores', type=str, help='how many CPU/GPU cores to use for sampling',default=4)
    parser.add_argument('--binscheme', type=str, help='how responses were binned',default='median')
    parser.add_argument('--signal', type=str, help='which familiarity signal to model',default='recent')
    parser.add_argument('--regressor', type=str, help='which data as regressor',default='null')
    parser.add_argument('--model', type=str, help='which parameters to regress on',default='v')
    parser.add_argument('--centerParam', type=str, help='which parameters to use centered parameterization',default='null')
    parser.add_argument('--randParam', type=str, help='which parameters to include random effect',default='vazt')
    parser.add_argument('--outdir', type=str, help='output directory to save results',default='/scratch/hyang336/working_dir/HDDM_HSSM/resp_binarized/')
    parser.add_argument('--TA', type=str, help='target_accept for NUTS sampler',default=0.8)
    parser.add_argument('--run', type=str, help='whether to run the sampler or just plot data distribution and prior predict',default='sample')
    parser.add_argument('--loglik', type=str, help='whether to use approx_differentiable or analytical log-likelihood',default='approx_differentiable')
    args = parser.parse_args()

    samples=int(args.samples)
    burnin=int(args.burnin)
    ncores=int(args.cores)
    binscheme=args.binscheme
    signalname=args.signal
    regressor=args.regressor
    modelname=args.model #v, a, z, t #t cause convergence problem when it has random effect in HSSM 0.2.2
    centered_param=args.centerParam
    rand_param=args.randParam
    outdir=args.outdir
    TA=float(args.TA)
    run=args.run
    loglik=args.loglik

    if centered_param != 'null':
        overall_noncentered=False
        print('some parameters are centered, therefore turning off overall non-centered')
    else:
        overall_noncentered=True
        print('no parameter is centered, therefore turning on overall non-centered')

    # make the output directory if it doesn't exist
    if not os.path.exists(outdir):
        os.makedirs(outdir,exist_ok=True)

    # path to onnx file for apporx_differentiable loglik
    onnx_file = '/home/hyang336/PPCPRC/analyses/test_phase/HSSM/ddm.onnx'

################################################################# Helper functions ###################################################################
    def formula_builder(HSSM_param,centered=False,regres=False,random_effect=True):
        if centered:
            if random_effect:
                if regres:                    
                    formula = HSSM_param + " ~ 0 + (1 + x|subj_idx)"
                else:
                    formula = HSSM_param + " ~ 0 + (1|subj_idx)"
            else:
                # warning since without random effect the centered vs. noncentered doesn't make sense
                print('Warning: centered=True but random_effect=False, the centered version will have the same formula as the non-centered version')
                if regres:                    
                    formula = HSSM_param + " ~ 1 + x"
                else:
                    formula = HSSM_param + " ~ 1"
        else:
            if random_effect:
                if regres:
                    formula = HSSM_param + " ~ 1 + x + (1 + x|subj_idx)"
                else:
                    formula = HSSM_param + " ~ 1 + (1|subj_idx)"
            else:
                if regres:                    
                    formula = HSSM_param + " ~ 1 + x"
                else:
                    formula = HSSM_param + " ~ 1"
        return formula

    def prior_builder(HSSM_param,centered=False,regres=False,random_effect=True):
        prior={}
        if HSSM_param == 'v':
            inter_dist='Normal'
            inter_dist_param1_name='mu'
            inter_dist_param1_val=1
            inter_dist_param2_name='sigma'
            inter_dist_param2_val=2
            inter_initval=1
            rand_inter_sigma_val=1            
            rand_inter_sigma_initval=0.3            
        elif HSSM_param == 'a':
            inter_dist='Gamma'
            inter_dist_param1_name='mu'
            inter_dist_param1_val=1.5
            inter_dist_param2_name='sigma'
            inter_dist_param2_val=0.75
            inter_initval=1
            rand_inter_sigma_val=1
            rand_inter_sigma_initval=0.3
        elif HSSM_param == 't':
            inter_dist='Gamma'
            inter_dist_param1_name='mu'
            inter_dist_param1_val=0.4
            inter_dist_param2_name='sigma'
            inter_dist_param2_val=0.2
            inter_initval=0.3
            rand_inter_sigma_val=0.03
            rand_inter_sigma_initval=0.01
        elif HSSM_param == 'z':
            inter_dist='Beta'
            inter_dist_param1_name='alpha'
            inter_dist_param1_val=5
            inter_dist_param2_name='beta'
            inter_dist_param2_val=5
            inter_initval=.5
            rand_inter_sigma_val=0.05
            rand_inter_sigma_initval=0.01

        x_prior={'name': 'Normal', 'mu': 0, 'sigma': 1, 'initval': 0}
        rand_mu_dist='Normal'
        rand_mu_val_noncentered=0
        rand_sigma_dist='HalfNormal'
        rand_slope_sigma_val=0.5
        rand_slope_sigma_initval=0.5

        prior={}
        inter_prior = { "name": inter_dist, inter_dist_param1_name: inter_dist_param1_val, inter_dist_param2_name: inter_dist_param2_val, "initval": inter_initval}
        x_prior={'name': 'Normal', 'mu': 0, 'sigma': 1, 'initval': 0}
        x_subj_prior_nc={'name': rand_mu_dist, 'mu': rand_mu_val_noncentered, 'sigma': {'name': rand_sigma_dist, 'sigma': rand_slope_sigma_val, 'initval': rand_slope_sigma_initval}}
        inter_subj_prior_nc={'name': rand_mu_dist, 'mu': rand_mu_val_noncentered, 'sigma': {'name': rand_sigma_dist, 'sigma': rand_inter_sigma_val, 'initval': rand_inter_sigma_initval}}
        x_subj_prior_c={'name':rand_mu_dist,"mu":x_prior,"sigma":{'name':rand_sigma_dist,'sigma':rand_slope_sigma_val,'initval':rand_slope_sigma_initval}}
        inter_subj_prior_c={'name':rand_mu_dist,"mu":inter_prior,"sigma":{'name':rand_sigma_dist,'sigma':rand_inter_sigma_val,'initval':rand_inter_sigma_initval}}

        ### combine parts into full priors ###
        if centered:
            if random_effect:
                if regres:
                    prior = {
                        "1|subj_idx": inter_subj_prior_c,
                        "x|subj_idx": x_subj_prior_c
                    }
                    
                else:
                    prior = {
                        "1|subj_idx": inter_subj_prior_c
                    }
            else:
                if regres:
                    prior = {
                        "Intercept": inter_prior,
                        "x": x_prior
                    }
                else:
                    prior = {
                        "Intercept": inter_prior
                    }
        else:
            if random_effect:
                if regres:
                    prior = {
                        "Intercept": inter_prior,
                        "x": x_prior,
                        "1|subj_idx": inter_subj_prior_nc,
                        "x|subj_idx": x_subj_prior_nc
                    }
                else:
                    prior = {
                        "Intercept": inter_prior,
                        "1|subj_idx": inter_subj_prior_nc
                    }
            else:
                if regres:
                    prior = {
                        "Intercept": inter_prior,
                        "x": x_prior
                    }
                else:
                    prior = {
                        "Intercept": inter_prior
                    }
                
        return prior
###################################################################    # load the data###################################################################
    if binscheme == 'median':
        if signalname == 'recent':
            # load the csv
            fam_data = pd.read_csv('/scratch/hyang336/working_dir/HDDM_HSSM/HSSM_freq_MedianBin_data.csv')
        elif signalname == 'lifetime':
            # load the csv
            fam_data = pd.read_csv('/scratch/hyang336/working_dir/HDDM_HSSM/HSSM_life_MedianBin_data.csv')
    elif binscheme == 'maxRT':
        if signalname == 'recent':
            # load the csv
            fam_data = pd.read_csv('/scratch/hyang336/working_dir/HDDM_HSSM/HSSM_freq_bin_data.csv')
        elif signalname == 'lifetime':
            # load the csv
            fam_data = pd.read_csv('/scratch/hyang336/working_dir/HDDM_HSSM/HSSM_life_bin_data.csv')
    else:
        raise ValueError('binscheme not recognized')
    
    # remove trials with < 0.2 sec RT
    fast_trial_num = len(fam_data[fam_data['rt'] <= 0.2])
    total_trial_num = len(fam_data)
    fam_data = fam_data[fam_data['rt'] > 0.2]
    # print out the proportion of trials removed
    print('Proportion of trials removed:', fast_trial_num/total_trial_num)
##################################################### Call functions to make formula and priors #########################################################################   
    formulas={}
    priors={}
    for par in ['v','a','z','t']:
        if centered_param != 'null':
            if par in centered_param:
                centered=True
            else:
                centered=False

        if par == modelname and regressor != 'null':
            regres=True
        else:
            regres=False

        if par in rand_param:
            random_effect=True
        else:
            random_effect=False

        formulas[par] = formula_builder(par,centered=centered,regres=regres,random_effect=random_effect)
        priors[par] = prior_builder(par,centered=centered,regres=regres,random_effect=random_effect)
#####################################################   # subset the dataframe ###################################################################    
    sim_data = fam_data[['subj_idx','rt','bin_rating','bin_scheme']]
    # rename the rating column to response
    sim_data = sim_data.rename(columns={'bin_rating':'response'})

    # plot RT distribution for each of the two response categories separately
    fig, ax = plt.subplots(1, 2, figsize=(10, 5))
    ax[0].hist(sim_data[sim_data['response'] == 1]['rt'], bins=100, color='blue', alpha=0.5, label='resp 1')
    ax[0].legend()
    ax[1].hist(sim_data[sim_data['response'] == -1]['rt'], bins=100, color='red', alpha=0.5, label='resp -1')
    ax[1].legend()

    plt.savefig(outdir+'RT_distribution_' + str(binscheme) + '-binarized.png')

########################################################################################################################################################
    
###################### Define model, null model is a special case since it doesn't have regressor###################################################################
    if regressor == 'null':        
        # format data to be fed into the model, NOTE that "rt" and "response" are reserved keywords
        data = pd.DataFrame({
            'rt':sim_data['rt'],
            'response':sim_data['response'],
            'subj_idx':sim_data['subj_idx']
        })
                      
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

    # define the model
    model = hssm.HSSM(
        noncentered=overall_noncentered,
        loglik=onnx_file,
        loglik_kind = loglik,
        data=data,
        prior_settings="safe",
        include=[
            {
                "name": "v",
                "formula": formulas['v'],
                "prior": priors['v'],
                "link": "identity",
            },
            {
                "name": "a",
                "formula": formulas['a'],
                "prior": priors['a'],
                "link": "identity",
            },
            {
                "name": "z",
                "formula": formulas['z'],
                "prior": priors['z'],
                "link": "identity",
            },
            {
                "name": "t",
                "formula": formulas['t'],
                "prior": priors['t'],
                "link": "identity",
            }

        ],

    )  
            
########################################################################################################################################################

    if run == 'sample':
        #sample from the model and save the results
        infer_data_race4nba_v = model.sample(sampler="nuts_numpyro", chains=4, cores=ncores, draws=samples, tune=burnin, idata_kwargs = {'log_likelihood': True}, target_accept=TA)
        #save trace
        az.to_netcdf(infer_data_race4nba_v,outdir +'sample-' + str(burnin) + '-' + str(samples) + '_TA-' + str(TA) + '_binarized-' +str(binscheme) +  '_CenterParams-' + str(centered_param) + '_RandParams-'+ str(rand_param) + '_' + signalname + '_' + modelname + '_on-' + regressor + '.nc4')
        #save trace plot
        az.plot_trace(
            infer_data_race4nba_v,
            var_names="~log_likelihood",  # we exclude the log_likelihood traces here
        )
        plt.savefig(outdir+'posterior_diagnostic_' + str(burnin) + '-' + str(samples) + '_TA-' + str(TA) + '_binarized-' +str(binscheme) +  '_CenterParams-' + str(centered_param) + '_RandParams-'+ str(rand_param) + '_' + signalname + '_' + modelname + '_on-' + regressor + '.png')
        #save summary
        res_sum=az.summary(model.traces)
        res_sum.to_csv(outdir+'summary_' + str(burnin) + '-' + str(samples) + '_TA-' + str(TA) + '_binarized-' +str(binscheme) +  '_CenterParams-' + str(centered_param) + '_RandParams-'+ str(rand_param) + '_' + signalname + '_' + modelname + '_on-' + regressor + '.csv')
    else:
        #plot data distribution and prior predict
        print('not implemented yet')
        