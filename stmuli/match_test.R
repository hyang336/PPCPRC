file="C:/Users/haozi/Desktop/PhD/fMRI_PrC-PPC/stmuli/genetic_180_manovaR.csv"
mydata=read.csv(file)
mydata$set=as.factor(mydata$set)

result=manova(cbind(mydata$avg_feat_overlap_541,mydata$norm.fam,mydata$ln.KF.,mydata$Length_Letters,mydata$Length_Syllables)~mydata$set)
summary(result)
#p=0.944, Df=9 matched