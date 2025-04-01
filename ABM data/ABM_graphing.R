tolerance_test <- read.csv("tolerance-test-100-runs.csv",header = T)
tolerance_test$Tolerance_factor <- as.factor(tolerance_test$Tolerance)
group_size_test <- read.csv("group_size_1000_steps.csv",header=T)
group_size_test$Size_factor <- as.factor(group_size_test$Size)
group_size_test$Tolerance_factor <- as.factor(group_size_test$Tolerance)

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
tolerance_test %>% group_by(Tolerance_factor) %>% summarize(m = mean(Similaity_ratio), c = mean(Coherence)) -> average_tolerances
average_tolerances$diff <- (average_tolerances$m - average_tolerances$Tolerance)
tolerance_similarity_baseline <- ggplot(average_tolerances,aes(x = Tolerance, y = m)) + geom_point()
tolerance_average_
