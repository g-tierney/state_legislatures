require(openxlsx)
require(dplyr)

capitals <- read.xlsx("data/state_capitals.xlsx",sheet = "data")
capitals <- select(capitals,Code,Capital,Name)
capitals <- rename(capitals,
                   capital = Capital,
                   state_name = Name)

#standardize names
capitals$capital[capitals$Code == "MN"] <- "St. Paul"