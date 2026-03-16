# Fiqh Database - README

## Purpose

This database contains  rulings from the four Sunni madhabs on wudu accommodations and prayer during illness. Built for a RAG application targeting Muslims with physical limitations - part of the **Ummah.build Ramadan Hacks 2026 hackathon**

The app allows a user to describe their medical condition, select a madhab, and receive a plain-English ruling sourced from verified Islamic scholarship rather than generic AI output.

---

## Files

| File | Madhab | Data Rows |
|---|---|---|
| `hanafi_fiqh.xlsx` | Hanafi | 15 |
| `maliki_fiqh.xlsx` | Maliki | 16 |
| `hanbali_fiqh.xlsx` | Hanbali | 15 |
| `shafii_fiqh.xlsx` | Shafi'i | 16 |

All four files share an identical 33-column schema.

---

## Column Reference

| Display Header | Variable Name | Description |
|---|---|---|
| Entry # | `entry_num` | Unique row ID for RAG indexing |
| Category | `category` | High-level section (Wudu Accommodations / Illness & Special Circumstances) |
| Sub-Category | `sub_category` | Specific topic group |
| Condition / Topic | `condition_topic` | Plain-language topic name |
| Arabic Term | `arabic_term` | Arabic technical term (Unicode UTF-8) |
| Madhab | `madhab` | School of law |
| Ruling (Summary) | `ruling_summary` | One-sentence plain-English ruling - optimised for app display |
| Ruling Detail | `ruling_detail` | Full ruling with reasoning and context |
| Conditions for Dispensation | `conditions_for_dispensation` | Specific conditions that must be met to use the accommodation |
| Hierarchy / Steps | `hierarchy_steps` | Step-by-step procedure; steps separated by " | " |
| Classical Scholar | `classical_scholar` | Named scholars who established or documented this ruling |
| Classical Text | `classical_text` | Authoritative classical texts with full titles and authors |
| Text Reference | `text_reference` | Specific volume/page citations |
| Quranic Evidence | `quranic_evidence` | Quran verses with surah:verse numbers |
| Hadith Evidence | `hadith_evidence` | Hadith with collection name and number |
| Hadith Grade | `hadith_grade` | Authenticity grading (Sahih, Hasan, Da'if, Maudu') |
| Legal Maxim (Qawa'id) | `legal_maxim` | Fiqh legal maxims with Arabic and translation |
| Cross-Madhab Note | `cross_madhab_note` | Key differences vs. other schools - primary RAG comparison field |
| Fatwa Body | `fatwa_body` | Contemporary institutional sources |
| Fatwa Reference | `fatwa_reference` | Specific fatwa numbers or document names |
| Source URL 1 | `source_url_1` | Direct article/fatwa URL (not homepage) |
| Source URL 2 | `source_url_2` | Direct article/fatwa URL |
| Source URL 3 | `source_url_3` | Direct article/fatwa URL |
| Breaks Wudu? | `breaks_wudu` | Yes / No / N/A / Disputed |
| Breaks Fast? | `breaks_fast` | Yes / No / N/A |
| Requires Tayammum? | `requires_tayammum` | Yes / No / N/A / conditional description |
| Repeat Prayer After? | `repeat_prayer_after` | Whether prayers performed with accommodation must be repeated after recovery |
| Prior Purity Required? | `prior_purity_required` | Whether purity was required when medical device/bandage was applied |
| Wudu Frequency | `wudu_frequency` | How often wudu must be renewed |
| Excused Najasah Threshold | `excused_najasah_threshold` | Measurement of excused impurity (e.g. Hanafi dirham ~5cm) |
| Notes / Nuances | `notes_nuances` | Subtleties, exceptions, common mistakes, internal scholarly disputes |
| App Display Tag | `app_display_tag` | Short tag for filtering in the app UI |
| Verified? | `verified` | Whether ruling has been cross-checked against classical source |

## App Display Tags

Tags used in the `app_display_tag` column for UI filtering:

`Wounds & Bandages` | `Incontinence` | `Chronic Bleeding` | `Chronic Flatulence` | `Catheter Users` | `Colostomy Users` | `Eczema / Skin Conditions` | `Medicated Creams` | `Tayammum` | `Tayammum (Hospital)` | `Chronic Pain / Posture` | `Vomiting / Nausea` | `IV Lines / Fasting` | `Feeding Tubes / Fasting` | `Combining Prayers` | `Qibla (Hospital)` | `Hospital Gown / Bedding`
