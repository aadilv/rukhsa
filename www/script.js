// suggestion chips
function setSuggestion(text) {
  var el = document.getElementById("question");
  if (!el) return;
  el.value = text;
  $("#question").trigger("change");
}

// speech-to-text
function startSpeechInput() {
  console.log("SpeechRecognition:", window.SpeechRecognition);
  console.log("webkitSpeechRecognition:", window.webkitSpeechRecognition);

  var SpeechRecognition = window.SpeechRecognition ||
                          window.webkitSpeechRecognition ||
                          null;

  if (!SpeechRecognition) {
    Shiny.setInputValue(
      "speech_error",
      "Speech recognition is not supported in this browser. Please use Chrome or Edge.",
      { priority: "event" }
    );
    return;
  }

  var recognition = new SpeechRecognition();
  recognition.lang            = "en-US";
  recognition.interimResults  = false;
  recognition.maxAlternatives = 1;
  recognition.continuous      = false;

  var btn = document.getElementById("mic_btn");

  function resetBtn() {
    if (btn) {
      btn.classList.remove("recording");
      btn.innerHTML = "&#127908;";
    }
  }

  if (btn) {
    btn.classList.add("recording");
    btn.innerHTML = "&#9632;";
  }

  recognition.onresult = function(event) {
    var transcript = event.results[0][0].transcript;
    var el = document.getElementById("question");
    if (el) {
      el.value = transcript;
      $("#question").trigger("change");
    }
    resetBtn();
  };

  recognition.onerror = function(event) {
    console.log("Speech error:", event.error);
    var msg = "Mic error: " + event.error;
    if (event.error === "not-allowed") {
      msg = "Microphone access denied. Please allow mic access in your browser settings and reload.";
    } else if (event.error === "no-speech") {
      msg = "No speech detected. Please try again.";
    }
    Shiny.setInputValue("speech_error", msg, { priority: "event" });
    resetBtn();
  };

  recognition.onend = function() {
    resetBtn();
  };

  try {
    recognition.start();
    console.log("Recognition started");
  } catch(e) {
    console.log("Recognition start error:", e);
    Shiny.setInputValue(
      "speech_error",
      "Could not start microphone: " + e.message,
      { priority: "event" }
    );
    resetBtn();
  }
}