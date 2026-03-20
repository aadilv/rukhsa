// suggestion chips
function setSuggestion(text) {
  var el = document.getElementById("question");
  if (!el) return;
  el.value = text;
  Shiny.setInputValue("question", text, { priority: "event" });
}

// speech-to-text
function startSpeechInput() {
  var SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;

  if (!SpeechRecognition) {
    Shiny.setInputValue("speech_error", "Speech recognition is not supported in this browser. Please use Chrome or Edge.", { priority: "event" });
    return;
  }

  var recognition = new SpeechRecognition();
  recognition.lang      = "en-US";
  recognition.interimResults = false;
  recognition.maxAlternatives = 1;

  var btn = document.getElementById("mic_btn");
  if (btn) {
    btn.classList.add("recording");
    btn.innerHTML = "&#9632;";
  }

  recognition.onresult = function(event) {
    var transcript = event.results[0][0].transcript;
    var el = document.getElementById("question");
    if (el) {
      el.value = transcript;
      Shiny.setInputValue("question", transcript, { priority: "event" });
    }
  };

  recognition.onerror = function(event) {
    Shiny.setInputValue("speech_error", "Mic error: " + event.error, { priority: "event" });
  };

  recognition.onend = function() {
    var btn = document.getElementById("mic_btn");
    if (btn) {
      btn.classList.remove("recording");
      btn.innerHTML = "&#127908;"; 
    }
  };

  recognition.start();
}