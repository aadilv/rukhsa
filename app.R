options(bslib.color_contrast_warnings = FALSE)

library(shiny)
library(bslib)
library(dplyr)
library(stringr)

source("R/data_utils.R")

db      <- load_fiqh_data()
MADHABS <- unique(db$madhab)

SUGGESTIONS <- c(
  "How can I pray sitting down?",
  "Does vomiting break wudu?",
  "Can I pray with a catheter?",
  "How do I do tayammum in hospital?"
)

my_theme <- bs_theme(
  version      = 5,
  bg           = "#FEFCE8",
  fg           = "#064E3B",
  primary      = "#065F46", 
  secondary    = "#6EE7B7",
  success      = "#10B981",
  base_font    = font_google("Inter"),
  heading_font = font_google("Inter")
)

ui <- page_fluid(
  theme = my_theme,
  tags$link(rel = "stylesheet", href = "styles.css"),
  tags$script(src = "scripts.js"),

  div(class = "question-card",                         

    h2("Rukhsa", class = "mb-0"),
    p("Islamic rulings on prayer & purification for Muslims with medical conditions.",
      class = "text-muted mb-4"),

    div(class = "mb-3",
      tags$label("Select your madhab", class = "form-label fw-semibold"),
      selectInput("madhab", NULL, choices = MADHABS, selected = MADHABS[1], width = "100%")
    ),

    div(class = "mb-2",
      tags$label("Describe your situation or ask a question",
                 class = "form-label fw-semibold"),
      tags$textarea(
        id          = "question",
        class       = "form-control",
        rows        = "3",
        placeholder = "e.g. I have a urinary catheter. How do I perform wudu and pray?",
        style       = "resize: vertical;"
      )
    ),

    div(class = "mb-4",
      lapply(SUGGESTIONS, function(s) {
        tags$span(
          class   = "chip-btn rounded-pill px-3 py-1 me-1 mb-1 d-inline-block",
          style   = "cursor: pointer; font-size: 0.85rem;",
          onclick = sprintf("setSuggestion('%s')", s),
          s
        )
      })
    ),

    actionButton("submit", "Get ruling", class = "btn btn-primary w-100 mb-4")
  ),

  uiOutput("answer_area")
)

server <- function(input, output, session) {

  madhab_data <- reactive({
    filter_by_madhab(db, input$madhab)
  })

  observe({
    cat("Madhab:", input$madhab, "| rows:", nrow(madhab_data()), "\n")
  })

  results <- eventReactive(input$submit, {
    req(input$question)
    q <- tolower(trimws(input$question))
    madhab_data() %>%
      filter(
        str_detect(tolower(condition_topic), q) |
        str_detect(tolower(ruling_summary),  q) |
        str_detect(tolower(app_display_tag), q) |
        str_detect(tolower(sub_category),    q) |
        str_detect(tolower(ruling_detail),   q)
      ) %>%
      head(3)
  })

  output$answer_area <- renderUI({
    req(results())
    r <- results()

    if (nrow(r) == 0) {
      return(div(class = "answer-card",
        card(card_body(
          p("No matching rulings found. Try rephrasing your question.", class = "text-muted")
        ))
      ))
    }

    cards <- lapply(seq_len(nrow(r)), function(i) {
      row <- r[i, ]
      card(
        class = "mb-3",
        card_header(row$condition_topic),
        card_body(
          p(row$ruling_summary, class = "fw-semibold mb-2"),
          tags$hr(),
          p(row$ruling_detail),
          tags$small(row$fatwa_body, class = "text-muted")
        )
      )
    })

    div(class = "answer-card", tagList(cards))
  })
}

shinyApp(ui, server)