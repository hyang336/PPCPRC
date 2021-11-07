#partial out PrC beta from precuneus beta for each subject
#also convert beta to z-scores within each region and participant
#to account for difference in signal strength due to susceptibility artifact

datapath="C:\\Users\\haozi\\Desktop\\PhD\\fMRI_PrC-PPC_data\\hddm\\"

prc.data=read.csv(paste(datapath,"PrC\\hddm_data_prc.csv",sep=""))
precuneus.data=read.csv(paste(datapath,"precuneus_func-defined\\hddm_data_prec.csv",sep=""))
mpfc.data=read.csv(paste(datapath,"mPFC_func-defined\\hddm_data_mpfc.csv",sep=""))

#test whether beta differ in magnitude between regions
#t.test(abs(prc.data$prc_beta),abs(precuneus.data$precuneus_beta))

SSID=unique(prc.data$subj_idx)
for (i in c(1:length(SSID))){
  prc.beta=prc.data$prc_beta[prc.data$subj_idx==SSID[i]]
  prc.data$prc_z[prc.data$subj_idx==SSID[i]]=scale(prc.beta)#z-score
  precuneus.beta=precuneus.data$precuneus_beta[precuneus.data$subj_idx==SSID[i]]
  precuneus.data$precuneus_z[precuneus.data$subj_idx==SSID[i]]=scale(precuneus.beta)#z-score
  
  mpfc.beta=mpfc.data$mpfc_beta[mpfc.data$subj_idx==SSID[i]]
  mpfc.data$mpfc_z[mpfc.data$subj_idx==SSID[i]]=scale(mpfc.beta)#z-score
  
  #regression
  m1=lm(precuneus.beta~prc.beta)
  m2=lm(mpfc.beta~prc.beta)
  #residual
  precuneus.data$residuals[precuneus.data$subj_idx==SSID[i]]=resid(m1)
  mpfc.data$residuals[mpfc.data$subj_idx==SSID[i]]=resid(m2)
  #z-score residuals
  precuneus.data$residuals_z[precuneus.data$subj_idx==SSID[i]]=scale(resid(m1))
  mpfc.data$residuals_z[mpfc.data$subj_idx==SSID[i]]=scale(resid(m2))
}

#write.csv(prc.data,paste(datapath,"PrC\\hddm_data_prc.csv",sep=""))
write.csv(precuneus.data,paste(datapath,"precuneus_func-defined\\hddm_data_prec_res.csv",sep=""))
write.csv(mpfc.data,paste(datapath,"mPFC_func-defined\\hddm_data_mpfc_res.csv",sep=""))