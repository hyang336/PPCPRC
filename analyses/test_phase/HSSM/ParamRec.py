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
    parser.add_argument('--model', type=str, help='which model to run')
    parser.add_argument('--outdir', type=str, help='outpu directory to save results',default='/scratch/hyang336/working_dir/HDDM_HSSM/simulations/')
    args = parser.parse_args()

    model=args.model
    outdir=args.outdir

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
    a0=0
    b0=1
    #intercept0=np.log(1/beta(a0,b0))
    intercept0=0.85

    a1=1.5
    b1=3
    #intercept1=np.log(1/beta(a1,b1))
    intercept1=2.1

    a2=3
    b2=1.5
    #intercept2=np.log(1/beta(a2,b2))
    intercept2=2.1

    a3=1
    b3=0
    #intercept3=np.log(1/beta(a3,b3))
    intercept3=0.85

    n_subjects=30 #number of subjects
    n_trials=200 #number of trials per subject
    param_sv=0.2 #standard deviation of the subject-level parameters

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
        # generate neural data
        simneural=np.random.uniform(0, 1, size=n_trials)
        # generate v0, v1, v2, v3
        v0=np.exp(np.random.normal(intercept0, param_sv) + np.random.normal(a0, param_sv)*np.log(simneural) + np.random.normal(b0, param_sv)*np.log(1-simneural))
        v1=np.exp(np.random.normal(intercept1, param_sv) + np.random.normal(a1, param_sv)*np.log(simneural) + np.random.normal(b1, param_sv)*np.log(1-simneural))
        v2=np.exp(np.random.normal(intercept2, param_sv) + np.random.normal(a2, param_sv)*np.log(simneural) + np.random.normal(b2, param_sv)*np.log(1-simneural))
        v3=np.exp(np.random.normal(intercept3, param_sv) + np.random.normal(a3, param_sv)*np.log(simneural) + np.random.normal(b3, param_sv)*np.log(1-simneural))
        
        ###IMPORTANT: for interpretable param rec test, make sure generate params within training bounds of LAN###
        # only keep entries in subject_data that are in bounds
        v0_inb= np.where(np.logical_and(v0>= 0,v0<= 2.5))
        v1_inb= np.where(np.logical_and(v1>= 0,v1<= 2.5))
        v01_inb=np.intersect1d(v0_inb[0],v1_inb[0])

        v2_inb= np.where(np.logical_and(v2>= 0,v2<= 2.5))
        v3_inb= np.where(np.logical_and(v3>= 0,v3<= 2.5))
        v23_inb=np.intersect1d(v2_inb[0],v3_inb[0])

        v0123_inb=np.intersect1d(v01_inb,v23_inb)#indices of elements that are in bound for all 4 arrays

        #only keep inbound elements
        simneural=simneural[v0123_inb]
        v0=v0[v0123_inb]
        v1=v1[v0123_inb]
        v2=v2[v0123_inb]
        v3=v3[v0123_inb]
        
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
        rand_x = np.random.uniform(0, 1, size=len(simneural))
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

    # Define models
    match model:
        case 'true':
            # True model
            model_race4nba_v_true = hssm.HSSM(
                data=sim_data_concat,
                model='race_no_bias_angle_4',
                a=2.0,
                z=0.0,
                include=[
                    {
                        "name": "v0",
                        "prior":{"name": "Uniform", "lower": -1, "upper": 3},
                        "formula": "v0 ~ 1 + (x|subID) + (y|subID)",
                        "link": "log",
                    },
                    {
                        "name": "v1",
                        "prior":{"name": "Uniform", "lower": -1, "upper": 3},
                        "formula": "v1 ~ 1 + (x|subID) + (y|subID)",
                        "link": "log",
                    },
                    {
                        "name": "v2",
                        "prior":{"name": "Uniform", "lower": -1, "upper": 3},
                        "formula": "v2 ~ 1 + (x|subID) + (y|subID)",
                        "link": "log",
                    },
                    {
                        "name": "v3",
                        "prior":{"name": "Uniform", "lower": -1, "upper": 3},
                        "formula": "v3 ~ 1 + (x|subID) + (y|subID)",
                        "link": "log",
                    }
                ],
            )
            #sample from the model
            infer_data_race4nba_v_true = model_race4nba_v_true.sample(step=pm.Slice(model=model_race4nba_v_true.pymc_model), sampler="mcmc", chains=4, cores=4, draws=5000, tune=10000,idata_kwargs = {'log_likelihood': True})
            # compute WAIC
            az.waic(infer_data_race4nba_v_true)
            #save trace
            az.to_netcdf(infer_data_race4nba_v_true,outdir+'sample_5000_10000_trace_ParamInbound_Fixed_az_SliceSampler_true.nc4')
            #save trace plot
            az.plot_trace(
                infer_data_race4nba_v_true,
                var_names="~log_likelihood",  # we exclude the log_likelihood traces here
            )
            plt.savefig(outdir+'posterior_diagnostic_5000_10000_trace_ParamInbound_Fixed_az_SliceSampler_true.png')
            #save summary
            res_sum_true=az.summary(model_race4nba_v_true.traces)
            res_sum_true.to_csv(outdir+'summary_5000_10000_trace_ParamInbound_Fixed_az_SliceSampler_true.csv')
        
        case 'null':
            # model with no relationship between v and neural data
            model_race4nba_v_null = hssm.HSSM(
                data=sim_data_concat,
                model='race_no_bias_angle_4',
                a=2.0,
                z=0.0,
                include=[
                    {
                        "name": "v0",
                        "prior":{"name": "Uniform", "lower": -1, "upper": 3},
                        "formula": "v0 ~ 1 + (1|subID)",
                        "link": "log"
                    },
                    {
                        "name": "v1",
                        "prior":{"name": "Uniform", "lower": -1, "upper": 3},
                        "formula": "v1 ~ 1 + (1|subID)",
                        "link": "log"
                    },
                    {
                        "name": "v2",
                        "prior":{"name": "Uniform", "lower": -1, "upper": 3},
                        "formula": "v2 ~ 1 + (1|subID)",
                        "link": "log"
                    },
                    {
                        "name": "v3",
                        "prior":{"name": "Uniform", "lower": -1, "upper": 3},
                        "formula": "v3 ~ 1 + (1|subID)",
                        "link": "log"
                    }
                ],
            )
            infer_data_race4nba_v_null = model_race4nba_v_null.sample(step=pm.Slice(model=model_race4nba_v_null.pymc_model), sampler="mcmc", chains=4, cores=4, draws=5000, tune=10000,idata_kwargs = {'log_likelihood': True})
            az.waic(infer_data_race4nba_v_null)
            az.to_netcdf(infer_data_race4nba_v_null,outdir+'sample_5000_10000_trace_ParamInbound_Fixed_az_SliceSampler_null.nc4')
            az.plot_trace(
                infer_data_race4nba_v_null,
                var_names="~log_likelihood",  # we exclude the log_likelihood traces here
            )
            plt.savefig(outdir+'posterior_diagnostic_5000_10000_trace_ParamInbound_Fixed_az_SliceSampler_null.png')
            res_sum_null=az.summary(model_race4nba_v_null.traces)
            res_sum_null.to_csv(outdir+'summary_5000_10000_trace_ParamInbound_Fixed_az_SliceSampler_null.csv')

        case 'rand':
            # model with regression on random vectors (i.e. fake neural data that has the same distribution but was not involved in generating the parameters)
            model_race4nba_v_rand = hssm.HSSM(
                data=sim_data_concat,
                model='race_no_bias_angle_4',
                a=2.0,
                z=0.0,
                include=[
                    {
                        "name": "v0",
                        "prior":{"name": "Uniform", "lower": -1, "upper": 3},
                        "formula": "v0 ~ 1 + (rand_x|subID) + (rand_y|subID)",
                        "link": "log",
                    },
                    {
                        "name": "v1",
                        "prior":{"name": "Uniform", "lower": -1, "upper": 3},
                        "formula": "v1 ~ 1 + (rand_x|subID) + (rand_y|subID)",
                        "link": "log",
                    },
                    {
                        "name": "v2",
                        "prior":{"name": "Uniform", "lower": -1, "upper": 3},
                        "formula": "v2 ~ 1 + (rand_x|subID) + (rand_y|subID)",
                        "link": "log",
                    },
                    {
                        "name": "v3",
                        "prior":{"name": "Uniform", "lower": -1, "upper": 3},
                        "formula": "v3 ~ 1 + (rand_x|subID) + (rand_y|subID)",
                        "link": "log",
                    }
                ],
            )
            infer_data_race4nba_v_rand = model_race4nba_v_rand.sample(step=pm.Slice(model=model_race4nba_v_rand.pymc_model), sampler="mcmc", chains=4, cores=4, draws=5000, tune=10000,idata_kwargs = {'log_likelihood': True})
            az.waic(infer_data_race4nba_v_rand)
            az.to_netcdf(infer_data_race4nba_v_rand,outdir+'sample_5000_10000_trace_ParamInbound_Fixed_az_SliceSampler_rand.nc4')
            az.plot_trace(
                infer_data_race4nba_v_rand,
                var_names="~log_likelihood",  # we exclude the log_likelihood traces here
            )
            plt.savefig(outdir+'posterior_diagnostic_5000_10000_trace_ParamInbound_Fixed_az_SliceSampler_rand.png')
            res_sum_rand=az.summary(model_race4nba_v_rand.traces)
            res_sum_rand.to_csv(outdir+'summary_5000_10000_trace_ParamInbound_Fixed_az_SliceSampler_rand.csv')



