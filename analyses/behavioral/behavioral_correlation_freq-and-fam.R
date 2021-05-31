#correlate frequency judgement with actual presentation frequency, and lifetime fam judgement with normative data.
#using results from my ERP study as background to judge the data quality of the fMRI study.
datapath="C:\\Users\\haozi\\Desktop\\PhD\\fMRI_PrC-PPC_data\\"

library(psych)
library(readxl)
background_ERP=read_excel(paste(datapath,"resource from ERP study\\only_Pearson_R.xlsx",sep=""), sheet = "transposed")

ss_list=c('001','002','003','004','005','006','007','008','010','011','012','013','014','015','016','017','018','019','020','021','022','023','024','095','026','027','028','029','030','031','032')
#ss_list=c('001','002','003','004','005','006','007','008','011','013','014','016','020','021','022','095','026')
#create empty dataframes to store the correlation values
freq_frame=data.frame(matrix(ncol = 3, nrow = length(ss_list)))
x <- c("pearson_R","SSID","task")
colnames(freq_frame) <- x
fam_frame=freq_frame
postscan_frame=freq_frame
freqpost_frame=freq_frame
normobjfreq_frame=freq_frame
freqnorm_frame=freq_frame
objfreqpostscan_frame=freq_frame

#create empty frame to store response counts in each task
trialcount_frame=data.frame(matrix(ncol=16,nrow=length(ss_list)))
x=c("SSID","freq1_count","freq2_count","freq3_count","freq4_count","freq5_count","fam1_count","fam2_count","fam3_count","fam4_count","fam5_count","pscan1_count","pscan2_count","pscan3_count","pscan4_count","pscan5_count")
colnames(trialcount_frame)=x

#creat empty dataframes to store the mean resp for each level of freq and fam for each ss
freqavg=data.frame(matrix(ncol=3,nrow=length(ss_list)*5))
x=c("mean_resp","SSID","obj_freq")
colnames(freqavg)=x
famavg=data.frame(matrix(ncol=3,nrow=length(ss_list)*5))
x=c("mean_resp","SSID","norm_fam")
colnames(famavg)=x
postscanavg=data.frame(matrix(ncol=3,nrow=length(ss_list)*5))
x=c("mean_resp","SSID","norm_fam")
colnames(postscanavg)=x

#create empty dataframes to store the mean RT for each judgement
freqRTavg=data.frame(matrix(ncol=3,nrow=length(ss_list)*5))
x=c("mean_RT","SSID","resp")
colnames(freqRTavg)=x
famRTavg=data.frame(matrix(ncol=3,nrow=length(ss_list)*5))
x=c("mean_RT","SSID","resp")
colnames(famRTavg)=x

#empty frame to store all frequency data
data_freq_all=data.frame()

library(gtools)
#load data, calculate correlation and mean resp for each level of freq and fam in a for-loop
for (i in c(1:length(ss_list))){
data_dir=paste(datapath,"behavioral\\sub-",ss_list[i],sep="")
data_file=list.files(data_dir,pattern=paste("^",ss_list[i],"_startphase*",sep=""))
data=read_excel(paste(data_dir,"\\",data_file,sep=""))
#remove rows with all NAs but two columns
data=data[rowSums(is.na(data)) != ncol(data)-2, ]
#extract testphase data
data_freq=data[data$task=="recent",]
data_fam=data[data$task=="lifetime",]
data_postscan=data[data$task=="post_scan",]
#store freq data for DDM
data_freq_all=rbind(data_freq_all,data_freq)
#calculate normfam for frequency items to be compared with post_scan response
data_freq.match=data_freq[match(data_postscan$Stimuli,data_freq$Stimuli),]#match item order
data_postscan$norm_fam=data_freq.match$norm_fam
data_postscan$objective_freq=data_freq.match$objective_freq
norm_fam_freq_qt=quantcut(data_postscan$norm_fam,q=5,labels=FALSE)
data_postscan$norm_fam_qt=norm_fam_freq_qt
#cut the normative fam ratings into 5 levels
norm_fam_qt=quantcut(data_fam$norm_fam,q=5,labels=FALSE)
data_fam$norm_fam_qt=norm_fam_qt
#average
freqavg$SSID[(5*(i-1)+1):(5*i)]=ss_list[i]
freqavg$obj_freq[(5*(i-1)+1):(5*i)]=seq(1,9,2)
#each level of obj_freq
freqavg$mean_resp[5*(i-1)+1]=mean(as.numeric(data_freq$Response[data_freq$objective_freq==1]),na.rm=TRUE)
freqavg$mean_resp[5*(i-1)+2]=mean(as.numeric(data_freq$Response[data_freq$objective_freq==3]),na.rm=TRUE)
freqavg$mean_resp[5*(i-1)+3]=mean(as.numeric(data_freq$Response[data_freq$objective_freq==5]),na.rm=TRUE)
freqavg$mean_resp[5*(i-1)+4]=mean(as.numeric(data_freq$Response[data_freq$objective_freq==7]),na.rm=TRUE)
freqavg$mean_resp[5*(i-1)+5]=mean(as.numeric(data_freq$Response[data_freq$objective_freq==9]),na.rm=TRUE)

famavg$SSID[(5*(i-1)+1):(5*i)]=ss_list[i]
famavg$norm_fam[(5*(i-1)+1):(5*i)]=c(1:5)
#each level of obj_freq
famavg$mean_resp[5*(i-1)+1]=mean(as.numeric(data_fam$Response[data_fam$norm_fam_qt==1]),na.rm=TRUE)
famavg$mean_resp[5*(i-1)+2]=mean(as.numeric(data_fam$Response[data_fam$norm_fam_qt==2]),na.rm=TRUE)
famavg$mean_resp[5*(i-1)+3]=mean(as.numeric(data_fam$Response[data_fam$norm_fam_qt==3]),na.rm=TRUE)
famavg$mean_resp[5*(i-1)+4]=mean(as.numeric(data_fam$Response[data_fam$norm_fam_qt==4]),na.rm=TRUE)
famavg$mean_resp[5*(i-1)+5]=mean(as.numeric(data_fam$Response[data_fam$norm_fam_qt==5]),na.rm=TRUE)

postscanavg$SSID[(5*(i-1)+1):(5*i)]=ss_list[i]
postscanavg$norm_fam[(5*(i-1)+1):(5*i)]=c(1:5)
#each level of obj_freq
postscanavg$mean_resp[5*(i-1)+1]=mean(as.numeric(data_postscan$Response[data_postscan$norm_fam_qt==1]),na.rm=TRUE)
postscanavg$mean_resp[5*(i-1)+2]=mean(as.numeric(data_postscan$Response[data_postscan$norm_fam_qt==2]),na.rm=TRUE)
postscanavg$mean_resp[5*(i-1)+3]=mean(as.numeric(data_postscan$Response[data_postscan$norm_fam_qt==3]),na.rm=TRUE)
postscanavg$mean_resp[5*(i-1)+4]=mean(as.numeric(data_postscan$Response[data_postscan$norm_fam_qt==4]),na.rm=TRUE)
postscanavg$mean_resp[5*(i-1)+5]=mean(as.numeric(data_postscan$Response[data_postscan$norm_fam_qt==5]),na.rm=TRUE)

#RT average
freqRTavg$SSID[(5*(i-1)+1):(5*i)]=ss_list[i]
freqRTavg$resp[(5*(i-1)+1):(5*i)]=seq(1,5,1)
#each level of obj_freq
freqRTavg$mean_RT[5*(i-1)+1]=mean(as.numeric(data_freq$RespTime[data_freq$Response==1]),na.rm=TRUE)
freqRTavg$mean_RT[5*(i-1)+2]=mean(as.numeric(data_freq$RespTime[data_freq$Response==2]),na.rm=TRUE)
freqRTavg$mean_RT[5*(i-1)+3]=mean(as.numeric(data_freq$RespTime[data_freq$Response==3]),na.rm=TRUE)
freqRTavg$mean_RT[5*(i-1)+4]=mean(as.numeric(data_freq$RespTime[data_freq$Response==4]),na.rm=TRUE)
freqRTavg$mean_RT[5*(i-1)+5]=mean(as.numeric(data_freq$RespTime[data_freq$Response==5]),na.rm=TRUE)

famRTavg$SSID[(5*(i-1)+1):(5*i)]=ss_list[i]
famRTavg$resp[(5*(i-1)+1):(5*i)]=seq(1,5,1)
#each level of obj_freq
famRTavg$mean_RT[5*(i-1)+1]=mean(as.numeric(data_fam$RespTime[data_fam$Response==1]),na.rm=TRUE)
famRTavg$mean_RT[5*(i-1)+2]=mean(as.numeric(data_fam$RespTime[data_fam$Response==2]),na.rm=TRUE)
famRTavg$mean_RT[5*(i-1)+3]=mean(as.numeric(data_fam$RespTime[data_fam$Response==3]),na.rm=TRUE)
famRTavg$mean_RT[5*(i-1)+4]=mean(as.numeric(data_fam$RespTime[data_fam$Response==4]),na.rm=TRUE)
famRTavg$mean_RT[5*(i-1)+5]=mean(as.numeric(data_fam$RespTime[data_fam$Response==5]),na.rm=TRUE)

##########################trial counts/scale usage#####################
trialcount_frame$freq1_count[i]=sum(as.numeric(data_freq$Response)==1,na.rm = TRUE)
trialcount_frame$freq2_count[i]=sum(as.numeric(data_freq$Response)==2,na.rm = TRUE)
trialcount_frame$freq3_count[i]=sum(as.numeric(data_freq$Response)==3,na.rm = TRUE)
trialcount_frame$freq4_count[i]=sum(as.numeric(data_freq$Response)==4,na.rm = TRUE)
trialcount_frame$freq5_count[i]=sum(as.numeric(data_freq$Response)==5,na.rm = TRUE)
trialcount_frame$fam1_count[i]=sum(as.numeric(data_fam$Response)==1,na.rm = TRUE)
trialcount_frame$fam2_count[i]=sum(as.numeric(data_fam$Response)==2,na.rm = TRUE)
trialcount_frame$fam3_count[i]=sum(as.numeric(data_fam$Response)==3,na.rm = TRUE)
trialcount_frame$fam4_count[i]=sum(as.numeric(data_fam$Response)==4,na.rm = TRUE)
trialcount_frame$fam5_count[i]=sum(as.numeric(data_fam$Response)==5,na.rm = TRUE)
trialcount_frame$pscan1_count[i]=sum(as.numeric(data_postscan$Response)==1,na.rm = TRUE)
trialcount_frame$pscan2_count[i]=sum(as.numeric(data_postscan$Response)==2,na.rm = TRUE)
trialcount_frame$pscan3_count[i]=sum(as.numeric(data_postscan$Response)==3,na.rm = TRUE)
trialcount_frame$pscan4_count[i]=sum(as.numeric(data_postscan$Response)==4,na.rm = TRUE)
trialcount_frame$pscan5_count[i]=sum(as.numeric(data_postscan$Response)==5,na.rm = TRUE)

trialcount_frame$SSID[i]=ss_list[i]
##############################correlation#####################
corr_freq=corr.test(as.numeric(data_freq$Response),data_freq$objective_freq,method="pearson")
freq_frame$SSID[i]=ss_list[i]
freq_frame$task[i]="recent"
freq_frame$pearson_R[i]=corr_freq[1]

corr_fam=corr.test(as.numeric(data_fam$Response),data_fam$norm_fam,method="pearson")
fam_frame$SSID[i]=ss_list[i]
fam_frame$task[i]="lifetime"
fam_frame$pearson_R[i]=corr_fam[1]

corr_postscan=corr.test(as.numeric(data_postscan$Response),data_postscan$norm_fam,method="pearson")
postscan_frame$SSID[i]=ss_list[i]
postscan_frame$task[i]="post_scan"
postscan_frame$pearson_R[i]=corr_postscan[1]

#also correlate freq judgement with post-scan lifetime (useful in determining whether to model them in the same GLM)
corr_freqpost=corr.test(as.numeric(data_freq.match$Response),as.numeric(data_postscan$Response),method="pearson")
freqpost_frame$SSID[i]=ss_list[i]
freqpost_frame$task[i]="freq_and_postscan"
freqpost_frame$pearson_R[i]=corr_freqpost[1]

#and the correlation between normfam and objective frequency 
corr_normobjfreq=corr.test(as.numeric(data_postscan$objective_freq),as.numeric(data_postscan$norm_fam),method="pearson")
normobjfreq_frame$SSID[i]=ss_list[i]
normobjfreq_frame$task[i]="N/A"
normobjfreq_frame$pearson_R[i]=corr_normobjfreq[1]

#aaaaand the correlation between frequency response and normfam
corr_freqnorm=corr.test(as.numeric(data_freq$norm_fam),as.numeric(data_freq$Response),method="pearson")
freqnorm_frame$SSID[i]=ss_list[i]
freqnorm_frame$task[i]="freq"
freqnorm_frame$pearson_R[i]=corr_freqnorm[1]


#AAAAAAAND the correlation between postscan judgement and objective frequency (should be nonsignificant if they are doing the task)
corr_objfreqpostscan=corr.test(as.numeric(data_postscan$objective_freq),as.numeric(data_postscan$Response),method="pearson")
objfreqpostscan_frame$SSID[i]=ss_list[i]
objfreqpostscan_frame$task[i]="postscan"
objfreqpostscan_frame$pearson_R[i]=corr_objfreqpostscan[1]
}

fam_frame$pearson_R=as.numeric(fam_frame$pearson_R)
freq_frame$pearson_R=as.numeric(freq_frame$pearson_R)
postscan_frame$pearson_R=as.numeric(postscan_frame$pearson_R)

#account for the correction of lifetime-irr ratings we did in the fMRI analyses
freqpost_frame_corr=freqpost_frame
freqpost_frame_corr=freqpost_frame_corr[freqpost_frame_corr$SSID!='010',]#remove sub-010
#replace postscan ratings with norm ratings for 4 subs
freqpost_frame_corr$pearson_R[freqpost_frame_corr$SSID=='020']=freqnorm_frame$pearson_R[freqnorm_frame$SSID=='020']
freqpost_frame_corr$pearson_R[freqpost_frame_corr$SSID=='022']=freqnorm_frame$pearson_R[freqnorm_frame$SSID=='022']
freqpost_frame_corr$pearson_R[freqpost_frame_corr$SSID=='023']=freqnorm_frame$pearson_R[freqnorm_frame$SSID=='023']
freqpost_frame_corr$pearson_R[freqpost_frame_corr$SSID=='029']=freqnorm_frame$pearson_R[freqnorm_frame$SSID=='029']

#t test correlation between freq judgement and postscan ratings against 0
t.test(unlist(freqpost_frame_corr$pearson_R))

#RT analyses of the frequency task, also as a basis to define accurate and inaccurate trials for DDM

#create objective freq rank
data_freq_all$objective_freq_rank[data_freq_all$objective_freq==9]=5
data_freq_all$objective_freq_rank[data_freq_all$objective_freq==7]=4
data_freq_all$objective_freq_rank[data_freq_all$objective_freq==5]=3
data_freq_all$objective_freq_rank[data_freq_all$objective_freq==3]=2
data_freq_all$objective_freq_rank[data_freq_all$objective_freq==1]=1

#if the objective freq rank and participants responses differ more than 1, a trial is marked as inaccurate
data_freq_all$accuracy=0
data_freq_all$accuracy[abs(as.numeric(data_freq_all$Response)-data_freq_all$objective_freq_rank)<=1]=1#1 means correct

#average RT across accurate and inaccurate trials separately for each subject
library(dplyr)
data_freq_summary=data_freq_all %>%
  group_by(ParticipantNum,accuracy) %>%
  summarise(mean = mean(RespTime,na.rm=TRUE), n = n())

#paired t-test
t.test(data_freq_summary$mean[data_freq_summary$accuracy==0],data_freq_summary$mean[data_freq_summary$accuracy==1],paired=TRUE,alternative='greater')
#only significant in one-tailed test, possibly due to our definition of accuracy being a bit lenient

#This is what Stefan suggested, comparing RT for trials rated as 5 while having only 1 or 3 presentations vs. those having 7 or 9 presentations during the study
data_freq_only5=data_freq_all[as.numeric(data_freq_all$Response)==5&!is.na(data_freq_all$Response),]
data_freq_only5=data_freq_only5[data_freq_only5$objective_freq_rank!=3,]
data_freq_only5$obj_freq_bin[data_freq_only5$objective_freq_rank==4|data_freq_only5$objective_freq_rank==5]=1
data_freq_only5$obj_freq_bin[data_freq_only5$objective_freq_rank==1|data_freq_only5$objective_freq_rank==2]=0

data_freq_only5_summary=data_freq_only5 %>%
  group_by(ParticipantNum,obj_freq_bin) %>%
  summarise(mean = mean(RespTime,na.rm=TRUE), n = n())#some subjects have no lower bin

#get rid of people with only one bin
sub_bin_count=count(data_freq_only5_summary,var='ParticipantNum')
droplist=sub_bin_count$ParticipantNum[sub_bin_count$n==1]
data_freq_only5_summary.complete=data_freq_only5_summary[!is.element(data_freq_only5_summary$ParticipantNum,droplist),]
#stats
t.test(data_freq_only5_summary.complete$mean[data_freq_only5_summary.complete$obj_freq_bin==1],data_freq_only5_summary.complete$mean[data_freq_only5_summary.complete$obj_freq_bin==0],paired=TRUE)
#not significant, but these are based on a very small number of trials




####################################plots################################
bsize=0.1
library(ggplot2)
#generate ggplots, using ERP data as background
freq.plot=ggplot(data=background_ERP,aes(x=freq)) +
  geom_histogram(fill='grey',binwidth = bsize)+
  geom_histogram(data=freq_frame,aes(x=pearson_R),binwidth = bsize)+labs(y="participant count", x="frequency correlation")+theme(axis.text=element_text(size=(15)),axis.title=element_text(size=(15)))
ggsave(filename='freq_histo.png',path=paste(datapath,'interim_summary\\',sep=''),plot=freq.plot,dpi=300,scale = 0.9)

fam.plot=ggplot(data=background_ERP,aes(x=fam)) +
  geom_histogram(fill='grey',binwidth = bsize)+
  geom_histogram(data=fam_frame,aes(x=pearson_R),binwidth=bsize)+labs(y="participant count", x="familiarity correlation")+theme(axis.text=element_text(size=(15)),axis.title=element_text(size=(15)))
ggsave(filename='fam_histo.png',path=paste(datapath,'interim_summary\\',sep=''),plot=fam.plot,dpi=300,scale = 0.9)

#for post_scan, use lifetime response correlation as background instead of ERP
postscan.plot=ggplot(data=fam_frame,aes(x=pearson_R))+
  geom_histogram(fill='grey',binwidth = bsize)+
  geom_histogram(data=postscan_frame,aes(x=pearson_R),binwidth=bsize)+labs(y="participant count", x="familiarity correlation")+theme(axis.text=element_text(size=(15)),axis.title=element_text(size=(15)))
ggsave(filename='postscan_histo.png',path=paste(datapath,'interim_summary\\',sep=''),plot=postscan.plot,dpi=300,scale = 0.9)

#generate barplots as in Devin's paper using freqavg and famavg
library(dplyr)
#use piping to chain functions
freq.sum=freqavg %>%
  group_by(obj_freq) %>%
  summarise(sub_mean=mean(mean_resp),sub_sd=sd(mean_resp),sub_se=sd(mean_resp)/sqrt(n()))
freq.bar=ggplot(freq.sum,aes(x=obj_freq,y=sub_mean))+geom_col()+geom_errorbar(aes(ymin=sub_mean-sub_se,ymax=sub_mean+sub_se),width=0.2)+theme(axis.text=element_text(size=(15)),axis.title=element_text(size=(15)))+geom_smooth(data=freq.sum,aes(x = obj_freq, y = sub_mean),method = "lm", se= FALSE, color = "firebrick1", size = 1)
ggsave(filename='freq_bar.png',path=paste(datapath,'interim_summary\\',sep=''),plot=freq.bar,dpi=300,scale = 0.9)

fam.sum=famavg %>%
  group_by(norm_fam) %>%
  summarise(sub_mean=mean(mean_resp),sub_sd=sd(mean_resp),sub_se=sd(mean_resp)/sqrt(n()))
fam.bar=ggplot(fam.sum,aes(x=norm_fam,y=sub_mean))+geom_col()+geom_errorbar(aes(ymin=sub_mean-sub_se,ymax=sub_mean+sub_se),width=0.2)+theme(axis.text=element_text(size=(15)),axis.title=element_text(size=(15)))+geom_smooth(data=fam.sum,aes(x = norm_fam, y = sub_mean),method = "lm", se= FALSE, color = "firebrick1", size = 1)
ggsave(filename='fam_bar.png',path=paste(datapath,'interim_summary\\',sep=''),plot=fam.bar,dpi=300,scale = 0.9)

postscan.sum=postscanavg %>%
  group_by(norm_fam) %>%
  summarise(sub_mean=mean(mean_resp),sub_sd=sd(mean_resp),sub_se=sd(mean_resp)/sqrt(n()))
postscan.bar=ggplot(postscan.sum,aes(x=norm_fam,y=sub_mean))+geom_col()+geom_errorbar(aes(ymin=sub_mean-sub_se,ymax=sub_mean+sub_se),width=0.2)+theme(axis.text=element_text(size=(15)),axis.title=element_text(size=(15)))+geom_smooth(data=postscan.sum,aes(x = norm_fam, y = sub_mean),method = "lm", se= FALSE, color = "firebrick1", size = 1)
ggsave(filename='postscan_bar.png',path=paste(datapath,'interim_summary\\',sep=''),plot=postscan.bar,dpi=300,scale = 0.9)

#t-test compare the correlations with normfam between lifetime task and post_scan
t.test(fam_frame$pearson_R,postscan_frame$pearson_R,paired=TRUE,alternative = "greater")#they are significantly different
#some descriptive stats
lowercut=mean(postscan_frame$pearson_R)-2*sd(postscan_frame$pearson_R)
uppercut=mean(postscan_frame$pearson_R)+2*sd(postscan_frame$pearson_R)
postscan_frame$outlier[postscan_frame$pearson_R<=lowercut|postscan_frame$pearson_R>=uppercut]='yes'
#a few subjects have much lower correlations during post_scan compared to in the scanner (e.g. 020, 022),removing the 3 made the t-test nonsignificant
fam_ex=fam_frame[!(fam_frame$SSID=="020" | fam_frame$SSID=="022" ),]
postscan_ex=postscan_frame[!(postscan_frame$SSID=="020" | postscan_frame$SSID=="022" ),]
t.test(fam_ex$pearson_R,postscan_ex$pearson_R,paired=TRUE,alternative = "greater")

#plot reaction time in the test phase
freqRT.sum=freqRTavg %>%
  group_by(resp) %>%
  summarise(sub_mean_RT=mean(mean_RT),sub_sd=sd(mean_RT),sub_se=sd(mean_RT)/sqrt(n()))
freqRT.bar=ggplot(freqRT.sum,aes(x=resp,y=sub_mean_RT))+geom_col()+geom_errorbar(aes(ymin=sub_mean_RT-sub_se,ymax=sub_mean_RT+sub_se),width=0.2)+theme(axis.text=element_text(size=(15)),axis.title=element_text(size=(15)))
ggsave(filename='freqRT_bar.png',path=paste(datapath,'interim_summary\\',sep=''),plot=freqRT.bar,dpi=300,scale = 0.9)

famRT.sum=famRTavg %>%
  group_by(resp) %>%
  summarise(sub_mean_RT=mean(mean_RT),sub_sd=sd(mean_RT),sub_se=sd(mean_RT)/sqrt(n()))
famRT.bar=ggplot(famRT.sum,aes(x=resp,y=sub_mean_RT))+geom_col()+geom_errorbar(aes(ymin=sub_mean_RT-sub_se,ymax=sub_mean_RT+sub_se),width=0.2)+theme(axis.text=element_text(size=(15)),axis.title=element_text(size=(15)))
ggsave(filename='famRT_bar.png',path=paste(datapath,'interim_summary\\',sep=''),plot=famRT.bar,dpi=300,scale = 0.9)

######response histogram#######
library(ggpubr)
library(tidyr)
#convert to long
trialcount_frame_long=gather(trialcount_frame,"trial_type","trial_count",-SSID)
#use shorter trial type labels
trialcount_frame_long$trial_type[trialcount_frame_long$trial_type=="freq1_count"]='r1'
trialcount_frame_long$trial_type[trialcount_frame_long$trial_type=="freq2_count"]='r2'
trialcount_frame_long$trial_type[trialcount_frame_long$trial_type=="freq3_count"]='r3'
trialcount_frame_long$trial_type[trialcount_frame_long$trial_type=="freq4_count"]='r4'
trialcount_frame_long$trial_type[trialcount_frame_long$trial_type=="freq5_count"]='r5'
trialcount_frame_long$trial_type[trialcount_frame_long$trial_type=="fam1_count"]='l1'
trialcount_frame_long$trial_type[trialcount_frame_long$trial_type=="fam2_count"]='l2'
trialcount_frame_long$trial_type[trialcount_frame_long$trial_type=="fam3_count"]='l3'
trialcount_frame_long$trial_type[trialcount_frame_long$trial_type=="fam4_count"]='l4'
trialcount_frame_long$trial_type[trialcount_frame_long$trial_type=="fam5_count"]='l5'
histolist=list()
#loop over subjects to generate freq and fam histogram
for (i in c(1:length(ss_list))){
  chunk=trialcount_frame_long[trialcount_frame_long$SSID==ss_list[i],]
  p = ggplot(data=chunk, aes(x=trial_type, y=trial_count)) +
    geom_bar(stat='identity')+theme(axis.title.x = element_blank())
  histolist[[i]] = p
}
histo_collect=ggarrange(plotlist=histolist, 
          labels = ss_list,font.label = list(size = 15),hjust=-1.5,vjust=0.75)
histo_collect

