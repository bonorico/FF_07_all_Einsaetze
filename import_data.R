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

rmean <- weeklyd$n |> mean() # arithmetic mean: this is overestimating the rate because it is not normalizing by number of weeks --> average weekly rate

# Process homogeneous rate
rhom <- sum(weeklyd$n)/max(weeklyd$Week)

# theoretical model assuming an homogeneous counting process with rare = r
# test for homogeneity by plotting observed counting process against theoretical expected and sample of CPs 

simn <- do.call(
  "rbind",
  lapply(1:50,
         function(i) {
           set.seed(260+i)
           tibble(
             Week = weeklyd$Week,
             n = rpois(dim(weeklyd)[1], rmean)
           ) |> 
             mutate(
               N = cumsum(n),
               repl = i
             )
          
         })
)


hist(weeklyd$n, xlab = "Weekly rates")

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
  data = simn,
  aes(Week, N, group = repl)
  ) + 
  geom_step(
    alpha = 0.5, colour = "grey"
    ) + 
  geom_step(
    data = weeklyd |> 
      select(Week, n) |> 
      arrange(Week) |> 
      mutate(
        N = cumsum(n),
        repl = 0,
        type = "Observed"
      ) |> 
      bind_rows(
        weeklyd |> 
          filter(n < 10) |> 
          arrange(Week) |> 
          mutate(
            N = cumsum(n),
         #   repl = 0,
            type = "Observed (n < 10)"
          )
      ),
    aes(Week, N, colour = type),
    linewidth = 1
    ) +
  ylab("Kumulative Anzahl der Einsätze je Woche") 


gridExtra::grid.arrange(
  
  p1, p2
  
)


