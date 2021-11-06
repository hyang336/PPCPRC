#check RT priming effect of repetition and lifetime familiarity
library(rio)
datapath="C:\\Users\\haozi\\Desktop\\PhD\\fMRI_PrC-PPC_data\\"
ss_list=c('001','002','003','004','005','006','007','008','011','012','013','014','015','016','017','018','019','020','021','022','023','024','095','026','027','028','029','030','031','032')

#dataframe for saving regression slopes
beta_frame=data.frame(matrix(ncol = 3, nrow = length(ss_list)))
x <- c("SSID","freq_slope","lifetime_slope")
colnames(beta_frame) <- x

RT_freq_frame=data.frame(matrix(ncol = 3,nrow=0))
x <- c("SSID","freq_RT","pres")
colnames(RT_freq_frame) <- x

RT_life_frame=data.frame(matrix(ncol = 3, nrow = 0))
x <- c("SSID","life_RT","lifetime_ratings")
colnames(RT_life_frame) <- x

for (i in c(1:length(ss_list))){
  beta_frame$SSID[i]=ss_list[i]
  
  data=import(paste(datapath,'behavioral\\sub-',ss_list[i],'\\',ss_list[i],'_startphase-study_startrun-1_starttrial-1_data.xlsx',sep=''))
  animacy_data=data[data$task=='animacy',]
  postscan_data=data[data$task=='post_scan',]
  animacy_data=animacy_data[rowSums(is.na(animacy_data)) != ncol(animacy_data), ]#remove all-NA rows
  postscan_data=postscan_data[rowSums(is.na(postscan_data)) != ncol(postscan_data), ]#remove all-NA rows
  
  #load postscan data into the animacy data
  for (j in c(1:dim(animacy_data)[1])){
    animacy_data$postscan[j]=postscan_data$Response[postscan_data$Stimuli==animacy_data$Stimuli[j]]
  }
  
  #extract mean RT for each level of repetition and lifetime familiarity for plots
  RT.pres1=mean(animacy_data$RespTime[animacy_data$objective_freq%%10==1],na.rm=TRUE)
  RT.pres2=mean(animacy_data$RespTime[animacy_data$objective_freq%%10==2],na.rm=TRUE)
  RT.pres3=mean(animacy_data$RespTime[animacy_data$objective_freq%%10==3],na.rm=TRUE)
  RT.pres4=mean(animacy_data$RespTime[animacy_data$objective_freq%%10==4],na.rm=TRUE)
  RT.pres5=mean(animacy_data$RespTime[animacy_data$objective_freq%%10==5],na.rm=TRUE)
  RT.pres6=mean(animacy_data$RespTime[animacy_data$objective_freq%%10==6],na.rm=TRUE)
  RT.pres7=mean(animacy_data$RespTime[animacy_data$objective_freq%%10==7],na.rm=TRUE)
  RT.pres8=mean(animacy_data$RespTime[animacy_data$objective_freq%%10==8],na.rm=TRUE)
  RT.pres9=mean(animacy_data$RespTime[animacy_data$objective_freq%%10==9],na.rm=TRUE)
  RT.freq_temp=cbind(rep(ss_list[i],9),rbind(RT.pres1,RT.pres2,RT.pres3,RT.pres4,RT.pres5,RT.pres6,RT.pres7,RT.pres8,RT.pres9),seq(1,9))
  x <- c("SSID","freq_RT","pres")
  colnames(RT.freq_temp) <- x
  RT_freq_frame=rbind(RT_freq_frame,RT.freq_temp)
  
  RT.life1=mean(animacy_data$RespTime[animacy_data$postscan==1],na.rm = TRUE)
  RT.life2=mean(animacy_data$RespTime[animacy_data$postscan==2],na.rm = TRUE)
  RT.life3=mean(animacy_data$RespTime[animacy_data$postscan==3],na.rm = TRUE)
  RT.life4=mean(animacy_data$RespTime[animacy_data$postscan==4],na.rm = TRUE)
  RT.life5=mean(animacy_data$RespTime[animacy_data$postscan==5],na.rm = TRUE)
  RT.life_temp=cbind(rep(ss_list[i],5),rbind(RT.life1,RT.life2,RT.life3,RT.life4,RT.life5),seq(1,5))
  x <- c("SSID","life_RT","lifetime_ratings")
  colnames(RT.life_temp) <- x
  RT_life_frame=rbind(RT_life_frame,RT.life_temp)
  
  #z-score all continuous or ordinal variables (RT, freq, norm_fam, postscan fam)
  animacy_data$RT_z=scale(animacy_data$RespTime)
  animacy_data$freq_z=scale(animacy_data$objective_freq%%10)
  animacy_data$norm_fam_z=scale(animacy_data$norm_fam)
  animacy_data$postscan_z=scale(as.numeric(animacy_data$postscan))
  
  #replacing normfam with postscan fam is participant rating exists (except for sub-020 and sub-022 since they have abnormal post-scan lifetime ratings)
  animacy_data$lifetime_z=animacy_data$norm_fam_z
  if (ss_list[i]!='020'&&ss_list[i]!='022'){
    for (k in c(1:dim(animacy_data)[1])){
      if (!is.na(animacy_data$postscan_z[k])){
        animacy_data$lifetime_z[k]=animacy_data$postscan_z[k]
      }
    }
  }
  
  #run regression RT~freq+fam in animacy task
  RT_reg=lm(RT_z~freq_z+lifetime_z,data=animacy_data)#regress RT and 
  
  #extract coefficients for 2nd level tests
  beta_frame$freq_slope[i]=RT_reg$coefficients[[2]]
  beta_frame$lifetime_slope[i]=RT_reg$coefficients[[3]]
}

#t tests for regression slope of freq & life on RT against 0
t.test(beta_frame$freq_slope)#highly significant
t.test(beta_frame$lifetime_slope)#still significant
#priming effect (i.e. reduction in RT) was observed for both factors

#plot RT across repetitions
library(ggplot2)
#summary stats
RT.freq_sum=data.frame(matrix(ncol = 3,nrow=0))
x <- c("pres","rt","se")
colnames(RT.freq_sum) <- x

for (i in seq(1,9)){
  RT.freq_sum=rbind(RT.freq_sum,data.frame(pres=i,rt=mean(as.numeric(RT_freq_frame$freq_RT[RT_freq_frame$pres==i]),na.rm=TRUE),se=sd(RT_freq_frame$freq_RT[RT_freq_frame$pres==i],na.rm=TRUE)/sqrt(length(RT_freq_frame$freq_RT[RT_freq_frame$pres==i&!is.na(RT_freq_frame$freq_RT)]))))
}

RT.life_sum=data.frame(matrix(ncol = 3,nrow=0))
x <- c("lifetime_ratings","rt","se")
colnames(RT.life_sum) <- x

for (i in seq(1,5)){
  RT.life_sum=rbind(RT.life_sum,data.frame(lifetime_ratings=i,rt=mean(as.numeric(RT_life_frame$life_RT[RT_life_frame$lifetime_ratings==i]),na.rm=TRUE),se=sd(RT_life_frame$life_RT[RT_life_frame$lifetime_ratings==i],na.rm=TRUE)/sqrt(length(RT_life_frame$life_RT[RT_life_frame$lifetime_ratings==i&!is.na(RT_life_frame$life_RT)]))))
}

#freq RT plot
p1=ggplot(data = RT.freq_sum,aes(x=as.factor(pres),y = rt,group=1)) + 
  geom_line()+
  geom_point()+
  geom_errorbar(aes(ymin=rt-se, ymax=rt+se), width=.2,position=position_dodge(.9))

#lifetime RT plot
p2=ggplot(data = RT.life_sum,aes(x=as.factor(lifetime_ratings),y = rt,group=1)) + 
  geom_line()+
  geom_point()+
  geom_errorbar(aes(ymin=rt-se, ymax=rt+se), width=.2,position=position_dodge(.9))