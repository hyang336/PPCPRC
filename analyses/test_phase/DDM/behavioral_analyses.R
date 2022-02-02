#behavioral analyses for frequency judgement

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
                position=position_dodge(.9)) 

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
