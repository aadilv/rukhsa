library(httr2)

call_groq <- function(question, madhab, context_rows) {
  api_key <- Sys.getenv("GROQ_API_KEY")

  context_text <- if (nrow(context_rows) == 0) {
    "No specific rulings found in the database for this query."
  } else {
    rows_text <- lapply(seq_len(nrow(context_rows)), function(i) {
      r <- context_rows[i, ]
      paste0(
        "Topic: ", r$condition_topic, "\n",
        "Ruling: ", r$ruling_summary, "\n",
        "Detail: ", r$ruling_detail, "\n",
        "Cross-madhab note: ", r$cross_madhab_note, "\n",
        "Source: ", r$fatwa_body
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
    "IMPORTANT: Base your answer STRICTLY on the database context below. ",
    "Do not use your general training knowledge. ",
    "If the context does not cover the question, say so explicitly.\n\n",
    "Database context:\n\n",
    context_text, "\n\n",
    "Guidelines:\n",
    "- Answer in plain English, clearly and concisely\n",
    "- Use numbered steps where a procedure is involved\n",
    "- Use bullet points for conditions or exceptions\n",
    "- Bold key rulings using **text** markdown\n",
    "- Cite the classical scholar or source when the context provides one\n",
    "- Note important differences from other madhabs if the context mentions them\n",
    "- Keep the answer under 300 words\n",
    "- End with the source name from the context"
  )

  response <- tryCatch({
    raw <- request("https://api.groq.com/openai/v1/chat/completions") |>
      req_headers(
        "Authorization" = paste("Bearer", api_key),
        "Content-Type"  = "application/json"
      ) |>
      req_body_json(list(
        model      = "llama-3.3-70b-versatile",
        max_tokens = 600,
        messages   = list(
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

  answer <- response$choices[[1]]$message$content
  return(answer)
}