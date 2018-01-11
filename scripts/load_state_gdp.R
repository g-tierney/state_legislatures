require(openxlsx)
require(dplyr)
require(stringr)

state_gdp <- read.xlsx("data/state_gdp.xlsx",sheet = "gdp",
                              startRow = 6)
state_gdp <- state_gdp[!is.na(state_gdp$gdp_2016),1:2]

state_gdp$name <- str_trim(str_replace_all(state_gdp$name,pattern = "[^[:alpha:] ]",replacement = ""))
head(state_gdp)
