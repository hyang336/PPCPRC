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
    parser.add_argument('--outdir', type=str, help='outpu directory to save results',default='/scratch/hyang336/working_dir/HDDM_HSSM/simulations/')
    parser.add_argument('--TA', type=str, help='target_accept for NUTS sampler',default=0.8)
    args = parser.parse_args()

    samples=int(args.samples)
    burnin=int(args.burnin)
    outdir=args.outdir

    # make the output directory if it doesn't exist
    if not os.path.exists(outdir):
        os.makedirs(outdir)

    #--------------------------------------We can try several generative model--------------------------------###
    n_subjects = 25 # number of subjects
    n_trials = 50 # number of trials per subject - vary from low to high values to check shrinkage
    sd_v = 0.3 # sd for v-intercept (also used for a)
    mean_v = 1.25 # mean for v-intercept
    mean_vx = 0.8 # mean for slope of x onto v
    mean_vy = 0.2 # mean for slope of x onto v

    sd_tz=0.1
    mean_a = 1.5
    mean_t = 0.5
    mean_z = 0.5
    data_list = []
    param_list =[]

    for i in range(n_subjects):
        # Make parameters for subject i
        intercept = np.random.normal(mean_v, sd_v, size=1)
        x = np.random.uniform(-1, 1, size=n_trials)
        y = np.random.uniform(-1, 1, size=n_trials)
        v_x = np.random.normal(mean_vx, sd_v, size=1)
        v_y = np.random.normal(mean_vy, sd_v, size=1)
        v = intercept + (v_x * x) + (v_y * y)
        a = np.random.normal(mean_a, sd_v, size=1)
        z = np.random.normal(mean_z, sd_tz, size=1)
        t = np.random.normal(mean_t, sd_tz, size=1)
        # v is a vector which differs over trials by x and y, so we have different v for every trial - other params are same for all trials
        true_values = np.column_stack(
            [v, np.repeat(a, axis=0, repeats=n_trials), np.repeat(z, axis=0,repeats=n_trials), np.repeat(t, axis=0, repeats=n_trials)]
        )
        # Simulate data
        obs_ddm_reg_v = hssm.simulate_data(model="ddm", theta=true_values, size=1)
        # store ground truth params
        param_list.append(
            pd.DataFrame(
                {
                "intercept": intercept,
                "v_x": v_x,
                "v_y": v_y,
                "a": a,
                "z": z,
                "t": t,
                }
            )
        )
        # Append simulated data to list
        data_list.append(
            pd.DataFrame(
                {
                "rt": obs_ddm_reg_v["rt"],
                "response": obs_ddm_reg_v["response"],
                "x": x,
                "y": y,
                "subject": i,
                }
            )
        )

    #make a single dataframe of subject-wise simulated data
    dataset_reg_v_hier = pd.concat(data_list)

    ####################################################################################### Define models ################################################################################################
    model_reg_v_ddm_hier1A = hssm.HSSM(
        data=dataset_reg_v_hier,
        # loglik_kind="approx_differentiable", works best with analytic model
        prior_settings = "safe",
        include=[
            {
            "name": "v",
            "formula": "v ~ 1 + x + y + (1 + x + y| subject)",
            "prior": {
                "Intercept": {"name": "Normal", "mu": 1, "sigma": 2, "initval": 1},
                "x": {"name": "Normal", "mu": 0, "sigma": 1, "initval": 0},
                "y": {"name": "Normal", "mu": 0, "sigma": 1, "initval": 0},
                "1|subject": {"name": "Normal",
                    "mu": 0, # using non-centered approach so mu's of indiv subject offsets should be 0
                    "sigma": {"name": "HalfNormal",
                        "sigma": 1
                        }, "initval": 0.5
                    },

                "x|subject": {"name": "Normal",
                    "mu": 0,
                    "sigma": {"name": "HalfNormal",
                        "sigma": 0.5,
                        }, "initval": 0.5
                    },
                "y|subject": {"name": "Normal",
                    "mu": 0,
                    "sigma": {"name": "HalfNormal",
                        "sigma": 0.5,
                        }, "initval": 0.5
                    },
            },
            "link": "identity",
            },
            {
            "name": "t",
            "formula": "t ~ 1 + (1 | subject)",
            "prior": {
                "Intercept": {"name": "Normal", "mu": 0.5, "sigma": 0.4, "initval": 0.3},
                "1|subject": {"name": "Normal",
                    "mu": 0,
                    "sigma": {"name": "HalfNormal",
                        "sigma": 0.5, "initval": .1
                        },
                    },
                },
            "link": "identity",
            },
            {
            "name": "z",
            "formula": "z ~ 1 + (1 | subject)",
            "prior": {
                # "Intercept": {"name": "HalfNormal", "sigma": 1, "initval": .5},
                "1|subject": {"name": "Normal",
                    "mu": 0,
                    "sigma": {"name": "HalfNormal",
                        "sigma": 0.05, "initval": .01
                        },
                    },
                },
            },
            {
            "name": "a",
            "formula": "a ~ 1 + (1 | subject)",
            "prior": {
                "Intercept": {"name": "Gamma", "mu": 0.5, "sigma": 1.75, "initval": 1},
                "1|subject": {"name": "Normal",
                    "mu": 0,
                    "sigma": {"name": "HalfNormal",
                        "sigma": 1, "initval": 0.3
                        },
                    },
                },
            },
        ],
        noncentered = True,
        # p_outlier=0
        )
    
    samples_model_reg_v_ddm_hier1A = model_reg_v_ddm_hier1A.sample(
        sampler="nuts_numpyro", # type of sampler to choose, 'nuts_numpyro'
        cores=1, # how many cores to use
        chains=3, # how many chains to run
        draws=samples, # number of draws from the markov chain
        tune=burnin, # number of burn-in samples
        idata_kwargs=dict(log_likelihood=True))
    az.to_netcdf(samples_model_reg_v_ddm_hier1A,outdir+'sample_' + str(burnin) + '_' + str(samples) + '_ddm_frankmj.nc4')
            
    az.plot_trace(
                samples_model_reg_v_ddm_hier1A,
                var_names="~log_likelihood",  # we exclude the log_likelihood traces here
            )
    plt.savefig(outdir+'posterior_diagnostic_' + str(burnin) + '_' + str(samples) + '_ddm_frankmj.png')
    #save summary
    res_sum_true=az.summary(model_reg_v_ddm_hier1A.traces)
    res_sum_true.to_csv(outdir+'summary_' + str(burnin) + '_' + str(samples) + '_ddm_frankmj.csv')
        