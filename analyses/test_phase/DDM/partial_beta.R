#partial out PrC beta from precuneus beta for each subject
datapath="C:\\Users\\haozi\\Desktop\\PhD\\fMRI_PrC-PPC_data\\hddm\\"

prc.data=read.csv(paste(datapath,"PrC\\hddm_data_prc.csv",sep=""))
precuneus.data=read.csv(paste(datapath,"precuneus\\hddm_data_prec.csv",sep=""))

SSID=unique(prc.data$subj_idx)
for (i in c(1:length(SSID))){
  prc.beta=prc.data$prc_beta[prc.data$subj_idx==SSID[i]]
  precuneus.beta=precuneus.data$precuneus_beta[precuneus.data$subj_idx==SSID[i]]
  #regression
  m1=lm(precuneus.beta~prc.beta)
  #residual
  precuneus.data$residuals[precuneus.data$subj_idx==SSID[i]]=resid(m1)
}

write.csv(precuneus.data,paste(datapath,"precuneus\\hddm_data_prec_res.csv",sep=""))
