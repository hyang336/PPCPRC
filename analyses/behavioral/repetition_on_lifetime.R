#check if repetition in the study phase boosted lifetime familiarity ratings post-scan
#use normtive lifetime ratings as baseline, compare post-pre (subject rating - normative rating) lifetime rating difference for words presented 9 times with those presented 1 times.
#This is more sensitive than just correlating lifetime rating with presentation frequency since it takes the baseline difference of lifetime ratings between the bins into consideration. Also, it is likely that the repetition only had a small effect on lifetime ratings, which may not give a significant correlation.
library(rio)
library(plyr)

SSID=c('001','002','003','004','005','006','007','008','010','011','012','013')
#for each subject, calculate the average difference of normative lifetime ratings between the two most extreme bins, and the average difference in post-scan ratings
data=data.frame(pp_9=as.numeric(),pp_1=as.numeric(),SSID=as.character())
for (i in c(1:length(SSID))){
  temp_data=import(paste0("C:\\Users\\haozi\\Desktop\\PhD\\fMRI_PrC-PPC_data\\behavioral\\sub-",SSID[i],'\\',SSID[i],'_startphase-study_startrun-1_starttrial-1_data.xlsx'))
  animacy_data=temp_data[temp_data$task=='animacy',]
  ps_data=temp_data[temp_data$task=='post_scan',]
  words.9=unique(animacy_data$Stimuli[animacy_data$objective_freq==91])
  words.9=words.9[!is.na(words.9)]
  words.1=unique(animacy_data$Stimuli[animacy_data$objective_freq==11])
  words.1=words.1[!is.na(words.1)]
  
  norm.9=animacy_data$norm_fam[animacy_data$objective_freq==91&animacy_data$Stimuli %in% words.9]
  norm.1=animacy_data$norm_fam[animacy_data$objective_freq==11&animacy_data$Stimuli %in% words.1]
  post.9=as.numeric(ps_data$Response[ps_data$Stimuli %in% words.9])
  post.1=as.numeric(ps_data$Response[ps_data$Stimuli %in% words.1])
  
  #range normalization since norm and post-scan ratings are on different scales
  norm.9.st=(norm.9-1)/8
  norm.1.st=(norm.1-1)/8
  post.9.st=(post.9-1)/5
  post.1.st=(post.1-1)/5
  
  #calculate the avg. post-pre differences
  post_pre.9=post.9.st-norm.9.st
  post_pre.1=post.1.st-norm.1.st
  
  pp.9.mean=mean(post_pre.9,na.rm=TRUE)
  pp.1.mean=mean(post_pre.1,na.rm=TRUE)
  
  data=rbind(data,data.frame(pp.9.mean,pp.1.mean,SSID[i]))
  }
#t-test compare pre-post lifetime rating differences
pp.9_1.t=t.test(data$pp.9.mean,data$pp.1.mean,paired = TRUE)
pp.9_1.t
#kinda close to being significant with 12 subjects