#partial out PrC beta from precuneus beta for each subject
#also convert beta to z-scores within each region and participant
#to account for difference in signal strength due to susceptibility artifact

datapath="C:\\Users\\haozi\\Desktop\\PhD\\fMRI_PrC-PPC_data\\hddm\\"

prc.data=read.csv(paste(datapath,"PrC\\hddm_data_prc.csv",sep=""))
# precuneus.data=read.csv(paste(datapath,"precuneus_func-defined\\hddm_data_prec.csv",sep=""))
# mpfc.data=read.csv(paste(datapath,"mPFC_func-defined\\hddm_data_mpfc.csv",sep=""))
# inf_occip.data=read.csv(paste(datapath,"control_WFUaal_inf_occip\\hddm_data_inf_occip.csv",sep=""))
# sup_temporal.data=read.csv(paste(datapath,"control_WFUaal_sup_temporal\\hddm_data.csv",sep=""))
# rand.data=read.csv(paste(datapath,"control_random\\hddm_data_rand.csv",sep=""))
prc_roi_strict.data=read.csv(paste(datapath,"PrC_roi_strict\\hddm_data.csv",sep=""))

#test whether beta differ in magnitude between regions
t.test(abs(prc.data$prc_beta),abs(precuneus.data$precuneus_beta), paired=TRUE)

SSID=unique(prc.data$subj_idx)
for (i in c(1:length(SSID))){
  # prc.beta=prc.data$prc_beta[prc.data$subj_idx==SSID[i]]
  # prc.data$prc_z[prc.data$subj_idx==SSID[i]]=scale(prc.beta)#z-score
  # precuneus.beta=precuneus.data$precuneus_beta[precuneus.data$subj_idx==SSID[i]]
  # precuneus.data$precuneus_z[precuneus.data$subj_idx==SSID[i]]=scale(precuneus.beta)#z-score
  # 
  # mpfc.beta=mpfc.data$mpfc_beta[mpfc.data$subj_idx==SSID[i]]
  # mpfc.data$mpfc_z[mpfc.data$subj_idx==SSID[i]]=scale(mpfc.beta)#z-score
  
  # inf_occip.beta=inf_occip.data$inf_occip_beta[inf_occip.data$subj_idx==SSID[i]]
  # inf_occip.data$inf_occip_z[inf_occip.data$subj_idx==SSID[i]]=scale(inf_occip.beta)#z-score
  
  # sup_temporal.beta=sup_temporal.data$sup_temporal_beta[sup_temporal.data$subj_idx==SSID[i]]
  # sup_temporal.data$sup_temporal_z[sup_temporal.data$subj_idx==SSID[i]]=scale(sup_temporal.beta)#z-score
  
  # rand.beta=rand.data$random_num[rand.data$subj_idx==SSID[i]]
  # rand.data$random_z[rand.data$subj_idx==SSID[i]]=scale(rand.beta)#z-score
  
  prc_roi_strict.beta=prc_roi_strict.data$roi_beta[prc_roi_strict.data$subj_idx==SSID[i]]
  prc_roi_strict.data$roi_z[prc_roi_strict.data$subj_idx==SSID[i]]=scale(prc_roi_strict.beta)#z-score
  
  # #regression
  # m1=lm(precuneus.beta~prc.beta)
  # m2=lm(mpfc.beta~prc.beta)
  # m3=lm(mpfc.beta~precuneus.beta)
  # #residual
  # precuneus.data$residuals[precuneus.data$subj_idx==SSID[i]]=resid(m1)
  # mpfc.data$residuals[mpfc.data$subj_idx==SSID[i]]=resid(m2)
  # mpfc.data$residuals2[mpfc.data$subj_idx==SSID[i]]=resid(m3)
  # #z-score residuals
  # precuneus.data$residuals_z[precuneus.data$subj_idx==SSID[i]]=scale(resid(m1))
  # mpfc.data$residuals_z[mpfc.data$subj_idx==SSID[i]]=scale(resid(m2))
  # mpfc.data$residuals2_z[mpfc.data$subj_idx==SSID[i]]=scale(resid(m3))
}

#write.csv(prc.data,paste(datapath,"PrC\\hddm_data_prc.csv",sep=""))
# write.csv(precuneus.data,paste(datapath,"precuneus_func-defined\\hddm_data_prec_res.csv",sep=""))
# write.csv(mpfc.data,paste(datapath,"mPFC_func-defined\\hddm_data_mpfc_res.csv",sep=""))
# write.csv(inf_occip.data,paste(datapath,"control_WFUaal_inf_occip\\hddm_data_inf_occip_z.csv",sep=""))
# write.csv(sup_temporal.data,paste(datapath,"control_WFUaal_sup_temporal\\hddm_data_sup_temporal_z.csv",sep=""))
# write.csv(rand.data,paste(datapath,"control_random\\hddm_data_rand_z.csv",sep=""))
write.csv(prc_roi_strict.data,paste(datapath,"PrC_roi_strict\\hddm_data_z.csv",sep=""))
