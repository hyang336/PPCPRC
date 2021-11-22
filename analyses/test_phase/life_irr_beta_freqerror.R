#2-step regression to see if voxels showing task-irrelevant lifetime effect during frequency judgement tracks the amount of frequency overestimation

datapath="C:\\Users\\haozi\\Desktop\\PhD\\fMRI_PrC-PPC_data\\"

library(psych)
library(readxl)
library(scales)

#load behavioral results
data=read.csv(paste(datapath,"test_mirror_event\\test_lifetime-in-freq_event_compiled.csv",sep=""))

ss_list=c('001','002','003','004','005','006','007','008','011','012','013','014','015','016','017','018','019','020','021','022','023','024','095','026','027','028','029','030','031','032')

freq_error.on.beta=data.frame(matrix(ncol=2,nrow=length(ss_list)))
x=c("slope","SSID")
colnames(freq_error.on.beta)=x

for (i in c(1:length(ss_list))){
  data.sub=data[data$sub==as.numeric(ss_list[i]),]

  m1=lm(data.sub$freq_overestimate~data.sub$ROI_beta)
  
  freq_error.on.beta$slope[i]=m1[[1]][[2]]
  freq_error.on.beta$SSID[i]=ss_list[i]
}

#on-tailed t-test for greater than 0, since the slope should be positive for mirror effect (i.e. more lifetime fam -> overestimate frequency)
t.test(freq_error.on.beta$slope,alternative = 'less')
