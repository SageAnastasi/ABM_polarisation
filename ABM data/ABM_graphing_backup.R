setwd("~/GitHub/ABM_polarisation/ABM data")

tolerance_test <- read.csv("tolerance-test-100-runs.csv",header = T)
tolerance_test$Tolerance_factor <- as.factor(tolerance_test$Tolerance)

group_size_test <- read.csv("group_size_1000_steps.csv",header=T)
group_size_test$Size_factor <- as.factor(group_size_test$Size)
group_size_test$Tolerance_factor <- as.factor(group_size_test$Tolerance)

asymmetric <- read.csv("asymmetric-tolerance.csv",header=T)
asymmetric$Group1_tolerance_factor <- as.factor(asymmetric$g1_t)
asymmetric$g2_t_factor < - as.factor(asymmetric$g2_t)

minority <- read.csv("weak_minority_preferences.csv",header=T)
minority$g1_t_factor <- as.factor(minority$g1_t)
minority$g2_t_factor <- as.factor(minority$g2_t)



library(ggplot2)
library(dplyr)
library(cowplot)
library(xtable)


#tolerance testing
tolerance_stabilisation <- ggplot(tolerance_test, aes(x=Tolerance_factor, y=Coherence)) + 
  geom_boxplot() + 
  labs(title = "Steps required for model to stabilise",x = "Required proportion of same-group neighbours to be happy", y = "Number of steps before all agents were happy") +
  scale_y_continuous(breaks = seq(0, 60, by = 10))

tolerance_similarity <- ggplot(tolerance_test, aes(x=Tolerance_factor, y=Similaity_ratio
)) + 
  geom_boxplot()+ 
  labs(title = "Per-run average proportion of agent's same-group neighbours",x = "Required proportion of same-group neighbours to be happy", y = "Proportion of same-group neighbours") +
  scale_y_continuous(breaks = seq(0, 1, by = 0.05))


tolerance_dimension <- ggplot(tolerance_test, aes(x=Tolerance_factor, y=Dimension
)) + 
  geom_boxplot()+ 
  labs(title = "Embedded dimensionality of the network",x = "Required proportion of same-group neighbours to be happy", y = "Dimensionality") +
  scale_y_continuous(breaks = seq(0, 2, by=1))

#tolerance_test %>% group_by(Tolerance_factor) %>% summarize(m = mean(Similaity_ratio), c = mean(Coherence), d = mean(Dimension)) -> average_tolerances
#average_tolerances$Tolerance <- c(0.05,0.1,0.15,0.2,0.25,0.3,0.35,0.4,0.45,0.5,0.55,0.6,0.65,0.7,0.75,0.8,0.85,0.9,0.95,1)
#average_tolerances$diff <- (average_tolerances$m - average_tolerances$Tolerance)
#tolerance_similarity_baseline <- ggplot(average_tolerances,aes(x = Tolerance, y = m)) + geom_point()
#tolerance_similarity_difference <- ggplot(average_tolerances,aes(x = Tolerance, y = diff)) + geom_point()

tolerance_test %>% group_by(Tolerance) %>% summarize(Similarity = mean(Similaity_ratio), Dimension = mean(Dimension), Stabilisation = mean(Coherence))-> tolerance_average 

xtable(tolerance_average)

#group size testing
group_size_test %>% filter(Coherence > 0) -> size_finished_runs


size_stabilisation <- ggplot(size_finished_runs, aes(x=Size_factor, y=Coherence,fill=Tolerance_factor
)) + 
  geom_boxplot()+   
  labs(title = "Steps required for model to stabilise",x = "Size of smaller group", y = "Number of steps before all agents were happy") +
  scale_y_continuous(breaks = seq(0, 1000, by = 100))  +
  scale_fill_discrete("Tolerance")

size_finished_runs %>% group_by(Tolerance,Size) %>% summarize(m = mean(Similarity), d = mean(Dimension), g1 = mean(Group1_similarity), g2 = mean(Group2_similarity)) -> average_size

#size_similarity_all <- ggplot(size_finished_runs, aes(x=Size_factor, y=Similarity,fill=Tolerance_factor
#)) + 
#  geom_boxplot()
#size_similarity_group1 <- ggplot(size_finished_runs, aes(x=Size_factor, y=Group1_similarity
#,fill=Tolerance_factor
#)) + 
#  geom_boxplot()
#size_similarity_group2 <- ggplot(size_finished_runs, aes(x=Size_factor, y=Group2_similarity
#,fill=Tolerance_factor
#)) + 
#  geom_boxplot()


group_size_test %>% filter(Coherence > 0) %>% group_by(Size,Tolerance) %>% summarize(m = mean(Similarity), c = mean(Coherence), g1 = mean(Group1_similarity),g2 = mean(Group2_similarity),d = mean(Dimension)) -> average_group_size
average_group_size$diff = (average_group_size$m - average_group_size$Tolerance)
average_group_size$diff1 = (average_group_size$g1 - average_group_size$Tolerance)
average_group_size$diff2 = (average_group_size$g2 - average_group_size$Tolerance)
average_group_size$Tolerance_factor = as.factor(average_group_size$Tolerance)


size_dimension <- ggplot(average_group_size, aes(x=Size, y=d,col=Tolerance_factor,shape=Tolerance_factor
)) + 
  geom_point()+   
  labs(title = "Embedded dimensionality",x = "Size of smaller group", y = "Dimension") +
  scale_y_continuous(breaks = seq(0, 2, by = 0.5)) +
  scale_color_discrete("Tolerance") +
  scale_shape_discrete("Tolerance")


xtable(average_group_size)

size_similarity_baseline <- ggplot(average_group_size,aes(x = Size, y = m,col=Tolerance_factor,shape=Tolerance_factor)) + 
  geom_point() +
  labs(title = "Average proportion of same-group neighbours",x = "Size of smaller group", y = "Proportion of same-group neighbours") +
  scale_y_continuous(breaks = seq(0, 1, by = 0.05))


size_similarity_small_group <- ggplot(average_group_size,aes(x = Size, y = g1,col=Tolerance_factor,shape=Tolerance_factor)) + geom_point() +
labs(title = "Small group only: average proportion of same-group neighbours",x = "Size of smaller group", y = "Proportion of same-group neighbours") +
  scale_y_continuous(breaks = seq(0, 1, by = 0.05),limits = c(0.2,1)) +
  scale_color_discrete("Tolerance") +
  scale_shape_discrete("Tolerance")


average_group_size$large_group <- (1-average_group_size$Size)
size_similarity_large_group <- ggplot(average_group_size,aes(x = large_group, y = g2,col=Tolerance_factor,shape=Tolerance_factor)) + geom_point() +
  labs(title = "Large group only: average proportion of same-group neighbours",x = "Size of larger group", y = "Proportion of same-group neighbours") +
  scale_y_continuous(breaks = seq(0, 1, by = 0.05),limits = c(0.2,1)) +
  scale_color_discrete("Tolerance") +
  scale_shape_discrete("Tolerance")

plot_grid(size_similarity_small_group,size_similarity_large_group,labels="AUTO")

#DOESN'T WORK  
#size_dimension <- ggplot(group_size_test, aes(x=Size, y=Dimension,fill=Tolerance_factor
#)) + 
  #geom_boxplot()+   
  #labs(title = "Embedded dimensionality",x = "Size of smaller group", y = "Dimension") +
  #scale_y_continuous(breaks = seq(0, 2, by=1)) +
  #scale_color_discrete("Tolerance") +
  #scale_shape_discrete("Tolerance")



#size_similarity_all_difference <- ggplot(average_group_size,aes(x = Size, y = diff,col=Tolerance_factor,shape=Tolerance_factor)) + 
#  geom_point()
  
#size_similarity_g1_difference <- ggplot(average_group_size,aes(x = Size, y = diff1,col=Tolerance_factor,shape=Tolerance_factor)) + geom_point()
#size_similarity_g2_difference <- ggplot(average_group_size,aes(x = Size, y = diff2,col=Tolerance_factor,shape=Tolerance_factor)) + geom_point()

#asymmetric tolerance testing
asymmetric %>% group_by(g1_t,g2_t) %>% summarize(m = mean(Similaity_ratio), c = mean(Coherence), g1 = mean(g1_similarity),g2 = mean(g2_similarity),d = mean(Dimension),) -> asymmetric_average
asymmetric_average$Group1_tolerance_factor <- as.factor(asymmetric_average$g1_t)
asymmetric_stabilisation <- ggplot(asymmetric_average,aes(x = g2_t, y = c,colour = Group1_tolerance_factor,shape=Group1_tolerance_factor)) + geom_point() +
labs(title = "Steps required for model to stabilise",x = "Required proportion of same-group neighbours for group 2 to be happy", y = "Number of steps before all agents were happy") +
  scale_y_continuous(breaks = seq(0, 100, by = 10)) +
  scale_color_discrete("Group 1 Tolerance") +
  scale_shape_discrete("Group 1 Tolerance") 

asymmetric_similarity_all <- ggplot(asymmetric_average,aes(x = g2_t, y = m,col=Group1_tolerance_factor,shape=Group1_tolerance_factor)) + geom_point() +
  labs(title = "Average proportion of same-group neighbours",x = "Required proportion of same-group neighbours for group 2 to be happy", y = "Proportion of same-group neighbours") +
  scale_y_continuous(breaks = seq(0, 1, by = 0.05))+
  scale_color_discrete("Group 1 Tolerance") +
  scale_shape_discrete("Group 1 Tolerance") 


asymmetric_similarity_group1_fixed <- ggplot(asymmetric_average,aes(x = g2_t, y = g1,col=Group1_tolerance_factor,shape=Group1_tolerance_factor)) + geom_point() +
  labs(title = "Group 1 only: average proportion of same-group neighbours",x = "Required proportion of same-group neighbours for group 2 to be happy", y = "Proportion of same-group neighbours") +
  scale_y_continuous(breaks = seq(0, 1, by = 0.05))+
  scale_color_discrete("Group 1 Tolerance") +
  scale_shape_discrete("Group 1 Tolerance") 


asymmetric_similarity_group2_changing <- ggplot(asymmetric_average,aes(x = g2_t, y = g2,col=Group1_tolerance_factor,shape=Group1_tolerance_factor)) + geom_point() +
  labs(title = "Group 2 only: average proportion of same-group neighbours",x = "Required proportion of same-group neighbours for group 2 to be happy", y = "Proportion of same-group neighbours") +
  scale_y_continuous(breaks = seq(0, 1, by = 0.05))+
  scale_color_discrete("Group 1 Tolerance") +
  scale_shape_discrete("Group 1 Tolerance") 

plot_grid(asymmetric_similarity_group1_fixed,asymmetric_similarity_group2_changing,labels="AUTO")

xtable(asymmetric_average)

asymmetric_dimension <- ggplot(asymmetric_average,aes(x = g2_t, y = d,colour = Group1_tolerance_factor,shape=Group1_tolerance_factor)) + geom_point() +
  labs(title = "Embedded dimensionality",x = "Required proportion of same-group neighbours for group 2 to be happy", y = "Dimension") +
  scale_y_continuous(breaks = seq(0, 2, by = 0.5)) +
  scale_color_discrete("Group 1 Tolerance") +
  scale_shape_discrete("Group 1 Tolerance") 

#asymmetric_average$diff1 = (asymmetric_average$g1 - asymmetric_average$g1_t)
#asymmetric_average$diff2 = (asymmetric_average$g2 - asymmetric_average$g2_t)
#asymmetric_g1_difference <- ggplot(asymmetric_average,aes(x = g2_t, y = diff1,col=g1_t_factor,shape=g1_t_factor)) + geom_point()
#asymmetric_g2_difference <- ggplot(asymmetric_average,aes(x = g2_t, y = diff2,col=g1_t_factor,shape=g1_t_factor)) + geom_point()

#weak minority preferences testing
minority %>% group_by(g1_t,g2_t) %>% summarize(m = mean(Similarity), c = mean(Coherence), g1 = mean(Group1_similarity),g2 = mean(Group2_similarity)) -> minority_average
minority_average$Group1_tolerance_factor <- as.factor(minority_average$g1_t)
minority_average$Group2_tolerance_factor <- as.factor(minority_average$g2_t)
minority_average %>% filter(!g1_t %in% c(0.5,0.9)) -> minority_average_small
minority_average %>% filter(g1_t %in% c(0.5,0.9)) -> minority_average_large 

minority %>% filter(!g1_t %in% c(0.5,0.9)) -> minority_small
minority %>% filter(g1_t %in% c(0.5,0.9)) -> minority_large


minority_stabilisation_large <- ggplot(minority_large, aes(x=g1_t_factor, y=Coherence,fill=g2_t_factor)) + 
  geom_boxplot() + 
  labs(title = "Steps required for model to stabilise",x = "Required proportion of same-group neighbours for group 1 to be happy", y = "Number of steps before all agents were happy") +
  scale_y_continuous(breaks = seq(0, 500, by = 50)) +
  scale_fill_discrete("Group 2 Tolerance")

minority_stabilisation_small <- ggplot(minority_small, aes(x=g1_t_factor, y=Coherence,fill=g2_t_factor)) + 
  geom_boxplot() + 
  labs(title = "Steps required for model to stabilise",x = "Required proportion of same-group neighbours for group 1 to be happy", y = "Number of steps before all agents were happy") +
  scale_y_continuous(breaks = seq(0, 500, by = 50)) +
  scale_fill_brewer(palette="Dark2") +
  scale_fill_discrete("Group 2 Tolerance")

plot_grid(minority_stabilisation_large,minority_stabilisation_small,labels="AUTO")


minority_average %>% filter(!g1_t %in% c(0.5,0.9)) -> minority_average_small
minority_average %>% filter(g1_t %in% c(0.5,0.9)) -> minority_average_large 

xtable(minority_average_large)
xtable(minority_average_small)


minority_average_similarity <- ggplot(minority_average, aes(x=Group1_tolerance_factor, y=m,color=Group2_tolerance_factor,shape = Group2_tolerance_factor)) + 
  geom_point() + 
  labs(title = "Average proportion of same-group neighbours",x = "Required proportion of same-group neighbours for group 1 to be happy", y = "Proportion of same-group neighbours") +
  scale_y_continuous(breaks = seq(0, 1, by = 0.05))

minority_similarity_small <- ggplot(minority_average_small, aes(x=Group1_tolerance_factor, y=m,color=Group2_tolerance_factor,shape = Group2_tolerance_factor)) + 
  geom_point() + 
  labs(title = "Average proportion of same-group neighbours",x = "Required proportion of same-group neighbours for group 1 to be happy", y = "Proportion of same-group neighbours") +
  scale_y_continuous(breaks = seq(0, 1, by = 0.01))  +
  scale_color_brewer(palette="Dark2")+
  scale_color_discrete("Group 2 Tolerance") +
  scale_shape_discrete("Group 2 Tolerance") 


minority_similarity_large <- ggplot(minority_average_large, aes(x=Group1_tolerance_factor, y=m,color=Group2_tolerance_factor,shape = Group2_tolerance_factor)) + 
  geom_point() + 
  labs(title = "Average proportion of same-group neighbours",x = "Required proportion of same-group neighbours for group 1 to be happy", y = "Proportion of same-group neighbours") +
  scale_y_continuous(breaks = seq(0, 1, by = 0.025)) 
  scale_color_discrete("Group 2 Tolerance") +
  scale_shape_discrete("Group 2 Tolerance") 


plot_grid(minority_similarity_large,minority_similarity_small,labels="AUTO")


minority_group1_similarity <- ggplot(minority_average_small, aes(x=Group1_tolerance_factor, y=g1,color=Group2_tolerance_factor,shape = Group2_tolerance_factor)) + 
  geom_point() + 
  labs(title = "Group 1 only: average proportion of same-group neighbours",x = "Required proportion of same-group neighbours for group 1 to be happy", y = "Proportion of same-group neighbours") +
  scale_y_continuous(breaks = seq(0, 1, by = 0.01))  +
  scale_color_brewer(palette="Dark2") +
 scale_color_discrete("Group 2 Tolerance") +
  scale_shape_discrete("Group 2 Tolerance") 

minority_group2_similarity <- ggplot(minority_average_small, aes(x=Group1_tolerance_factor, y=g2,color=Group2_tolerance_factor,shape = Group2_tolerance_factor)) + 
  geom_point() + 
  labs(title = "Group 2 only: average proportion of same-group neighbours",x = "Required proportion of same-group neighbours for group 1 to be happy", y = "Proportion of same-group neighbours") +
  scale_y_continuous(breaks = seq(0, 1, by = 0.01)) +
  scale_color_discrete("Group 2 Tolerance") +
  scale_shape_discrete("Group 2 Tolerance") 


plot_grid(minority_group1_similarity,minority_group2_similarity,labels="AUTO")

minority_group1_similarity_large <- ggplot(minority_average_large, aes(x=Group1_tolerance_factor, y=g1,color=Group2_tolerance_factor,shape = Group2_tolerance_factor)) + 
  geom_point() + 
  labs(title = "Group 1 only: average proportion of same-group neighbours",x = "Required proportion of same-group neighbours for group 1 to be happy", y = "Proportion of same-group neighbours") +
  scale_y_continuous(breaks = seq(0, 1, by = 0.05))  +
  scale_color_brewer(palette="Dark2") +
  scale_color_discrete("Group 2 Tolerance") +
  scale_shape_discrete("Group 2 Tolerance") 

minority_group2_similarity_large <- ggplot(minority_average_large, aes(x=Group1_tolerance_factor, y=g2,color=Group2_tolerance_factor,shape = Group2_tolerance_factor)) + 
  geom_point() + 
  labs(title = "Group 2 only: average proportion of same-group neighbours",x = "Required proportion of same-group neighbours for group 1 to be happy", y = "Proportion of same-group neighbours") +
  scale_y_continuous(breaks = seq(0, 1, by = 0.01)) +
  scale_color_discrete("Group 2 Tolerance") +
  scale_shape_discrete("Group 2 Tolerance") 

plot_grid(minority_group1_similarity_large,minority_group2_similarity_large,labels="AUTO")
