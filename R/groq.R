library(httr2)

call_groq <- function(question, madhab, context_rows) {
  api_key <- Sys.getenv("GROQ_API_KEY")
  if (api_key == "") return("GROQ_API_KEY not set.")

  context_text <- if (nrow(context_rows) == 0) {
    "No specific rulings found in the database for this query."
  } else {
    rows_text <- lapply(seq_len(nrow(context_rows)), function(i) {
      r <- context_rows[i, ]
      paste0(
        "Topic: ",             r$condition_topic,   "\n",
        "Display tag: ",       r$app_display_tag,   "\n",
        "Ruling summary: ",    r$ruling_summary,    "\n",
        "Ruling detail: ",     r$ruling_detail,     "\n",
        "Notes & nuances: ",   r$notes_nuances,     "\n",
        "Classical scholars: ", r$classical_scholar, "\n",
        "Classical text: ",    r$classical_text,    "\n",
        "Quranic evidence: ",  r$quranic_evidence,  "\n",
        "Cross-madhab note: ", r$cross_madhab_note
      )
    })
    paste(rows_text, collapse = "\n\n---\n\n")
  }

  system_prompt <- paste0(
    "You are Rukhsa, an Islamic jurisprudence assistant specialising in rulings ",
    "for Muslims with physical disabilities and medical conditions.\n\n",
    "You ONLY answer questions about wudu, salah, fasting, tayammum, and related Islamic ",
    "rulings for people with medical conditions or physical limitations. ",
    "If the user asks about anything outside this scope, respond with exactly: ",
    "'I can only help with Islamic rulings on prayer and purification for people ",
    "with medical conditions. Please ask a related question.'\n\n",
    "You are answering according to the ", madhab, " madhab.\n\n",
    "PRIMARY SOURCE: Use the following verified database context as your main source. ",
    "The web search tool is available to supplement procedural details (e.g. step-by-step ",
    "posture descriptions) that the database does not fully cover. ",
    "Always prioritise database context. Do not contradict it with web search results.\n\n",
    "Database context:\n\n", context_text, "\n\n",
    "Guidelines:\n",
    "- Answer in plain English, clearly and concisely\n",
    "- Use numbered steps where a procedure is involved\n",
    "- Use bullet points for conditions or exceptions\n",
    "- Bold key rulings using **text** markdown\n",
    "- Reference the classical scholar or Quranic evidence when the context provides it\n",
    "- Note important differences from other madhabs if the context mentions them\n",
    "- Pay attention to Notes & nuances in the context - these contain important exceptions\n",
    "- Keep the answer under 300 words\n",
    "- Do NOT end with a 'Source:' line - sources are shown separately in the UI"
  )

  response <- tryCatch({
    raw <- request("https://api.groq.com/openai/v1/chat/completions") |>
      req_headers(
        "Authorization" = paste("Bearer", api_key),
        "Content-Type"  = "application/json"
      ) |>
      req_body_json(list(
        model      = "llama-3.3-70b-versatile",
        max_tokens = 700,
        tools      = list(
          list(
            type     = "function",
            `function` = list(
              name        = "web_search",
              description = "Search the web for supplementary Islamic jurisprudence procedural details",
              parameters  = list(
                type       = "object",
                properties = list(
                  query = list(
                    type        = "string",
                    description = "Search query"
                  )
                ),
                required   = list("query")
              )
            )
          )
        ),
        tool_choice = "auto",
        messages    = list(
          list(role = "system", content = system_prompt),
          list(role = "user",   content = question)
        )
      )) |>
      req_timeout(30) |>
      req_perform()
    resp_body_json(raw)
  }, error = function(e) {
    return(list(error = conditionMessage(e)))
  })

  if (!is.null(response$error)) {
    return(paste("Sorry, there was an error:", response$error))
  }

  content <- response$choices[[1]]$message$content

  if (is.character(content) && length(content) == 1) return(content)

  if (is.list(content)) {
    for (block in content) {
      if (!is.null(block$type) && block$type == "text") {
        return(block$text)
      }
    }
  }

  return("Could not parse response. Please try again.")
}