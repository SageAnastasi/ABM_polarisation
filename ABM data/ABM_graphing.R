setwd("~/GitHub/ABM_polarisation/ABM data")

tolerance_test <- read.csv("tolerance-test-100-runs.csv",header = T)
tolerance_test$Tolerance_factor <- as.factor(tolerance_test$Tolerance)
group_size_test <- read.csv("group_size_1000_steps.csv",header=T)
group_size_test$Size_factor <- as.factor(group_size_test$Size)
group_size_test$Tolerance_factor <- as.factor(group_size_test$Tolerance)
asymmetric <- read.csv("asymmetric-tolerance.csv",header=T)
asymmetric$g1_t_factor <- as.factor(asymmetric$g1_t)
asymmetric$g2_t_factor < - as.factor(asymmetric$g2_t)
minority <- read.csv("weak-minority-preferences.csv",header=T)
minority$g1_t_factor <- as

library(ggplot2)


#tolerance testing
tolerance_stabilisation <- ggplot(tolerance_test, aes(x=Tolerance_factor, y=Coherence)) + 
  geom_boxplot()
tolerance_similarity <- ggplot(tolerance_test, aes(x=Tolerance_factor, y=Similaity_ratio
)) + 
  geom_boxplot()
tolerance_dimension <- ggplot(tolerance_test, aes(x=Tolerance_factor, y=Dimension
)) + 
  geom_boxplot()

#group size testing
size_stabilisation <- ggplot(group_size_test, aes(x=Size_factor, y=Coherence,fill=Tolerance_factor
)) + 
  geom_boxplot()
size_similarity_all <- ggplot(group_size_test, aes(x=Size_factor, y=Similarity,fill=Tolerance_factor
)) + 
  geom_boxplot()

size_dimension <- ggplot(group_size_test, aes(x=Size_factor, y=Dimension,fill=Tolerance_factor
)) + 
  geom_boxplot()
size_similarity_group1 <- ggplot(group_size_test, aes(x=Size_factor, y=Group1_similarity
,fill=Tolerance_factor
)) + 
  geom_boxplot()
size_similarity_group2 <- ggplot(group_size_test, aes(x=Size_factor, y=Group2_similarity
,fill=Tolerance_factor
)) + 
  geom_boxplot()


library(dplyr)
tolerance_test %>% group_by(Tolerance_factor) %>% summarize(m = mean(Similaity_ratio), c = mean(Coherence), d = mean(Dimension)) -> average_tolerances
average_tolerances$Tolerance <- c(0.05,0.1,0.15,0.2,0.25,0.3,0.35,0.4,0.45,0.5,0.55,0.6,0.65,0.7,0.75,0.8,0.85,0.9,0.95,1)
average_tolerances$diff <- (average_tolerances$m - average_tolerances$Tolerance)
tolerance_similarity_baseline <- ggplot(average_tolerances,aes(x = Tolerance, y = m)) + geom_point()
tolerance_similarity_difference <- ggplot(average_tolerances,aes(x = Tolerance, y = diff)) + geom_point()


#group size tolerance/smilarity difference testing
group_size_test %>% group_by(Size,Tolerance) %>% summarize(m = mean(Similarity), c = mean(Coherence), g1 = mean(Group1_similarity),g2 = mean(Group2_similarity),d = mean(Dimension)) -> average_group_size
average_group_size$diff = (average_group_size$m - average_group_size$Tolerance)
average_group_size$diff1 = (average_group_size$g1 - average_group_size$Tolerance)
average_group_size$diff2 = (average_group_size$g2 - average_group_size$Tolerance)
average_group_size$Tolerance_factor = as.factor(average_group_size$Tolerance)
size_similarity_baseline <- ggplot(average_group_size,aes(x = Size, y = m,col=Tolerance_factor,shape=Tolerance_factor)) + geom_point()
size_similarity_all_difference <- ggplot(average_group_size,aes(x = Size, y = diff,col=Tolerance_factor,shape=Tolerance_factor)) + geom_point()
size_similarity_g1_difference <- ggplot(average_group_size,aes(x = Size, y = diff1,col=Tolerance_factor,shape=Tolerance_factor)) + geom_point()
size_similarity_g2_difference <- ggplot(average_group_size,aes(x = Size, y = diff2,col=Tolerance_factor,shape=Tolerance_factor)) + geom_point()
size_convergence <- ggplot(average_group_size,aes(x = Size, y = c,col=Tolerance_factor,shape=Tolerance_factor)) + geom_point()

#asymmetric tolerance testing
asymmetric %>% group_by(g1_t,g2_t) %>% summarize(m = mean(Similaity_ratio), c = mean(Coherence), g1 = mean(g1_similarity),g2 = mean(g2_similarity),d = mean(Dimension),) -> asymmetric_average
asymmetric_average$g1_t_factor <- as.factor(asymmetric_average$g1_t)
asymmetric_convergence <- ggplot(asymmetric_average,aes(x = g2_t, y = c,col=g1_t_factor,shape=g1_t_factor)) + geom_point()
asymmetric_average$diff1 = (asymmetric_average$g1 - asymmetric_average$g1_t)
asymmetric_average$diff2 = (asymmetric_average$g2 - asymmetric_average$g2_t)
asymmetric_g1_difference <- ggplot(asymmetric_average,aes(x = g2_t, y = diff1,col=g1_t_factor,shape=g1_t_factor)) + geom_point()
asymmetric_g2_difference <- ggplot(asymmetric_average,aes(x = g2_t, y = diff2,col=g1_t_factor,shape=g1_t_factor)) + geom_point()

#weak minority preferences testing

