options(bslib.color_contrast_warnings = FALSE)

library(shiny)
library(bslib)
library(shinyjs)
library(dplyr)
library(stringr)
library(markdown)

source("R/data_utils.R")
source("R/groq.R")

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
  useShinyjs(),

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

    actionButton("submit", "Get ruling", class = "btn btn-primary w-100 mb-4"),

    div(
      id    = "loading",
      style = "display:none; text-align:center; padding: 12px 0;",
      tags$div(class = "spinner-border spinner-border-sm text-success", role = "status"),
      tags$span(" Looking up ruling...", class = "text-muted ms-2")
    )
  ),

  uiOutput("answer_area")
)

server <- function(input, output, session) {

  madhab_data <- reactive({
    filter_by_madhab(db, input$madhab)
  })

  retrieve_rows <- function(question, madhab_df) {
  stop_words <- c("how", "do", "i", "to", "the", "a", "an", "is", "can",
                  "what", "does", "in", "for", "my", "me", "with", "and",
                  "or", "it", "this", "that", "should", "would", "could",
                  "have", "has", "be", "are", "was", "were", "will", "when")

  keywords <- question |>
    tolower() |>
    str_replace_all("[^a-z ]", " ") |>
    str_split("\\s+") |>
    unlist() |>
    (\(x) x[nchar(x) > 2 & !x %in% stop_words])()

  if (length(keywords) == 0) return(madhab_df[0, ])

  pattern <- paste(keywords, collapse = "|")

  # score rows: topic/tag match = 2 points, detail match = 1 point
  # return top 3 by score so most relevant rows bubble up
  madhab_df |>
    mutate(
      score =
        (str_detect(tolower(condition_topic), pattern) * 2) +
        (str_detect(tolower(app_display_tag), pattern) * 2) +
        (str_detect(tolower(sub_category),    pattern) * 2) +
        (str_detect(tolower(ruling_summary),  pattern) * 1) +
        (str_detect(tolower(ruling_detail),   pattern) * 1)
    ) |>
    filter(score > 0) |>
    arrange(desc(score)) |>
    head(3) |>
    select(-score)
}

  groq_response <- reactiveVal(NULL)
  matched_rows  <- reactiveVal(NULL)

  observeEvent(input$submit, {
    req(input$question)

    groq_response(NULL)
    matched_rows(NULL)

    show("loading")

    rows <- retrieve_rows(input$question, madhab_data())
    matched_rows(rows)

    answer <- call_groq(input$question, input$madhab, rows)
    groq_response(answer)

    hide("loading")
  })

  output$answer_area <- renderUI({
    req(groq_response())

    answer <- groq_response()
    rows   <- matched_rows()

    answer_html <- markdown::markdownToHTML(
      text = answer,
      fragment.only = TRUE,  
      options = c("smartypants")
    )

    answer_card <- card(
      class = "mb-3",
      card_header(
        tags$span(input$madhab, class = "badge bg-success me-2"),
        "Ruling"
      ),
      card_body(
        class = "ruling-body",
        HTML(answer_html)
      ) 
    )

    sources_section <- if (!is.null(rows) && nrow(rows) > 0) {
  source_items <- lapply(seq_len(nrow(rows)), function(i) {
    r <- rows[i, ]

    # collect non-empty URLs
    urls <- c(r$source_url_1, r$source_url_2, r$source_url_3)
    urls <- urls[!is.na(urls) & nchar(trimws(urls)) > 0]

    url_links <- if (length(urls) > 0) {
      link_tags <- lapply(urls, function(u) {
        tags$a(href = u, target = "_blank",
               class = "d-block text-success",
               style = "font-size:0.78rem; word-break:break-all;",
               u)
      })
      do.call(tagList, link_tags)
    }

    tags$li(
      class = "mb-2",
      tags$strong(r$condition_topic),
      tags$br(),
      tags$small(r$fatwa_body, class = "text-muted"),
      url_links
    )
  })

  div(class = "mt-3",
    tags$details(
      tags$summary(
        style = "cursor:pointer; font-size:0.85rem;",
        class = "text-muted",
        "Sources used"
      ),
      tags$ul(class = "mt-2 ps-3", source_items)
      )
    )
  }

    div(class = "answer-card",
      answer_card,
      sources_section
    )
  })
}

shinyApp(ui, server)