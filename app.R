options(bslib.color_contrast_warnings = FALSE)

library(shiny)
library(bslib)
library(shinyjs)
library(dplyr)
library(stringr)
library(markdown)

source("R/data_utils.R")
source("R/groq.R")
source("R/hadith.R")
source("R/quran.R")
source("R/comparison.R")
source("R/prayer.R")

db      <- load_fiqh_data()
MADHABS <- unique(db$madhab)

SUGGESTIONS <- c(
  "How can I pray sitting down?",
  "Does vomiting break wudu?",
  "Can I pray with a catheter?",
  "How do I do tayammum in hospital?"
)

SCOPE_TERMS <- c(
  "wudu", "prayer", "salah", "tayammum", "madhab", "fiqh",
  "hospital", "sick", "illness", "catheter", "colostomy", "bandage",
  "cast", "eczema", "skin", "incontinence", "vomit", "bleed", "wound",
  "sit", "stand", "prostrate", "qibla", "fast", "fasting", "ablution",
  "ghusl", "najasah", "impure", "purif", "rukhsa", "jabirah",
  "discharge", "pray", "rukuh", "sujud", "lean", "chair", "lie"
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

  tags$head(
    tags$meta(name = "viewport",
              content = "width=device-width, initial-scale=1, shrink-to-fit=no"),
    tags$link(rel = "stylesheet", href = "styles.css"),
    tags$script(src = "script.js")
  ),
  useShinyjs(),

  div(class = "question-card",

    h2("Rukhsa", class = "mb-0"),
    p("Islamic rulings on prayer & purification for Muslims with medical conditions.",
      class = "text-muted mb-3"),

    uiOutput("prayer_banner"),

    div(class = "mb-3",
      tags$label("Select your madhab", class = "form-label fw-semibold"),
      selectInput("madhab", NULL, choices = MADHABS, selected = MADHABS[1], width = "100%")
    ),

    div(class = "mb-3",
      div(class = "form-check d-flex align-items-center gap-2",
        tags$input(
          type  = "checkbox",
          id    = "show_comparison",
          class = "form-check-input mt-0"
        ),
        tags$label(
          `for` = "show_comparison",
          class = "form-check-label text-muted mb-0",
          style = "font-size:0.875rem;",
          "Also show how other madhabs rule on this"
        )
      )
    ),

    div(class = "mb-2",
      tags$label("Describe your situation or ask a question",
                 class = "form-label fw-semibold"),
      div(class = "d-flex gap-2 align-items-start",
        div(class = "flex-grow-1",
          textAreaInput(
            inputId     = "question",
            label       = NULL,
            value       = "",
            rows        = 3,
            placeholder = "e.g. I have a urinary catheter. How do I perform wudu and pray?",
            width       = "100%"
          )
        ),
        tags$button(
          id      = "mic_btn",
          class   = "mic-btn flex-shrink-0 mt-1",
          title   = "Click to speak your question",
          onclick = "startSpeechInput()",
          HTML("&#127908;")
        )
      )
    ),

    div(
      id    = "speech_error_box",
      style = "display:none;",
      class = "mt-1",
      tags$small(id = "speech_error_text", class = "text-danger")
    ),

    div(class = "mb-4 mt-3",
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

  uiOutput("history_ui"),
  uiOutput("answer_area"),

  tags$footer(
    class = "text-center text-muted mt-5 mb-4",
    style = "font-size:0.78rem; max-width:680px; margin-left:auto; margin-right:auto;",
    tags$hr(),
    p("Rukhsa provides information based on classical Islamic scholarship. ",
      "For personal religious matters, consult a qualified Islamic scholar. ",
      "Rulings are documented from primary sources but are not a substitute for scholarly guidance.")
  )
)

server <- function(input, output, session) {

  madhab_data <- reactive({
    filter_by_madhab(db, input$madhab)
  })

  output$prayer_banner <- renderUI({
  lat <- input$user_lat
  lon <- input$user_lon

  banner_html <- tryCatch(
    get_prayer_banner(lat = lat, lon = lon),
    error = function(e) NULL
    )
  if (is.null(banner_html)) return(NULL)
  div(
    class = "alert alert-success py-2 px-3 mb-3",
    style = "font-size:0.85rem;",
    HTML(banner_html)
    )
  })

  observeEvent(input$speech_error, {
    req(input$speech_error)
    runjs(sprintf(
      "document.getElementById('speech_error_text').innerText = '%s';
       document.getElementById('speech_error_box').style.display = 'block';",
      gsub("'", "\\'", input$speech_error)
    ))
  })

  observeEvent(input$question, {
    runjs("document.getElementById('speech_error_box').style.display = 'none';")
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

    scored <- madhab_df |>
      mutate(
        score =
          (str_detect(tolower(condition_topic), pattern) * 3) +
          (str_detect(tolower(app_display_tag), pattern) * 3) +
          (str_detect(tolower(sub_category),    pattern) * 2) +
          (str_detect(tolower(ruling_summary),  pattern) * 1) +
          (str_detect(tolower(ruling_detail),   pattern) * 1)
      ) |>
      filter(score >= 2) |>
      arrange(desc(score))

    if (nrow(scored) == 0) return(madhab_df[0, ])

    top    <- scored |> head(1)
    second <- scored |> slice(2)

    if (nrow(second) > 0 && second$score[1] >= (top$score[1] / 2)) {
      result <- bind_rows(top, second)
    } else {
      result <- top
    }

    result |> select(-score)
  }

  is_in_scope <- function(question) {
    any(str_detect(tolower(question), SCOPE_TERMS))
  }

  question_history <- reactiveVal(character(0))
  groq_response    <- reactiveVal(NULL)
  matched_rows     <- reactiveVal(NULL)
  comparison_tbl   <- reactiveVal(NULL)

  observeEvent(input$submit, {
    req(input$question)
    q <- trimws(input$question)
    if (nchar(q) == 0) return()

    groq_response(NULL)
    matched_rows(NULL)
    comparison_tbl(NULL)

    if (!is_in_scope(q)) {
      groq_response("I can only help with Islamic rulings on prayer and purification for people with medical conditions. Please ask a related question.")
      matched_rows(data.frame())
      return()
    }

    show("loading")

    rows <- retrieve_rows(q, madhab_data())
    matched_rows(rows)

    if (nrow(rows) == 0) {
      groq_response("__no_match__")
      hide("loading")
      return()
    }

    answer <- call_groq(q, input$madhab, rows)

    if (str_detect(tolower(answer), "429|rate limit|too many")) {
      answer <- "The service is temporarily busy. Please wait a moment and try again."
    }

    groq_response(answer)

    current <- question_history()
    question_history(head(unique(c(q, current)), 5))

    if (isTRUE(input$show_comparison)) {
      comparison_tbl(build_comparison(db, q))
    }

    hide("loading")
  })

  output$history_ui <- renderUI({
    hist <- question_history()
    if (length(hist) == 0) return(NULL)
    div(class = "question-card mt-2 mb-2",
      tags$p("Recent questions", class = "text-muted mb-1",
             style = "font-size:0.8rem;"),
      lapply(hist, function(q) {
        display <- if (nchar(q) > 50) paste0(substr(q, 1, 50), "...") else q
        tags$span(
          class   = "chip-btn rounded-pill px-3 py-1 me-1 mb-1 d-inline-block",
          style   = "cursor:pointer; font-size:0.8rem; background:#F0FDF4;",
          onclick = sprintf("setSuggestion('%s')", gsub("'", "\\'", q)),
          display
        )
      })
    )
  })

  output$answer_area <- renderUI({
    req(groq_response())

    answer <- groq_response()
    rows   <- matched_rows()
    comp   <- comparison_tbl()

    if (answer == "__no_match__") {
      available <- sort(unique(madhab_data()$app_display_tag))
      return(div(class = "answer-card",
        card(card_body(
          p("No rulings found for that query in the ",
            tags$strong(input$madhab), " database.", class = "mb-3"),
          p("Try one of these covered topics:", class = "fw-semibold mb-2"),
          div(lapply(available, function(t) {
            tags$span(
              class   = "chip-btn rounded-pill px-3 py-1 me-1 mb-1 d-inline-block",
              style   = "cursor:pointer; font-size:0.8rem;",
              onclick = sprintf("setSuggestion('%s')", t),
              t
            )
          }))
        ))
      ))
    }

    answer_html <- markdownToHTML(
      text          = answer,
      fragment.only = TRUE,
      options       = c("smartypants")
    )

    answer_card <- card(
      class = "mb-3",
      card_header(
        class = "d-flex justify-content-between align-items-center",
        div(
          tags$span(input$madhab, class = "badge bg-success me-2"),
          "Ruling"
        ),
        div(class = "d-flex gap-2",
          tags$button(
            id      = "copy-btn",
            class   = "btn btn-sm btn-outline-secondary",
            style   = "font-size:0.75rem;",
            onclick = "copyRuling()",
            "Copy"
          ),
          tags$button(
            id      = "share-btn",
            class   = "btn btn-sm btn-outline-success",
            style   = "font-size:0.75rem;",
            onclick = "shareRuling()",
            "Share"
          )
        )
      ),
      card_body(
        class = "ruling-body",
        tags$div(id = "ruling-text", HTML(answer_html))
      )
    )

    comparison_card <- if (!is.null(comp) && nrow(comp) > 0) {
      card(
        class = "mb-3",
        card_header("How other madhabs rule on this"),
        card_body(
          tags$table(
            class = "table table-sm table-borderless mb-0",
            tags$tbody(lapply(seq_len(nrow(comp)), function(i) {
              r <- comp[i, ]
              tags$tr(
                tags$td(tags$strong(r$madhab)),
                tags$td(r$ruling_summary)
              )
            }))
          )
        )
      )
    }

    sources_section <- if (!is.null(rows) && nrow(rows) > 0) {

      source_items <- lapply(seq_len(nrow(rows)), function(i) {
        r <- rows[i, ]

        # hadith - fails silently
        hadith_text <- tryCatch(
          get_hadith_text(r$hadith_evidence),
          error = function(e) NULL
        )

        # quran verses - up to 2, fails silently
        quran_verses <- tryCatch(
          get_quran_verses(r$quranic_evidence),
          error = function(e) list()
        )

        urls <- c(r$source_url_1, r$source_url_2, r$source_url_3)
        urls <- urls[!is.na(urls) & nchar(trimws(urls)) > 0]

        url_links <- if (length(urls) > 0) {
          do.call(tagList, lapply(urls, function(u) {
            tags$a(href = u, target = "_blank",
                   class = "d-block text-success",
                   style = "font-size:0.78rem; word-break:break-all;",
                   u)
          }))
        }

        hadith_block <- if (!is.null(hadith_text)) {
          tags$blockquote(
            class = "hadith-quote mt-2 mb-1",
            tags$p(class = "mb-0", hadith_text),
            tags$footer(class = "blockquote-footer mt-1", r$hadith_grade)
          )
        }

        quran_block <- if (length(quran_verses) > 0) {
          do.call(tagList, lapply(quran_verses, function(v) {
            tags$blockquote(
              class = "hadith-quote mt-2 mb-1",
              tags$p(class = "mb-0 fst-italic",
                     paste0("\u201c", v$text, "\u201d")),
              tags$footer(class = "blockquote-footer mt-1", v$ref)
            )
          }))
        }

        tags$li(
          class = "mb-3",
          tags$strong(r$condition_topic),
          tags$br(),
          tags$small(r$fatwa_body, class = "text-muted"),
          hadith_block,
          quran_block,
          url_links
        )
      })

      div(class = "mt-3",
        tags$details(
          tags$summary(
            style = "cursor:pointer; font-size:0.85rem;",
            class = "text-muted",
            "Sources & evidence"
          ),
          tags$ul(class = "mt-2 ps-3", source_items)
        )
      )
    }

    div(class = "answer-card", answer_card, comparison_card, sources_section)
  })
}

shinyApp(ui, server)