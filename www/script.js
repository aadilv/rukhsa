function getTextarea() {
  var wrapper = document.getElementById("question");
  if (!wrapper) return null;
  return wrapper.tagName === "TEXTAREA" ? wrapper : wrapper.querySelector("textarea");
}

// suggestion chips
function setSuggestion(text) {
  var el = getTextarea();
  if (!el) return;
  el.value = text;
  Shiny.setInputValue("question", text, { priority: "event" });
}

// copy ruling text to clipboard
function copyRuling() {
  var el = document.getElementById("ruling-text");
  if (!el) return;
  var text = el.innerText;

  if (navigator.clipboard && window.isSecureContext) {
    navigator.clipboard.writeText(text).then(function() {
      setCopyLabel("Copied");
    }).catch(function() { fallbackCopy(text); });
  } else {
    fallbackCopy(text);
  }
}

function fallbackCopy(text) {
  var ta = document.createElement("textarea");
  ta.value = text;
  ta.style.position = "fixed";
  ta.style.opacity  = "0";
  document.body.appendChild(ta);
  ta.focus();
  ta.select();
  try { document.execCommand("copy"); } catch(e) {}
  document.body.removeChild(ta);
  setCopyLabel("Copied");
}

function setCopyLabel(label) {
  var btn = document.getElementById("copy-btn");
  if (!btn) return;
  btn.innerText = label;
  setTimeout(function() { btn.innerText = "Copy"; }, 2000);
}

function shareRuling() {
  var el = document.getElementById("ruling-text");
  if (!el) return;
  var text    = el.innerText;
  var snippet = text.substring(0, 280) + (text.length > 280 ? "..." : "");

  if (navigator.share) {
    navigator.share({
      title: "Rukhsa - Islamic Ruling",
      text:  snippet,
      url:   window.location.href
    }).catch(function() {});
  } else if (navigator.clipboard && window.isSecureContext) {
    navigator.clipboard.writeText(window.location.href).then(function() {
      setShareLabel("Link copied");
    });
  } else {
    setShareLabel("Copy URL from address bar");
  }
}

function setShareLabel(label) {
  var btn = document.getElementById("share-btn");
  if (!btn) return;
  btn.innerText = label;
  setTimeout(function() { btn.innerText = "Share"; }, 2500);
}

// speech-to-text
function startSpeechInput() {
  var SpeechRecognition = window.SpeechRecognition ||
                          window.webkitSpeechRecognition ||
                          null;

  if (!SpeechRecognition) {
    Shiny.setInputValue(
      "speech_error",
      "Speech input is not supported in this browser.",
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
    var el = getTextarea();
    if (el) {
      el.value = transcript;
      Shiny.setInputValue("question", transcript, { priority: "event" });
    }
    resetBtn();
  };

  recognition.onerror = function(event) {
    var msg = "Mic error: " + event.error;
    if (event.error === "not-allowed") {
      msg = "Microphone access denied. Allow mic in browser settings then reload.";
    } else if (event.error === "no-speech") {
      msg = "No speech detected. Please try again.";
    }
    Shiny.setInputValue("speech_error", msg, { priority: "event" });
    resetBtn();
  };

  recognition.onend = function() { resetBtn(); };

  try {
    recognition.start();
  } catch(e) {
    Shiny.setInputValue(
      "speech_error",
      "Could not start microphone: " + e.message,
      { priority: "event" }
    );
    resetBtn();
  }
}