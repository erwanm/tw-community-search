
library('reshape2')
library('ggplot2')

loadData <- function(filename="measures.csv") {
  read.csv(filename)
}

# filterElements(df,2,'A','vanilla')
# returns dataframe df filtered with series and device specified, and in the part corresponding to <wikiVersionRef>
# only the rows for which the 'element' exists in the rows corresponding to <wikiVersionProbe>.
#
filterElements <- function(data, seriesV, deviceV, wikiVersionProbe, wikiVersionRef='original') {
  dfRef <- subset(data, data$series==seriesV & data$device ==deviceV & data$wiki.version == wikiVersionRef)
  dfProbe <- subset(data, data$series==seriesV & data$device ==deviceV & data$wiki.version == wikiVersionProbe)
  dfRefMatch <- do.call(rbind, lapply(unique(dfProbe$element), function (elem) {
    dfRefM <- subset(dfRef, dfRef$element==elem)
  }))
  rbind(dfRefMatch, dfProbe)
}

boxPlotsFreeY <- function(df, xVar='wikiVersion', yVar='mainRefresh') {
  ggplot(df, aes_string(x=xVar,y=yVar,fill=xVar)) +geom_boxplot() + facet_grid(element ~ ., scales='free_y')
}
