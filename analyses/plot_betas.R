#use beta summary in excel file (typed in manually) for plots, has more options than MATLAB plots

#load data
library(rio)
data=import("C:\\Users\\haozi\\OneDrive\\Desktop\\PhD\\fMRI_PrC-PPC_data\\plots_abovethreshold\\manual_results2023.xlsx")
#output folder
datapath="C:\\Users\\haozi\\OneDrive\\Desktop\\PhD\\Paper_2\\revision_1\\"

#parse data for different plots
PrC_test_rele_data=subset(data, grepl("life", signal)  &  task == "lifetime" & ROI=="PrC"| grepl("recent", signal)  &  task == "frequency"& ROI=="PrC")
test_lifetime_data=subset(data, grepl("life",signal) & task == "lifetime" | grepl("life", signal) & task =="frequency")
study_recent_data=subset(data, grepl("pres",signal) & task == "animacy_all" )
study_lifetime_all_data=subset(data, grepl("life",signal) & task == "animacy_all" )
study_lifetime_pres1_data=subset(data, grepl("life",signal) & task == "animacy_pres1" )

#generate plots
library(ggplot2)
library(RColorBrewer)

#select pallet
brewer.pal(n = 3, name = "Paired")
#"#A6CEE3" "#1F78B4" "#B2DF8A"

#task-relevant lifetime-recent conjunction PrC plot
p1 <- ggplot(PrC_test_rele_data, aes(x=signal, y=beta_avg, fill=ROI)) + 
  geom_bar(stat="identity", position=position_dodge(),show.legend = FALSE) +
  #geom_errorbar(aes(ymin=beta_avg-beta_se, ymax=beta_avg+beta_se), width=.2,position=position_dodge(.9),colour="white")+ 
  scale_fill_manual(values="#1F78B4") + theme_minimal()+ theme(plot.background = element_rect(fill="black"),panel.background = element_rect(fill="black", colour="white"),panel.border = element_blank(),
           panel.grid.major = element_blank(),
           panel.grid.minor = element_blank(),
           legend.background = element_rect(fill="black"),
           legend.title = element_text(color="white", size=13),
           legend.text = element_text(color="white",size=13),
           axis.text.x = element_text(color="white",size=20,vjust=0.5),
           axis.text.y = element_text(color="white",size=20),
           axis.title = element_blank())+ labs(x = '            Task-relevant lifetime familiarity             Task-relevant recent familiarity (frequency)',y ="Parameter estimates")+scale_x_discrete(labels=c('1','2','3','4','5','1','2','3','4','5'))
ggsave(filename='PrC_task-rele_life-recent-conj_bar.png',path=datapath,plot=p1,scale = 0.9,width = 2400,height=1600,units='px')


##task-relevant-irrelevant lifetime conjunction plots (PrC & IT_P)
#lifetime judgement
p2.1 <- ggplot(test_lifetime_data[test_lifetime_data$task=="lifetime",], aes(x=signal, y=beta_avg, fill=ROI)) + 
  geom_bar(stat="identity", position=position_dodge(),show.legend = FALSE) +
  #geom_errorbar(aes(ymin=beta_avg-beta_se, ymax=beta_avg+beta_se), width=.2,position=position_dodge(.9),colour="white")+
  scale_fill_manual(values=c("#1F78B4","#A6CEE3")) + 
  theme_minimal()+ 
  theme(plot.background = element_rect(fill="black"),panel.background = element_rect(fill="black", colour="white"),panel.border = element_blank(),
                                                                                                                          panel.grid.major = element_blank(),
                                                                                                                          panel.grid.minor = element_blank(),
                                                                                                                          legend.background = element_rect(fill="black"),
                                                                                                                          legend.title = element_text(color="white",size=13),
                                                                                                                          legend.text = element_text(color="white",size=13),
                                                                                                                          axis.text.x = element_text(color="white",size=20,vjust=0.5),
                                                                                                                          axis.text.y = element_text(color="white",size=20),
                                                                                                                          axis.title = element_blank())+ 
  labs(x="Task-relevant lifetime familiarity", y ="Parameter estimates")+scale_x_discrete(labels=c('1','2','3','4','5'))
ggsave(filename='PrC_task-rele_life-conj_bar.png',path=datapath,plot=p2.1,width = 350*3,height=467*3,units='px',scale = 0.9)
#frequency judgement
p2.2 <- ggplot(test_lifetime_data[test_lifetime_data$task=="frequency",], aes(x=signal, y=beta_avg, fill=ROI)) + 
  geom_bar(stat="identity", position=position_dodge(),show.legend = FALSE) +
  #geom_errorbar(aes(ymin=beta_avg-beta_se, ymax=beta_avg+beta_se), width=.2,position=position_dodge(.9),colour="white")+
  scale_fill_manual(values=c("#1F78B4","#A6CEE3")) + 
  theme_minimal()+ 
  theme(plot.background = element_rect(fill="black"),panel.background = element_rect(fill="black", colour="white"),panel.border = element_blank(),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        legend.background = element_rect(fill="black"),
        legend.title = element_text(color="white",size=13),
        legend.text = element_text(color="white",size=13),
        axis.text.x = element_text(color="white",size=20,vjust=0.5),
        axis.text.y = element_text(color="white",size=20),
        axis.title = element_blank())+ 
  labs(x="Task-irrelevant lifetime familiarity", y ="Parameter estimates")+scale_x_discrete(labels=c('1','2','3','4','5'))
ggsave(filename='PrC_task-irrele_life-conj_bar.png',path=datapath,plot=p2.2,width = 350*3,height=467*3,units='px',scale = 0.9)


#task-irrelevant recent familiarity in study phase
p3 <- ggplot(study_recent_data, aes(x=signal, y=beta_avg, fill=color)) + 
  geom_bar(stat="identity", position=position_dodge(),show.legend = FALSE) +
  #geom_errorbar(aes(ymin=beta_avg-beta_se, ymax=beta_avg+beta_se), width=.2,position=position_dodge(.9),colour="white")+
  scale_fill_manual(values=c("#1F78B4","#A6CEE3")) + 
  theme_minimal()+ 
  theme(plot.background = element_rect(fill="black"),panel.background = element_rect(fill="black", colour="white"),panel.border = element_blank(),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        legend.background = element_rect(fill="black"),
        legend.title = element_text(color="white",size=13),
        legend.text = element_text(color="white",size=13),
        axis.text.x = element_text(color="white",size=20,vjust=0.5),
        axis.text.y = element_text(color="white",size=20),
        axis.title = element_blank())+ 
  labs(x="Task-irrelevant recent familiarity (frequency)", y ="Parameter estimates")+scale_x_discrete(labels=c('1','2','3','4','5','6','7','8','9'))
ggsave(filename='PrC_task-irrele_recent_bar.png',path=datapath,plot=p3,width = 2400,height=1600,units='px',scale = 0.9)


#task-irrelevant lifetime familiarity in study phase, all trials
p4 <- ggplot(study_lifetime_all_data, aes(x=signal, y=beta_avg, fill=ROI)) + 
  geom_bar(stat="identity", position=position_dodge(),show.legend = FALSE) +
  #geom_errorbar(aes(ymin=beta_avg-beta_se, ymax=beta_avg+beta_se), width=.2,position=position_dodge(.9),colour="white")+
  scale_fill_manual(values=c("#1F78B4","#A6CEE3","#B2DF8A")) + 
  theme_minimal()+ 
  theme(plot.background = element_rect(fill="black"),panel.background = element_rect(fill="black", colour="white"),panel.border = element_blank(),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        legend.background = element_rect(fill="black"),
        legend.title = element_text(color="white",size=13),
        legend.text = element_text(color="white",size=13),
        axis.text.x = element_text(color="white",size=20,vjust=0.5),
        axis.text.y = element_text(color="white",size=20),
        axis.title = element_blank())+ 
  labs(x="Task-irrelevant lifetime familiarity", y ="Parameter estimates")+scale_x_discrete(labels=c('1','2','3','4','5'))
ggsave(filename='PrC_study_life-all_bar.png',path=datapath,plot=p4,width = 2400,height=1600,units='px',scale = 0.9)


#task-irrelevant lifetime familiarity in study phase, pres 1
p5 <- ggplot(study_lifetime_pres1_data, aes(x=signal, y=beta_avg, fill=ROI)) + 
  geom_bar(stat="identity", position=position_dodge(),show.legend = FALSE) +
  #geom_errorbar(aes(ymin=beta_avg-beta_se, ymax=beta_avg+beta_se), width=.2,position=position_dodge(.9),colour="white")+
  scale_fill_manual(values="#1F78B4") + 
  theme_minimal()+ 
  theme(plot.background = element_rect(fill="black"),panel.background = element_rect(fill="black", colour="white"),panel.border = element_blank(),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        legend.background = element_rect(fill="black"),
        legend.title = element_text(color="white",size=13),
        legend.text = element_text(color="white",size=13),
        axis.text.x = element_text(color="white",size=20,vjust=0.5),
        axis.text.y = element_text(color="white",size=20),
        axis.title = element_blank())+ 
  labs(x="Task-irrelevant lifetime familiarity", y ="Parameter estimates")+scale_x_discrete(labels=c('1','2','3','4','5'))
ggsave(filename='PrC_study_life-pres1_bar.png',path=datapath,plot=p5,width = 2400,height=1600,units='px',scale = 0.9)



