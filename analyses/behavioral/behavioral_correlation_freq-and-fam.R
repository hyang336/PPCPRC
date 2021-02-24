#correlate frequency judgement with actual presentation frequency, and lifetime fam judgement with normative data.
#using results from my ERP study as background to judge the data quality of the fMRI study.
datapath="C:\\Users\\haozi\\Desktop\\PhD\\fMRI_PrC-PPC_data\\"

library(psych)
library(readxl)
background_ERP=read_excel(paste(datapath,"resource from ERP study\\only_Pearson_R.xlsx",sep=""), sheet = "transposed")

#ss_list=c('001','002','003','004','005','006','007','008','010','011','012','013','014','016','017','018','019','020','021','022','024','095','026','027','028')
ss_list=c('001','002','003','004','005','006','007','008','011','013','014','016','020','021','022','095','026')
#create empty dataframes to store the correlation values
freq_frame=data.frame(matrix(ncol = 3, nrow = length(ss_list)))
x <- c("pearson_R","SSID","task")
colnames(freq_frame) <- x
fam_frame=freq_frame

#creat empty dataframes to store the mean resp for each level of freq and fam for each ss
freqavg=data.frame(matrix(ncol=3,nrow=length(ss_list)*5))
x=c("mean_resp","SSID","obj_freq")
colnames(freqavg)=x
famavg=data.frame(matrix(ncol=3,nrow=length(ss_list)*5))
x=c("mean_resp","SSID","norm_fam")
colnames(famavg)=x

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
#correlation
corr_freq=corr.test(as.numeric(data_freq$Response),data_freq$objective_freq,method="pearson")
freq_frame$SSID[i]=ss_list[i]
freq_frame$task[i]="recent"
freq_frame$pearson_R[i]=corr_freq[1]
corr_fam=corr.test(as.numeric(data_fam$Response),data_fam$norm_fam,method="pearson")
fam_frame$SSID[i]=ss_list[i]
fam_frame$task[i]="lifetime"
fam_frame$pearson_R[i]=corr_fam[1]
}

fam_frame$pearson_R=as.numeric(fam_frame$pearson_R)
freq_frame$pearson_R=as.numeric(freq_frame$pearson_R)
bsize=0.1
library(ggplot2)
#generate ggplots, using ERP data as background
freq.plot=ggplot(data=background_ERP,aes(x=freq)) +
  geom_histogram(fill='grey',binwidth = bsize)+
  geom_histogram(data=freq_frame,aes(x=pearson_R),binwidth = bsize)+labs(y="participant count", x="frequency correlation")+theme(axis.text=element_text(size=(30)),axis.title=element_text(size=(30)))

fam.plot=ggplot(data=background_ERP,aes(x=fam)) +
  geom_histogram(fill='grey',binwidth = bsize)+
  geom_histogram(data=fam_frame,aes(x=pearson_R),binwidth=bsize)+labs(y="participant count", x="familiarity correlation")+theme(axis.text=element_text(size=(30)),axis.title=element_text(size=(30)))

#generate barplots as in Devin's paper using freqavg and famavg
library(dplyr)
#use piping to chain functions
freq.sum=freqavg %>%
  group_by(obj_freq) %>%
  summarise(sub_mean=mean(mean_resp),sub_sd=sd(mean_resp),sub_se=sd(mean_resp)/sqrt(n()))
freq.bar=ggplot(freq.sum,aes(x=obj_freq,y=sub_mean))+geom_col()+geom_errorbar(aes(ymin=sub_mean-sub_se,ymax=sub_mean+sub_se),width=0.2)+theme(axis.text=element_text(size=(30)),axis.title=element_text(size=(30)))

fam.sum=famavg %>%
  group_by(norm_fam) %>%
  summarise(sub_mean=mean(mean_resp),sub_sd=sd(mean_resp),sub_se=sd(mean_resp)/sqrt(n()))
fam.bar=ggplot(fam.sum,aes(x=norm_fam,y=sub_mean))+geom_col()+geom_errorbar(aes(ymin=sub_mean-sub_se,ymax=sub_mean+sub_se),width=0.2)+theme(axis.text=element_text(size=(30)),axis.title=element_text(size=(30)))
