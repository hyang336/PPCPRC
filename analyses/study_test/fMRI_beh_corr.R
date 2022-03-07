
##############################################################fMRI behavioral correlation across subjects###############################################################
datapath="C:\\Users\\haozi\\Desktop\\PhD\\fMRI_PrC-PPC_data\\priming_mirror_corr\\"
freq.data=read.csv(paste(datapath,"freq_prime.csv",sep=""))
fam.data=read.csv(paste(datapath,"fam_prime.csv",sep=""))
mirror.data=read.csv(paste(datapath,"mirror.csv",sep=""))

library(ggplot2)
f1=ggplot(freq.data, aes(x=con_val, y=slope)) + 
  geom_point()+
  geom_smooth(method=lm)+
  theme(axis.text=element_text(size=(15)),axis.title=element_text(size=(15)))+
  xlab("PrC contrast value")+
  ylab("slope: RT~frequency")
ggsave(filename='freq_prime.png',path='C:\\Users\\haozi\\Desktop\\PhD\\fMRI_PrC-PPC_data\\interim_summary\\ch2_figs\\',plot=f1,width=4,height=4,units="in",dpi=300,scale = 1)

f2=ggplot(fam.data, aes(x=con_val, y=slope)) + 
  geom_point()+
  geom_smooth(method=lm)+
  theme(axis.text=element_text(size=(15)),axis.title=element_text(size=(15)))+
  xlab("PrC contrast value")+
  ylab("slope: RT~lifetime ratings")
ggsave(filename='fam_prime.png',path='C:\\Users\\haozi\\Desktop\\PhD\\fMRI_PrC-PPC_data\\interim_summary\\ch2_figs\\',plot=f2,width=4,height=4,units="in",dpi=300,scale = 1)

f3=ggplot(mirror.data, aes(x=con_val, y=slope)) + 
  geom_point()+
  geom_smooth(method=lm)+
  theme(axis.text.y=element_text(size=(12)),axis.text.x=element_text(size=(15)),axis.title=element_text(size=(15)))+
  xlab("PrC contrast value")+
  ylab("slope: freq.error~lifetime ratings")
ggsave(filename='mirror.png',path='C:\\Users\\haozi\\Desktop\\PhD\\fMRI_PrC-PPC_data\\interim_summary\\ch2_figs\\',plot=f3,width=4,height=4,units="in",dpi=300,scale = 1)
