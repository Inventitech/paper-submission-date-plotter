library(ggplot2)
library(parsedate)
library(scales)
library(plotly)

files <- list.files(path = ".", pattern = "*-arrivals.csv$")
for(file in files) {
  data <- read.csv(file, header = F)
  write.csv(data, paste(file, "-cleaned", sep=""))
}

system("for f in *-cleaned; do sed s/$/,${f}/ -i ${f}; done;")
system("cat *-cleaned > arrivals.csv")

system("grep -v 'V1' arrivals.csv > arrivals-t.csv && mv arrivals-t.csv arrivals.csv")

system("sed 's/\\.csv//' -i arrivals.csv")
system("sed 's/-arrivals-cleaned//' -i arrivals.csv")
system("sed '1s/^/id,date,venue\\n/' -i arrivals.csv")

data <- read.csv("arrivals.csv")
data$id <- as.numeric(data$id)
data$date <- parse_date(as.character(data$date))

prepared.data <- NULL
for(v in unique(data$venue)) {
  data.s <- subset(data, venue == v)
  
  max.date <- max(data.s$date)
  max.id <- max(data.s$id)
  
  threshold.date <- max.date - as.difftime(5, unit="days")
  data.s <- data.s[data.s$date > threshold.date,]
  
  data.s$date <- as.POSIXct(as.numeric(as.POSIXct(data.s$date)) - as.numeric(as.POSIXct(threshold.date)), origin="1970-01-01", tz="UTC")
  
  if(data.s[1,]$id > 1) {
    data.s <- rbind(data.s, data.frame(id=data.s[1,]$id-1, date=as.POSIXct("1970-01-01", format = "%Y-%m-%d"), venue=data.s[1,]$venue))
  }
  data.s$id <- data.s$id/max.id
  
  
  if(!exists("prepared.data")) {
    prepared.data <<- data.s 
  }
  else {
    prepared.data <<- rbind(prepared.data, data.s)
  }
}

g <- ggplot(prepared.data, aes(date, id, color=venue)) + geom_line() +
  scale_x_datetime(date_breaks = "1 day") + 
  scale_y_continuous(labels = scales::percent) +
  xlab("") + ylab("% of Submissions Received") + theme(legend.position = "bottom")
ggplotly(g)