# posterior diagnostics and results for HSSM model
import numpy as np
import pandas as pd
import hssm
import arviz as az
from matplotlib import pyplot as plt
import os
import argparse

#models
model_file='/scratch/hyang336/working_dir/HDDM_HSSM/resp_binarized/sample_10000_10000_TA_0.8_trace_median-binarized_t-strat_norandom_recent_v_on_null.nc4'

#empirical data
fam_data = pd.read_csv('/scratch/hyang336/working_dir/HDDM_HSSM/HSSM_freq_MedianBin_data.csv')

# load model and plot pair plots
inf_data=az.from_netcdf(model_file)

#increase the maximum number of subplots
az.rcParams["plot.max_subplots"] = 200

subIDs=inf_data.posterior.data_vars['a_1|subj_idx'].subj_idx__factor_dim.values
#plot pair plots for each subject
for subID in subIDs:
    az.plot_pair(inf_data,var_names=['a_Intercept','a_1|subj_idx','a_1|subj_idx_sigma','v_Intercept','v_1|subj_idx','v_1|subj_idx_sigma','z_Intercept','z_1|subj_idx','z_1|subj_idx_sigma','t'],divergences=True,coords={'subj_idx__factor_dim':str(subID),'v_1|subj_idx__factor_dim':str(subID)})
    plt.savefig('/scratch/hyang336/working_dir/HDDM_HSSM/resp_binarized/sub-'+str(subID)+'.png')
    plt.close()

#posterior check, need to recreate exactly the same model
fam_data = pd.read_csv('/scratch/hyang336/working_dir/HDDM_HSSM/HSSM_freq_MedianBin_data.csv')
sim_data = fam_data[['subj_idx','rt','bin_rating','bin_scheme']]
# rename the rating column to response
sim_data = sim_data.rename(columns={'bin_rating':'response'})
data = pd.DataFrame({
            'rt':sim_data['rt'],
            'response':sim_data['response'],
            'subj_idx':sim_data['subj_idx']
        })
##Priors following Dr. Frank's suggestion
v_intercept_prior = {
    "Intercept": {"name": "Normal", "mu": 1, "sigma": 2, "initval": 1},
    "1|subj_idx": {"name": "Normal",
        "mu": 0, # using non-centered approach so mu's of indiv subject offsets should be 0
        "sigma": {"name": "HalfNormal",
            "sigma": 1
            }, "initval": 0.5
        },
}
v_slope_prior = {
    "Intercept": {"name": "Normal", "mu": 1, "sigma": 2, "initval": 1},
    "x": {"name": "Normal", "mu": 0, "sigma": 1, "initval": 0},
    "x|subj_idx": {"name": "Normal",
        "mu": 0,
        "sigma": {"name": "HalfNormal",
            "sigma": 0.5,
            }, "initval": 0.5
        },
    "1|subj_idx": {"name": "Normal",
        "mu": 0,
        "sigma": {"name": "HalfNormal",
            "sigma": 1, "initval": 0.3
            },
        },
}

a_intercept_prior = {
    "Intercept": {"name": "Gamma", "mu": 1.5, "sigma": 0.75, "initval": 1},
    "1|subj_idx": {"name": "Normal",
        "mu": 0,
        "sigma": {"name": "HalfNormal",
            "sigma": 1, "initval": 0.3
            },
        },
}
a_slope_prior = {
    "Intercept": {"name": "Gamma", "mu": 1.5, "sigma": 0.75, "initval": 1},
    "x": {"name": "Normal", "mu": 0, "sigma": 1, "initval": 0},
    "x|subj_idx": {"name": "Normal",
        "mu": 0,
        "sigma": {"name": "HalfNormal",
            "sigma": 0.5,
            }, "initval": 0.5
        },
    "1|subj_idx": {"name": "Normal",
        "mu": 0,
        "sigma": {"name": "HalfNormal",
            "sigma": 1, "initval": 0.3
            },
        },
}

z_intercept_prior = {
    "Intercept": {"name": "Beta", "alpha": 5, "beta": 5, "initval": .5},
    "1|subj_idx": {"name": "Normal",
        "mu": 0,
        "sigma": {"name": "HalfNormal",
            "sigma": 0.05, "initval": .01
            },
        },
}
z_slope_prior = {
    "Intercept": {"name": "Beta", "alpha": 5, "beta": 5, "initval": .5},
    "x": {"name": "Normal", "mu": 0, "sigma": 1, "initval": 0},
    "x|subj_idx": {"name": "Normal",
        "mu": 0,
        "sigma": {"name": "HalfNormal",
            "sigma": 0.5,
            }, "initval": 0.5
        },
    "1|subj_idx": {"name": "Normal",
        "mu": 0,
        "sigma": {"name": "HalfNormal",
            "sigma": 0.05, "initval": .01
            },
        },
}

t_intercept_prior = {
    "Intercept": {"name": "Gamma", "mu": 0.4, "sigma": 0.2, "initval": 0.3},
    "1|subj_idx": {"name": "Normal",
        "mu": 0,
        "sigma": {"name": "HalfNormal",
            "sigma": 0.03, "initval": .01
            },
        },
}
t_slope_prior = {
    "Intercept": {"name": "Gamma", "mu": 0.4, "sigma": 0.2, "initval": 0.3},
    "x": {"name": "Normal", "mu": 0, "sigma": 1, "initval": 0},
    "x|subj_idx": {"name": "Normal",
        "mu": 0,
        "sigma": {"name": "HalfNormal",
            "sigma": 0.5, "initval": 0.5
            }
        },
    "1|subj_idx": {"name": "Normal",
        "mu": 0,
        "sigma": {"name": "HalfNormal",
            "sigma": 0.03, "initval": .01
            },
        },
}

# create the model
model= hssm.HSSM(
        data=data,
        prior_settings="safe",
        include=[
            {
                "name": "v",
                "formula": "v ~ 1 + (1|subj_idx)",
                "prior": v_intercept_prior,
                "link": "identity",
            },
            {
                "name": "a",
                "formula": "a ~ 1 + (1|subj_idx)",
                "prior": a_intercept_prior,
                "link": "identity",
            },
            {
                "name": "z",
                "formula": "z ~ 1 + (1|subj_idx)",
                "prior": z_intercept_prior,
                "link": "identity",
            }
        ],
    )

model._inference_obj=inf_data
model.sample_posterior_predictive()

# pull out posterior predictive samples
pps=inf_data.posterior_predictive['rt,response'].values

#reshape to combine different chains
pps=pps.reshape(-1,pps.shape[3])

#plot pps RT as subplot histograms for response option -1 and 1
plt.close()
fig, ax = plt.subplots(1, 2, figsize=(10, 5))
ax[0].hist(pps[pps[:,1] == 1,0], bins=100, color='blue', alpha=0.5, label='resp 1')
ax[0].legend()
ax[1].hist(pps[pps[:,1] == -1,0], bins=100, color='red', alpha=0.5, label='resp -1')
ax[1].legend()
plt.savefig('/scratch/hyang336/working_dir/HDDM_HSSM/resp_binarized/RT_distribution_PPS_median-binarized_t-strat_norandom_recent_v_on_null.png')
# import arviz as az
# import matplotlib.pyplot as plt

# nm=az.from_netcdf('/scratch/hyang336/working_dir/HDDM_HSSM/resp_binarized/sample_10000_10000_TA_0.8_trace_median-binarized_t-strat_norandom_recent_v_on_null.nc4')
# az.rcParams["plot.max_subplots"] = 200
# az.plot_pair(nm,var_names=['a_Intercept','a_1|subj_idx','a_1|subj_idx_sigma','v_Intercept','v_1|subj_idx','v_1|subj_idx_sigma','z_Intercept','z_1|subj_idx','z_1|subj_idx_sigma','t'],divergences=True,coords={'subj_idx__factor_dim':'1','v_1|subj_idx__factor_dim':'1'})
# plt.savefig('/scratch/hyang336/working_dir/HDDM_HSSM/resp_binarized/null_model_sub-1.png')

