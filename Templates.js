.pragma library

// Prompt skeletons and their per-template checklists. Kept as a plain JS
// library (no QML imports, no state) so the panel can treat it as data and
// a user override file can be merged over it with the same shape.
//
// Each template: { id, label, hint, body, tips[] }
//   id    - stable key; drafts are persisted under it, so renaming an id
//           orphans that draft rather than corrupting it.
//   label - what the dropdown shows.
//   hint  - one line under the panel title, for the currently selected one.
//   body  - the placeholder prompt. ALL-CAPS angle-bracket slots are the
//           parts you replace; everything else is scaffolding worth keeping.
//   tips  - the checklist rendered under the editor.

var GENERAL = [
  "Give a role and a goal, not just a topic.",
  "State the audience and the output format up front.",
  "Show one worked example when the shape matters.",
  "Say what to do on missing info: ask, or assume and flag.",
  "Put long reference material last, your question first."
]

var TEMPLATES = [
  {
    id: "general",
    label: "General task",
    hint: "Role, task, context, format, done-criteria.",
    body: [
      "# Role",
      "You are <ROLE / EXPERTISE>.",
      "",
      "# Task",
      "<ONE SENTENCE: THE THING YOU WANT DONE>",
      "",
      "# Context",
      "- Audience: <WHO READS THIS>",
      "- Background: <WHAT YOU ALREADY KNOW / TRIED>",
      "- Constraints: <TIME, TOOLS, BUDGET, STYLE, THINGS OFF-LIMITS>",
      "",
      "# Output",
      "- Format: <BULLETS / TABLE / MARKDOWN DOC / JSON SCHEMA>",
      "- Length: <ROUGH SIZE>",
      "- Tone: <PLAIN / FORMAL / TECHNICAL>",
      "",
      "# Done when",
      "<HOW I WILL JUDGE A GOOD ANSWER>",
      "",
      "If anything above is ambiguous, ask before answering."
    ].join("\n"),
    tips: GENERAL
  },
  {
    id: "code",
    label: "Code & debugging",
    hint: "Symptom, expected, repro, environment, ask.",
    body: [
      "# Goal",
      "<WHAT THE CODE SHOULD DO / WHAT TO CHANGE>",
      "",
      "# Symptom",
      "Expected: <WHAT SHOULD HAPPEN>",
      "Actual:   <WHAT HAPPENS INSTEAD>",
      "",
      "# Reproduce",
      "1. <STEP>",
      "2. <STEP>",
      "",
      "# Environment",
      "<LANGUAGE + VERSION, FRAMEWORK, OS, RELEVANT DEPS>",
      "",
      "# Relevant code",
      "```<LANG>",
      "<PASTE THE SMALLEST SNIPPET THAT SHOWS THE PROBLEM>",
      "```",
      "",
      "# Error output",
      "```",
      "<FULL ERROR / STACK TRACE, NOT PARAPHRASED>",
      "```",
      "",
      "# What I already tried",
      "- <ATTEMPT AND WHAT IT DID>",
      "",
      "# Ask",
      "Explain the root cause first, then give the minimal fix as a diff.",
      "Do not restructure code I did not ask you to touch."
    ].join("\n"),
    tips: [
      "Paste the real error text, never a summary of it.",
      "Include versions - most wrong answers are version drift.",
      "Give the smallest snippet that still reproduces it.",
      "List what you already tried so it isn't suggested back.",
      "Ask for cause first, fix second - it catches wrong guesses."
    ]
  },
  {
    id: "writing",
    label: "Writing & editing",
    hint: "Audience, purpose, voice, length, what not to change.",
    body: [
      "# Task",
      "<WRITE / REWRITE / TIGHTEN / RESTRUCTURE> the text below.",
      "",
      "# Audience",
      "<WHO READS IT AND WHAT THEY ALREADY KNOW>",
      "",
      "# Purpose",
      "After reading, they should <THINK / DO / DECIDE ...>.",
      "",
      "# Voice",
      "- Tone: <DIRECT / WARM / FORMAL>",
      "- Avoid: <JARGON, HYPE, EM DASHES, WHATEVER YOU HATE>",
      "- Keep: <TERMS, NAMES, CLAIMS THAT MUST SURVIVE EDITING>",
      "",
      "# Constraints",
      "- Length: <WORD OR PARAGRAPH COUNT>",
      "- Format: <EMAIL / POST / DOC / SLIDE NOTES>",
      "",
      "# Text",
      "\"\"\"",
      "<PASTE THE DRAFT HERE>",
      "\"\"\"",
      "",
      "Return the edited version first, then a short list of what you changed and why."
    ].join("\n"),
    tips: [
      "Name the reader - 'for my team' and 'for a customer' differ hugely.",
      "Say what the reader should do after reading.",
      "List banned words and must-keep phrases explicitly.",
      "Give a length budget or you'll get a wall of text.",
      "Ask for the edit plus a changelog so you can review the edit."
    ]
  },
  {
    id: "research",
    label: "Research & synthesis",
    hint: "Question, scope, sources, uncertainty handling.",
    body: [
      "# Question",
      "<THE SPECIFIC QUESTION, NOT THE TOPIC>",
      "",
      "# Why",
      "I need this to <DECISION THIS FEEDS>.",
      "",
      "# Scope",
      "- Include: <REGIONS, YEARS, PRODUCTS, SEGMENTS>",
      "- Exclude: <WHAT IS OUT OF SCOPE>",
      "- Recency: <HOW OLD IS TOO OLD>",
      "",
      "# Sources",
      "Prefer <PRIMARY SOURCES / DOCS / PAPERS>. Cite each claim.",
      "",
      "# Output",
      "1. Short answer (3-5 lines).",
      "2. Evidence table: claim | source | date | confidence.",
      "3. What would change this answer.",
      "",
      "Mark anything you are unsure about as UNCERTAIN rather than smoothing it over.",
      "If you cannot verify a claim, say so instead of guessing."
    ].join("\n"),
    tips: [
      "Ask a question, not a topic - topics get encyclopedia entries.",
      "Say what decision it feeds so the depth matches the stakes.",
      "Set a recency bound; stale facts are the usual failure.",
      "Demand per-claim citations, not a bibliography at the end.",
      "Ask explicitly for uncertainty to be marked, not smoothed."
    ]
  },
  {
    id: "analysis",
    label: "Data analysis",
    hint: "Data shape, question, method, and how to handle gaps.",
    body: [
      "# Data",
      "Shape: <ROWS x COLUMNS, ONE ROW = ONE ...>",
      "Columns: <NAME (TYPE, UNITS, MEANING)>",
      "Known issues: <NULLS, DUPLICATES, TIMEZONE, OUTLIERS>",
      "",
      "# Question",
      "<WHAT I WANT TO LEARN FROM IT>",
      "",
      "# Method",
      "- Preferred approach: <OR: PICK ONE AND JUSTIFY IT>",
      "- Tools: <PANDAS / SQL / SPREADSHEET / R>",
      "",
      "# Output",
      "- The answer in one sentence.",
      "- The numbers that support it.",
      "- The code you used, runnable as-is.",
      "- Caveats: what this analysis cannot tell me.",
      "",
      "Do not invent values. If a column you need is missing, stop and say which.",
      "",
      "# Sample",
      "```",
      "<PASTE 5-10 REPRESENTATIVE ROWS INCLUDING THE HEADER>",
      "```"
    ].join("\n"),
    tips: [
      "Describe columns with units - 'revenue' alone is ambiguous.",
      "Paste a real sample, header included, not a description of it.",
      "Flag known data issues so they aren't silently averaged away.",
      "Ask for runnable code, so the number can be re-derived.",
      "Say 'do not invent values' - it turns a guess into a question."
    ]
  }
]

function templates() {
  return TEMPLATES
}

// Locate a template by id, falling back to the first one. Callers treat the
// result as always-valid, which keeps a stale persisted selection (an id from
// a template that was edited out) from blanking the panel.
function byId(id) {
  for (var i = 0; i < TEMPLATES.length; i++) {
    if (TEMPLATES[i].id === id) return TEMPLATES[i]
  }
  return TEMPLATES[0]
}

function indexOfId(id) {
  for (var i = 0; i < TEMPLATES.length; i++) {
    if (TEMPLATES[i].id === id) return i
  }
  return 0
}

function options() {
  var out = []
  for (var i = 0; i < TEMPLATES.length; i++) {
    out.push({ value: TEMPLATES[i].id, label: TEMPLATES[i].label })
  }
  return out
}
