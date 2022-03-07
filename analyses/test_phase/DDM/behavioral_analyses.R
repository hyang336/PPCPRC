#behavioral analyses for frequency judgement (DDM specific)

#load data, all the behavioral part are the same across csv files so just load the prc one
datapath="C:\\Users\\haozi\\Desktop\\PhD\\fMRI_PrC-PPC_data\\hddm\\"

# prc.data=read.csv(paste(datapath,"PrC\\hddm_data_prc.csv",sep=""))
prc.data=read.csv(paste(datapath,"PrC_roi_strict\\hddm_data.csv",sep=""))

SSID=unique(prc.data$subj_idx)
#####################plot accuracy per presentation frequency###################################
pres1=prc.data[prc.data$stim==1,]
pres3=prc.data[prc.data$stim==3,]
pres5=prc.data[prc.data$stim==5,]
pres7=prc.data[prc.data$stim==7,]
pres9=prc.data[prc.data$stim==9,]

pres1_acc=list()
pres3_acc=list()
pres5_acc=list()
pres7_acc=list()
pres9_acc=list()
for (i in c(1:length(SSID))){
  pres1_acc[i]=sum(pres1$response[pres1$subj_idx==SSID[i]])/length(pres1$response[pres1$subj_idx==SSID[i]])
  pres3_acc[i]=sum(pres3$response[pres3$subj_idx==SSID[i]])/length(pres3$response[pres3$subj_idx==SSID[i]])
  pres5_acc[i]=sum(pres5$response[pres5$subj_idx==SSID[i]])/length(pres5$response[pres5$subj_idx==SSID[i]])
  pres7_acc[i]=sum(pres7$response[pres7$subj_idx==SSID[i]])/length(pres7$response[pres7$subj_idx==SSID[i]])
  pres9_acc[i]=sum(pres9$response[pres9$subj_idx==SSID[i]])/length(pres9$response[pres9$subj_idx==SSID[i]])
}

library(dplyr)
library(tidyr)
#combine into a long dataframe
df=do.call(rbind, Map(data.frame, pres1_acc=pres1_acc,pres3_acc=pres3_acc,pres5_acc=pres5_acc,pres7_acc=pres7_acc,pres9_acc=pres9_acc))
df$ssid=data.frame(SSID)
df.long=gather(df,pres,accuracy,pres1_acc:pres9_acc,factor_key=TRUE)

#summary using dplyr
df.sum <- df.long %>%
  group_by(pres) %>%
  summarise(acc = mean(accuracy,na.rm=TRUE), std = sd(accuracy,na.rm=TRUE),n = n(),se = std / sqrt(n))


library(ggplot2)
acc_bar=ggplot(df.sum,aes(x=pres,y=acc))+ 
  geom_bar(stat="identity", color="black", 
           position=position_dodge()) +
  geom_errorbar(aes(ymin=acc-se, ymax=acc+se), width=.2,
                position=position_dodge(.9)) +
  theme(axis.text=element_text(size=(15)),axis.title=element_text(size=(15)))+
  scale_x_discrete(labels=c('1','3','5','7','9'))+
  xlab("objective presentation frequency")+
  ylab("accuracy")+
  geom_hline(yintercept=0.2,color = "red",linetype="dashed")
ggsave(filename='pres_acc_strict.png',path='C:\\Users\\haozi\\Desktop\\PhD\\fMRI_PrC-PPC_data\\interim_summary\\',plot=acc_bar,width=4,height=6,units="in",dpi=300,scale = 0.9)
####################compare RT for correct and incorrect trials#######################################
#A paired t-test when you have unequal sample sizes does not make any sense, conceptually or mathematically. So we have to summarize across trial
pres1_acc_rt=list()
pres1_inacc_rt=list()
pres3_acc_rt=list()
pres3_inacc_rt=list()
pres5_acc_rt=list()
pres5_inacc_rt=list()
pres7_acc_rt=list()
pres7_inacc_rt=list()
pres9_acc_rt=list()
pres9_inacc_rt=list()
for (i in c(1:length(SSID))){
  pres1_acc_rt[i]=mean(prc.data$rt[prc.data$subj_idx==SSID[i]&prc.data$response==1&prc.data$stim==1],na.rm=TRUE)
  pres1_inacc_rt[i]=mean(prc.data$rt[prc.data$subj_idx==SSID[i]&prc.data$response==0&prc.data$stim==1],na.rm=TRUE)
  
  pres3_acc_rt[i]=mean(prc.data$rt[prc.data$subj_idx==SSID[i]&prc.data$response==1&prc.data$stim==3],na.rm=TRUE)
  pres3_inacc_rt[i]=mean(prc.data$rt[prc.data$subj_idx==SSID[i]&prc.data$response==0&prc.data$stim==3],na.rm=TRUE)
  
  pres5_acc_rt[i]=mean(prc.data$rt[prc.data$subj_idx==SSID[i]&prc.data$response==1&prc.data$stim==5],na.rm=TRUE)
  pres5_inacc_rt[i]=mean(prc.data$rt[prc.data$subj_idx==SSID[i]&prc.data$response==0&prc.data$stim==5],na.rm=TRUE)
  
  pres7_acc_rt[i]=mean(prc.data$rt[prc.data$subj_idx==SSID[i]&prc.data$response==1&prc.data$stim==7],na.rm=TRUE)
  pres7_inacc_rt[i]=mean(prc.data$rt[prc.data$subj_idx==SSID[i]&prc.data$response==0&prc.data$stim==7],na.rm=TRUE)
  
  pres9_acc_rt[i]=mean(prc.data$rt[prc.data$subj_idx==SSID[i]&prc.data$response==1&prc.data$stim==9],na.rm=TRUE)
  pres9_inacc_rt[i]=mean(prc.data$rt[prc.data$subj_idx==SSID[i]&prc.data$response==0&prc.data$stim==9],na.rm=TRUE)
}

t.test(unlist(pres1_acc_rt),unlist(pres1_inacc_rt),paired = TRUE,alternative='less')#marginally sig.
t.test(unlist(pres3_acc_rt),unlist(pres3_inacc_rt),paired = TRUE,alternative='less')#reverse is true
t.test(unlist(pres5_acc_rt),unlist(pres5_inacc_rt),paired = TRUE,alternative='less')#reverse is true
t.test(unlist(pres7_acc_rt),unlist(pres7_inacc_rt),paired = TRUE,alternative='less')#sig.
t.test(unlist(pres9_acc_rt),unlist(pres9_inacc_rt),paired = TRUE,alternative='less')#sig.

#seems similar to the U-shape RT-difference curve in Farshad Rafiei & Dobromir Rahnev (2021)

#########################################LME for RT#################################################

# We want to see if RT differred based on subjective*objective ratings. And interaction effect (regression slope of obj_freq being positive for low ratings,
# and negative or at least less positive for high ratings would indicate an effect of accuracy, becasue for low obj_freq, low ratings were correct and should 
# lead to faster response, while for high obj_freq, the high ratings were correct)

rating_data=read.csv(paste(datapath,"PrC_strict_rating\\hddm_data_z.csv",sep=""))

library(scales)
#ranking the objective presentation column so the two factors have the same range.
rating_data$stim=rescale(rating_data$stim,to=c(1,5),from=range(rating_data$stim,na.rm = TRUE,finite=TRUE))

library(lme4)
library(lmerTest)
m1=lmer(formula = rt ~ stim*rating + (1|subj_idx) + (0+stim*rating|subj_idx),data=rating_data,REML = TRUE) #random intercept and random slopes for subject, with estimating the correlation between the two
#Failed to converge, removing random slopes

m2=lmer(formula = rt ~ stim*rating + (1|subj_idx),data=rating_data,REML = TRUE) # random intercept for subject
summary(m2) #have a significant interaction

m3=lmer(formula = rt ~ stim*response + (1|subj_idx),data=rating_data,REML = TRUE) # random intercept for subject
summary(m3) #no significant interaction or main effect of accuracy (response)

#follow up test correlating the slope of the rt ~ obj_freq within each rating with the actual rating, we are expecting a negative correlation because the slope of the RT-obj effect would be more positive for low ratings.
# this needs to be done in two steps, first within subject, then across
SSID=unique(rating_data$subj_idx)
slope.slope=list()
for (i in c(1:length(SSID))){
  rt= rating_data$rt[rating_data$subj_idx==SSID[i]&rating_data$rating==1]
  obj_freq=rating_data$stim[rating_data$subj_idx==SSID[i]&rating_data$rating==1]
  reg=lm(rt~ obj_freq)
  slope.1=reg['coefficients'][1][[1]][[2]]#nasty nested list...
  
  rt= rating_data$rt[rating_data$subj_idx==SSID[i]&rating_data$rating==2]
  obj_freq=rating_data$stim[rating_data$subj_idx==SSID[i]&rating_data$rating==2]
  reg=lm(rt~ obj_freq)
  slope.2=reg['coefficients'][1][[1]][[2]]#nasty nested list...
  
  rt= rating_data$rt[rating_data$subj_idx==SSID[i]&rating_data$rating==3]
  obj_freq=rating_data$stim[rating_data$subj_idx==SSID[i]&rating_data$rating==3]
  reg=lm(rt~ obj_freq)
  slope.3=reg['coefficients'][1][[1]][[2]]#nasty nested list...
  
  rt= rating_data$rt[rating_data$subj_idx==SSID[i]&rating_data$rating==4]
  obj_freq=rating_data$stim[rating_data$subj_idx==SSID[i]&rating_data$rating==4]
  reg=lm(rt~ obj_freq)
  slope.4=reg['coefficients'][1][[1]][[2]]#nasty nested list...
  
  rt= rating_data$rt[rating_data$subj_idx==SSID[i]&rating_data$rating==5]
  obj_freq=rating_data$stim[rating_data$subj_idx==SSID[i]&rating_data$rating==5]
  reg=lm(rt~ obj_freq)
  slope.5=reg['coefficients'][1][[1]][[2]]#nasty nested list...
  
  #second regress with slope ~ rating
  reg2=lm(c(slope.1,slope.2,slope.3,slope.4,slope.5)~c(1,2,3,4,5))
  slope.slope[i]=reg2['coefficients'][1][[1]][[2]]
}

t.test(unlist(slope.slope),alternative = 'less') #nonsignificant, indicating that accurate responses were not faster than inaccurate one

# A second way to test RT accuracy effect, simply comparing accurate vs. inaccurate RT within-subject, then take the RT different to a second level t-test
rt.diff=list()
for (i in c(1:length(SSID))){
 rt.acc=rating_data$rt[rating_data$subj_idx==SSID[i]&rating_data$response==1]
 rt.inacc=rating_data$rt[rating_data$subj_idx==SSID[i]&rating_data$response==0]
 
 rt.acc.mean=mean(rt.acc,na.rm=TRUE)
 rt.inacc.mean=mean(rt.inacc,na.rm=TRUE)
 
 rt.diff[i]=rt.acc.mean-rt.inacc.mean
}

t.test(unlist(rt.diff),alternative = 'less') # this time it is significant

# An intermediate way to test RT accuracy effect, comparing accurate vs. inaccurate RT for within each obj_freq and participant (using within-subject ANOVA (how is this different for the lmer?)





#check singularity
tt=getME(m1,"theta")
ll=getME(m1,"lower")
min(tt[ll==0]) #<10^-6 is bad, not in this case (https://rstudio-pubs-static.s3.amazonaws.com/33653_57fc7b8e5d484c909b615d8633c01d51.html)