
# This is the user-interface definition of a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
#

require(markdown)

library(shiny)
library(shinyBS)

shinyUI(fluidPage(

  # Application title
  titlePanel("Building an analysis of exercise data"),

  # Sidebar with a slider input for number of bins
  sidebarLayout(
    sidebarPanel(
      checkboxInput ("dc_show", "Show data cleaning options", value=FALSE),
      conditionalPanel(
        condition="input.dc_show == true",
        wellPanel(
          sliderInput("na_threshold",
                    "% of NA Allowable by feature:",
                    min = 1,
                    max = 100,
                    value = 50)
        ),
        bsTooltip("na_threshold", "Remove features that have at least this many observations missing", placement = "bottom", trigger = "hover",
                  options = NULL),
        wellPanel(id="r17_panel",
          checkboxInput("remove_one_seven", "Remove bookkeeping features (1-7)", value=TRUE)
        ),
        bsTooltip("r17_panel", 
                  "Remove features one through seven that are not sensor readings but bookkeeping information", 
                  placement = "bottom", trigger = "hover", options = NULL),
        wellPanel(
          checkboxInput("remove_nzv", "Remove features with Near Zero Variance", value=TRUE),
          conditionalPanel(
            condition="input.remove_nzv == true",
            sliderInput("freqCut",
                        "Frequency Cutoff ratio",
                        min= 1,
                        max = 50,
                        value = 95/5),
            bsTooltip("freqCut", 
                      "Cutoff for the ratio of the most common value to the second most common value", 
                      placement = "bottom", trigger = "hover", options = NULL),
            sliderInput("uniqueCut",
                        "Unique Cutoff Percentage",
                        min= 0,
                        max = 100,
                        value = 10),
            bsTooltip("uniqueCut", 
                      "Cutoff for the percentage of distinct values out of the number of total samples", 
                      placement = "bottom", trigger = "hover", options = NULL)
          )
        )
      ),
      checkboxInput("do_rpart", "Build Recursive Partitioning Model", value=FALSE),
      checkboxInput("do_rfor", "Build Random Forest Model", value=FALSE),
      conditionalPanel(
        condition="input.do_rfor == true",
        wellPanel (
          sliderInput("ntree",
                      "Number of Trees",
                      min= 1,
                      max = 500,
                      value = 20),
          actionButton("rfor_go", "Execute")
        )
      )
    ),
    # Show a plot of the generated distribution
    mainPanel(
      tabsetPanel(id="inTabSet",
        tabPanel("Introduction",
                 includeMarkdown("todo.txt")
        ),
        tabPanel("Cleaning",
                 strong('raw data dim:'),
                 textOutput("dim", inline=TRUE),
                 br(),
                 strong ('Features after N/A cleanup:'),
                 textOutput("dimna", inline=TRUE),
                 br(),
                 strong('Features after bookkeeping cleanup:'),
                 textOutput("dim_book", inline=TRUE),
                 br(),
                 strong('Features after Near Zero Variance removal'),
                 textOutput ("dim_nzv", inline=TRUE)
        ),
        tabPanel("Recursive Partionining",
                 h2("Summary:"),
                 conditionalPanel(
                   condition="output.rp_runtime>0",
                   strong('This model achieved '),
                   textOutput("rp_acc", inline=TRUE),
                   strong ('% accuracy and took '),
                   textOutput("rp_runtime", inline=TRUE),
                   strong ('seconds to train')
                  ),
                  h2 ('Details:'),
                  verbatimTextOutput ("rpcm"),
                  plotOutput("rp_fancy_plot")
        ),
        tabPanel("Random Forest", value = "RF",
                 h2("Summary:"),
                 conditionalPanel(
                   condition="output.rf_runtime>0",
                   strong('This model achieved '),
                   textOutput("rf_acc", inline=TRUE),
                   strong ('% accuracy and took '),
                   textOutput("rf_runtime", inline=TRUE),
                   strong ('seconds to train')
                 ),
                 h2 ('Details:'),
                 #conditionalPanel(
                #   condition="output.rf_runtime>0",
                   verbatimTextOutput ("rfor_cm"),
                   plotOutput("rf_vip_plot")
                 #)
        )
      )
    )
  ))
)



