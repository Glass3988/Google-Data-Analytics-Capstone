##STEP 1: download tidyverse package ##
install.packages("tidyverse")
library(tidyverse)

##STEP 2: import and load dataframes ##
q1_2019 <- read_csv("Divvy_Trips_2019_Q1.csv")
q1_2020 <- read_csv("Divvy_Trips_2020_Q1.csv")


##STEP 3: review imported data ##
colnames(q1_2019)
colnames(q1_2020)

str(q1_2019)
str(q1_2020)

head(q1_2019)
head(q1_2020)

glimpse(q1_2019)
glimpse(q1_2020)


##STEP 4: match all column names with most current quarter ##
q1_2019 <- rename(q1_2019, 
                  ride_id = trip_id,
                  rideable_type = bikeid,
                  started_at = start_time,
                  ended_at = end_time,
                  start_station_name = from_station_name,
                  start_station_id = from_station_id,
                  end_station_name = to_station_name,
                  end_station_id = to_station_id,
                  member_casual = usertype)



##STEP 5: review if changes worked ##
colnames(q1_2019)
colnames(q1_2020)



##STEP 6: mutate or delete incongruent data types and columns so ##
## both data frames can be bound together in new frame ##
q1_2019 <- q1_2019 %>%
  mutate(ride_id = as.character(ride_id),
         rideable_type = as.character(rideable_type),
         started_at = ymd_hms(started_at),
         ended_at = ymd_hms(ended_at),
         ride_length = as.numeric(difftime(ended_at, started_at, units = 'secs')))

q1_2020 <- q1_2020 %>%
  mutate(started_at = ymd_hms(started_at),
         ended_at = ymd_hms(ended_at),
         ride_length = as.numeric(difftime(ended_at, started_at, units = 'secs')))


all_trips <- bind_rows(q1_2019, q1_2020)


all_trips <- all_trips %>%
  select(-c(start_lat, start_lng, end_lat, end_lng, birthyear, gender, tripduration))


##STEP 7: review data in new data frame ##
colnames(all_trips)

head(all_trips)

str(all_trips)

glimpse(all_trips)

summary(all_trips)


##STEP 8: reassign labels in member_casual for consolidation ##
table(all_trips$member_casual)

all_trips <- all_trips %>%
  mutate(member_casual = recode(member_casual,
                                "Subscriber" = "member",
                                "Customer" = "casual"))

table(all_trips$member_casual)


##STEP 9: add day, month, and year columns for more ways to aggregate data ##
all_trips$date <- as.Date(all_trips$started_at)

all_trips <- all_trips %>%
  mutate(month = format(as.Date(all_trips$date), "%m"),
         day = format(as.Date(all_trips$date), "%d"),
         year = format(as.Date(all_trips$date), "%Y"),
         day_of_week = format(as.Date(all_trips$date), "%A"),
         time_of_day = format(as.POSIXct(all_trips$started_at), "%H"))



##STEP 10: mutate ride_length data type to numeric, and to seconds instead of minutes ##
all_trips <- all_trips %>%
  mutate(ride_length = as.numeric(difftime(ended_at, started_at, units = 'secs')))


##STEP 11: remove entries where bikes were taken out for quality inspection, ## 
## and where ride_length data is negative ##
all_trips_v2 <- all_trips[!(all_trips$start_station_name == "HQ QR" | 
                              all_trips$end_station_name == "HQ QR" | all_trips$ride_length<0),]


##STEP 12: various descriptive analysis functions of ride_length in all_trips_v2 ##
summary(all_trips_v2)

mean(all_trips_v2$ride_length) 

median(all_trips_v2$ride_length) 

max(all_trips_v2$ride_length)

min(all_trips_v2$ride_length)


##STEP 13: Compare ride_length descriptive analysis aggregate outputs ##
## between Members and Casuals ##
aggregate(all_trips_v2$ride_length ~ all_trips_v2$member_casual, FUN = mean)

aggregate(all_trips_v2$ride_length ~ all_trips_v2$member_casual, FUN = median)

aggregate(all_trips_v2$ride_length ~ all_trips_v2$member_casual, FUN = max)

aggregate(all_trips_v2$ride_length ~ all_trips_v2$member_casual, FUN = min)


##STEP 14: Compare average ride_length between Members and Casuals for ##
## each day of the week ##
all_trips_v2$day_of_week <- ordered(all_trips_v2$day_of_week, 
                                    levels=c("Sunday", 
                                             "Monday",
                                             "Tuesday", 
                                             "Wednesday", 
                                             "Thursday", 
                                             "Friday", 
                                             "Saturday"))


aggregate(all_trips_v2$ride_length ~ all_trips_v2$member_casual + 
            all_trips_v2$day_of_week, FUN = mean)



##STEP 16: Total number and average duration of rides by both members and casuals
## for each day of the week ##
all_trips_v2 %>%
  group_by(member_casual, day_of_week) %>%
  summarise(number_of_rides = n(),
            average_duration = mean(ride_length))


##STEP 17: Various graphs of number_of_rides by rider type ##


## num of rides for days of week
all_trips_v2 %>%
  group_by(member_casual, day_of_week) %>%
  summarise(Total_Rides = n()) %>%
  ggplot(aes(x = day_of_week, y = Total_Rides, fill = member_casual)) +
  geom_col(position = "dodge") + 
  scale_y_continuous (labels = scales::comma) +
  labs(title = "Total Rides by Rider Type for each Day of Week")


## num of rides for days of month
all_trips_v2 %>%
  group_by(member_casual, day) %>%
  summarise(Total_Rides = n()) %>%
  ggplot(aes(x = day, y = Total_Rides, fill = member_casual)) +
  geom_col() +
  labs(title = "Total Rides by Rider Type for Each Day of Month")


## Number of rides throughout the day
all_trips_v2 %>%
  group_by(member_casual, time_of_day) %>%
  summarise(Total_Rides = n()) %>%
  ##slice_max(totals, n = 10) %>%
  ggplot(aes(x = time_of_day, y = Total_Rides, fill = member_casual)) +
  theme(axis.text.x = element_text(angle = 45)) +
  geom_col(position = "dodge") +
  labs(title = "Total Number of Rides Throughout Hours of the Day")



## faceted
all_trips_v2 %>%
  group_by(member_casual, day_of_week) %>%
  summarise(number_of_rides = n()) %>%
  ggplot(aes(x = day_of_week, y = number_of_rides)) +
  facet_wrap(~member_casual) +
  geom_col() +
  theme(axis.text.x = element_text(angle = 45)) +
  labs(title = "Number of Rides by Rider Type for each Day of the Week: Faceted")


##STEP 18: Various graphs of average_duration by rider type ##


## Average duration of rides for days of week
all_trips_v2 %>%
  group_by(member_casual, day_of_week) %>%
  summarise(Average_Duration = mean(ride_length)) %>%
  ggplot(aes(x = day_of_week, y = Average_Duration, fill = member_casual)) +
  geom_col(position = "dodge") + 
  labs(title = "Average Ride Duration by Rider Type for Each Day of Week")


## Average duration of rides for days of month
all_trips_v2 %>%
  group_by(member_casual, day) %>%
  summarise(Average_Duration = mean(ride_length)) %>%
  ggplot(aes(x = day, y = Average_Duration, fill = member_casual)) +
  geom_col() + 
  labs(title = "Average Ride Duration by Rider Type for Each Day of Month")


## Average duration of rides throughout the day
all_trips_v2 %>%
  group_by(member_casual, time_of_day) %>%
  summarise(Average_Duration = mean(ride_length)) %>%
  ##slice_max(average_duration, n = 10) %>%
  ggplot(aes(x = time_of_day, y = Average_Duration, fill = member_casual)) +
  theme(axis.text.x = element_text(angle = 45)) +
  geom_col(position = "dodge") +
  labs(title = "Average Duration of Rides Throughout Hours of the Day")


## faceted
all_trips_v2 %>%
  group_by(member_casual, day_of_week) %>%
  summarise(average_duration = mean(ride_length)) %>%
  ggplot(aes(x = day_of_week, y = average_duration)) +
  facet_wrap(~member_casual) +
  geom_col() +
  theme(axis.text.x = element_text(angle = 45)) +
  labs(title = "Average Ride Duration by Rider Type for each Day of the Week: Faceted")




## STEP 19: Start and End Station Frequency ##


## Total Start Station SORTS, HISTOGRAMS, GRAPHS 
sort(table(all_trips_v2$start_station_id), decreasing = TRUE)
sort(table(all_trips_v2$start_station_name), decreasing = TRUE)

## 30 bins, 20 stations each
all_trips_v2 %>%
  group_by(member_casual, start_station_id) %>%
  ggplot(aes(x = start_station_id, fill = member_casual)) +
  geom_histogram(position = "dodge") + 
  labs(title = "Histogram of Instances a Station was the Start of a Ride")

## total time start
all_trips_v2 %>%
  group_by(member_casual, start_station_id) %>%
  summarise(Total_Start_Instances = n()) %>%
  #slice_max(Total_Start_Instances, n = 10) %>%
  ggplot(aes(x = start_station_id, y = Total_Start_Instances, fill = member_casual)) +
  theme(axis.text.x = element_text(angle = 45)) +
  geom_col() +
  labs(title = "Total of Each Station Being the Start of a Ride")


## when were they starts
all_trips_v2 %>%
  group_by(member_casual, start_station_id, time_of_day) %>%
  summarise(Total_Start_Instances = n()) %>%
  ##slice_max(total_starts, n = 10) %>%
  ggplot(aes(x = time_of_day, y = Total_Start_Instances, fill = member_casual)) +
  theme(axis.text.x = element_text(angle = 45)) +
  geom_col(position = "dodge") +
  labs(title = "Instances When a Ride Begins During the Day")


## Total End Station SORTS, HISTOGRAMS, GRAPHS 
sort(table(all_trips_v2$end_station_id), decreasing = TRUE)
sort(table(all_trips_v2$end_station_name), decreasing = TRUE)


## 30 bins, 20 stations each
all_trips_v2 %>%
  group_by(member_casual, end_station_id) %>%
  ggplot(aes(x = end_station_id, fill = member_casual)) +
  geom_histogram(position = "dodge") +
  labs(title = "Histogram of Instances a Station was the End of a Ride")



## Total times end
all_trips_v2 %>%
  group_by(member_casual, end_station_id) %>%
  summarise(Total_End_Instances = n()) %>%
  slice_max(Total_End_Instances, n = 10) %>%
  ggplot(aes(x = end_station_id, y = Total_End_Instances, fill = member_casual)) +
  theme(axis.text.x = element_text(angle = 45)) +
  geom_col() + 
  labs(title = "Total of Each Station Being the End of a Ride")



## When were they ends
all_trips_v2 %>%
  group_by(member_casual, end_station_id, time_of_day) %>%
  summarise(Total_End_Instances = n()) %>%
  ##slice_max(total_starts, n = 10) %>%
  ggplot(aes(x = time_of_day, y = Total_End_Instances, fill = member_casual)) +
  theme(axis.text.x = element_text(angle = 45)) +
  geom_col(position = "dodge") + 
  labs(title = "Instances When a Ride Ends During the Day")




## STEP 20: Find the most frequented routes traveled by members and casuals

## Create Route Columns for Analysis
all_trips_v2$stationid_pairs <- paste(all_trips_v2$start_station_id, ",", all_trips_v2$end_station_id)
all_trips_v2$stationname_pairs <- paste(all_trips_v2$start_station_name, ",", all_trips_v2$end_station_name)

## Top 10 Most Frequented Routes
all_trips_v2 %>%
  group_by(member_casual, stationid_pairs) %>%
  summarise(Total_Start_and_End = n()) %>%
  slice_max(Total_Start_and_End, n = 10) %>%
  ggplot(aes(x = fct_reorder(stationid_pairs, Total_Start_and_End),
             y = Total_Start_and_End, fill = member_casual)) +
  theme(axis.text.x = element_text(angle = 45)) +
  geom_col() +
  labs(title = "Top 10 Most Frequented Start and End Stations")

## STATION NAME
all_trips_v2 %>%
  group_by(member_casual, stationname_pairs) %>%
  summarise(Total_Start_and_End = n()) %>%
  slice_max(Total_Start_and_End, n = 10)



## Most Frequented Route for Any Given Week by member_casual
all_trips_v2 %>%
  group_by(member_casual, day_of_week, stationname_pairs) %>%
  summarise(Start_and_End = n()) %>%
  slice_max(Start_and_End, n = 1) %>%
  ##print(n = 28) %>%
  ggplot(aes(x = day_of_week, y = Start_and_End, fill = stationname_pairs)) +
  facet_wrap(~member_casual) +
  theme(axis.text.x = element_text(angle = 45)) +
  geom_col(position = "dodge") +
  labs(title = "Most Frequented Start and End Stations During the Week")+
  theme(legend.position="bottom")




## Most Frequented Route for Any Given Week, Station Name
all_trips_v2 %>%
  group_by(member_casual, day_of_week, stationname_pairs) %>%
  summarise(Start_and_End = n()) %>%
  slice_max(Start_and_End, n = 1)






## USELESS ##
## Most Frequented Route for Any Given Week by stationid_pairs
all_trips_v2 %>%
  group_by(member_casual, day_of_week, stationid_pairs) %>%
  summarise(Start_and_End = n()) %>%
  slice_max(Start_and_End, n = 1) %>%
  ##print(n = 28) %>%
  ggplot(aes(x = fct_reorder(day_of_week, Start_and_End), y = Start_and_End, fill = stationid_pairs)) +
  theme(axis.text.x = element_text(angle = 45)) +
  geom_col(position = "dodge") +
  labs(title = "Most Frequented Start and Stop Stations During Week: Station Id Pairs")




write.csv(all_trips_v2, file = 'thing.csv')




