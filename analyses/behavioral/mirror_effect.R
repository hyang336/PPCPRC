datapath="C:\\Users\\haozi\\Desktop\\PhD\\fMRI_PrC-PPC_data\\"

library(psych)
library(readxl)
library(scales)
ss_list=c('001','002','003','004','005','006','007','008','011','012','013','014','015','016','017','018','019','020','021','022','023','024','095','026','027','028','029','030','031','032')

freq_error.on.pscan=data.frame(matrix(ncol=2,nrow=length(ss_list)))
x=c("slope","SSID")
colnames(freq_error.on.pscan)=x

freq_error_pscan=data.frame(matrix(ncol = 6, nrow = length(ss_list)))
x <- c("SSID","freq_err_ps1","freq_err_ps2","freq_err_ps3","freq_err_ps4","freq_err_ps5")
colnames(freq_error_pscan) <- x

for (i in c(1:length(ss_list))){
 #load behavioral results
  data_dir=paste(datapath,"behavioral\\sub-",ss_list[i],sep="")
  data_file=list.files(data_dir,pattern=paste("^",ss_list[i],"_startphase*",sep=""))
  data=read_excel(paste(data_dir,"\\",data_file,sep=""))
  
  #remove rows with all NAs but two columns
  data=data[rowSums(is.na(data)) != ncol(data)-2, ]
  
  #extract testphase data
  data_freq=data[data$task=="recent",]
  data_fam=data[data$task=="lifetime",]
  data_postscan=data[data$task=="post_scan",]

  #match item order of freq with postscan
  data_freq.match=data_freq[match(data_postscan$Stimuli,data_freq$Stimuli),]#match item order
  data_freq.match$postscan=data_postscan$Response
  
  #rescale obj. freq to 1-5
  data_freq.match$objective_freq_rescale=rescale(data_freq.match$objective_freq, to = c(1,5))
  
  #the difference between judged freq and obj. freq should scale with lifetime familiarity, for now we use subject-specific lifetime ratings
  freq_error=as.numeric(data_freq.match$Response)-data_freq.match$objective_freq_rescale
  #record participant level summary stats for plotting
  freq_error_pscan$SSID[i]=ss_list[i]
  freq_error_pscan$freq_err_ps1[i]=mean(freq_error[data_freq.match$postscan==1],na.rm=TRUE)                      
  freq_error_pscan$freq_err_ps2[i]=mean(freq_error[data_freq.match$postscan==2],na.rm=TRUE)
  freq_error_pscan$freq_err_ps3[i]=mean(freq_error[data_freq.match$postscan==3],na.rm=TRUE)
  freq_error_pscan$freq_err_ps4[i]=mean(freq_error[data_freq.match$postscan==4],na.rm=TRUE)
  freq_error_pscan$freq_err_ps5[i]=mean(freq_error[data_freq.match$postscan==5],na.rm=TRUE)
  
  #regression
  m1=lm(freq_error~as.numeric(data_freq.match$postscan))
  
  freq_error.on.pscan$slope[i]=m1[[1]][[2]]
  freq_error.on.pscan$SSID[i]=ss_list[i]
}

#on-tailed t-test for greater than 0, since the slope should be positive for mirror effect (i.e. more lifetime fam -> overestimate frequency)
t.test(freq_error.on.pscan$slope,alternative = 'greater')

####For plot##############
library(ggplot2)
#summary across participants
mirror_sum=data.frame(matrix(ncol = 3,nrow=0))
x <- c("pscan","freq_error","se")
colnames(mirror_sum) <- x

#column names of subject frame
results_col=colnames(freq_error_pscan)
results_col=results_col[-1]
for (i in seq(1,5)){
  coln=results_col[i]
  mirror_sum=rbind(mirror_sum,data.frame(pscan=i,freq_error=mean(as.numeric(freq_error_pscan[,coln]),na.rm=TRUE),se=sd(freq_error_pscan[,coln],na.rm=TRUE)/sqrt(length(freq_error_pscan[,coln]))))
}

freq_err.bar=ggplot(mirror_sum,aes(x=pscan,y=freq_error))+
  geom_col()+geom_errorbar(aes(ymin=freq_error-se,ymax=freq_error+se),width=0.2)+
  theme(axis.text=element_text(size=15),axis.title.x = element_text(size=13),axis.title.y = element_text(size=15))+
  xlab("post-scan lifetime familiarity ratings")+
  ylab("frequency overestimation")
ggsave(filename='freqerror_bar.png',path=paste(datapath,'interim_summary\\ch2_figs\\',sep=''),plot=freq_err.bar,width=4,height=4,units="in",dpi=300,scale = 1)


