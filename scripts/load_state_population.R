require(openxlsx)
require(dplyr)
require(stringr)

state_population <- read.xlsx("data/state_population_totals.xlsx",sheet = "data",
                              startRow = 5,rowNames = F)
#drop extra data
state_population <- state_population[!is.na(state_population$total_population),1:2]

#remove periods that start state names
state_population$name <- str_replace(string = state_population$name,pattern = "\\.",replacement = "")
head(state_population)
