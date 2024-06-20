#generate data using race_4 model, there are separate v and z for each accumulator, but a and t are shared
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
    parser = argparse.ArgumentParser(description='Simulate data and fit HSSM model')
    parser.add_argument('--samples', type=str, help='how many samples to draw from MCMC chains',default=5000)
    parser.add_argument('--burnin', type=str, help='how many samples to burn in from MCMC chains',default=5000)
    parser.add_argument('--cores', type=str, help='how many CPU/GPU cores to use for sampling',default=4)
    parser.add_argument('--SubSlope', type=str, help='whether to include subject-specific slope in the generated data',default=False) #Having subject slopes make the model very difficult to converge. With the constraints on computational resources, we cannnot afford to sample too long of a chain.
    parser.add_argument('--model', type=str, help='which model to run')
    parser.add_argument('--outdir', type=str, help='outpu directory to save results',default='/scratch/hyang336/working_dir/HDDM_HSSM/simulations/')
    parser.add_argument('--TA', type=str, help='target_accept for NUTS sampler',default=0.8)
    args = parser.parse_args()

    model=args.model
    outdir=args.outdir
    samples=int(args.samples)
    burnin=int(args.burnin)
    ncores=int(args.cores)
    SubSlope=args.SubSlope
    TA=float(args.TA)

    # print out the arguments for debugging
    print('model:',model)
    print('outdir:',outdir)
    print('samples:',samples)
    print('burnin:',burnin)
    print('ncores:',ncores)
    print('SubSlope:',SubSlope)
    print('TA:',TA)

    # make the output directory if it doesn't exist
    if not os.path.exists(outdir):
        os.makedirs(outdir)

    #--------------------------------------We can try several generative model--------------------------------###
    #fake trialwise neural data, the 4 accumulators are simulated to have monotonic or nonmonotonic relationships with 
    #(log-transformed) neural data. This is controlled by take the beta distribution and log transform it, making it a 
    #simple linear regression on the log-transformed neural data. The intercept becomes the log transform of 1 over beta 
    #function, evaluated at the parameters for the beta distribution (a and b). This intercept was the normalizing factor
    #before the log transformation to make sure the function was a distibution (i.e. integrate to 1). Note, larger values
    #of a or b will result in large positive or negative value of v down the line, may need to find a way to rescale it...
    # These values should generate v in the range of 0 to 2.5, which is the range of v that the LAN model can handle, as long
    # as the neural data is in the range of 0 to 1. The neural data is generated from a uniform distribution, so it should
    a0=1
    b0=2
    #intercept0=np.log(1/beta(a0,b0))
    intercept0=0.85

    a1=1.75
    b1=2.25
    #intercept1=np.log(1/beta(a1,b1))
    intercept1=2.1

    a2=2.25
    b2=1.75
    #intercept2=np.log(1/beta(a2,b2))
    intercept2=2.1

    a3=2
    b3=1
    #intercept3=np.log(1/beta(a3,b3))
    intercept3=0.85

    n_subjects=30 #number of subjects
    n_trials=200 #number of trials per subject
    param_sv=0.1 #standard deviation of the subject-level parameters
    epsilon=1e-10 #small number to avoid log(0) in the log transformation

    # Save trial-level parameters for each subject
    subject_params={
        "v0": np.array([]),
        "v1": np.array([]),
        "v2": np.array([]),
        "v3": np.array([]),
        "simneural": np.array([]),
        "subID": np.array([])
    }

    # simulated data list
    sim_data=[]

    # Generate subject-level parameters
    for i in range(n_subjects):
        # set the seed for each subject deterministically so all models are based on the same data
        np.random.seed(i)
        # generate neural data, standard normal as the real data
        simneural=np.random.normal(size=n_trials)
        # rescale to 0-1
        simneural=(simneural - np.min(simneural))/(np.max(simneural) - np.min(simneural))
        # make sure there no exact 0 or 1 otherwise the log becomes undefined
        simneural=np.clip(simneural,epsilon,1-epsilon)

        # Whether to include subject-specific slope, default is False
        if SubSlope:
            # generate v0, v1, v2, v3
            v0=np.exp(np.random.normal(intercept0, param_sv) + np.random.normal((a0-1), param_sv)*np.log(simneural) + np.random.normal((b0-1), param_sv)*np.log(1-simneural))
            v1=np.exp(np.random.normal(intercept1, param_sv) + np.random.normal((a1-1), param_sv)*np.log(simneural) + np.random.normal((b1-1), param_sv)*np.log(1-simneural))
            v2=np.exp(np.random.normal(intercept2, param_sv) + np.random.normal((a2-1), param_sv)*np.log(simneural) + np.random.normal((b2-1), param_sv)*np.log(1-simneural))
            v3=np.exp(np.random.normal(intercept3, param_sv) + np.random.normal((a3-1), param_sv)*np.log(simneural) + np.random.normal((b3-1), param_sv)*np.log(1-simneural))
        else:
            # generate v0, v1, v2, v3
            v0=np.exp(np.random.normal(intercept0, param_sv) + (a0-1)*np.log(simneural) + (b0-1)*np.log(1-simneural))
            v1=np.exp(np.random.normal(intercept1, param_sv) + (a1-1)*np.log(simneural) + (b1-1)*np.log(1-simneural))
            v2=np.exp(np.random.normal(intercept2, param_sv) + (a2-1)*np.log(simneural) + (b2-1)*np.log(1-simneural))
            v3=np.exp(np.random.normal(intercept3, param_sv) + (a3-1)*np.log(simneural) + (b3-1)*np.log(1-simneural))

        ###IMPORTANT: for interpretable param rec test, make sure generate params within training bounds of LAN###
        # instead of removing out-of-bound elements, we can replace the out-of-bound elements with the boundary values to avoid discontinuity
        v0 = np.clip(v0, 0, 2.5)
        v1 = np.clip(v1, 0, 2.5)
        v2 = np.clip(v2, 0, 2.5)
        v3 = np.clip(v3, 0, 2.5)

        # save to subject_params
        subject_params["v0"]=np.append(subject_params["v0"],v0)
        subject_params["v1"]=np.append(subject_params["v1"],v1)
        subject_params["v2"]=np.append(subject_params["v2"],v2)
        subject_params["v3"]=np.append(subject_params["v3"],v3)
        subject_params["simneural"]=np.append(subject_params["simneural"],simneural)
        subject_params["subID"]=np.append(subject_params["subID"],np.repeat(i,len(simneural)))

        # simulate RT and choices
        true_values = np.column_stack(
        [v0,v1,v2,v3, np.repeat([[2.0, 0.0, 1e-3,0.0]], axis=0, repeats=len(simneural))]
        )
        # Get mode simulations
        race4nba_v = simulator.simulator(true_values, model="race_no_bias_angle_4", n_samples=1)

        # Random regressor as control
        rand_x = np.random.normal(size=len(simneural))
        rand_x = (rand_x - np.min(rand_x))/(np.max(rand_x) - np.min(rand_x))
        rand_x = np.clip(rand_x,epsilon,1-epsilon)
        
        sim_data.append(
            pd.DataFrame(
                {
                    "rt": race4nba_v["rts"].flatten(),
                    "response": race4nba_v["choices"].flatten(),
                    "x": np.log(simneural),
                    "y": np.log(1-simneural),
                    "rand_x": np.log(rand_x),
                    "rand_y": np.log(1-rand_x),
                    "subID": i
                }
            )
        )

    #make a single dataframe of subject-wise simulated data
    sim_data_concat=pd.concat(sim_data)

    ####################################################################################### Define models ################################################################################################
    match model:
        case 'true':
            if SubSlope:
                # True model
                model_race4nba_v_true = hssm.HSSM(
                    data=sim_data_concat,
                    model='race_no_bias_angle_4',
                    choices=4,
                    prior_settings="safe",
                    a=2.0,
                    z=0.0,
                    include=[
                        {
                            "name": "v0",                            
                            "formula": "v0 ~ 1 + x + y + (1 + x + y|subID)",
                            # "prior":slope_prior_true,
                            "link": "log",
                            "bounds": (0, 2.5)
                        },
                        {
                            "name": "v1",                            
                            "formula": "v1 ~ 1 + x + y + (1 + x + y|subID)",
                            # "prior":slope_prior_true,
                            "link": "log",
                            "bounds": (0, 2.5)
                        },
                        {
                            "name": "v2",                            
                            "formula": "v2 ~ 1 + x + y + (1 + x + y|subID)",
                            # "prior":slope_prior_true,
                            "link": "log",
                            "bounds": (0, 2.5)
                        },
                        {
                            "name": "v3",                            
                            "formula": "v3 ~ 1 + x + y + (1 + x + y|subID)",
                            # "prior":slope_prior_true,
                            "link": "log",
                            "bounds": (0, 2.5)
                        }
                    ],
                )
            else:
                # True model
                model_race4nba_v_true = hssm.HSSM(
                    data=sim_data_concat,
                    model='race_no_bias_angle_4',
                    choices=4,
                    noncentered=True,
                    prior_settings="safe",
                    a=2.0,
                    z=0.0,
                    include=[
                        {
                            "name": "v0",                            
                            "formula": "v0 ~ 1 + x + y + (1|subID)",
                            # "prior":intercept_prior_true,
                            "link": "log",
                            "bounds": (0, 2.5)
                        },
                        {
                            "name": "v1",                            
                            "formula": "v1 ~ 1 + x + y + (1|subID)",
                            # "prior":intercept_prior_true,
                            "link": "log",
                            "bounds": (0, 2.5)
                        },
                        {
                            "name": "v2",                            
                            "formula": "v2 ~ 1 + x + y + (1|subID)",
                            # "prior":intercept_prior_true,
                            "link": "log",
                            "bounds": (0, 2.5)
                        },
                        {
                            "name": "v3",                            
                            "formula": "v3 ~ 1 + x + y + (1|subID)",
                            # "prior":intercept_prior_true,
                            "link": "log",
                            "bounds": (0, 2.5)
                        }
                    ],
                )
            #sample from the model
            #infer_data_race4nba_v_true = model_race4nba_v_true.sample(step=pm.Slice(model=model_race4nba_v_true.pymc_model), sampler="mcmc", chains=4, cores=4, draws=5000, tune=10000,idata_kwargs = {'log_likelihood': True})
            infer_data_race4nba_v_true = model_race4nba_v_true.sample(sampler="nuts_numpyro", chains=4, cores=ncores, draws=samples, tune=burnin,idata_kwargs = {'log_likelihood': True}, target_accept=TA)            
            #save trace
            #az.to_netcdf(infer_data_race4nba_v_true,outdir+'sample_5000_10000_trace_ParamInbound_Fixed_az_SliceSampler_true.nc4')
            az.to_netcdf(infer_data_race4nba_v_true,outdir+'sample_' + str(burnin) + '_' + str(samples) + '_trace_ParamInbound_Fixed_az_NutsNumpyro_true.nc4')
            #save trace plot
            az.plot_trace(
                infer_data_race4nba_v_true,
                var_names="~log_likelihood",  # we exclude the log_likelihood traces here
            )
            #plt.savefig(outdir+'posterior_diagnostic_5000_10000_trace_ParamInbound_Fixed_az_SliceSampler_true.png')
            plt.savefig(outdir+'posterior_diagnostic_' + str(burnin) + '_' + str(samples) + '_trace_ParamInbound_Fixed_az_NutsNumpyro_true.png')
            #save summary
            res_sum_true=az.summary(model_race4nba_v_true.traces)
            #res_sum_true.to_csv(outdir+'summary_5000_10000_trace_ParamInbound_Fixed_az_SliceSampler_true.csv')
            res_sum_true.to_csv(outdir+'summary_' + str(burnin) + '_' + str(samples) + '_trace_ParamInbound_Fixed_az_NutsNumpyro_true.csv')
        
        case 'null':
            # model with no relationship between v and neural data
            model_race4nba_v_null = hssm.HSSM(
                data=sim_data_concat,
                model='race_no_bias_angle_4',
                choices=4,
                noncentered=True,
                prior_settings="safe",
                a=2.0,
                z=0.0,
                include=[
                    {
                        "name": "v0",                        
                        "formula": "v0 ~ 1 + (1|subID)",
                        #"prior":null_prior,
                        "link": "log",
                        "bounds": (0, 2.5)
                    },
                    {
                        "name": "v1",                        
                        "formula": "v1 ~ 1 + (1|subID)",
                        #"prior":null_prior,
                        "link": "log",
                        "bounds": (0, 2.5)
                    },
                    {
                        "name": "v2",                        
                        "formula": "v2 ~ 1 + (1|subID)",
                        #"prior":null_prior,
                        "link": "log",
                        "bounds": (0, 2.5)
                    },
                    {
                        "name": "v3",                        
                        "formula": "v3 ~ 1 + (1|subID)",
                        #"prior":null_prior,
                        "link": "log",
                        "bounds": (0, 2.5)
                    }
                ],
            )
            #infer_data_race4nba_v_null = model_race4nba_v_null.sample(step=pm.Slice(model=model_race4nba_v_null.pymc_model), sampler="mcmc", chains=4, cores=4, draws=5000, tune=10000,idata_kwargs = {'log_likelihood': True})
            infer_data_race4nba_v_null = model_race4nba_v_null.sample(sampler="nuts_numpyro", chains=4, cores=ncores, draws=samples, tune=burnin,idata_kwargs = {'log_likelihood': True}, target_accept=TA)
            # az.to_netcdf(infer_data_race4nba_v_null,outdir+'sample_5000_10000_trace_ParamInbound_Fixed_az_SliceSampler_null.nc4')
            az.to_netcdf(infer_data_race4nba_v_null,outdir+'sample_' + str(burnin) + '_' + str(samples) + '_trace_ParamInbound_Fixed_az_NutsNumpyro_null.nc4')
            az.plot_trace(
                infer_data_race4nba_v_null,
                var_names="~log_likelihood",  # we exclude the log_likelihood traces here
            )
            # plt.savefig(outdir+'posterior_diagnostic_5000_10000_trace_ParamInbound_Fixed_az_SliceSampler_null.png')
            plt.savefig(outdir+'posterior_diagnostic_' + str(burnin) + '_' + str(samples) + '_trace_ParamInbound_Fixed_az_NutsNumpyro_null.png')
            res_sum_null=az.summary(model_race4nba_v_null.traces)
            # res_sum_null.to_csv(outdir+'summary_5000_10000_trace_ParamInbound_Fixed_az_SliceSampler_null.csv')
            res_sum_null.to_csv(outdir+'summary_' + str(burnin) + '_' + str(samples) + '_trace_ParamInbound_Fixed_az_NutsNumpyro_null.csv')

        case 'rand':
            if SubSlope:                
                # model with regression on random vectors (i.e. fake neural data that has the same distribution but was not involved in generating the parameters)
                model_race4nba_v_rand = hssm.HSSM(
                    data=sim_data_concat,
                    model='race_no_bias_angle_4',
                    choices=4,
                    noncentered=True,
                    prior_settings="safe",
                    a=2.0,
                    z=0.0,
                    include=[
                        {
                            "name": "v0",                            
                            "formula": "v0 ~ 1 + rand_x + rand_y + (1 + rand_x + rand_y|subID)",
                            #"prior":slope_prior_rand,
                            "link": "log",
                            "bounds": (0, 2.5)
                        },
                        {
                            "name": "v1",                            
                            "formula": "v1 ~ 1 + rand_x + rand_y + (1 + rand_x + rand_y|subID)",
                            #"prior":slope_prior_rand,
                            "link": "log",
                            "bounds": (0, 2.5)
                        },
                        {
                            "name": "v2",                            
                            "formula": "v2 ~ 1 + rand_x + rand_y + (1 + rand_x + rand_y|subID)",
                            #"prior":slope_prior_rand,
                            "link": "log",
                            "bounds": (0, 2.5)
                        },
                        {
                            "name": "v3",                            
                            "formula": "v3 ~ 1 + rand_x + rand_y + (1 + rand_x + rand_y|subID)",
                            #"prior":slope_prior_rand,
                            "link": "log",
                            "bounds": (0, 2.5)
                        }
                    ],
                )
            else:
                # model with regression on random vectors (i.e. fake neural data that has the same distribution but was not involved in generating the parameters)
                model_race4nba_v_rand = hssm.HSSM(
                    data=sim_data_concat,
                    model='race_no_bias_angle_4',
                    choices=4,
                    noncentered=True,
                    prior_settings="safe",
                    a=2.0,
                    z=0.0,
                    include=[
                        {
                            "name": "v0",                            
                            "formula": "v0 ~ 1 + rand_x + rand_y + (1|subID)",
                            # "prior":intercept_prior_rand,
                            "link": "log",
                            "bounds": (0, 2.5)
                        },
                        {
                            "name": "v1",                            
                            "formula": "v1 ~ 1 + rand_x + rand_y + (1|subID)",
                            # "prior":intercept_prior_rand,
                            "link": "log",
                            "bounds": (0, 2.5)
                        },
                        {
                            "name": "v2",                            
                            "formula": "v2 ~ 1 + rand_x + rand_y + (1|subID)",
                            # "prior":intercept_prior_rand,
                            "link": "log",
                            "bounds": (0, 2.5)
                        },
                        {
                            "name": "v3",                            
                            "formula": "v3 ~ 1 + rand_x + rand_y + (1|subID)",
                            # "prior":intercept_prior_rand,
                            "link": "log",
                            "bounds": (0, 2.5)
                        }
                    ],
                )
            # infer_data_race4nba_v_rand = model_race4nba_v_rand.sample(step=pm.Slice(model=model_race4nba_v_rand.pymc_model), sampler="mcmc", chains=4, cores=4, draws=5000, tune=10000,idata_kwargs = {'log_likelihood': True})
            infer_data_race4nba_v_rand = model_race4nba_v_rand.sample(sampler="nuts_numpyro", chains=4, cores=ncores, draws=samples, tune=burnin,idata_kwargs = {'log_likelihood': True}, target_accept=TA)
            # az.to_netcdf(infer_data_race4nba_v_rand,outdir+'sample_5000_10000_trace_ParamInbound_Fixed_az_SliceSampler_rand.nc4')
            az.to_netcdf(infer_data_race4nba_v_rand,outdir+'sample_' + str(burnin) + '_' + str(samples) + '_trace_ParamInbound_Fixed_az_NutsNumpyro_rand.nc4')
            az.plot_trace(
                infer_data_race4nba_v_rand,
                var_names="~log_likelihood",  # we exclude the log_likelihood traces here
            )
            # plt.savefig(outdir+'posterior_diagnostic_5000_10000_trace_ParamInbound_Fixed_az_SliceSampler_rand.png')
            plt.savefig(outdir+'posterior_diagnostic_' + str(burnin) + '_' + str(samples) + '_trace_ParamInbound_Fixed_az_NutsNumpyro_rand.png')
            res_sum_rand=az.summary(model_race4nba_v_rand.traces)
            # res_sum_rand.to_csv(outdir+'summary_5000_10000_trace_ParamInbound_Fixed_az_SliceSampler_rand.csv')
            res_sum_rand.to_csv(outdir+'summary_' + str(burnin) + '_' + str(samples) + '_trace_ParamInbound_Fixed_az_NutsNumpyro_rand.csv')



