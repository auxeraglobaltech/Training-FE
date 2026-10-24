# Prompt for Generating the Workshop Deck

**How to use:** open claude.ai on Windows, attach `workshop-riscv-foundations-outline.md`, and paste the prompt below.

---

## THE PROMPT

I'm attaching a detailed slide-by-slide outline for a full-day technical workshop. I need you to turn it into a polished PowerPoint deck.

Build it as a **complete, runnable Python script** using `python-pptx`. I'll run it myself on Windows. Do not try to describe the deck — write the code that produces it.

### Deliverable

A single script `build_deck.py` that, when run, produces `riscv-cpu-verification-workshop.pptx` — 91 slides, 16:9 widescreen, matching the attached outline exactly.

### Audience and tone context

The audience is professional IP-level design-verification engineers in India — they know SystemVerilog and UVM but have never verified a CPU. This is a corporate technical training deck, not a conference talk and not a sales pitch. It should look like something a senior engineer made: dense, precise, confident, no stock photos, no clip art, no gradients, no "synergy" language.

---

### Design System — follow exactly

**Slide size:** 13.333 in × 7.5 in (16:9)

**Colours** (define as RGBColor constants at the top):
```
INK        #12233F   deep navy   — section backgrounds, headings
INK_SOFT   #2A3F5F   muted navy  — sub-headings
ACCENT     #2E7DD1   blue        — rules, emphasis, table headers
WARN       #F08A24   orange      — callouts, "important" markers
GOOD       #2F9E68   green       — ticks, positive cells
PAPER      #FFFFFF   white       — content slide background
WASH       #F5F7FA   near-white  — code/diagram block backgrounds
RULE       #D8DEE7   light grey  — table gridlines, dividers
MUTED      #64748B   grey        — footers, captions, speaker asides
```

**Fonts** (Windows-native, do not substitute):
- Headings and body: **Segoe UI** (use Segoe UI Semibold weight for headings via bold=True)
- Code, ASCII diagrams, register maps: **Consolas**

**Type scale:**
| Element | Size | Weight | Colour |
|---|---|---|---|
| Title slide title | 44 pt | bold | white |
| Section divider number | 72 pt | bold | ACCENT |
| Section divider title | 36 pt | bold | white |
| Content slide title | 28 pt | bold | INK |
| Body bullet L1 | 17 pt | regular | INK |
| Body bullet L2 | 15 pt | regular | INK_SOFT |
| Table header | 13 pt | bold | white on ACCENT |
| Table cell | 12 pt | regular | INK |
| Code / ASCII block | 11 pt | regular | INK on WASH |
| Callout text | 20 pt | bold | INK or white |
| Footer | 9 pt | regular | MUTED |

---

### Layouts — implement as helper functions

Use `prs.slide_layouts[6]` (blank) for everything and place shapes manually. Do not use built-in placeholder layouts.

**1. `add_title_slide()`**
Full-bleed INK rectangle. Title 44 pt white, centred-left at 1.0 in. Subtitle 20 pt in ACCENT below it. Presenter name/date 14 pt MUTED at bottom.

**2. `add_section_divider(number, title, summary)`**
Full-bleed INK rectangle. Huge module number (e.g. "03") in ACCENT at 72 pt, top-left. Module title 36 pt white beneath. One-line summary 16 pt at 70% white. A 3 in × 0.05 in ACCENT rule between number and title.
Insert one before each MODULE in the outline (12 total, including the LAB).

**3. `add_content_slide(title, blocks, module_label, slide_no)`**
- PAPER background
- Title at left 0.6 in, top 0.4 in, width 12.1 in, 28 pt bold INK
- ACCENT rule: 1.6 in × 0.055 in at left 0.6 in, top 1.25 in
- Content region: left 0.6 in, top 1.6 in, width 12.1 in, height 5.2 in
- Footer at top 6.95 in: module label left in 9 pt MUTED, slide number right-aligned
- `blocks` is an ordered list of content elements, stacked vertically with 0.15 in gaps

**Block types to support:**

- `('bullets', [(level, text), ...])` — level 0 uses a `▪` marker in ACCENT, level 1 uses `–` indented 0.35 in. Support inline `**bold**` markup by splitting into runs.
- `('code', "multi-line string")` — WASH rounded rectangle, 1 pt RULE outline, Consolas, no autofit, 0.12 in internal padding. **Preserve every space and newline exactly** — the ASCII diagrams and register bit-field maps depend on it.
- `('table', [[header row], [row], ...])` — native PowerPoint table. Header row: ACCENT fill, white bold text. Body rows: alternate PAPER / WASH banding. RULE-coloured borders. Auto-size column widths proportional to max content length in each column. First column left-aligned, numeric columns centred.
- `('callout', "text")` — full-width INK rounded rectangle, white 20 pt bold text, centred. Use for the lines the outline marks as key statements.
- `('note', "text")` — thin left border bar in WARN, WASH background, 14 pt italic INK_SOFT. Use for "Verification hook", "Callback", "Teaching point" asides that appear *on* the slide.
- `('big', "text")` — single centred statement, 26 pt bold INK, generous whitespace. For slides that are one idea.

**4. `add_two_col_slide(title, left_blocks, right_blocks, ...)`**
Two 5.9 in columns with a 0.3 in gutter. Use for the outline's side-by-side comparisons (architectural vs microarchitectural state, CISC vs RISC, strong-now vs still-climbing).

---

### Content rules

1. **Follow the outline exactly.** Every slide, in order, with its stated number. Do not add slides, do not merge slides, do not editorialise the content. Slide 91 is the last one.

2. **Speaker notes are mandatory.** The outline contains blocks marked `> **Speaker note:**`, `> **Discussion prompt:**`, `> **Note:**`, `> **Framing:**`, and `> **Caveat:**`. Put every one of these into that slide's notes field via `slide.notes_slide.notes_text_frame.text`. These do **not** go on the slide face. Where a slide has no such block, write a 2–3 sentence speaker note yourself based on the slide's content and its role in the narrative.

3. **ASCII diagrams: keep them as `code` blocks** in Consolas, except for the eight priority diagrams below — render those as **native PowerPoint shapes** (rectangles, arrows, connectors, text boxes) so they look professionally drawn:
   - Slide 7 — separability: one ISA fanning out to four different implementations
   - Slide 22 — RISC-V value-capture stack (5 stacked layers)
   - Slide 53 — the CPU datapath (PC → IMEM → Decoder → RegFile → ALU → DMEM → writeback, with branch mux feedback)
   - Slide 65 — trap sequence flow (8 numbered steps, vertical)
   - Slide 81 — Ibex 2-stage microarchitecture (two large boxes, IF and ID/EX, with contents listed, two bus arrows out the bottom)
   - Slide 83 — OBI bus timing: draw as a **real timing diagram** with clock, req, gnt, rvalid waveforms as line shapes, not ASCII
   - Slide 85 — testbench architecture (nested boxes: UVM env → tb_top → DUT)
   - Slide 15 — modular ISA tree (RV32I base box with extension boxes branching below)

   For these, use `MSO_SHAPE.ROUNDED_RECTANGLE` with ACCENT or INK outlines, white or WASH fills, and `MSO_CONNECTOR.STRAIGHT` with arrowheads. Label everything.

4. **Tables must be native PowerPoint tables**, never text. There are roughly 25 tables in the outline. The big ones (M-mode CSRs, exception codes, ABI registers, decision matrix) are the most-used slides in the deck — get them right.

5. **The ✅ marks** in the C-vs-UVM-vs-Hybrid decision matrix (slide 50) should be a green check character in GOOD colour, centred in the cell.

6. **Code blocks containing assembly, C, or Makefile snippets** keep their exact indentation. Don't reflow or prettify.

7. **Overflow is the main failure mode.** Several slides are dense. After placing blocks, if total content height would exceed the 5.2 in content region, scale down font sizes proportionally (down to a floor of 9 pt for code, 13 pt for bullets, 10 pt for table cells) rather than letting anything run off the slide. Implement this as a fit-check helper and apply it to every content slide.

---

### Script architecture

Structure it as **declarative data plus a render engine**, not 91 hand-written blocks:

```python
# 1. Imports, theme constants, page setup
# 2. Helper functions (add_title_slide, add_section_divider,
#    add_content_slide, add_two_col_slide, block renderers,
#    fit-check, native-diagram builders)
# 3. SLIDES = [ ... ]   <- big declarative list, one dict per slide
# 4. Render loop: iterate SLIDES, dispatch by layout type
# 5. prs.save("riscv-cpu-verification-workshop.pptx")
```

Each entry in `SLIDES` looks like:
```python
{
  "n": 19,
  "layout": "content",
  "module": "M3 — Licensing Economics",
  "title": "The Royalty Math at Volume",
  "blocks": [
    ("bullets", [(0, "Publicly reported: **1–2% of chip ASP** for application processors")]),
    ("code", "MCU product line\n  100 M units/year × $2.00 ASP × ~1.5%\n  ≈ $0.03/unit ≈ $3 M per year"),
    ("callout", "Royalty scales with your success."),
  ],
  "notes": "State the NDA caveat out loud — actual ARM terms are confidential...",
}
```

### Output strategy

The script will be long. Emit it across **multiple messages**:
- **Message 1:** imports, theme, page setup, all helper functions, the native-diagram builders, and the empty `SLIDES = []` scaffold plus the render loop and save call. Make this part complete and self-consistent.
- **Messages 2–7:** append slide data in module-sized chunks, as `SLIDES += [ ... ]` blocks I can paste in sequence before the render loop.

Tell me clearly at each step where the code goes in the file. After the final chunk, give me the exact commands to run it on Windows:
```
pip install python-pptx
python build_deck.py
```

### Quality bar

Before you write anything, understand this: the deck will be projected in a training room for eight hours to engineers who read datasheets for a living. They will notice sloppiness.

- Consistent alignment — everything on a 0.6 in left margin, no exceptions
- Generous whitespace; never fill a slide edge to edge
- Nothing overlaps, nothing overflows, no text smaller than 9 pt
- Every slide has a footer with its module and number
- Every slide has speaker notes

**Do not** use: gradients, shadows, 3-D effects, WordArt, stock imagery, emoji on slide faces (the outline's ☕🍽🖥 markers are for the outline only — use text labels on the actual slides), or any font other than Segoe UI and Consolas.

Start with Message 1.

---

## AFTER IT'S BUILT

Things to check on first run, in order — these are where it will most likely go wrong:

1. **Overflow.** Scan slides 19, 26, 29, 50, 76, 77, 82, 84 — the densest tables. Anything running off the bottom means the fit-check helper needs a lower floor.
2. **The eight native diagrams.** These are the ones most likely to come out misaligned. Slide 83 (OBI timing) is the hardest — if it looks wrong, ask for it as a WaveDrom JSON instead and render it separately at wavedrom.com.
3. **Speaker notes present on all 91.** In PowerPoint: View → Notes Page, and scroll.
4. **Consolas actually applied** to code blocks — if ASCII diagrams look ragged, the font didn't take.

## FOLLOW-UP PROMPTS THAT WORK WELL

Once the deck exists, these are worth running as separate requests:

> Slide 83's OBI timing diagram is hard to read. Regenerate just that slide's shape code as a proper timing diagram: 5 clock cycles, signals `clk`, `req`, `gnt`, `rvalid`, `rdata` stacked vertically, with dashed vertical cycle boundaries and a labelled arrow showing the one-cycle gap between gnt and rvalid.

> Add a handout version: a second script that exports slides 10, 50, 68, 71, 76, and 77 to a separate 6-slide pptx sized for A4 portrait printing.

> The morning modules (slides 1–40) need to work standalone as a 2-hour executive briefing. Generate a cut-down 25-slide version from the same SLIDES data.
