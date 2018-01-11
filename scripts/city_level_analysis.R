require(openxlsx)
require(dplyr)
require(stringr)
require(data.table)
require(stargazer)
require(ggplot2)

city_data <- read.xlsx("data/all_cities.xlsx",sheet = "data",startRow = 3)

city_data <- city_data %>% mutate(comma_spot = str_locate(string = name,pattern = ",")[,1],
                                  semicolon_spot = str_locate(string = name,pattern = ";")[,1],
                                  state_name = str_sub(name,start = pmax(semicolon_spot,comma_spot,na.rm = T)+2,end = str_length(name)))
head(city_data)

table(city_data$state_name)                                  

#add capitals
source("scripts/load_capitals.R")

#standardize capital name
capitals$capital[capitals$state_name == "Minnesota"] <- "St. Paul city"
capitals$capital[capitals$state_name == "Ohio"] <- "Columbus city"
capitals$capital[capitals$state_name == "Hawaii"] <- "Urban Honolulu CDP, Hawaii"


city_data <- inner_join(city_data,capitals, by = c("state_name"))

#add population
source("scripts/load_state_population.R")
city_data <- left_join(city_data,state_population,by = c("state_name" = "name"))

#rank cities
city_data <- city_data %>% group_by(state_name) %>% mutate(
            is_capital = str_detect(string = name,pattern = paste0("^",capital)),
            has_capital = max(is_capital),
            pop_percentage = pop_2016/total_population*100,
            capital_pop_percentage = is_capital*pop_percentage,
            pop_ratio_from_biggest = pop_2016/max(pop_2016),
            capital_pct_from_biggest = is_capital*pop_ratio_from_biggest
          )

#check capitals correct
check_capitals <- city_data %>% group_by(state_name) %>% filter(is_capital == 1) %>% 
          summarize(
            num_capitals = sum(is_capital),
            name_one = name[1],
            name_two = name[2]
          )
check_capitals

### Make state-level dataset ###
state_level <- city_data %>% group_by(state_name) %>%
  summarise(
            has_capital = max(has_capital),
            capital_is_largest = max(is_capital & pop_2016 == max(pop_2016)),
            total_pop = mean(total_population)/100000,
            capital_pop_percentage = max(capital_pop_percentage),
            capital_pct_from_biggest = max(capital_pct_from_biggest)
  )

#add gov quality ranks
source("scripts/load_gov_ranks.R")
state_level <- inner_join(state_level,gov_ranks, by = c("state_name" = "state"))

#add gdp for control
source("scripts/load_state_gdp.R")
state_gdp$gdp_2016 <- state_gdp$gdp_2016/100000
state_level <- left_join(state_level,state_gdp,by = c("state_name" = "name"))

#function to run regression for different outcome variables
run_reg <- function(outcome_var,var_interest,data = state_level){
  formula <- as.formula(paste0(outcome_var, " ~ ",var_interest, " + total_pop + gdp_2016"))
  lm(formula = formula,data = data)
}

outcome_vars <- c("rank","mean_subranks","fiscal_stability","state_integrity"
                  #"fiscal_stability","budget_transparency","government_digitalization","state_integrity"
                  )
city_regs <- lapply(outcome_vars,FUN = run_reg,data = state_level,var_interest = "capital_pop_percentage")

outcome_labels <- c("Overall Rank","Mean of Subscores","Fiscal Stability","State Integrity"
                    #"Fiscal Stability","Budget Transparency","Government Digitization","State Integrity",
                    )
independent_var_labels <- c("Percentage of Population in Capital City","State Popluation (100,000)","State GDP (100,000s)")
stargazer(city_regs,type = "latex",header = F,
          dep.var.labels = outcome_labels,
          covariate.labels = independent_var_labels,float=FALSE,
          #notes = "Data are from 2016. Population and GDP are reported in 100,000s. Asterisks indicate significance at the 10/5/1 percent levels.",notes.align = "l",notes.append = F,
          out = "output/city_regression_results.tex")

#plot percentage of pop in captial vs ranking
jpeg(file = "output/population_percentage_gov_rank_scatter.jpeg")
ggplot(state_level,aes(x=capital_pop_percentage,y=rank)) + 
  geom_point(colour = "black",fill = "black") + 
  geom_smooth(method=lm) +
  xlab("Percent of Population in Capital City") + 
  ylab("U.S. News Government Rank") +
  ggtitle("Population Distribution and Government Quality") + theme(plot.title = element_text(hjust = 0.5))
dev.off()

