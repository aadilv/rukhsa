# Rukhsa: Islamic Fiqh for Muslims with Medical Conditions

<img width="1920" height="1440" alt="rukhsa" src="https://github.com/user-attachments/assets/1e6e15a3-7d4a-403a-ae51-b3ffdc2e4013" />

Submitted to [Ramadan Hacks](https://www.ummah.build/hackathon)

Having spent quite a bit of my life in and out of the hospital system, I noticed that the fiqh most of us learned growing up never really covered what happens when your body stops cooperating with the standard rules. The problem is that madrasahs teach the baseline, but the accommodations, dispensations, nuances etc. rarely make it into the curriculum.

Rukhsa is a RAG app that lets you describe your medical condition, select your madhab, and get a ruling grounded in verified classical Islamic scholarship.

The fiqh database includes sources primary classical texts including Ibn Abidin's *Radd al-Muhtar*, al-Nawawi's *al-Majmu'*, Ibn Qudama's *al-Mughni*, and al-Dardir's *al-Sharh al-Kabir*, as well as contemporary fatwa bodies including IIFA/OIC resolutions and madhab-specific fatwa sites. At the time of hackathon submission, it has 62 verified rulings across all four madhabs.

## Stack

- R Shiny
- Groq API &rarr; `llama-3.3-70b-versatile`
- [fawazahmed0/hadith-api](https://github.com/fawazahmed0/hadith-api) &rarr; hadith text, no key required
- [Al-Quran Cloud API](https://alquran.cloud/api) &rarr; Quran verse text, no key required
- [AlAdhan API](https://aladhan.com/prayer-times-api) by [@meezaan](https://github.com/meezaan) &rarr; prayer times, no key required
- Web Speech API &rarr; browser-native speech-to-text

## Run locally
```r
install.packages(c("shiny", "bslib", "shinyjs", "httr2",
                   "readxl", "dplyr", "stringr", "markdown"))
```

Add to `.Renviron` in the project root:
```
GROQ_API_KEY=your_key_here
```

Then:
```r
shiny::runApp()
```

## Disclaimer

Rukhsa is for informational purposes based on classical Islamic scholarship. For personal religious matters, consult a qualified scholar.
