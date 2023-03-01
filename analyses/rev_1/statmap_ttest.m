%% HY: custom one-tail t-test feature selection function built based on statmap_template.m

function [subj] = statmap_ttest(subj,data_patname,regsname,selname,new_map_patname,varargin)

% This is the sample/template statmap generation function
% %todo synopsis
%
% [SUBJ] = STATMAP_TEMPLATE(SUBJ,DATA_PATNAME,REGSNAME,SELNAME,NEW_MAP_PATNAME,EXTRA_ARG)
%          %todo function header
%
% Adds the following objects:
% - statmap pattern object
%
% Updates the subject structure by creating a new pattern,
% NEW_MAP_PATNAME, that contains a vector of P-values (for example)
%
% See STATMAP_ANOVA for a real example script %todo
%
% Uses all the conditions in REGSNAME. If you only want to use a
% subset of them, create a new regressors object with only those
% conditions
%
% Only uses those TRs labelled with a 1 in the SELNAME selector,
% and where there's an active condition in the REGSNAME regressors matrix
%
% All statmaps that can be used by FEATURE_SELECT have to take the
% extra_arg which can store any info your statmap might need
%
% EXTRA_ARG (optional, default = []). This could do anything, and
% the default could be anything. STATMAP_ANOVA.M ignores this, but
% other statmap functions might need it. %todo
%
% See the section on creating your own statmap in the manual %todo

% License:
%=====================================================================
%
% This is part of the Princeton MVPA toolbox, released under
% the GPL. See http://www.csbmb.princeton.edu/mvpa for more
% information.
%
% The Princeton MVPA toolbox is available free and
% unsupported to those who might find it useful. We do not
% take any responsibility whatsoever for any problems that
% you have related to the use of the MVPA toolbox.
%
% ======================================================================

if nargin<6
    error('Need 6 arguments, even if extra_arg is empty');
end

defaults.cur_iteration = NaN;
defaults.use_mvpa_ver = false;
defaults.tail='right'; %by default test for x is greater than y in ttest2(x,y)
args = propval(varargin,defaults);

pat  = get_mat(subj,'pattern',data_patname);
regs = get_mat(subj,'regressors',regsname);
sel  = get_mat(subj,'selector',selname);

sanity_check(pat,regs,sel,args);

TRs_to_use = find(sel==1);

% Note: don't forget to exclude rest timepoints, unless your
% function definitely requires them

pat   = pat(:,TRs_to_use);
regs = regs(:,TRs_to_use);

% statmap_anova.m has this option to call anova1_mvpa.m, which is another
% custom function that runs a slightly different anova, in this script im
% ignoring this option
p=run_mathworks_ttest(pat,regs,args);

% Now create a new pattern object to house the statmap with the p
% values in it
subj = init_object(subj,'pattern',new_map_patname);
subj = set_mat(subj,'pattern',new_map_patname,p);

% Every pattern needs to know which mask it is masked by
masked_by = get_objfield(subj,'pattern',data_patname,'masked_by');
subj = set_objfield(subj,'pattern',new_map_patname,'masked_by',masked_by);

hist = sprintf('Created by %s',mfilename());
subj = add_history(subj,'pattern',new_map_patname,hist);

created.function = mfilename();
created.data_patname = data_patname;
created.regsname = regsname;
created.selname = selname;
created.new_map_patname = new_map_patname;
created.args = args;
subj = add_created(subj,'pattern',new_map_patname,created);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function [p] = run_mathworks_ttest(pat,regs,args)

        % use between-subject stats since in this case each voxel is a "subject"
        % -- building of vector conds and vector groups

        nVox    = size(pat,1);
        nConds  = size(regs,1);
        %groups  = [];
        %dataIdx = [];

        %for c=1:nConds
            dataIdx = find(regs(1,:)==1);%condition 1
            dataIdy = find(regs(2,:)==1);%condition 2
            %dataIdx  =[dataIdx,theseIdx];
            %groups   =[groups,repmat(c,1,length(theseIdx))];
        %end

        % run the anova and save the p's
        p = zeros(nVox,1);

        for j=1:nVox
            if mod(j,10000) == 0
                % disp( sprintf('t-test on %i of %i',j,nVox) );
                fprintf('.');
            end
            [~,pval] = ttest2(pat(j,dataIdx'),pat(j,dataIdy'),'Vartype','unequal','Tail',args.tail);
            p(j)=pval;
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function [] = sanity_check(pat,regs,sel,args)

        keep_idx = find(sel==1);
        regs_actives = regs(:,keep_idx);

        % Check that the timepoints we're going to run feature
        % selection on are in the correct 1-of-n form
        %
        % N.B. your test timepoints might not be 1-of-n, but that's
        % none of our business here
        [isbool isrest isoveractive] = check_1ofn_regressors(regs_actives);
        if ~isbool | isoveractive
            error('Your regressors aren''t in 1-of-n form');
        end

        if size(pat,2) ~= size(regs,2)
            error('Wrong number of timepoints');
        end

        if size(pat,2) ~= size(sel,2)
            error('Wrong number of timepoints');
        end

        if ~isrow(sel)
            error('Your selector needs to be a row vector');
        end

        if max(sel)>2 | min(sel)<0
            disp('These selectors don''t look like cross-validation selectors');
            error('Are you feeding in your runs by accident?');
        end

        if ~length(find(regs)) | ~length(find(sel))
            warning('There''s nothing for the t-test to run on');
        end

        fprintf('Using t-test with %s tail',args.tail);
    end
end