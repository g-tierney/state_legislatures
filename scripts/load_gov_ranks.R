require(openxlsx)
require(dplyr)
require(stringr)
require(data.table)

gov_ranks <- read.xlsx("data/usnews_state_government_ranks.xlsx",sheet = "data")
names(gov_ranks) <- str_to_lower(str_replace_all(names(gov_ranks),pattern = "\\.","_"))
gov_ranks <- mutate(gov_ranks,
                    mean_subranks = (fiscal_stability+budget_transparency+government_digitalization+state_integrity)/4,
                    mean_non_digitization = (fiscal_stability+budget_transparency+state_integrity)/3,
                    rank = as.numeric(str_replace(government_rank,"\\#","")),
                    government_rank = NULL,
                    state = str_trim(state)
)
