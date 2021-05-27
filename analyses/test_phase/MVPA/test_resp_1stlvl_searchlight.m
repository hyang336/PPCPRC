%% run searchlight classification of high vs. low lifetime and frequency judgement, either combine both tasks into one (sorta like a conjunction ananlysis) or separately


clear variables

% check if decoding.m is in path, otherwise abort
if isempty(which('decoding.m'))
    error('Please add TDT to the matlab path')
end

% initialize TDT & cfg
cfg = decoding_defaults;

%% Set parameters

cfg.analysis = 'searchlight';
cfg.searchlight.radius = 2; % set searchlight size in voxels
% Define whether you want to see the searchlight
cfg.plot_selected_voxels = 0; % all x steps, set 0 for not plotting, 1 for each step, 2 for each 2nd, etc
cfg.plot_design = 1;

cfg.results.output = {'accuracy_minus_chance'}; % Hint: If you like to know the SL size at around a voxel, add 'ninputdim';
cfg.decoding.method = 'classification_kernel';

%% Set the output directory where data will be saved
% cfg.results.dir = % e.g. 'toyresults'
cfg.results.write = 0; % no results are written to disk



