#compare stimuli in this study with those in Duke et al. (2017) on various dimensions
library(rio)
duke_stim=import("C:\\Users\\haozi\\OneDrive\\Desktop\\PhD\\collaboration with Nicole Anderson\\overlap_stim.csv")
ref_table=import("C:\\Users\\haozi\\OneDrive\\Desktop\\PhD\\PPCPRC\\stmuli\\marked items.xlsx")
my_stim_file=read.table("C:\\Users\\haozi\\OneDrive\\Desktop\\PhD\\PPCPRC\\stmuli\\genetic_180_manovaR.csv", sep = '\t', header = TRUE)

#find stimuli and their characteristics in the two studies
library(dplyr)
ref_duke = ref_table %>%
  filter(Concept %in% duke_stim$word)
ref_mine = ref_table %>%
  filter(Concept %in% my_stim_file$concepts)

#shared stimuli between the two studies
overlap = inner_join(ref_duke, ref_mine)

#remove the overlapping stimuli
ref_duke_uniq=ref_duke[!(ref_duke$Concept %in% overlap$Concept),]
ref_mine_uniq=ref_mine[!(ref_mine$Concept %in% overlap$Concept),]

#drop some column
drop=c('Pronunciation','Phon_1st','KF','BNC')
ref_duke_uniq=ref_duke_uniq[,!(names(ref_duke_uniq) %in% drop)]
ref_mine_uniq=ref_mine_uniq[,!(names(ref_mine_uniq) %in% drop)]

#use manova to test the match of the remaining stimuli
ref_duke_uniq$study='duke'
ref_mine_uniq$study='mine'

combined_uniq=rbind(ref_duke_uniq,ref_mine_uniq)
#combined_uniq=combined_uniq[complete.cases(combined_uniq),]

dv=combined_uniq[,!(names(combined_uniq) %in% c('Concept','study'))]
iv=combined_uniq$study

m_model = manova(data.matrix(dv) ~ as.factor(iv))
summary(m_model,tol=0)