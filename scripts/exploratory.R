require(openxlsx)
require(dplyr)
require(stringr)
require(data.table)

metro_data <- read.xlsx("data/Metropolitan Statistical Areas 2010-2016.xlsx",
                        sheet = "data",startRow = 3,colNames = T)

#get state codes
metro_data <- metro_data %>% mutate(
              state = str_sub(str_extract(string = Geography2,pattern = ", [:upper:]{2}"),start = 3,end = 4),
              state_one = str_sub(str_extract(string = Geography2,pattern = "[:upper:]{2}-[:upper:]{2}"),1,2),
              state_two = str_sub(str_extract(string = Geography2,pattern = "[:upper:]{2}-[:upper:]{2}"),4,5),
              state_three = str_sub(str_extract(string = Geography2,pattern = "[:upper:]{2}-[:upper:]{2}-[:upper:]{2}"),7,8)
)

#duplicate rows for metro areas in multiple states

#add one copy for metro areas in two states, two for metro areas in three states
metro_data <- rbind(metro_data,metro_data[!is.na(metro_data$state_two),],metro_data[!is.na(metro_data$state_three),])

metro_data <- mutate(metro_data,
                     state = ifelse(duplicated(metro_data),state_two,state))

metro_data <- mutate(metro_data,
                     state = ifelse(duplicated(metro_data),state_three,state))

#check results
metro_data <- arrange(metro_data,Geography2)
metro_data[metro_data$Geography2 == "Allentown-Bethlehem-Easton, PA-NJ Metro Area" | 
             metro_data$Geography2 == "Chicago-Naperville-Elgin, IL-IN-WI Metro Area",]

metro_data <- select(metro_data,Geography2,state,Census_2010,Estimate_2016)
metro_data <- rename(metro_data,
                     name = Geography2,
                     census_2010 = Census_2010,
                     estimate_2016 = Estimate_2016)

metro_data <- filter(metro_data,
                     !is.na(state),
                     !(state %in% c("PR","DC")))
#load capitals
source(load_capitals.R)

#merge capitals
metro_data <- merge(metro_data,capitals,by.x = "state",by.y = "Code",all = T)

metro_data <- arrange(metro_data,state,estimate_2016)

#process ranks and capital info
metro_data <- metro_data %>% group_by(state) %>% mutate(
                     is_capital = str_detect(string = name,pattern = capital),
                     has_capital = max(is_capital),
                     pop_rank = percent_rank(estimate_2016),
                     capital_rank = is_capital*pop_rank,
                     pop_pct_from_biggest = (max(estimate_2016) - estimate_2016)/estimate_2016,
                     capital_pct_from_biggest = is_capital*pop_pct_from_biggest
              )


### Make state-level dataset ###
state_level <- metro_data %>% group_by(state) %>%
              summarise(state_name = state_name[1],
                        has_capital = max(has_capital),
                        capital_is_largest = max(is_capital & estimate_2016 == max(estimate_2016)),
                        total_metro_pop = sum(estimate_2016),
                        capital_rank = max(capital_rank),
                        capital_pct_from_biggest = max(capital_pct_from_biggest)
                        )

#merge government quality ranks
source("scripts/load_gov_ranks.R")


metro_data <- merge(metro_data,gov_ranks,by.x = "state_name",by.y = "state",all = T)
metro_state_level <- merge(state_level,gov_ranks,by.x = "state_name",by.y = "state",all = T)

lm(rank ~ capital_is_largest + total_metro_pop, data = metro_state_level)
lm(mean_subranks ~ capital_is_largest + total_metro_pop, data = metro_state_level)

metro_regs <- lapply(outcome_vars,FUN = run_reg,data = metro_state_level)
stargazer(metro_regs,type = "text")
