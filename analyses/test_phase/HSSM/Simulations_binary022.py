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
    parser.add_argument('--model', type=str, help='which model to run')
    parser.add_argument('--outdir', type=str, help='outpu directory to save results',default='/scratch/hyang336/working_dir/HDDM_HSSM/DDM_simulations/')
    parser.add_argument('--TA', type=str, help='target_accept for NUTS sampler',default=0.8)
    parser.add_argument('--tstrat', type=str, help='how to handle issue on the t paramter',default='clip')
    args = parser.parse_args()

    model=args.model
    outdir=args.outdir
    samples=int(args.samples)
    burnin=int(args.burnin)
    ncores=int(args.cores)
    TA=float(args.TA)
    tstrat=args.tstrat # 'clip' or 'RThack' or 'norandom' or 'clipRThack' or 'clipnorandom' or 'RThacknorandom' or 'clipRThacknorandom'

    # print out the arguments for debugging
    print('model:',model)
    print('outdir:',outdir)
    print('samples:',samples)
    print('burnin:',burnin)
    print('ncores:',ncores)
    print('TA:',TA)

    # make the output directory if it doesn't exist
    if not os.path.exists(outdir):
        os.makedirs(outdir,exist_ok=True)

    #--------------------------------------We can try several generative model--------------------------------###
    v_slope=0.45
    a_slope=0.3
    z_slope=0.1
    t_slope=0.2
    v_intercept=0.5
    a_intercept=2
    z_intercept=0.5
    t_intercept=0.5

    n_subjects=30 #number of subjects
    n_trials=200 #number of trials per subject
    param_sv=0.2 #standard deviation of the subject-level parameters

    # Save trial-level parameters for each subject
    subject_params={
        "v": np.array([]),
        "a": np.array([]),
        "z": np.array([]),
        "t": np.array([]),
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
        # generate v0, v1, v2, v3
        v=np.random.normal(v_intercept, param_sv) + np.random.normal(v_slope, param_sv)*simneural
        a=np.random.normal(a_intercept, param_sv) + np.random.normal(a_slope, param_sv)*simneural
        z=np.random.normal(z_intercept, param_sv) + np.random.normal(z_slope, param_sv)*simneural
        t=np.random.normal(t_intercept, param_sv) + np.random.normal(t_slope, param_sv)*simneural
        # clip parameters to stay within default bounds
        v = np.clip(v, -3, 3)
        a = np.clip(a, 0.3, 2.5)
        z = np.clip(z, 0, 1)
        if tstrat=='clip' or tstrat=='clipRThack' or tstrat=='clipnorandom' or tstrat=='clipRThacknorandom':
            t = np.clip(t, 0.3, 2)
        else:
            t = np.clip(t, 0, 2)
        # save to subject_params
        subject_params["v"]=np.append(subject_params["v"],v)
        subject_params["a"]=np.append(subject_params["a"],a)
        subject_params["z"]=np.append(subject_params["z"],z)
        subject_params["t"]=np.append(subject_params["t"],t)
        subject_params["simneural"]=np.append(subject_params["simneural"],simneural)
        subject_params["subID"]=np.append(subject_params["subID"],np.repeat(i,len(simneural)))
        # simulate RT and choices
        true_values = np.column_stack([v,a,z,t])
        # Get mode simulations
        ddm_all = simulator.simulator(true_values, model="ddm", n_samples=1)
        # Random regressor as control
        rand_x = np.random.normal(size=len(simneural))        
        if tstrat=='RThack' or tstrat=='clipRThack' or tstrat=='RThacknorandom' or tstrat=='clipRThacknorandom':            
            sim_data.append(
                pd.DataFrame(
                    {
                        "rt": ddm_all["rts"].flatten() + 0.3, # hack to work around the issue on parameter t in HSSM 0.2.2
                        "response": ddm_all["choices"].flatten(),
                        "x": simneural,                    
                        "rand_x": rand_x,                    
                        "subID": i
                    }
                )
            )
        else:
            sim_data.append(
                pd.DataFrame(
                    {
                        "rt": ddm_all["rts"].flatten(),
                        "response": ddm_all["choices"].flatten(),
                        "x": simneural,                    
                        "rand_x": rand_x,                    
                        "subID": i
                    }
                )
            )

    #make a single dataframe of subject-wise simulated data
    sim_data_concat=pd.concat(sim_data)

    #save subject-wise parameters
    param_df=pd.DataFrame(subject_params)
    param_df.to_csv(outdir+'simulation_binary_022_subject_params.csv')
    ####################################################################################### Define models ################################################################################################
    match model:
        case 'true':            
            # True model
            if tstrat=='norandom' or tstrat=='clipnorandom' or tstrat=='RThacknorandom' or tstrat=='clipRThacknorandom':
                model_ddm_true = hssm.HSSM(
                    data=sim_data_concat,                
                    prior_settings="safe",
                    include=[
                        {
                            "name": "v",                            
                            "formula": "v ~ 1 + x + (1 + x|subID)",
                            "prior": {
                                "Intercept": {"name": "Normal", "mu": 1, "sigma": 2, "initval": 1},
                                "x": {"name": "Normal", "mu": 0, "sigma": 1, "initval": 0},
                                "x|subID": {"name": "Normal",
                                    "mu": 0,
                                    "sigma": {"name": "HalfNormal",
                                        "sigma": 0.5
                                        }, "initval": 0.5
                                    },
                                "1|subID": {"name": "Normal",
                                    "mu": 0,
                                    "sigma": {"name": "HalfNormal",
                                        "sigma": 1
                                        }, "initval": 0.5
                                    }
                            },
                            "link": "identity"
                        },
                        {
                            "name": "a",                            
                            "formula": "a ~ 1 + x + (1 + x|subID)",
                            "prior": {
                                "Intercept": {"name": "Normal", "mu": 1, "sigma": 1.75, "initval": 1},
                                "x": {"name": "Normal", "mu": 0, "sigma": 1, "initval": 0},
                                "x|subID": {"name": "Normal",
                                    "mu": 0,
                                    "sigma": {"name": "HalfNormal",
                                        "sigma": 0.5
                                        }, "initval": 0.5
                                    },
                                "1|subID": {"name": "Normal",
                                    "mu": 0,
                                    "sigma": {"name": "HalfNormal",
                                        "sigma": 1
                                        }, "initval": 0.3
                                    }
                            },
                            "link": "identity"
                        },
                        {
                            "name": "z",                            
                            "formula": "z ~ 1 + x + (1 + x|subID)",
                            "prior": {
                                "Intercept": {"name": "HalfNormal", "sigma": 1, "initval": .5},
                                "x": {"name": "Normal", "mu": 0, "sigma": 1, "initval": 0},
                                "x|subID": {"name": "Normal",
                                    "mu": 0,
                                    "sigma": {"name": "HalfNormal",
                                        "sigma": 0.5
                                        }, "initval": 0.5
                                    },
                                "1|subID": {"name": "Normal",
                                    "mu": 0,
                                    "sigma": {"name": "HalfNormal",
                                        "sigma": 0.05
                                        }, "initval": 0.01
                                    }
                            },
                            "link": "identity"
                        }
                    ],
                )
            else:
                model_ddm_true = hssm.HSSM(
                    data=sim_data_concat,                
                    prior_settings="safe",
                    include=[
                        {
                            "name": "v",                            
                            "formula": "v ~ 1 + x + (1 + x|subID)",
                            "prior": {
                                "Intercept": {"name": "Normal", "mu": 1, "sigma": 2, "initval": 1},
                                "x": {"name": "Normal", "mu": 0, "sigma": 1, "initval": 0},
                                "x|subID": {"name": "Normal",
                                    "mu": 0,
                                    "sigma": {"name": "HalfNormal",
                                        "sigma": 0.5
                                        }, "initval": 0.5
                                    },
                                "1|subID": {"name": "Normal",
                                    "mu": 0,
                                    "sigma": {"name": "HalfNormal",
                                        "sigma": 1
                                        }, "initval": 0.5
                                    }
                            },
                            "link": "identity"
                        },
                        {
                            "name": "a",                            
                            "formula": "a ~ 1 + x + (1 + x|subID)",
                            "prior": {
                                "Intercept": {"name": "Normal", "mu": 1, "sigma": 1.75, "initval": 1},
                                "x": {"name": "Normal", "mu": 0, "sigma": 1, "initval": 0},
                                "x|subID": {"name": "Normal",
                                    "mu": 0,
                                    "sigma": {"name": "HalfNormal",
                                        "sigma": 0.5
                                        }, "initval": 0.5
                                    },
                                "1|subID": {"name": "Normal",
                                    "mu": 0,
                                    "sigma": {"name": "HalfNormal",
                                        "sigma": 1
                                        }, "initval": 0.3
                                    }
                            },
                            "link": "identity"
                        },
                        {
                            "name": "z",                            
                            "formula": "z ~ 1 + x + (1 + x|subID)",
                            "prior": {
                                "Intercept": {"name": "HalfNormal", "sigma": 1, "initval": .5},
                                "x": {"name": "Normal", "mu": 0, "sigma": 1, "initval": 0},
                                "x|subID": {"name": "Normal",
                                    "mu": 0,
                                    "sigma": {"name": "HalfNormal",
                                        "sigma": 0.5
                                        }, "initval": 0.5
                                    },
                                "1|subID": {"name": "Normal",
                                    "mu": 0,
                                    "sigma": {"name": "HalfNormal",
                                        "sigma": 0.05
                                        }, "initval": 0.01
                                    }
                            },
                            "link": "identity"
                        },
                        {
                            "name": "t",                            
                            "formula": "t ~ 1 + x + (1 + x|subID)",
                            "prior": {
                                "Intercept": {"name": "Normal", "mu": 0.5, "sigma": 0.4, "initval": 0.3},
                                "x": {"name": "Normal", "mu": 0, "sigma": 1, "initval": 0},
                                "x|subID": {"name": "Normal",
                                    "mu": 0,
                                    "sigma": {"name": "HalfNormal",
                                        "sigma": 0.5
                                        }, "initval": 0.5
                                    },
                                "1|subID": {"name": "Normal",
                                    "mu": 0,
                                    "sigma": {"name": "HalfNormal",
                                        "sigma": 0.5,  "initval": 0.1
                                        },
                                    }
                            },
                            "link": "identity"
                        }
                    ],
                )
            
            #sample from the model
            #infer_data_race4nba_v_true = model_race4nba_v_true.sample(step=pm.Slice(model=model_race4nba_v_true.pymc_model), sampler="mcmc", chains=4, cores=4, draws=5000, tune=10000,idata_kwargs = {'log_likelihood': True})
            infer_data_ddm_true = model_ddm_true.sample(sampler="nuts_numpyro", chains=4, cores=ncores, draws=samples, tune=burnin,idata_kwargs = {'log_likelihood': True}, target_accept=TA)            
            #save trace
            az.to_netcdf(infer_data_ddm_true,outdir+'sample_' + str(burnin) + '_' + str(samples) + '_trace_ParamInbound_ddm_NutsNumpyro_true' + 't-strat_' + str(tstrat) + '.nc4')
            #save trace plot
            az.plot_trace(
                infer_data_ddm_true,
                var_names="~log_likelihood",  # we exclude the log_likelihood traces here
            )
            plt.savefig(outdir+'posterior_diagnostic_' + str(burnin) + '_' + str(samples) + '_trace_ParamInbound_ddm_NutsNumpyro_true_' + 't-strat_' + str(tstrat) + '.png')
            #save summary
            res_sum_true=az.summary(model_ddm_true.traces)
            res_sum_true.to_csv(outdir+'summary_' + str(burnin) + '_' + str(samples) + '_trace_ParamInbound_ddm_NutsNumpyro_true_' + 't-strat_' + str(tstrat) + '.csv')
        
        case 'null':
            # model with no relationship between v and neural data
            if tstrat=='norandom' or tstrat=='clipnorandom' or tstrat=='RThacknorandom' or tstrat=='clipRThacknorandom':
                model_ddm_null = hssm.HSSM(
                    data=sim_data_concat,                
                    prior_settings="safe",
                    include=[
                        {
                            "name": "v",                            
                            "formula": "v ~ 1 + (1|subID)",
                            "prior": {
                                "Intercept": {"name": "Normal", "mu": 1, "sigma": 2, "initval": 1},
                                "1|subID": {"name": "Normal",
                                    "mu": 0,
                                    "sigma": {"name": "HalfNormal",
                                    "sigma": 1
                                    }, "initval": 0.5
                                    }
                            },
                            "link": "identity"
                        },
                        {
                            "name": "a",                            
                            "formula": "a ~ 1 + (1|subID)",
                            "prior": {
                                "Intercept": {"name": "Gamma", "mu": 0.5, "sigma": 1.75, "initval": 1},
                                "1|subID": {"name": "Normal",
                                    "mu": 0,
                                    "sigma": {"name": "HalfNormal",
                                    "sigma": 1
                                    }, "initval": 0.3
                                    }
                            },
                            "link": "identity"
                        },
                        {
                            "name": "z",                            
                            "formula": "z ~ 1 + (1|subID)",
                            "prior": {
                                "Intercept": {"name": "HalfNormal", "sigma": 1, "initval": .5},
                                "1|subID": {"name": "Normal",
                                    "mu": 0,
                                    "sigma": {"name": "HalfNormal",
                                    "sigma": 0.05
                                    }, "initval": 0.01
                                    }
                            },
                            "link": "identity"
                        }
                    ],
                )
            else:
                model_ddm_null = hssm.HSSM(
                    data=sim_data_concat,                
                    prior_settings="safe",
                    include=[
                        {
                            "name": "v",                            
                            "formula": "v ~ 1 + (1|subID)",
                            "prior": {
                                "Intercept": {"name": "Normal", "mu": 1, "sigma": 2, "initval": 1},
                                "1|subID": {"name": "Normal",
                                    "mu": 0,
                                    "sigma": {"name": "HalfNormal",
                                    "sigma": 1
                                    }, "initval": 0.5
                                    }
                            },
                            "link": "identity"
                        },
                        {
                            "name": "a",                            
                            "formula": "a ~ 1 + (1|subID)",
                            "prior": {
                                "Intercept": {"name": "Gamma", "mu": 0.5, "sigma": 1.75, "initval": 1},
                                "1|subID": {"name": "Normal",
                                    "mu": 0,
                                    "sigma": {"name": "HalfNormal",
                                    "sigma": 1
                                    }, "initval": 0.3
                                    }
                            },
                            "link": "identity"
                        },
                        {
                            "name": "z",                            
                            "formula": "z ~ 1 + (1|subID)",
                            "prior": {
                                "Intercept": {"name": "HalfNormal", "sigma": 1, "initval": .5},
                                "1|subID": {"name": "Normal",
                                    "mu": 0,
                                    "sigma": {"name": "HalfNormal",
                                    "sigma": 0.05
                                    }, "initval": 0.01
                                    }
                            },
                            "link": "identity"
                        },
                        {
                            "name": "t",                            
                            "formula": "t ~ 1 + (1|subID)",
                            "prior": {
                                "Intercept": {"name": "Normal", "mu": 0.5, "sigma": 0.4, "initval": 0.3},
                                "1|subID": {"name": "Normal",
                                    "mu": 0,
                                    "sigma": {"name": "HalfNormal",
                                        "sigma": 0.5,  "initval": 0.1
                                        },
                                    }
                            },
                            "link": "identity"
                        }
                    ],
                )
            #infer_data_race4nba_v_null = model_race4nba_v_null.sample(step=pm.Slice(model=model_race4nba_v_null.pymc_model), sampler="mcmc", chains=4, cores=4, draws=5000, tune=10000,idata_kwargs = {'log_likelihood': True})
            infer_data_ddm_null = model_ddm_null.sample(sampler="nuts_numpyro", chains=4, cores=ncores, draws=samples, tune=burnin,idata_kwargs = {'log_likelihood': True}, target_accept=TA)
            # az.to_netcdf(infer_data_race4nba_v_null,outdir+'sample_5000_10000_trace_ParamInbound_Fixed_az_SliceSampler_null.nc4')
            az.to_netcdf(infer_data_ddm_null,outdir+'sample_' + str(burnin) + '_' + str(samples) + '_trace_ParamInbound_ddm_NutsNumpyro_null_' + 't-strat_' + str(tstrat) + '.nc4')
            az.plot_trace(
                infer_data_ddm_null,
                var_names="~log_likelihood",  # we exclude the log_likelihood traces here
            )
            # plt.savefig(outdir+'posterior_diagnostic_5000_10000_trace_ParamInbound_Fixed_az_SliceSampler_null.png')
            plt.savefig(outdir+'posterior_diagnostic_' + str(burnin) + '_' + str(samples) + '_trace_ParamInbound_ddm_NutsNumpyro_null_' + 't-strat_' + str(tstrat) + '.png')
            res_sum_null=az.summary(model_ddm_null.traces)
            # res_sum_null.to_csv(outdir+'summary_5000_10000_trace_ParamInbound_Fixed_az_SliceSampler_null.csv')
            res_sum_null.to_csv(outdir+'summary_' + str(burnin) + '_' + str(samples) + '_trace_ParamInbound_ddm_NutsNumpyro_null_' + 't-strat_' + str(tstrat) + '.csv')

        case 'rand':                        
            # model with regression on random vectors (i.e. fake neural data that has the same distribution but was not involved in generating the parameters)
            if tstrat=='norandom' or tstrat=='clipnorandom' or tstrat=='RThacknorandom' or tstrat=='clipRThacknorandom':
                model_ddm_rand = hssm.HSSM(
                    data=sim_data_concat,                
                    prior_settings="safe",
                    include=[
                        {
                            "name": "v",                            
                            "formula": "v ~ 1 + rand_x + (1 + rand_x|subID)",
                            "prior": {
                                "Intercept": {"name": "Normal", "mu": 1, "sigma": 2, "initval": 1},
                                "rand_x": {"name": "Normal", "mu": 0, "sigma": 1, "initval": 0},
                                "rand_x|subID": {"name": "Normal",
                                    "mu": 0,
                                    "sigma": {"name": "HalfNormal",
                                        "sigma": 0.5
                                        }, "initval": 0.5
                                    },
                                "1|subID": {"name": "Normal",
                                    "mu": 0,
                                    "sigma": {"name": "HalfNormal",
                                        "sigma": 1
                                        }, "initval": 0.5
                                    }
                            },
                            "link": "identity"
                        },
                        {
                            "name": "a",                            
                            "formula": "a ~ 1 + rand_x + (1 + rand_x|subID)",
                            "prior": {
                                "Intercept": {"name": "Normal", "mu": 1, "sigma": 1.75, "initval": 1},
                                "rand_x": {"name": "Normal", "mu": 0, "sigma": 1, "initval": 0},
                                "rand_x|subID": {"name": "Normal",
                                    "mu": 0,
                                    "sigma": {"name": "HalfNormal",
                                        "sigma": 0.5
                                        }, "initval": 0.5
                                    },
                                "1|subID": {"name": "Normal",
                                    "mu": 0,
                                    "sigma": {"name": "HalfNormal",
                                        "sigma": 1
                                        }, "initval": 0.3
                                    }
                            },
                            "link": "identity"
                        },
                        {
                            "name": "z",                            
                            "formula": "z ~ 1 + rand_x + (1 + rand_x|subID)",
                            "prior": {
                                "Intercept": {"name": "HalfNormal", "sigma": 1, "initval": .5},
                                "rand_x": {"name": "Normal", "mu": 0, "sigma": 1, "initval": 0},
                                "rand_x|subID": {"name": "Normal",
                                    "mu": 0,
                                    "sigma": {"name": "HalfNormal",
                                        "sigma": 0.5
                                        }, "initval": 0.5
                                    },
                                "1|subID": {"name": "Normal",
                                    "mu": 0,
                                    "sigma": {"name": "HalfNormal",
                                        "sigma": 0.05
                                        }, "initval": 0.01
                                    }
                            },
                            "link": "identity"
                        }
                    ],
                )
            else:
                model_ddm_rand = hssm.HSSM(
                    data=sim_data_concat,                
                    prior_settings="safe",
                    include=[
                        {
                            "name": "v",                            
                            "formula": "v ~ 1 + rand_x + (1 + rand_x|subID)",
                            "prior": {
                                "Intercept": {"name": "Normal", "mu": 1, "sigma": 2, "initval": 1},
                                "rand_x": {"name": "Normal", "mu": 0, "sigma": 1, "initval": 0},
                                "rand_x|subID": {"name": "Normal",
                                    "mu": 0,
                                    "sigma": {"name": "HalfNormal",
                                        "sigma": 0.5
                                        }, "initval": 0.5
                                    },
                                "1|subID": {"name": "Normal",
                                    "mu": 0,
                                    "sigma": {"name": "HalfNormal",
                                        "sigma": 1
                                        }, "initval": 0.5
                                    }
                            },
                            "link": "identity"
                        },
                        {
                            "name": "a",                            
                            "formula": "a ~ 1 + rand_x + (1 + rand_x|subID)",
                            "prior": {
                                "Intercept": {"name": "Normal", "mu": 1, "sigma": 1.75, "initval": 1},
                                "rand_x": {"name": "Normal", "mu": 0, "sigma": 1, "initval": 0},
                                "rand_x|subID": {"name": "Normal",
                                    "mu": 0,
                                    "sigma": {"name": "HalfNormal",
                                        "sigma": 0.5
                                        }, "initval": 0.5
                                    },
                                "1|subID": {"name": "Normal",
                                    "mu": 0,
                                    "sigma": {"name": "HalfNormal",
                                        "sigma": 1
                                        }, "initval": 0.3
                                    }
                            },
                            "link": "identity"
                        },
                        {
                            "name": "z",                            
                            "formula": "z ~ 1 + rand_x + (1 + rand_x|subID)",
                            "prior": {
                                "Intercept": {"name": "HalfNormal", "sigma": 1, "initval": .5},
                                "rand_x": {"name": "Normal", "mu": 0, "sigma": 1, "initval": 0},
                                "rand_x|subID": {"name": "Normal",
                                    "mu": 0,
                                    "sigma": {"name": "HalfNormal",
                                        "sigma": 0.5
                                        }, "initval": 0.5
                                    },
                                "1|subID": {"name": "Normal",
                                    "mu": 0,
                                    "sigma": {"name": "HalfNormal",
                                        "sigma": 0.05
                                        }, "initval": 0.01
                                    }
                            },
                            "link": "identity"
                        },
                        {
                            "name": "t",                            
                            "formula": "t ~ 1 + rand_x + (1 + rand_x|subID)",
                            "prior": {
                                "Intercept": {"name": "Normal", "mu": 0.5, "sigma": 0.4, "initval": 0.3},
                                "rand_x": {"name": "Normal", "mu": 0, "sigma": 1, "initval": 0},
                                "rand_x|subID": {"name": "Normal",
                                    "mu": 0,
                                    "sigma": {"name": "HalfNormal",
                                        "sigma": 0.5
                                        }, "initval": 0.5
                                    },
                                "1|subID": {"name": "Normal",
                                    "mu": 0,
                                    "sigma": {"name": "HalfNormal",
                                        "sigma": 0.5,  "initval": 0.1
                                        },
                                    }
                            },
                            "link": "identity"
                        }
                    ],
                )
            
            # infer_data_race4nba_v_rand = model_race4nba_v_rand.sample(step=pm.Slice(model=model_race4nba_v_rand.pymc_model), sampler="mcmc", chains=4, cores=4, draws=5000, tune=10000,idata_kwargs = {'log_likelihood': True})
            infer_data_ddm_rand = model_ddm_rand.sample(sampler="nuts_numpyro", chains=4, cores=ncores, draws=samples, tune=burnin,idata_kwargs = {'log_likelihood': True}, target_accept=TA)
            # az.to_netcdf(infer_data_race4nba_v_rand,outdir+'sample_5000_10000_trace_ParamInbound_Fixed_az_SliceSampler_rand.nc4')
            az.to_netcdf(infer_data_ddm_rand,outdir+'sample_' + str(burnin) + '_' + str(samples) + '_trace_ParamInbound_ddm_NutsNumpyro_rand_' + 't-strat_' + str(tstrat) + '.nc4')
            az.plot_trace(
                infer_data_ddm_rand,
                var_names="~log_likelihood",  # we exclude the log_likelihood traces here
            )
            # plt.savefig(outdir+'posterior_diagnostic_5000_10000_trace_ParamInbound_Fixed_az_SliceSampler_rand.png')
            plt.savefig(outdir+'posterior_diagnostic_' + str(burnin) + '_' + str(samples) + '_trace_ParamInbound_ddm_NutsNumpyro_rand_' + 't-strat_' + str(tstrat) + '.png')
            res_sum_rand=az.summary(model_ddm_rand.traces)
            # res_sum_rand.to_csv(outdir+'summary_5000_10000_trace_ParamInbound_Fixed_az_SliceSampler_rand.csv')
            res_sum_rand.to_csv(outdir+'summary_' + str(burnin) + '_' + str(samples) + '_trace_ParamInbound_ddm_NutsNumpyro_rand_' + 't-strat_' + str(tstrat) + '.csv')



