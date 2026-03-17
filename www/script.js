// suggestion chips
function setSuggestion(text) {
  var el = document.getElementById("question");
  if (!el) return;
  el.value = text;
  Shiny.setInputValue("question", text, { priority: "event" });
}

// placeholder: speech-to-text hook