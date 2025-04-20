#' Upload 'scraped' data and further clean it
#' 
#' 
#' 

library(tidyverse)

data <- read.csv(
  "./data/einsaetze_abt07_cleaned_stripped.csv"
) |> 
  mutate(
    Zusammenfassung = unlist(
      lapply(
        stringr::str_split(data$Zusammenfassung, "Details"),
        function(x)
          x[1]
      )
      
    )
  ) |> 
  mutate(
    Zusammenfassung = unlist(
      lapply(
        stringr::str_split(Zusammenfassung, "//feuer"),
        function(x){
          if (length(x) > 1)
            NA_character_
          else
            x[1]
        }
          
      )
      
    ),
    
    einsatz_status = 1,
    
    Datum = lubridate::dmy_hm(Datum, tz = "CET"),
    Yearmonth = as.Date(Datum),
    Week = difftime(
      Yearmonth, min(Yearmonth), units = "week"
    ) |> 
      as.numeric() |> 
      round()
  )


weeklyd <- data |> 
  count(Week, einsatz_status)

labeld <- weeklyd |> filter(n>=10) |> 
  left_join(
    data |> 
      distinct(Yearmonth, Week),
by = "Week"
) |> 
  mutate(
    Y = 
      as.character(lubridate::year(Yearmonth)),
    M = as.character(lubridate::month(Yearmonth)),
    
    YM = paste(Y,M, sep = "-")
    ) |> 
  distinct(Week, n, YM)
    

# mean weekly count

r <- weeklyd$n |> mean()

# theoretical model assuming an homogeneous counting process with rare = r

set.seed(26097)

simn <- rpois(dim(weeklyd)[1], r)

p1 <- ggplot(
  weeklyd,
  aes(Week, n)
) + 
  geom_point() +
  geom_line() +
  geom_text(
    data = labeld,
    aes(Week, n, label = YM), 
    hjust = -0.5          
  ) +
  ylab("Anzahl der Einsätze je Woche")

p2 <- ggplot(
  weeklyd |> 
    select(Week, n) |> 
    mutate(
      N = cumsum(n),
      type = "Observed"
    ) |> 
    bind_rows(
      tibble(
        Week = weeklyd$Week,
        n = simn,
        N = cumsum(n),
        type = "Theoretical"
      )
      
    ),
  aes(Week, N, colour = type)
) + geom_step() +
  ylab("Kumulative Anzahl der Einsätze je Woche") 


gridExtra::grid.arrange(
  
  p1, p2
  
)


