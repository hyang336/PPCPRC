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

if __name__ == '__main__':
    mp.freeze_support()    
    mp.set_start_method('spawn', force=True)

    outdir='/scratch/hyang336/working_dir/HDDM_HSSM/freq_race4nba_fit'
    if not os.path.exists(outdir):
        os.makedirs(outdir)
    
    #--------------------------------------Load in data and preprocessing--------------------------------###
    #load in data from csv files
    freq_data=pd.read_csv('/scratch/hyang336/working_dir/HDDM_HSSM/HSSM_freq_data.csv')
    life_data=pd.read_csv('/scratch/hyang336/working_dir/HDDM_HSSM/HSSM_life_data.csv')



    
    dataset_race4nba_v = pd.DataFrame(
        {
            "rt": race4nba_v["rts"].flatten(),
            "response": race4nba_v["choices"].flatten(),
            "x": np.log(simneural),
            "y": np.log(1-simneural)
        }
    )


    #estimate parameters based on data
    model_race4nba_v = hssm.HSSM(
        data=dataset_race4nba_v,
        model='race_no_bias_angle_4',
        a=2.0,
        z=0.0,
        include=[
            {
                "name": "v0",
                "prior":{"name": "Uniform", "lower": -1, "upper": 3},
                "formula": "v0 ~ 1 + x + y",
                "link": "log",
            },
            {
                "name": "v1",
                "prior":{"name": "Uniform", "lower": -1, "upper": 3},
                "formula": "v1 ~ 1 + x + y",
                "link": "log",
            },
            {
                "name": "v2",
                "prior":{"name": "Uniform", "lower": -1, "upper": 3},
                "formula": "v2 ~ 1 + x + y",
                "link": "log",
            },
            {
                "name": "v3",
                "prior":{"name": "Uniform", "lower": -1, "upper": 3},
                "formula": "v3 ~ 1 + x + y",
                "link": "log",
            }
        ],
    )

    #sample from the model, 2500-2500 is not enough for the chain the converge
    infer_data_race4nba_v = model_race4nba_v.sample(step=pm.Slice(model=model_race4nba_v.pymc_model), sampler="mcmc", chains=4, cores=4, draws=5000, tune=10000)
    #save model
    az.to_netcdf(infer_data_race4nba_v,outdir+'/sample_5000_10000_trace_ParamInbound_Fixed_az_SliceSampler.nc4')

    #load model
    #infer_data_race4_v=az.from_netcdf('/home/hyang336/HSSM_race5_dev/HY_dev/race_4_LAN/sample50_trace.nc4')

    #diagnostic plots
    az.plot_trace(
        infer_data_race4nba_v,
        var_names="~log_likelihood",  # we exclude the log_likelihood traces here
    )
    plt.savefig(outdir+'/posterior_diagnostic_5000_10000_trace_ParamInbound_Fixed_az_SliceSampler.png')

    #fit summary
    res_sum=az.summary(model_race4nba_v.traces)
    res_sum.to_csv(outdir+'/summary_5000_10000_trace_ParamInbound_Fixed_az_SliceSampler.csv')