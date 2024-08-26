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

v_intercept_prior_centered = {
    "1|subj_idx": {"name": "Normal",
        "mu": {"name": "Normal",
            "mu": 1,
            "sigma": 2,
            "initval": 1
            },
        "sigma": {"name": "HalfNormal",
            "sigma": 1,
            "initval": 0.5
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