
# This is the server logic for a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
#

require (e1071)

library(shiny)
library(caret)
library(randomForest)
library(rpart)
library(rpart.plot)

if (!file.exists("pml-training.csv")) {
  download.file("http://d396qusza40orc.cloudfront.net/predmachlearn/pml-training.csv", destfile="./pml-training.csv")
}

if (!file.exists("pml-testing.csv")) {
  download.file("http://d396qusza40orc.cloudfront.net/predmachlearn/pml-testing.csv", "pml-testing.csv")
}
training <- read.csv ("pml-training.csv", na.strings=c("", "NA"))
testing <- read.csv ("pml-testing.csv",  na.strings=c("", "NA"))

shinyServer(function(input, output, session) {

  output$rf_runtime <- renderText("0")
  output$rp_runtime <- renderText("0")
  output$dim <- renderText(dim(training))
  num_obs = dim(training)[1]
  
  training_reduced1 <- reactive({
    training[ , colSums(is.na(training)) < (num_obs * input$na_threshold / 100)]
  })
  output$dimna <- renderText(dim(training_reduced1())[2])

#  training_reduced2 <- reactive({ifelse(input$remove_one_seven==TRUE,training_reduced1()[-c(1:7)],training_reduced1())})
  training_reduced2 <- reactive({
    if (input$remove_one_seven) tr2 <- training_reduced1()[-c(1:7)]
    else tr2 <- training_reduced1()
  })
  output$dim_book <- renderText(dim(training_reduced2())[2])

  training_reduced3 <- reactive ({
    if (input$remove_nzv) {
      ZV = nearZeroVar(training_reduced2(), 
                      freqCut=input$freqCut, 
                      uniqueCut=input$uniqueCut, 
                      saveMetrics = TRUE)
      tr3 <- training_reduced2()[,ZV[, 'nzv']==0]
    }
    else tr3 <- training_reduced2()   
  })
  output$dim_nzv <- renderText(dim(training_reduced3())[2])
  
  set.seed(1337)
  train_set <- reactive({createDataPartition(y=(training_reduced3())$classe, p=0.7, list=FALSE)})
  train_subset <- reactive({training_reduced3()[train_set(), ]})
  validate <- reactive({training_reduced3()[-train_set(), ]  })
  
  rpart_cm <- reactive ({
    start = proc.time()
    if (input$do_rpart) {
      rpm <- rpart(classe ~ ., data=train_subset())
      predictions <- predict(rpm,validate(),type="class")
      rpart_cm <- confusionMatrix(predictions, validate()$classe)
      output$rp_fancy_plot <- renderPlot(rpart.plot(rpm))
    } 
    else {
      rpart_cm <- NULL
      output$rp_fancy_plot <- renderPlot(NULL)
    }
    runtime = proc.time()-start
    output$rp_runtime = renderText(runtime[3])
    output$rp_acc = renderText(rpart_cm$overall[1]*100)
    rpart_cm
  })
  foo <- reactive({rpart_cm()})
  output$rpcm <- renderPrint({foo()})
  
  rf_cm = reactive ({
    input$rfor_go
    start = proc.time()
    if (isolate(input$do_rfor)) {
      rfm <- isolate(rforest_model <- randomForest(classe~.,data=train_subset(),ntree=input$ntree))
      predictions <- predict(rfm,validate())
      rfor_cm  <- confusionMatrix(predictions, validate()$classe)
      output$rf_vip_plot <- renderPlot (varImpPlot(rfm,n.var=15,
                                                   main="Feature impact on exercise quality",
                                                   bg="blue"))
      updateTabsetPanel(session, "inTabSet", selected = "RF")
      output$rf_acc = renderText(rfor_cm$overall[1]*100)
    }
    else {
      rfor_cm <- NULL
    }
    runtime = proc.time()-start
    output$rf_runtime = renderText(runtime[3])
    rfor_cm
  })
  foo2 <- reactive({rf_cm()})
  output$rfor_cm <- renderPrint ({foo2()})
  outputOptions(output, 'rf_runtime', suspendWhenHidden=FALSE)
  outputOptions(output, 'rp_runtime', suspendWhenHidden=FALSE)
})
