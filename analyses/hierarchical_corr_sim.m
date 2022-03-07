%% simlulate the effect of selecting voxels based on 2nd-level t-test results and then correlate those voxels with interindividual difference
%To simplify, parameter of the distributions are chosen more or less
%arbitrarily, as long as they indicate a qualitative difference between
%having a true effect (mean != 0) and having a null effect (mean == 0)

%the task has two conditions (A and B), participants perform 100 trials on
%under each condition, providing ratings on a 5-point scale. The true
%effect on the behavioral side is that condition B is associated with
%higher ratings than A. The true effect on the neural side is that a region
%is activated more for higher ratings (4,5) than lower ratings (1,2). The
%goal is to test whether by not enforcing any other constraints, the
%effect size of rating in the neural data is correlated with the rating
%difference between B and A across participants.

%number of simulation round
nsim=1000;
%number of subject
nsub=30;
%number of trials per sub
ntrial=200;

% %% Null distribution of cluster-level stats in simulated neural data (based on Kriegstorke et al. 2009)
% for round=1:1000
%     %just noise
%     nulldata=zeros(30,30,20,200)+normrnd(0,2,[30,30,20,200]);
%     %also need to smooth it
%     for x=1:size(nulldata,4)
%         nulldata(:,:,:,x)=smooth3(nulldata(:,:,:,x),'gaussian',3);
%     end
%     
%     
% end

for i=1:nsim
    %% group-level behavioral distribution
    A_dist=normrnd(2,1,nsub,1);%condition A has a mean rating of 2
    B_dist=normrnd(4,1,nsub,1);%condition B has a mean rating of 4
    
    for j=1:nsub
        A_dist_sub=normrnd(A_dist(j),1,ntrial/2,1);%subject-specific distribution of cond A
        B_dist_sub=normrnd(B_dist(j),1,ntrial/2,1);%subject-specific distribution of cond B
        
        %discretize
        r1A=A_dist_sub<1.5;
        r2A=A_dist_sub>=1.5&A_dist_sub<2.5;
        r3A=A_dist_sub>=2.5&A_dist_sub<3.5;
        r4A=A_dist_sub>=3.5&A_dist_sub<4.5;
        r5A=A_dist_sub>=4.5;
        
        r1B=B_dist_sub<1.5;
        r2B=B_dist_sub>=1.5&B_dist_sub<2.5;
        r3B=B_dist_sub>=2.5&B_dist_sub<3.5;
        r4B=B_dist_sub>=3.5&B_dist_sub<4.5;
        r5B=B_dist_sub>=4.5;
        
        A_dist_sub(r1A)=1;
        A_dist_sub(r2A)=2;
        A_dist_sub(r3A)=3;
        A_dist_sub(r4A)=4;
        A_dist_sub(r5A)=5;
        
        B_dist_sub(r1B)=1;
        B_dist_sub(r2B)=2;
        B_dist_sub(r3B)=3;
        B_dist_sub(r4B)=4;
        B_dist_sub(r5B)=5;
        
        %mean rating differences between A and B
        beh_diff(j)=mean(B_dist_sub)-mean(A_dist_sub);
        
        %concatenate A and B conditions and permute to simulate random
        %trial order
        all_trial=[A_dist_sub;B_dist_sub];
        all_trial=all_trial(randperm(length(all_trial)));
        
        %neural data
        v=zeros(30,30,20,ntrial);%initialize neural data, 30x30x20 voxels of ntrials, (each trial is one TR, ignoring the hemodynamic details for now)
        v(15:20,15:20,10:15,all_trial==1)=-2;% a set of voxels showing linear effect of ratings, assuming consistency across subject
        v(15:20,15:20,10:15,all_trial==2)=-1;
        v(15:20,15:20,10:15,all_trial==4)=1;
        v(15:20,15:20,10:15,all_trial==5)=2;
        
        %adding spatiotemporal Gaussian noise
        v=v+normrnd(0,2,size(v));
        
        %smooth voxels (3-by-3-by-3), for normal distribution, the FWHM is
        %about 2.355 std
        for x=1:size(v,4)
            v(:,:,:,x)=smooth3(v(:,:,:,x),'gaussian',3);
        end
        
        %GLM
        X=zeros(ntrial,5);% ntrial by 5 condition (rating) design matrix
        X(all_trial==1,1)=1;%condition present = 1, absent = 0
        X(all_trial==2,2)=1;
        X(all_trial==3,3)=1;
        X(all_trial==4,4)=1;
        X(all_trial==5,5)=1;
        
        %mass univariate regression
        b=NaN(size(v,1),size(v,2),size(v,3),5);
        for x=1:size(v,1)
            for y=1:size(v,2)
                for z=1:size(v,3)
                    b(x,y,z,:)=regress(squeeze(v(x,y,z,:)),X);
                end
            end
        end
        
        %contrast image
        con(:,:,:,j)=(-2)*b(:,:,:,1)+(-1)*b(:,:,:,2)+1*b(:,:,:,4)+2*b(:,:,:,5);
        
    end
    
    %2nd-lvl t-test
    for x=1:size(con,1)
        for y=1:size(con,2)
            for z=1:size(con,3)
                [h,p,ci,stats]=ttest(con(x,y,z,:));
                tmap(x,y,z,:)=stats.tstat;
                pmap(x,y,z,:)=p;
            end
        end
    end
    
    %in my study we are not using cluster-level stats so just use voxel
    %Bonferroni (this would be more conservative than SPM, since SPM
    %"peak-level" stats considers smoothness of the data, so each atomic
    %element is bigger than a voxel)
    [sigx,sigy,sigz]=ind2sub(size(pmap),find(pmap<(0.05/(size(pmap,1)*size(pmap,2)*size(pmap,3)))));
    
    %use the significant voxels to extract subject-specific contrast value
    for voxel=1:length(sigx)
        sigcon(voxel,:)=con(sigx(voxel),sigy(voxel),sigz(voxel),:);%remember 4th dimension is subject
    end
    
    %average across voxel within-subject
    sigcon_avg=mean(sigcon);
    
    %correlation between behavioral (rating difference between condition B
    %and A) and contrast values of linear increase with ratings
    temp=corrcoef(sigcon_avg,beh_diff);
    r(i)=temp(2);
end

%false-positive rate
alpha=sum(r>0.35)/length(r);

