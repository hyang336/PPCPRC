library(ggplot2)
library(readxl)
library(tidyr)
data_dir='C:\\Users\\haozi\\OneDrive\\Desktop\\PhD\\fMRI_PrC-PPC_data\\Rev_1_test-decoding'
data=read_excel(paste(data_dir,'\\compiled_results.xlsx',sep=''))

#init summary across participants
class_sum=data.frame(matrix(ncol = 3,nrow=0))
x <- colnames(data)
x=x[-1]

for (i in 1:length(x)){
  classification=x[i]
  class_mean=mean(unlist(data[,grep(x[i],colnames(data))]),na.rm=TRUE)
  class_se=sd(unlist(data[,grep(x[i],colnames(data))]),na.rm=TRUE)/sqrt(30)
  class_sum=rbind(class_sum,c(classification,class_mean,class_se))
}
colnames(class_sum)=c('classification','mean','se')
class_sum$mean=as.numeric(class_sum$mean)
class_sum$se=as.numeric(class_sum$se)

#Stats against chance
t.test(data$rec_xsy,mu=0.5,alternative='greater')

#stats life inc against chance
t.test(data$life_xgy,mu=0.5,alternative='greater')

#compare decoding between task-rel life increase and life decrease
t.test(data$life_xsy,data$life_xgy,paired = TRUE)

#plot
decode.bar=ggplot(class_sum,aes(x=classification,y=mean))+
  geom_col()+geom_errorbar(aes(ymin=mean-se,ymax=mean+se),width=0.2)+
  theme(axis.text=element_text(size=15),axis.title.x = element_text(size=13),axis.title.y = element_text(size=15))+
  xlab("different binary classifications")+
  ylab("accuracy")

