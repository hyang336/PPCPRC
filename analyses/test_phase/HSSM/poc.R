#quick test on how SNR affect slope estimate
x=runif(400)
y1=2*x + rnorm(400,sd=1)
y2=2*x + rnorm(400,sd=8)

m1=lm(y1~x)
m2=lm(y2~x)

summary(m1)
summary(m2)


#proof of concept simulation to make sure either beta or spline regression work without the sequential sampling model part
library(ggplot2)

#ground truth parameters
a0=1
b0=2
i0=0.85

a1=2.5
b1=4
i1=2.1

a2=4
b2=2.5
i2=2.1

a3=2
b3=1
i3=0.85

n_sub=30
n_trial=200
sub_sv=0.2

#########################non-hierarchical case#############################
x=rnorm(n=n_sub*n_trial)
x=(x-min(x))/(max(x)-min(x))
v0=exp(i0+(a0-1)*log(x)+(b0-1)*log(1-x))+rnorm(n=n_sub*n_trial,sd=0.2)
v1=exp(i1+(a1-1)*log(x)+(b1-1)*log(1-x))+rnorm(n=n_sub*n_trial,sd=0.2)
v2=exp(i2+(a2-1)*log(x)+(b2-1)*log(1-x))+rnorm(n=n_sub*n_trial,sd=0.2)
v3=exp(i3+(a3-1)*log(x)+(b3-1)*log(1-x))+rnorm(n=n_sub*n_trial,sd=0.2)
data=data.frame(x=x,v0=v0,v1=v1,v2=v2,v3=v3)

# ground truth glm (throws an error)
beta0=glm(formula = 'v0~1 + I(log(x)) + I(log(1-x))',data=data,family = gaussian(link='log'), start=c(0,0,0))
beta1=glm(formula = 'v1~1 + I(log(x)) + I(log(1-x))',data=data,family = gaussian(link='log'), start=c(0,0,0))
beta2=glm(formula = 'v2~1 + I(log(x)) + I(log(1-x))',data=data,family = gaussian(link='log'), start=c(0,0,0))
beta3=glm(formula = 'v3~1 + I(log(x)) + I(log(1-x))',data=data,family = gaussian(link='log'), start=c(0,0,0))
data$v0_beta=predict(beta0)
data$v1_beta=predict(beta1)
data$v2_beta=predict(beta2)
data$v3_beta=predict(beta3)

ggplot(data,aes(x=x,y=v0))+
  geom_point(color = 'blue', alpha =0.6) +
  geom_line(aes(y=v0_beta),color='red',size=1)+
  labs(title = 'Model Predictions vs Actual Data',
       x = 'X',
       y = 'Y') +
  theme_minimal()
# spline
