#generate data using race_4 model, there are separate v and z for each accumulator, but a and t are shared
#from ssms.basic_simulators import simulator
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

    ##----------------------------------------------parse arguments -----------------------------------##
    parser = argparse.ArgumentParser(description='Simulate data and fit HSSM model')
    parser.add_argument('--samples', type=str, help='how many samples to draw from MCMC chains',default=5000)
    parser.add_argument('--burnin', type=str, help='how many samples to burn in from MCMC chains',default=5000)
    parser.add_argument('--cores', type=str, help='how many CPU/GPU cores to use for sampling',default=4)
    parser.add_argument('--model', type=str, help='which model to run')
    parser.add_argument('--regressor', type=str, help='which parameter to regress on',default='v')
    parser.add_argument('--outdir', type=str, help='outpu directory to save results',default='/scratch/hyang336/working_dir/HDDM_HSSM/DDM_simulations/')
    parser.add_argument('--TA', type=str, help='target_accept for NUTS sampler',default=0.8)
    parser.add_argument('--run', type=str, help='whether to run the sampler or just plot data distribution and prior predict',default='sample')
    parser.add_argument('--tstrat', type=str, help='how to handle issue on the t paramter',default='clip')
    args = parser.parse_args()

    model_type=args.model # 'true' or 'null', the random seed setting means the rand model was the same as true model...
    regressor=args.regressor
    outdir=args.outdir
    samples=int(args.samples)
    burnin=int(args.burnin)
    ncores=int(args.cores)
    TA=float(args.TA)
    tstrat=args.tstrat # 'clip' or 'RThack' or 'norandom' or 'clipnorandom' or 'RThacknorandom'
    run=args.run # 'sample' or 'prior_predict'

    # print out the arguments for debugging
    print('model:',model_type)
    print('outdir:',outdir)
    print('samples:',samples)
    print('burnin:',burnin)
    print('ncores:',ncores)
    print('TA:',TA)
    print('regressor:',regressor)
    print('tstrat:',tstrat)
    print('run:',run)

    # make the output directory if it doesn't exist
    if not os.path.exists(outdir):
        os.makedirs(outdir)

    #--------------------------------------Generate parameters and simulate data--------------------------------###
    # v in [-3, 3]
    v_intercept_mu=1.25 #normal
    v_slope_mu=0.3 #normal
    v_sigma=0.2 

    # a in [0.3, 2.5]
    a_intercept_a=1.5 #gamma with mean at 1.5
    a_intercept_b=1
    a_slope_mu=0.3 #normal
    a_slope_sigma=0.2

    # z in [0, 1]
    z_intercept_a=10 #beta with mean at 0.5
    z_intercept_b=10
    z_slope_mu=0.1 #normal
    z_slope_sigma=0.01

    # t in [0, 2]
    t_intercept_a=60 #gamma with mean at 0.5, variance at 0.0042
    t_intercept_b=120
    t_slope_mu=0.3 #normal
    t_slope_sigma=0.1

    n_subjects=30 #number of subjects
    n_trials=100 #number of trials per subject

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
        # generate neural data, standard normal as the real data, and 
        simneural=np.random.normal(size=n_trials)

        # generate v a z t based on regressor argument
        if regressor=='v':
            v_intercept=np.random.normal(loc=v_intercept_mu, scale=v_sigma, size=1)
            v_slope=np.random.normal(loc=v_slope_mu, scale=v_sigma, size=1)
            a_intercept=np.random.gamma(shape=a_intercept_a, scale=1/a_intercept_b, size=1) #numpy use scale parameterization
            z_intercept=np.random.beta(a=z_intercept_a, b=z_intercept_b, size=1)
            t_intercept=np.random.gamma(shape=t_intercept_a, scale=1/t_intercept_b, size=1)
            v=v_intercept+v_slope*simneural
            a=np.repeat(a_intercept, n_trials)
            z=np.repeat(z_intercept, n_trials)
            t=np.repeat(t_intercept, n_trials)
        elif regressor=='a':
            v_intercept=np.random.normal(loc=v_intercept_mu, scale=v_sigma, size=1)
            a_intercept=np.random.gamma(shape=a_intercept_a, scale=1/a_intercept_b, size=1)
            a_slope=np.random.normal(loc=a_slope_mu, scale=a_slope_sigma, size=1)
            z_intercept=np.random.beta(a=z_intercept_a, b=z_intercept_b, size=1)
            t_intercept=np.random.gamma(shape=t_intercept_a, scale=1/t_intercept_b, size=1)
            v=np.repeat(v_intercept, n_trials)
            a=a_intercept+a_slope*simneural
            z=np.repeat(z_intercept, n_trials)
            t=np.repeat(t_intercept, n_trials)
        elif regressor=='z':
            v_intercept=np.random.normal(loc=v_intercept_mu, scale=v_sigma, size=1)
            a_intercept=np.random.gamma(shape=a_intercept_a, scale=1/a_intercept_b, size=1)
            z_intercept=np.random.beta(a=z_intercept_a, b=z_intercept_b, size=1)
            z_slope=np.random.normal(loc=z_slope_mu, scale=z_slope_sigma, size=1)
            t_intercept=np.random.gamma(shape=t_intercept_a, scale=1/t_intercept_b, size=1)
            v=np.repeat(v_intercept, n_trials)
            a=np.repeat(a_intercept, n_trials)
            z=z_intercept+z_slope*simneural
            t=np.repeat(t_intercept, n_trials)
        elif regressor=='t':
            v_intercept=np.random.normal(loc=v_intercept_mu, scale=v_sigma, size=1)
            a_intercept=np.random.gamma(shape=a_intercept_a, scale=1/a_intercept_b, size=1)
            z_intercept=np.random.beta(a=z_intercept_a, b=z_intercept_b, size=1)
            t_intercept=np.random.gamma(shape=t_intercept_a, scale=1/t_intercept_b, size=1)
            t_slope=np.random.normal(loc=t_slope_mu, scale=t_slope_sigma, size=1)
            v=np.repeat(v_intercept, n_trials)
            a=np.repeat(a_intercept, n_trials)
            z=np.repeat(z_intercept, n_trials)
            t=t_intercept+t_slope*simneural

        # no clipping, adjust generating parameters to avoid extreme values
        # v = np.clip(v, -3, 3)
        # a = np.clip(a_i, 0.3, 2.5)
        # z = np.clip(z_i, 0, 1)

        if tstrat=='clip' or tstrat=='clipnorandom':
            t = np.clip(t, 0.3, 2)

        # simulate RT and choices
        true_values = np.column_stack([v,a,z,t])

        # save to subject_params
        subject_params["v"]=np.append(subject_params["v"],v)
        subject_params["a"]=np.append(subject_params["a"],a)
        subject_params["z"]=np.append(subject_params["z"],z)
        subject_params["t"]=np.append(subject_params["t"],t)
        subject_params["simneural"]=np.append(subject_params["simneural"],simneural)
        subject_params["subID"]=np.append(subject_params["subID"],np.repeat(i,len(simneural)))

        # Get model simulations
        ddm_all = hssm.simulate_data(model="ddm", theta=true_values, size=1)        
        
        if tstrat=='RThack' or tstrat=='RThacknorandom':
            sim_data.append(
                pd.DataFrame(
                    {
                        "rt": ddm_all["rt"] + 0.3,
                        "response": ddm_all["response"],
                        "x": simneural,                                        
                        "subID": i
                    }
                )
            )
        else:
            sim_data.append(
                pd.DataFrame(
                    {
                        "rt": ddm_all["rt"],
                        "response": ddm_all["response"],
                        "x": simneural,                  
                        "subID": i
                    }
                )
            )

    #make a single dataframe of subject-wise simulated data
    sim_data_concat=pd.concat(sim_data)

    #save subject-wise parameters
    param_df=pd.DataFrame(subject_params)
    param_df.to_csv(outdir+'simulation_binary022_simple' + '_regressor_' + str(regressor) + '_t-strat_' + str(tstrat) + '_subject_params.csv')
    
    #Plot the RT distributions in the simulated data for each subject
    fig, ax = plt.subplots(1, 1, figsize=(12, 6))
    for i in range(n_subjects):
        sim_data_concat[sim_data_concat["subID"]==i]["rt"].hist(bins=100, alpha=0.5, ax=ax)
    ax.set_title("RT distribution")
    ax.set_xlabel("RT")
    ax.set_ylabel("Frequency")
    plt.tight_layout()
    plt.savefig(outdir+'RT_distribution_' + 'regressor_' + str(regressor) + '_t-strat_' + str(tstrat) + '.png')
    plt.close()

    #plot the distribution of the parameters and the regressor
    fig, ax = plt.subplots(1, 4, figsize=(12, 6))
    ax[0].hist(subject_params["v"], bins=100)
    ax[0].set_title("v distribution")
    ax[1].hist(subject_params["a"], bins=100)
    ax[1].set_title("a distribution")
    ax[2].hist(subject_params["z"], bins=100)
    ax[2].set_title("z distribution")
    ax[3].hist(subject_params["t"], bins=100)
    ax[3].set_title("t distribution")
    plt.tight_layout()
    plt.savefig(outdir+'param_distribution_' + 'regressor_' + str(regressor) + '_t-strat_' + str(tstrat) + '.png')
    plt.close()

    ##------------------------- Specify formula and prior based on model and regressor -------------------##
    if model_type=='true':
        reg_key="x"
    elif model_type=='null':
        reg_key=None
    
    if reg_key is not None:
        match regressor:
            case 'v':
                v_form= f"v ~ 1 + {reg_key} + (1 + {reg_key}|subID)"
                a_form= "a ~ 1 + (1|subID)"
                z_form= "z ~ 1 + (1|subID)"
                t_form= "t ~ 1 + (1|subID)"
                v_prior={
                            "Intercept": {"name": "Normal", "mu": 1, "sigma": 2, "initval": 1},
                            f"{reg_key}": {"name": "Normal", "mu": 0, "sigma": 1, "initval": 0},
                            f"{reg_key}|subID": {"name": "Normal",
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
                        }
                a_prior={
                            "Intercept": {"name": "Gamma", "mu": 0.5, "sigma": 1.75, "initval": 1},                                
                            "1|subID": {"name": "Normal",
                                "mu": 0,
                                "sigma": {"name": "HalfNormal",
                                    "sigma": 1
                                    }, "initval": 0.3
                                }
                        }
                z_prior={
                            "Intercept": {"name": "HalfNormal", "sigma": 1, "initval": .5},
                            "1|subID": {"name": "Normal",
                                "mu": 0,
                                "sigma": {"name": "HalfNormal",
                                    "sigma": 0.05
                                    }, "initval": 0.01
                                }
                        }
                t_prior={
                            "Intercept": {"name": "Gamma", "mu": 0.4, "sigma": 0.2, "initval": 0.3},
                            "1|subID": {"name": "Normal",
                                "mu": 0,
                                "sigma": {"name": "HalfNormal",
                                    "sigma": 0.03, "initval": .01
                                    },
                                },
                        }
                link_func="identity"
            case 'a':
                v_form= "v ~ 1 + (1|subID)"
                a_form= f"a ~ 1 + {reg_key} + (1 + {reg_key}|subID)"
                z_form= "z ~ 1 + (1|subID)"
                t_form= "t ~ 1 + (1|subID)"
                v_prior={
                            "Intercept": {"name": "Normal", "mu": 1, "sigma": 2, "initval": 1},
                            "1|subID": {"name": "Normal",
                                "mu": 0,
                                "sigma": {"name": "HalfNormal",
                                    "sigma": 1
                                    }, "initval": 0.5
                                }
                        }
                a_prior={
                            "Intercept": {"name": "Gamma", "mu": 0.5, "sigma": 1.75, "initval": 1},                                
                            f"{reg_key}": {"name": "Normal", "mu": 0, "sigma": 1, "initval": 0},
                            f"{reg_key}|subID": {"name": "Normal",
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
                        }
                z_prior={
                            "Intercept": {"name": "HalfNormal", "sigma": 1, "initval": .5},
                            "1|subID": {"name": "Normal",
                                "mu": 0,
                                "sigma": {"name": "HalfNormal",
                                    "sigma": 0.05
                                    }, "initval": 0.01
                                }
                        }
                t_prior={
                            "Intercept": {"name": "Gamma", "mu": 0.4, "sigma": 0.2, "initval": 0.3},
                            "1|subID": {"name": "Normal",
                                "mu": 0,
                                "sigma": {"name": "HalfNormal",
                                    "sigma": 0.03, "initval": .01
                                    },
                                },
                        }
                link_func="identity" 
            case 'z':
                v_form= "v ~ 1 + (1|subID)"
                a_form= "a ~ 1 + (1|subID)"
                z_form= f"z ~ 1 + {reg_key} + (1 + {reg_key}|subID)"
                t_form= "t ~ 1 + (1|subID)"
                v_prior={
                            "Intercept": {"name": "Normal", "mu": 1, "sigma": 2, "initval": 1},
                            "1|subID": {"name": "Normal",
                                "mu": 0,
                                "sigma": {"name": "HalfNormal",
                                    "sigma": 1
                                    }, "initval": 0.5
                                }
                        }
                a_prior={
                            "Intercept": {"name": "Gamma", "mu": 0.5, "sigma": 1.75, "initval": 1},                               
                            "1|subID": {"name": "Normal",
                                "mu": 0,
                                "sigma": {"name": "HalfNormal",
                                    "sigma": 1
                                    }, "initval": 0.3
                                }
                        }
                z_prior={
                            "Intercept": {"name": "HalfNormal", "sigma": 1, "initval": .5},                                
                            f"{reg_key}": {"name": "Normal", "mu": 0, "sigma": 1, "initval": 0},
                            f"{reg_key}|subID": {"name": "Normal",
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
                        }
                t_prior={
                            "Intercept": {"name": "Gamma", "mu": 0.4, "sigma": 0.2, "initval": 0.3},
                            "1|subID": {"name": "Normal",
                                "mu": 0,
                                "sigma": {"name": "HalfNormal",
                                    "sigma": 0.03, "initval": .01
                                    },
                                },
                        }
                link_func="identity"
            case 't':
                v_form= "v ~ 1 + (1|subID)"
                a_form= "a ~ 1 + (1|subID)"
                z_form= "z ~ 1 + (1|subID)"
                t_form= f"t ~ 1 + {reg_key} + (1 + {reg_key}|subID)"
                v_prior={
                            "Intercept": {"name": "Normal", "mu": 1, "sigma": 2, "initval": 1},
                            "1|subID": {"name": "Normal",
                                "mu": 0,
                                "sigma": {"name": "HalfNormal",
                                    "sigma": 1
                                    }, "initval": 0.5
                                }
                        }
                a_prior={
                            "Intercept": {"name": "Gamma", "mu": 0.5, "sigma": 1.75, "initval": 1},                               
                            "1|subID": {"name": "Normal",
                                "mu": 0,
                                "sigma": {"name": "HalfNormal",
                                    "sigma": 1
                                    }, "initval": 0.3
                                }
                        }
                z_prior={
                            "Intercept": {"name": "HalfNormal", "sigma": 1, "initval": .5},
                            "1|subID": {"name": "Normal",
                                "mu": 0,
                                "sigma": {"name": "HalfNormal",
                                    "sigma": 0.05
                                    }, "initval": 0.01
                                }
                        }
                t_prior={
                            "Intercept": {"name": "Gamma", "mu": 0.4, "sigma": 0.2, "initval": 0.3},                                
                            f"{reg_key}": {"name": "Normal", "mu": 0, "sigma": 1, "initval": 0},
                            f"{reg_key}|subID": {"name": "Normal",
                                "mu": 0,
                                "sigma": {"name": "HalfNormal",
                                    "sigma": 0.5
                                    }, "initval": 0.5
                                }, 
                            "1|subID": {"name": "Normal",
                                "mu": 0,
                                "sigma": {"name": "HalfNormal",
                                    "sigma": 0.03, "initval": .01
                                    },
                                },
                        }
                link_func="identity"
    else:
        v_form= "v ~ 1 + (1|subID)"
        a_form= "a ~ 1 + (1|subID)"
        z_form= "z ~ 1 + (1|subID)"
        t_form= "t ~ 1 + (1|subID)"
        v_prior={
                    "Intercept": {"name": "Normal", "mu": 1, "sigma": 2, "initval": 1},
                    "1|subID": {"name": "Normal",
                        "mu": 0,
                        "sigma": {"name": "HalfNormal",
                            "sigma": 1
                            }, "initval": 0.5
                        }
                }
        a_prior={
                    "Intercept": {"name": "Gamma", "mu": 0.5, "sigma": 1.75, "initval": 1},                               
                    "1|subID": {"name": "Normal",
                        "mu": 0,
                        "sigma": {"name": "HalfNormal",
                            "sigma": 1
                            }, "initval": 0.3
                        }
                }
        z_prior={
                    "Intercept": {"name": "HalfNormal", "sigma": 1, "initval": .5},
                    "1|subID": {"name": "Normal",
                        "mu": 0,
                        "sigma": {"name": "HalfNormal",
                            "sigma": 0.05
                            }, "initval": 0.01
                        }
                }
        t_prior={
                    "Intercept": {"name": "Gamma", "mu": 0.4, "sigma": 0.2, "initval": 0.3},
                    "1|subID": {"name": "Normal",
                        "mu": 0,
                        "sigma": {"name": "HalfNormal",
                            "sigma": 0.03, "initval": .01
                            },
                        },
                }
        link_func="identity"
    
    ##-------------------------------- Define the models --------------------------------###
    if tstrat=='norandom' or tstrat=='clipnorandom' or tstrat=='RThacknorandom':
        model = hssm.HSSM(
            data=sim_data_concat,                
            prior_settings="safe",
            include=[
                {
                    "name": "v",                            
                    "formula": v_form,
                    "prior": v_prior,
                    "link": link_func
                },
                {
                    "name": "a",                            
                    "formula": a_form,
                    "prior": a_prior,
                    "link": link_func
                },
                {
                    "name": "z",                            
                    "formula": z_form,
                    "prior": z_prior,
                    "link": link_func
                }
            ],
        )
    else:
        model = hssm.HSSM(
            data=sim_data_concat,                
            prior_settings="safe",
            include=[
                {
                    "name": "v",                            
                    "formula": v_form,
                    "prior": v_prior,
                    "link": link_func
                },
                {
                    "name": "a",                            
                    "formula": a_form,
                    "prior": a_prior,
                    "link": link_func
                },
                {
                    "name": "z",                            
                    "formula": z_form,
                    "prior": z_prior,
                    "link": link_func
                },
                {
                    "name": "t",                            
                    "formula": t_form,
                    "prior": t_prior,
                    "link": link_func
                }
            ],
        )
    
    #--------------------------------------Fit the model--------------------------------###
                
    if run=='sample':
        #fit the model    
        infer_data_ddm = model.sample(sampler="nuts_numpyro", chains=4, cores=ncores, draws=samples, tune=burnin,idata_kwargs = {'log_likelihood': True}, target_accept=TA)
        
        az.to_netcdf(infer_data_ddm,outdir+'sample_' + str(burnin) + '_' + str(samples) + 'TA_' + str(TA) + '_trace_ParamInbound_ddm_simple_NutsNumpyro_' + str(model_type) + 'regress_' + str(regressor) + '_t-strat_' + str(tstrat) + '.nc4')
        az.plot_trace(
            infer_data_ddm,
            var_names="~log_likelihood",  # we exclude the log_likelihood traces here
        )
        plt.savefig(outdir+'posterior_diagnostic_' + str(burnin) + '_' + str(samples) + 'TA_' + str(TA) + '_trace_ParamInbound_ddm_simple_NutsNumpyro_' + str(model) + 'regress_' + str(regressor) + '_t-strat_' + str(tstrat) + '.png')
        res_sum=az.summary(model.traces)
        res_sum.to_csv(outdir+'summary_' + str(burnin) + '_' + str(samples) + 'TA_' + str(TA) + '_trace_ParamInbound_ddm_simple_NutsNumpyro_' + str(model_type) + 'regress_' + str(regressor) + '_t-strat_' + str(tstrat) + '.csv')
    elif run=='prior_predict':
        #HSSM prior predict method
        prior_predict=model.sample_prior_predictive(draws=1000,omit_offsets=False)
        az.to_netcdf(prior_predict,outdir+'prior_predict_ddm_simple_' + str(model_type) + 'regress_' + str(regressor) + '_t-strat_' + str(tstrat) + '.nc4')


