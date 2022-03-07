%number of simulation round
nsim=10000;
%number of subject
nsub=30;
%number of voxel
nvoxel=1000000;

voxel_effect=zeros(nvoxel,1);
voxel_effect(1000:2000)=0.2;%add effect into voxel
for i=1:nsim
    
    for j=1:nsub
        % For each subject, contrast value of 1 million voxels were
        % simulated as true voxel effect (1000 voxel at a fixed location
        % containing a contrast value of 0.2)plus random Gaussian noise        
        b_dist_sub=voxel_effect+normrnd(0,2,nvoxel,1);
        
        % For each subject, the regression slope between frequency error
        % and lifetime ratings is sampled from a group distribution with a
        % mean of 0.4 (i.e. assuming on the group level there is a true
        % effect)
        B_dist_sub(j)=normrnd(0.4,1);
        
        % filter the top 0.1% of voxels based on the contrast value and
        % average
        roi_value(j)=mean(maxk(b_dist_sub,ceil(length(b_dist_sub)*0.001)));     
    end
    
    % Across subject correlation of the regression slope and contrast value
    temp=corrcoef(B_dist_sub,roi_value);
    r(i)=temp(2);
end



