#correlate frequency judgement with actual presentation frequency, and lifetime fam judgement with normative data.
#using results from my ERP study as background to judge the data quality of the fMRI study.
datapath="C:\\Users\\haozi\\Desktop\\PhD\\fMRI_PrC-PPC_data\\"

library(psych)
library(readxl)
background_ERP=read_excel(paste(datapath,"resource from ERP study\\only_Pearson_R.xlsx",sep=""), sheet = "transposed")

ss_list=c('001','002','003','004','005','006','007')
#create empty dataframes to store the correlation values
freq_frame=data.frame(matrix(ncol = 3, nrow = length(ss_list)))
x <- c("pearson_R","SSID","task")
colnames(freq_frame) <- x
fam_frame=freq_frame

#load data, calculate correlation in a for-loop
for (i in c(1:length(ss_list))){
data_dir=paste(datapath,"behavioral\\sub-",ss_list[i],sep="")
data_file=list.files(data_dir,pattern=paste("^",ss_list[i],"_startphase*",sep=""))
data=read_excel(paste(data_dir,"\\",data_file,sep=""))
#remove rows will all NAs but two columns
data=data[rowSums(is.na(data)) != ncol(data)-2, ]
#extract testphase data
data_freq=data[data$task=="recent",]
data_fam=data[data$task=="lifetime",]
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
  geom_histogram(data=freq_frame,aes(x=pearson_R),binwidth = bsize)

fam.plot=ggplot(data=background_ERP,aes(x=fam)) +
  geom_histogram(fill='grey',binwidth = bsie)+
  geom_histogram(data=fam_frame,aes(x=pearson_R),binwidth=bsize)



