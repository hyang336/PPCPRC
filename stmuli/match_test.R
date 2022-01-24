file="C:/Users/haozi/Desktop/PhD/fMRI_PrC-PPC/stmuli/genetic_180_manovaR.csv"
mydata=read.table(file, sep = '\t', header = TRUE)
mydata$set=as.factor(mydata$set)

result=manova(cbind(mydata$avg_feat_overlap_541,mydata$norm.fam,mydata$ln.KF.,mydata$Length_Letters,mydata$Length_Syllables)~mydata$set)
summary(result)
#Df  Pillai approx F num Df den Df Pr(>F)
#mydata$set   9 0.17497  0.68495     45    850 0.9437