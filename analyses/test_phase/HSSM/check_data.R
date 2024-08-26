# check individual subjects' data after binning to see if they are unimodal in each response option
library(tidyverse)
library(diptest)
binned_data=read_csv('C:\\Users\\haozi\\OneDrive\\Desktop\\PhD\\fMRI_PrC-PPC_data\\HDDM_HSSM\\HSSM_freq_MedianBin_data.csv')

#output dir
out_dir='C:\\Users\\haozi\\OneDrive\\Desktop\\PhD\\fMRI_PrC-PPC_data\\HDDM_HSSM\\RT_dists\\'

#loop over subject and generate one RT histogram for each response option
subs=unique(binned_data$subj_idx)

#initialize a dataframe to save results
col_names <- c("SSID", "resp_1_dip_test_pval","resp_2_dip_test_pval")
dip_df <- data.frame(matrix(ncol = length(col_names), nrow = 0))
colnames(dip_df) <- col_names

for (ss in subs){
  sub_data_resp1<-binned_data%>%filter(subj_idx==ss&bin_rating==1)
  sub_data_resp2<-binned_data%>%filter(subj_idx==ss&bin_rating==-1)
  
  #Hartigans' dip test for unimodality
  dip_resp1=dip.test(sub_data_resp1$rt)
  dip_resp2=dip.test(sub_data_resp2$rt)
  
  sub_frame=data.frame(SSID=ss,resp_1_dip_test_pval=dip_resp1$p.value,resp_2_dip_test_pval=dip_resp2$p.value)
  dip_df=rbind(dip_df,sub_frame)
  
  #plot
  sub_resp_1.hist=ggplot(data=sub_data_resp1,aes(x=rt))+
    geom_histogram(binwidth=0.05)+
    labs(title=paste0(ss,'_resp1_RT'))
  
  sub_resp_2.hist=ggplot(data=sub_data_resp2,aes(x=rt))+
    geom_histogram(binwidth=0.05)+
    labs(title=paste0(ss,'_resp-1_RT'))
  
  #save figs
  ggsave(plot=sub_resp_1.hist,filename = paste0(out_dir,ss,'_resp_1_RT.png'))
  ggsave(plot=sub_resp_2.hist,filename = paste0(out_dir,ss,'_resp_-1_RT.png'))
}
