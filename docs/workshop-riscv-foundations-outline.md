# Workshop Deck Outline — RISC-V & CPU Verification Foundations

**Audience:** IP-level DV engineers (strong SystemVerilog/UVM, verified AXI/APB/SPI-class IP, never verified a CPU)
**Duration:** Full day, ~6.5 hrs content + breaks
**Slides:** 91
**Running order:** Business & market **first**, technical after lunch
**Goal:** By lunch they understand why RISC-V exists as a *business* and why India is betting on it. By 5 PM they understand what a CPU is, and they have run `make sim` on Ibex and seen TEST PASSED.

---

## Why This Order

Business first, with one exception: **a 25-minute ISA primer opens the day.**

You cannot explain "RISC-V is royalty-free vs. ARM's per-chip royalty" to someone who doesn't yet know what an ISA *is*. The entire business argument — licensing, sovereignty, custom extensions, the lot — rests on one technical idea: **the ISA is a contract that is separable from any implementation of it.** Establish that idea, then the whole morning has something to stand on.

Everything else technical waits until after lunch.

---

## Timing Plan

| Time | Module | Slides | Min |
|---|---|---|---|
| 09:00 | M0 — Opening | 1–4 | 15 |
| 09:15 | **M1 — An ISA in 25 Minutes** (the bridge) | 5–10 | 25 |
| 09:40 | M2 — RISC-V History & Governance | 11–17 | 35 |
| 10:15 | M3 — The Business Case: Licensing Economics | 18–22 | 25 |
| 10:40 | M4 — Geopolitics & Sovereignty | 23–25 | 20 |
| 11:00 | ☕ Break | — | 15 |
| 11:15 | M5 — Competitive Landscape & Market | 26–31 | 35 |
| 11:50 | M6 — RISC-V in India | 32–40 | 45 |
| 12:35 | 🍽 Lunch | — | 45 |
| 13:20 | M7 — From IP DV to CPU DV | 41–50 | 40 |
| 14:00 | M8 — Computer Architecture Foundations | 51–65 | 65 |
| 15:05 | ☕ Break | — | 15 |
| 15:20 | M9 — RISC-V ISA, Technical | 66–78 | 50 |
| 16:10 | M10 — Enter Ibex | 79–88 | 40 |
| 16:50 | 🖥 LAB — run `make sim` | — | 25 |
| 17:15 | M11 — Wrap & Roadmap | 89–91 | 15 |

> **The afternoon is the tight half.** See the Cut List at the end — it's calibrated for the post-lunch block, which is where you will actually run over.

---

# MODULE 0 — Opening (15 min)

### Slide 1 — Title
**From IP Verification to CPU Verification**
*A RISC-V and Ibex Foundations Workshop*
Your name / date / company

---

### Slide 2 — Where You Are Today
Three columns, each with a tick:
- ✅ You can build a UVM env from scratch
- ✅ You know agents, sequences, scoreboards, covergroups
- ✅ You have closed coverage on a real IP block

**One line, big:** *None of that is what makes CPU verification hard.*

> **Speaker note:** Set the tone in the first two minutes. This audience's instinct is "I know UVM, how different can a CPU be?" You'll answer that properly after lunch — but plant the flag now so they know the day is going somewhere.

---

### Slide 3 — Agenda
The timing table. Mark the lunch line clearly and say out loud:

> *"Morning is why RISC-V exists and why it matters — the business, the politics, the money, India. Afternoon is how a CPU actually works and how you verify one. Last 25 minutes, you run a real RISC-V core on your own machine."*

**Why business first:** because if you don't know why anyone is paying for this, the technical detail is trivia.

---

### Slide 4 — What You Walk Away With
- Why an ISA is a business asset, not just a technical spec
- What ARM actually charges, and what RISC-V actually costs
- Why India, China, and the EU all launched national RISC-V programmes
- A mental model of a CPU pipeline you can draw from memory
- The ability to read a RISC-V instruction encoding by hand
- A working Ibex simulation on your machine

> **Discussion prompt (2 min):** "Hands up — who knows what your company pays, per chip, for the CPU core in your last project?" Almost nobody does. That's the morning in one question.

---

# MODULE 1 — An ISA in 25 Minutes (25 min)

*The bridge. Minimum technical content required for the business story to make sense. Resist going deeper — the full ISA treatment is Module 9.*

### Slide 5 — The ISA Is a Contract
```
        SOFTWARE
   compilers, OS, applications
  ─────────── ISA ───────────   ← the contract
        HARDWARE
   pipeline, caches, silicon
```
- Software depends **only** on the contract
- Hardware may implement it **any way it likes**
- Neither side needs to know anything about the other

**This abstraction is the single most valuable idea in computer architecture — and it is the reason RISC-V can exist as a business model.**

---

### Slide 6 — What an ISA Specifies (and Doesn't)

| Specifies | Does NOT specify |
|---|---|
| Instruction encodings | Pipeline depth |
| Register count and width | Cache size |
| Memory model | Clock frequency |
| Privilege levels | Branch prediction |
| Trap behaviour | Process node |
| Exception causes | Power management |

**Read the right-hand column again.** Everything that determines whether a chip is fast, small, or cheap is *not* in the ISA. That's where implementations compete.

---

### Slide 7 — Separability: The Idea the Whole Day Rests On
```
         ONE ISA (the contract)
    ┌────────┬────────┬─────────┐
    ▼        ▼        ▼         ▼
 2-stage  5-stage  out-of-   1000-core
   MCU     MCU     order      array
  0.02mm²          server
                    chip

    ↑ same binary runs on all of them ↑
```
- Ibex: 2 stages, no branch prediction, microcontroller-class
- A datacentre RISC-V core: 20 stages, out-of-order, gigahertz
- **Same instruction encodings. Same software.**

**Business consequence:** if the contract is free to implement, then the value moves entirely into the implementation — and *anyone* can compete there.

---

### Slide 8 — CISC vs RISC — Why RISC-V Is "RISC"
**CISC (x86, VAX, 68k)** — 1970s reasoning
- Memory expensive → dense, variable-length encoding (x86: 1–15 bytes)
- Compilers weak → complex instructions that do a lot
- Microcode inside

**RISC (MIPS, SPARC, ARM, RISC-V)** — 1980s reasoning
- Memory cheap, compilers good
- Fixed-length, simple instructions, load/store architecture
- Easy to pipeline, easy to implement

**Verdict today:** modern x86 decodes CISC into RISC-like micro-ops internally.
*RISC won the microarchitecture argument. x86 won the compatibility argument.*

> **Speaker note:** Keep this to 3 minutes. It's context, not the point. The point is next.

---

### Slide 9 — What "Open ISA" Actually Means
✅ **Open:** the *specification* is free to read, implement, and extend. No licence. No royalty. No permission. No NDA.

❌ **Not open:** individual *implementations*. SiFive's cores are proprietary. Andes' cores are proprietary. That's fine and expected.

**Analogy:** RISC-V is like HTTP, USB, or Ethernet — the standard is open, the products built to it may not be.

> **Discussion prompt (3 min):** "Ibex is open *and* the ISA is open. Name a widely-used open-source implementation of x86."
> *(There isn't a viable one. Not because nobody wants one — because it's not legally possible. That's the point.)*

---

### Slide 10 — Why This Is a Business Story
Because of separability, an ISA can be owned three completely different ways:

| | **x86** | **ARM** | **RISC-V** |
|---|---|---|---|
| Owner | Intel / AMD | Arm Holdings | RISC-V International (non-profit) |
| Can you implement it? | Effectively no | Only with a licence | **Yes, freely** |
| Cost to use the ISA | N/A | $M upfront + per-chip royalty | **$0** |
| Can you extend it? | No | Limited | **Yes — reserved opcode space** |
| Can access be revoked? | N/A | Yes, contractually | **No** |

**That last row is why governments got involved.** Hold that thought — Module 4.

---

# MODULE 2 — RISC-V History & Governance (35 min)

### Slide 11 — 2010: A Three-Month Summer Project
- **UC Berkeley**, Parallel Computing Laboratory
- **Krste Asanović, Andrew Waterman, Yunsup Lee, David Patterson**
- Goal: a clean ISA for research and teaching. Existing ones were legally or technically unusable:
  - **x86** — too complex, licence-locked
  - **ARM** — licence-locked, expensive
  - **SPARC / MIPS** — encumbered, dated

**Why "V"?** The fifth RISC design from Berkeley (RISC-I 1981, RISC-II, SOAR, SPUR, RISC-V). Also a pun on "five" and "variations/vectors."

> **Speaker note:** David Patterson co-authored *Computer Architecture: A Quantitative Approach* and won the 2017 Turing Award. This is not a hobby project's pedigree. Say so — it pre-empts the "open source means amateur" reflex.

---

### Slide 12 — The Decision That Made It a Business
2014: the specification is published under a **BSD licence**.

They could have:
- Kept it academic (like SPUR — nobody remembers SPUR)
- Licensed it commercially (like MIPS did — and MIPS is now… a RISC-V company)
- **Given it away** ← they did this

**Result:** zero friction to adoption. A startup in Bengaluru and a hyperscaler in California start from exactly the same position, on the same day, with no lawyers involved.

---

### Slide 13 — Timeline
```
2010  Berkeley project starts
2011  First RISC-V silicon (Raven-1, 28nm)
2014  Spec published under BSD licence
2015  RISC-V Foundation formed (non-profit, ~30 members)
2016  SiFive founded — first commercial RISC-V vendor
2018  NVIDIA adopts RISC-V for GPU microcontrollers
2019  Base ISA + privileged spec ratified
2020  Foundation relocates to Switzerland → RISC-V International
2021  Alibaba/T-Head ships XuanTie; India signals DIR-V direction
2022  MeitY formally launches DIR-V programme
2023  Qualcomm + Google announce RISC-V Snapdragon Wear
2024  RVA23 profile ratified (Oct) — the software-ecosystem unlock
2025  Ubuntu 25.10 mandates RVA23; Android RISC-V ABI on RVA23
2026  India: THEJAS64 fabbed at SCL Chandigarh; DHRUV64 announced
```
**Note the shape:** 2010–2018 is quiet technical groundwork. 2019 onward is when the money and the governments arrive.

---

### Slide 14 — How RISC-V International Works
- Non-profit, **member-funded** — this is the entire revenue model
- Members vote on specifications; technical committees own extensions
- Work happens in public GitHub repos
- Specs progress: **Draft → Frozen → Ratified**
- Anyone may read and implement. **Membership buys *influence*, not *permission*.**

**The enforcement lever is the trademark:** you can build anything you like, but calling it "RISC-V compatible" requires conformance. That's how a free standard stays coherent.

---

### Slide 15 — The Modular ISA: Base + Extensions
```
        ┌──────────────────────────────┐
        │   RV32I  — base integer      │  ← mandatory, ~40 instructions
        │        frozen forever         │     frozen means FROZEN
        └──────────────────────────────┘
              │
    ┌─────┬───┴───┬─────┬─────┬─────┬─────┐
    ▼     ▼       ▼     ▼     ▼     ▼     ▼
    M     A       F     D     C     B     V
  mul/  atomic  float float compr bitmnp vector
  div           (SP)  (DP)  16-bit
```
- Pick only what your application needs
- Tiny sensor core: `RV32I` alone. AI accelerator host: `RV64GCV`.
- **Contrast with ARM/x86:** you take the whole ISA whether you use it or not, and you pay for it

**Commercial consequence:** a 0.02 mm² RISC-V core is viable. There is no such thing as a "partial" ARM licence at that scale.

---

### Slide 16 — The Fragmentation Problem
Modularity is a feature *and* an existential threat:
- Vendor A ships `RV64IMAC`
- Vendor B ships `RV64IMAFDC` + three custom extensions
- **A single Linux binary cannot run on both**

"Write once, run anywhere" breaks. This was the #1 criticism of RISC-V from 2015 to 2023, and it was a fair one.

---

### Slide 17 — Profiles: The Fix (and the Inflection Point)
A **profile** is a mandated bundle — "if you claim this profile, you have *all* of these extensions."

**RVA23** — ratified October 2024, the 64-bit application-processor profile:
- Mandates the **vector** extension (V) — critical for AI/ML and crypto
- Mandates the **hypervisor** extension — enables virtualization

**Why it changed the game:**
- RVA23 is the **baseline for the Android RISC-V ABI**
- **Ubuntu 25.10 mandates RVA23** — which obsoleted most existing RISC-V dev boards overnight

**RVA23 is the moment RISC-V became credible for general-purpose software, not just embedded.**

> **Note:** Ibex is an embedded core — RVA23 does not apply to it. Embedded-class profiles are the relevant ones there. Mention it, don't dwell.

---

# MODULE 3 — The Business Case: Licensing Economics (25 min)

*The genuinely new material. This is what turns "open source is nice" into "here is the P&L."*

### Slide 18 — How ARM Actually Makes Money
Two-part model, and both parts matter:

**1. Upfront licence fee** — right to use the IP at all
- **Architecture licence** — build your *own* core implementing the ARM ISA. Very expensive, few holders (Apple, Qualcomm, Samsung, NVIDIA…)
- **Core licence** — use ARM's designed core (e.g. Cortex-M4, Cortex-A78)
- **Flexible Access / subscription** — lower-cost entry tier aimed at startups

**2. Per-unit royalty** — every single chip you ship, forever

> **State this caveat aloud:** actual terms are under NDA and vary enormously by volume, product tier, and negotiating position. Publicly reported figures are directional only. Anyone quoting you a precise number is guessing.

---

### Slide 19 — The Royalty Math at Volume
Publicly reported ranges: roughly **1–2% of chip ASP** for application processors; **cents per unit** for microcontrollers.

Worked example — put real arithmetic on the slide:
```
MCU product line
  100 M units/year  ×  $2.00 ASP  ×  ~1.5%
  ≈ $0.03/unit  ≈  $3 M per year
  ... every year, for the life of the product
  ... plus the upfront licence

Phone SoC
  50 M units/year  ×  $500 ASP  ×  ~1%
  ≈ $5.00/unit  ≈  $250 M per year
```
**The key property: royalty scales with your success.** You pay the most precisely when you win biggest. For a high-volume, low-margin product, this is the difference between a viable business and a dead one.

---

### Slide 20 — What RISC-V Actually Costs (The Honest Version)
**The ISA: $0.** No licence, no royalty, no negotiation, no permission, no NDA, no renewal risk.

**But you still need a core.** Two paths:

| Path | You pay | You get |
|---|---|---|
| **Buy commercial RISC-V IP** (SiFive, Andes, Ventana) | Licence + royalty — but under real competitive pressure | Support, verification collateral, someone to blame |
| **Take an open core** (Ibex, CVA6, Rocket) | $0 — but you own integration, verification, support, maintenance | Total control, zero vendor dependency |

**The cost doesn't vanish. It moves — from *licensing* to *engineering*.**

---

### Slide 21 — Where the Cost Moves To (Read the Room)
Say this slowly, because it's about them:

> *"When a company takes an open core instead of licensing one, they don't save the money. They convert it into headcount. And the single largest line item in that headcount is verification."*

- An unverified open core is a liability, not an asset
- Somebody must own coverage closure, ISS co-simulation, and sign-off
- **That somebody is in this room**

**This is not a motivational flourish — it's the actual economic mechanism behind the job you're being trained for.**

---

### Slide 22 — Who Captures Value in the RISC-V Stack
```
  RISC-V International  ── membership fees. Non-profit. Captures almost nothing.
           │
  IP vendors            ── SiFive, Andes, Ventana, Codasip. Sell cores.
           │
  Design & verification ── services, tools, and in-house teams. GROWING FAST.
           │
  EDA                   ── Cadence, Synopsys, Siemens. Sell to everyone above.
           │
  Chip companies        ── capture the licence savings + product differentiation
```
**Note the inversion:** in the ARM model, the ISA owner captures a slice of every chip. In the RISC-V model, the ISA owner captures almost nothing — and the value redistributes downward to implementers and verifiers.

---

# MODULE 4 — Geopolitics & Sovereignty (20 min)

### Slide 23 — Why Switzerland?
2020: the RISC-V Foundation moved its incorporation from Delaware, USA → **Switzerland**, becoming RISC-V International.

**Stated reason:** ensure the standard remains **globally neutral**, insulated from any single country's export-control regime.

**Actual context:** escalating US–China trade restrictions. Members needed certainty that participation could not be revoked for political reasons.

**Teaching point, and the thesis of this module:**
> *An ISA is now geopolitical infrastructure.*

---

### Slide 24 — The Sovereignty Argument
Ask any government: what happens to your domestic electronics industry if a foreign company, subject to a foreign government, can revoke your right to build processors?

That is not hypothetical. It's the scenario that produced:

| Region | Programme |
|---|---|
| **India** | DIR-V (MeitY) — SHAKTI, VEGA |
| **China** | State-backed RISC-V push; Alibaba/T-Head XuanTie; explicit hedge against ISA export controls |
| **EU** | European Processor Initiative, DARE — RISC-V-based sovereign HPC |

**The common logic:** you cannot build a sovereign semiconductor industry on an ISA someone else controls. RISC-V is the only ISA that can be adopted *without asking anyone's permission.*

---

### Slide 25 — The Counter-Pressure
Be honest — this isn't a settled win:
- RISC-V's openness has drawn **regulatory scrutiny**, including US legislative proposals to restrict collaboration with Chinese entities on RISC-V
- The open governance model is precisely the defence: **there is no chokepoint to control.** You cannot embargo a published specification.
- But ecosystem participation, toolchains, and IP vendors *can* be pressured

**Nuanced takeaway for your engineers:** the ISA itself is genuinely un-embargoable. The ecosystem around it is not fully. That tension is live and worth watching.

---

# ☕ BREAK (15 min)

---

# MODULE 5 — Competitive Landscape & Market (35 min)

### Slide 26 — Who Actually Ships RISC-V Today

| Company | What they use it for |
|---|---|
| **NVIDIA** | GPU microcontrollers — billions of cores shipped *inside* GPUs |
| **Qualcomm** | Snapdragon Wear platform (with Google); AI chip instruction refinement |
| **Google** | Android RISC-V ABI; internal infrastructure controllers |
| **Western Digital / Seagate** | Storage controllers (SweRV, open-sourced) |
| **Meta** | MTIA AI accelerator control cores |
| **Samsung** | Various controllers |
| **Alibaba / T-Head** | XuanTie C-series application processors |
| **Espressif** | ESP32-C series — mass-market IoT Wi-Fi SoCs |
| **Infineon, Renesas, NXP, Microchip** | Announced RISC-V microcontroller lines |

> **Framing line:** *RISC-V's first billions of cores shipped invisibly, as controllers inside other people's chips.* Nobody had to be convinced to switch — the cores were never visible to customers in the first place. That's the wedge.

---

### Slide 27 — The RISE Project — Fixing the Real Bottleneck
**R**ISC-V **S**oftware **E**cosystem.

Members: **Andes, Google, Intel, Imagination, MediaTek, NVIDIA, Qualcomm, Red Hat, Rivos, Samsung, SiFive, T-Head, Ventana.**

Mandate: get Linux distros, Android, toolchains (GCC/LLVM), and language runtimes (Java, Go, Python) working *well* — not merely working — on RISC-V.

**Why it exists:** hardware was never the bottleneck. Software was. Note that this member list includes direct competitors co-funding shared infrastructure — a strong signal of where they think this goes.

---

### Slide 28 — Commercial IP vs Open Cores

**Commercial — you pay, you get support and verification collateral:**
SiFive · Andes Technology · Codasip · Ventana Micro · Tenstorrent · **MIPS** *(yes — they pivoted to RISC-V)*

**Open source — free, you own the verification burden:**

| Core | Origin | Class |
|---|---|---|
| **Ibex** | lowRISC (from PULP zero-riscy) | 32-bit MCU ← *this afternoon's DUT* |
| **CVA6** | OpenHW Group (from PULP Ariane) | 64-bit, Linux-capable |
| **Rocket** | UC Berkeley (Chisel) | 64-bit, in-order |
| **BOOM** | UC Berkeley | 64-bit, out-of-order |
| **CV32E40P** | OpenHW Group | 32-bit embedded |
| **SweRV / VeeR** | Western Digital | 32-bit, high performance |

> **Callback to slide 20:** the right-hand table is "free." Now you know what that word is doing.

---

### Slide 29 — Market Size: Read These Numbers Critically

| Source | 2025/26 size | Forecast |
|---|---|---|
| Mordor Intelligence | $1.34 B (2025) → $1.89 B (2026) | — |
| Global Market Insights | $2.3 B (2025) | $34.7 B by 2035, 31.3% CAGR |
| Straits Research | $1.35 B (2025) | $26.1 B by 2034, 42.9% CAGR |
| The SHD Group | — | **35.9 B units** / **$318 B revenue by 2031** |

**Say this out loud — it's the actual lesson:**
> *These estimates differ by ~2× for the same year because analysts define "the RISC-V market" differently. Some count only IP licensing revenue. Some count the full value of every SoC containing a RISC-V core anywhere on the die.* **Always ask what's being counted.**

**What is reliable:** unit shipment growth is real and fast, and it's concentrated in embedded and controller segments.

---

### Slide 30 — Where RISC-V Wins Today vs Where It's Still Climbing
```
STRONG NOW                          STILL CLIMBING
──────────────                      ───────────────
Embedded MCUs                       Smartphone application processors
Storage controllers                 Laptops / desktops
GPU & AI accelerator control cores  Datacenter servers
IoT / wireless SoCs                 Anything needing a mature GPU stack
Deeply customised domain chips      Windows-class software compatibility
Security enclaves (OpenTitan)
Academic / research
```
**The reason for the split is entirely software.** The left column doesn't need a rich software ecosystem. The right column does. That's exactly what RVA23 and RISE are attacking — and why slide 17 matters.

---

### Slide 31 — Why Companies Choose RISC-V — and the Honest Counterweights

**Why they choose it:**
1. **No royalties** — decisive at high volume (slide 19)
2. **No licence negotiation** — start today, no legal cycle
3. **Custom instructions** — reserved opcode space for domain acceleration
4. **Supply-chain independence** — no vendor or government can revoke access
5. **Talent** — universities teach it; graduates arrive knowing it

**The honest counterweights — put these on the slide:**
- Software ecosystem still behind ARM for application-class workloads
- On open cores, **you inherit the entire verification burden**
- Fragmentation risk is *managed* by profiles, not eliminated
- ARM's tooling, documentation, and support maturity are a genuine advantage

> **Speaker note:** Include the counterweights. An audience that only hears the upside will assume you're selling, and will discount the whole morning.

---

# MODULE 6 — RISC-V in India (45 min)

### Slide 32 — Why India Cares
Four drivers, in order of how often they're cited:
1. **Strategic autonomy** — an ISA is critical infrastructure; licence dependence is a national risk
2. **Royalty outflow** — every ARM-based chip designed in India sends royalties abroad
3. **Atmanirbhar Bharat** — self-reliance policy explicitly names semiconductors
4. **Talent leverage** — India already performs a large share of the world's chip *design*; owning the ISA moves the country up the value chain

**The phrase you'll hear:** *"RISC-V is India's ISA."* That deserves unpacking — next slide.

---

### Slide 33 — "RISC-V Is India's ISA" — What That Claim Actually Means
**What's true:**
- India adopted RISC-V as its **national ISA direction** for indigenous processors (DIR-V, MeitY)
- India has produced fully indigenous RISC-V silicon — designed *and* fabricated domestically
- Government-funded programmes and procurement are standardising on it

**What's not true:**
- RISC-V is not owned by India — it's governed by RISC-V International in Switzerland
- China, the EU, and others are running parallel national programmes on the *same* ISA

**The accurate formulation:**
> *India has chosen RISC-V as the foundation of its sovereign processor strategy — and the openness of the ISA is precisely what made that choice possible. No other ISA could have been adopted this way.*

> **Speaker note:** Be precise here. Your engineers will repeat what you say in interviews and customer meetings. The nuanced version is more impressive than the slogan, and it's defensible when someone pushes back.

---

### Slide 34 — DIR-V: Digital India RISC-V Programme
- Launched by **MeitY** in 2022, under Atmanirbhar Bharat
- Goal: indigenous microprocessor design, commercial silicon, and design wins
- Two anchor programmes:
  - **SHAKTI** — IIT Madras
  - **VEGA** — C-DAC (Centre for Development of Advanced Computing)
- Wider intent: an ecosystem of startups, academia, and government labs on a common ISA

**Connect back to Module 4:** this is the sovereignty argument, funded and executed.

---

### Slide 35 — SHAKTI (IIT Madras)
- India's first indigenous processor programme, RISC-V based
- A **family** of cores spanning the performance range:
  - **E-class** — microcontroller, IoT, embedded
  - **C-class** — mid-range controller, Linux-capable variants
  - **I-class** — higher performance, out-of-order targets
- Open-sourced; taped out on multiple nodes including SCL Chandigarh
- Significant academic output and startup spin-outs

---

### Slide 36 — VEGA (C-DAC)
- C-DAC's indigenous RISC-V processor family
- **THEJAS64** — 64-bit single-core SoC, **fabricated at SCL Chandigarh**. India's first fully indigenous RISC-V design *and* fabrication.
- **DHRUV64** — 1 GHz, 64-bit dual-core RISC-V CPU
- Boards shipping: **ARIES NOVA**, **ARIES ECO** — aimed at embedded developers, IoT, robotics, startups
- Nationwide VEGA workshop roadshows running through the academic ecosystem

> **Speaker note:** "Designed *and fabricated* in India" is the phrase that carries weight. Design alone is common — India does a lot of it for everyone else. The fabrication step is what makes it a sovereignty claim rather than a services claim.

---

### Slide 37 — Indian RISC-V Startups
| Company | Focus |
|---|---|
| **InCore Semiconductors** | RISC-V core IP, custom SoC design (IIT Madras spin-off) |
| **Mindgrove Technologies** | Indigenous SoCs for IoT/consumer (IIT Madras spin-off) |
| **Calligo Technologies** | High-performance / HPC-oriented RISC-V |

Plus multinationals expanding their Indian RISC-V design teams — realistically, **this is where the near-term jobs are.**

---

### Slide 38 — India Semiconductor Mission — The Industrial Context
- **ISM 2.0** — sustained government investment in design *and* fabrication
- **Tata + PSMC, Dholera (Gujarat)** — India's first large commercial fab
- **Micron, Sanand (Gujarat)** — ATMP (assembly, test, marking, packaging)
- **SCL Chandigarh** — existing government fab; where THEJAS64 was made
- India's semiconductor market projected around **$63 B by 2026**, ~20% CAGR

**Connect it:** fabs need designs. Designs need verification engineers. That's the room.

---

### Slide 39 — What This Means for Your Career
- Reported talent shortfall across Indian semiconductor design, fab, test, and packaging runs into the **hundreds of thousands**
- Typical reported VLSI compensation (2026): **~₹7.5 LPA** entry, **~₹26 LPA** at 5–8 years
- **CPU verification is one of the scarcest skills in that pool** — most DV engineers stay at IP level and never cross over
- Every core in this room's future — SHAKTI, VEGA, a startup's SoC, a multinational's controller — needs someone who can verify a pipeline, an interrupt controller, and a PMP

**Close the morning with:**
> *"That's why this is a CPU workshop and not a UVM refresher. This afternoon we start on the part almost nobody in the market can do."*

> **Caveat to state aloud:** salary and headcount figures come from industry and training-provider reports and vary widely by source, city, and company tier. Directional, not precise.

---

### Slide 40 — Morning Recap
- An ISA is a **contract**, separable from implementation — that's what makes all of this possible
- RISC-V gave the spec away in 2014; the value moved to implementers and **verifiers**
- ARM charges upfront + per-unit forever; RISC-V converts that cost into **headcount**
- An ISA is now geopolitical infrastructure — India, China, EU all responded
- DIR-V is real, funded, and has silicon: SHAKTI, VEGA, THEJAS64
- **After lunch: what a CPU actually is, and how you verify one.**

---

# 🍽 LUNCH (45 min)

---

# MODULE 7 — From IP DV to CPU DV (40 min)

*This module exists solely because of who's in the room. Do not skip it.*

### Slide 41 — Your Current Mental Model
```
  Sequence → Driver → [ DUT: AXI Slave ] → Monitor → Scoreboard
                            ↑                            ↑
                      config regs                  reference model
                                                  (predictable, small)
```
- Stimulus is **transactions** you generate
- The DUT is **reactive** — it responds to what you drive
- The reference model is a **function of the input**
- State space is bounded and enumerable

---

### Slide 42 — What Changes With a CPU
```
  Compiled Program (in memory)
          ↓
     [ CPU fetches its own stimulus ]
          ↓
  Bus transactions the CPU decides to make
          ↓
  Monitor → Scoreboard → ??? what is "correct"?
```
- The DUT **generates its own stimulus** by fetching instructions
- You do not drive transactions — you **load a program**
- "Correct" is defined by a 200-page ISA specification (the one from this morning)
- State space is effectively unbounded

---

### Slide 43 — The Five Things That Actually Get Harder

| # | Challenge | Why |
|---|---|---|
| 1 | **Stimulus is software** | You write C/assembly, not sequences |
| 2 | **No simple golden model** | Reference is an ISS (instruction set simulator) |
| 3 | **Architectural vs microarchitectural state** | Only some state is spec-visible |
| 4 | **Concurrency everywhere** | Pipeline, interrupts, memory all in flight together |
| 5 | **Coverage is semantic** | "Did we hit a load-use hazard?" not "did we hit a burst type?" |

---

### Slide 44 — Architectural vs Microarchitectural State
**Architectural (the contract — must match the spec)**
- 32 general-purpose registers `x0–x31`
- Program counter
- CSRs (`mstatus`, `mepc`, `mcause`, …)
- Memory contents

**Microarchitectural (implementation detail — free to differ)**
- Pipeline registers
- Forwarding paths
- Cache tags and valid bits
- Prefetch buffer contents

**Key line:** *An ISS models the left box only. Bugs live in the right box but must be caught by observing the left.*

> **Speaker note:** Single most important slide of the afternoon. Spend 5 minutes. It reframes every checker they will ever write. Tie it back to slide 5 — this *is* the contract, now viewed from the verification side.

---

### Slide 45 — How Do You Even Check a CPU? — Four Strategies
1. **Self-checking software** — program computes a known answer, writes PASS/FAIL to a magic address
2. **ISS co-simulation** — run Spike/Sail in lockstep, compare retired instructions
3. **Bus-level protocol checking** — assertions on OBI/AXI
4. **Formal / ISA-formal** — prove instruction semantics

*"Today's TB uses #1 and #3. #2 is where you graduate to."*

---

### Slide 46 — Strategy 1: Self-Checking Software (What This Repo Does)
```
CPU executes store to 0x00010000
         │
         ▼
data_req=1, data_we=1, data_addr=0x10000, data_wdata=?
         │
         ▼
   TB tohost monitor
         │
   wdata==1 ──► TEST PASSED
   wdata!=1 ──► TEST FAILED
```
- Convention borrowed from the official `riscv-tests` suite
- The TB knows *nothing* about what the software did
- Cheap and portable — the same test runs on FPGA and on silicon

---

### Slide 47 — Strategy 2: ISS Co-Simulation (The Industry Standard)
```
     Program
    ╱        ╲
   ▼          ▼
 [ RTL ]   [ Spike ISS ]
   │           │
 retired    retired
 instr +    instr +
 reg write  reg write
   ╲         ╱
    ▼       ▼
   compare every retirement
```
- Catches bugs the software never noticed
- Requires a **trace interface** out of the RTL (`RVFI` / `RVVI`)
- Ibex has `ibex_tracer.sv` and an RVFI port — this is where you go after Phase 10

---

### Slide 48 — Where UVM Still Earns Its Keep
Your UVM skills are not wasted — they move to the **environment**, not the stimulus.

| UVM does | Example |
|---|---|
| Bus back-pressure | Hold `gnt=0` for N cycles |
| Error injection | Assert `data_err_i` on a load |
| Interrupt timing | Assert `irq_timer_i` at cycle 4,271 |
| Debug control | Drive `debug_req_i` mid-instruction |
| Fault injection | Force a bit flip in a cache RAM |

**None of these can be done from software.**

---

### Slide 49 — The Hybrid Method
```
C code writes sync flag → UVM monitor sees it on the bus
                              ↓
                    UVM sequence fires stimulus
                       (interrupt / bus error)
                              ↓
              C trap handler runs, writes result to tohost
                              ↓
              UVM scoreboard checks value AND timing
```
*This is how real CPU verification teams test interrupts. You'll build this in Phase 6.*

---

### Slide 50 — Decision Matrix: C vs UVM vs Hybrid

| Feature | C Test | UVM Seq | Hybrid |
|---|---|---|---|
| ISA arithmetic | ✅ | | |
| CSR read/write | ✅ | | |
| Exception handlers | ✅ | | |
| PMP configuration | ✅ | | |
| OBI bus protocol | | ✅ | |
| Bus back-pressure | | ✅ | |
| Bus error injection | | ✅ | |
| Interrupt timing / latency | | | ✅ |
| Cache ECC injection | | | ✅ |
| Debug halt / resume | | | ✅ |
| WFI wakeup latency | | | ✅ |

> **Print as a handout.** They will refer to it for the next 10 weeks.

---

# MODULE 8 — Computer Architecture Foundations (65 min)

*Assume they know digital logic and RTL. Do not assume they know pipelines.*

### Slide 51 — The Stored-Program Idea
- Instructions and data live in the **same memory**, in the same format
- The machine reads a number, and that number *means* an action
- **Von Neumann** (1945) — one memory, one bus
- **Harvard** — separate instruction and data memory/buses

**Ibex is "modified Harvard":** two separate bus ports, one shared address space.
Point at `instr_req`/`instr_addr` and `data_req`/`data_addr` on the interface.

---

### Slide 52 — The Instruction Cycle
```
        ┌─────────────┐
   ┌───►│    FETCH    │  read instruction at PC
   │    └──────┬──────┘
   │           ▼
   │    ┌─────────────┐
   │    │   DECODE    │  what is it? which registers?
   │    └──────┬──────┘
   │           ▼
   │    ┌─────────────┐
   │    │   EXECUTE   │  ALU does the work
   │    └──────┬──────┘
   │           ▼
   │    ┌─────────────┐
   │    │   MEMORY    │  load/store only
   │    └──────┬──────┘
   │           ▼
   │    ┌─────────────┐
   └────┤  WRITEBACK  │  result → register file
        └─────────────┘
```
**PC advances by 4 (or 2 for compressed) unless something changes it.**

---

### Slide 53 — The Datapath
Clean block diagram: PC → IMEM → Decoder → RegFile → ALU → DMEM → RegFile writeback, with the branch-target mux feeding back into PC.

Label every wire. Tell them: **"You will find every one of these signals in the Ibex waveform in about two hours."**

---

### Slide 54 — The Register File
- 32 registers × 32 bits (RV32)
- **`x0` is hardwired to zero** — writes are silently discarded
- 2 read ports + 1 write port (Ibex `RegFileFF` = flip-flop based)
- Why `x0` matters: `mv rd, rs` is really `addi rd, rs, 0`; `nop` is `addi x0, x0, 0`

> **Verification hook:** "write to x0, read it back, expect 0" is a real test case. It's in the plan.

---

### Slide 55 — Why Pipeline? The Laundry Analogy
Non-pipelined: 4 loads × 4 stages × 30 min = 8 hrs
Pipelined: overlapping = 3.5 hrs

Then the CPU version:
- **Single-cycle:** clock period = worst-case path through *everything*
- **Pipelined:** clock period = worst *stage*
- Throughput ↑, latency per instruction roughly unchanged

---

### Slide 56 — Classic 5-Stage vs Ibex 2-Stage
```
Classic RISC (MIPS-style):
IF │ ID │ EX │ MEM │ WB

Ibex (2-stage, default):
IF │ ID/EX
   └─ decode + execute + memory + writeback all in one stage

Ibex (3-stage, WritebackStage=1):
IF │ ID/EX │ WB
```
- Fewer stages = fewer hazards, smaller area, lower IPC ceiling
- Ibex targets **embedded control**, not application performance
- Our TB uses `WritebackStage=0`

**Callback:** this is slide 7's separability made concrete — same ISA, radically different implementation.

---

### Slide 57 — Hazard Type 1: Structural
Two instructions want the same hardware resource in the same cycle.
- Example: single-ported memory — fetch and load collide
- Ibex avoids most of this with **separate instruction and data buses**
- Resolution: stall

---

### Slide 58 — Hazard Type 2: Data (RAW)
```asm
addi t0, zero, 5
addi t1, t0, 3     # needs t0 — is it written yet?
```
- **RAW** (read-after-write) — the real one
- WAR / WAW only matter with out-of-order execution; Ibex is in-order, so they're free
- Solutions: **stall** (slow) or **forward/bypass** (fast)

Diagram: forwarding path from EX output back to EX input.

---

### Slide 59 — The Load-Use Hazard (The One You Can't Forward Away)
```asm
lw   t0, 0(a0)
addi t1, t0, 1     # t0 not back from memory yet
```
- The memory result arrives *after* the point where it's needed
- Must stall at least one cycle — compilers try to fill the slot
- **Prime verification target.** Directed assembly test in Phase 3.

---

### Slide 60 — Hazard Type 3: Control
```asm
beq t0, t1, target
addi t2, t2, 1      # should this execute?
```
- Branch outcome isn't known until EX
- Instructions already fetched must be **flushed**
- Ibex: no branch predictor by default (`BranchPredictor=0`) — take the penalty
- **Verification targets:** taken vs not-taken, back-to-back branches, branch target spanning a cache line

---

### Slide 61 — Memory Hierarchy
Pyramid: Registers (1 cyc) → L1 (~4) → L2 (~12) → DRAM (~200) → Flash/Disk.

**Ibex reality check:**
- Optional **instruction cache** (`ICache` parameter — off in our config)
- **No data cache at all** — every load/store goes straight to the bus
- Why: embedded cores value latency *predictability*; determinism > throughput

---

### Slide 62 — Memory-Mapped I/O
- No special I/O instructions in RISC-V — peripherals are just addresses
- A store to `0x00020000` is a UART character write
- A store to `0x00010000` is our end-of-test signal

Show the actual repo memory map:
```
0x00000000 - 0x0000FFFF   64 KB   Instruction ROM
0x00010000 - 0x0003FFFF  192 KB   Data RAM
0x00010000                4 B     tohost  (end-of-test)
0x00020000                4 B     UART TX
```

---

### Slide 63 — Privilege Modes
```
Machine (M)      ── highest, always present, firmware/bare metal
Supervisor (S)   ── OS kernel (needs virtual memory)
User (U)         ── applications
```
- Ibex supports **M** and optionally **U**
- No S-mode → no MMU → **no Linux on Ibex**
- *This is why Ibex is a microcontroller core, not an application processor* — and why RVA23 (slide 17) doesn't apply to it

---

### Slide 64 — Exceptions vs Interrupts
| | Exception | Interrupt |
|---|---|---|
| Source | The instruction itself | Outside the core |
| Timing | **Synchronous** — same place every run | **Asynchronous** — timing varies |
| Examples | illegal instr, ECALL, misaligned load | timer, external, software |
| Reproducible? | Yes | Not without control |

**Verification consequence:** exceptions → pure C tests. Interrupts → hybrid, because UVM must control the timing.

---

### Slide 65 — The Trap Sequence
```
1. Event occurs (exception or interrupt)
2. HW saves PC        → mepc
3. HW records reason  → mcause
4. HW records detail  → mtval
5. HW saves/clears MIE→ mstatus.MPIE ← MIE, MIE ← 0
6. PC ← mtvec
7. ... handler runs ...
8. MRET: PC ← mepc, MIE ← MPIE
```
**Every one of those steps is a checkable assertion.** Phases 5 and 6 build them.

---

# ☕ BREAK (15 min)

---

# MODULE 9 — RISC-V ISA, Technical (50 min)

*The morning covered what an ISA is. This is what RISC-V specifically says.*

### Slide 66 — RV32I: The Whole Base ISA on One Slide
~40 instructions:
- **Arithmetic:** `ADD SUB ADDI`
- **Logical:** `AND OR XOR ANDI ORI XORI`
- **Shifts:** `SLL SRL SRA SLLI SRLI SRAI`
- **Compare:** `SLT SLTU SLTI SLTIU`
- **Branch/Jump:** `BEQ BNE BLT BGE BLTU BGEU JAL JALR`
- **Load/Store:** `LB LH LW LBU LHU SB SH SW`
- **Upper immediate:** `LUI AUIPC`
- **System:** `ECALL EBREAK FENCE`

**That's it. That's a complete, Turing-capable CPU.**

---

### Slide 67 — Load/Store Architecture
```asm
# RISC-V — must be explicit
lw   t0, 0(a0)      # load
addi t0, t0, 1      # compute
sw   t0, 0(a0)      # store

# x86 — one instruction touches memory and computes
addl $1, (%rax)
```
- ALU operands come only from registers
- Only load/store instructions touch memory
- **Why you care:** simpler pipeline, and the data bus traffic becomes predictable and checkable

**Addressing modes:** RISC-V has essentially **one** — `register + signed 12-bit immediate`. Compare x86's base + index×scale + displacement + segment. One adder does address generation.

---

### Slide 68 — The Six Instruction Formats
```
      31        25 24  20 19  15 14 12 11   7 6    0
 R:  │ funct7    │ rs2 │ rs1 │funct3│  rd  │opcode│  reg-reg
 I:  │  imm[11:0]      │ rs1 │funct3│  rd  │opcode│  immediate, loads, JALR
 S:  │ imm[11:5] │ rs2 │ rs1 │funct3│imm[4:0]│opcode│ stores
 B:  │imm[12|10:5]│rs2 │ rs1 │funct3│imm[4:1|11]│opcode│ branches
 U:  │       imm[31:12]              │  rd  │opcode│  LUI, AUIPC
 J:  │  imm[20|10:1|11|19:12]        │  rd  │opcode│  JAL
```

---

### Slide 69 — Why the Immediates Look Insane
The B and J immediate bits appear **scrambled**. This is deliberate.

**Reason:** `rs1`, `rs2`, and `rd` are always in the *same bit positions* across every format, and immediate bits are placed so each output bit comes from as few source positions as possible.

**Consequence:**
- Register file read can begin **before decode completes** — no muxing needed
- Immediate sign-extension is fixed wiring, not a barrel shifter

> **Speaker note:** A beautiful example of ISA design serving microarchitecture. Ugly for humans, cheap in silicon — and that trade was made consciously. Strong discussion point for RTL-minded people.

---

### Slide 70 — Hand-Decode Exercise (Interactive, 10 min)
Put three words on the slide; the room decodes them in pairs.
```
0x00A50513   →  ?
0x00052283   →  ?
0x00028463   →  ?
```
Worked example to demonstrate first:
```
0x00A50513
31       25 24   20 19   15 14 12 11    7 6      0
┌──────────┬───────┬───────┬─────┬───────┬────────┐
│  imm[11:0] = 0x00A │ rs1=x10 │ 000 │ rd=x10 │0010011│
└──────────┴───────┴───────┴─────┴───────┴────────┘
→  addi x10, x10, 10     (addi a0, a0, 10)
```
Answers: `addi a0, a0, 10` · `lw t0, 0(a0)` · `beq t0, zero, +8`

> **Highest-value 10 minutes of the day. Do not cut it.** Do the first one on a whiteboard, by hand.

---

### Slide 71 — ABI and Calling Convention
The ISA says nothing about *who owns which register*. The **ABI** does.

| Register | ABI Name | Role | Saved by |
|---|---|---|---|
| x0 | zero | hardwired 0 | — |
| x1 | ra | return address | caller |
| x2 | sp | stack pointer | callee |
| x5–7 | t0–t2 | temporaries | caller |
| x8 | s0/fp | saved / frame pointer | callee |
| x10–11 | a0–a1 | args / return values | caller |
| x12–17 | a2–a7 | arguments | caller |
| x18–27 | s2–s11 | saved | callee |

**Why you care:** when you read a disassembly at 4:30 PM, you'll see `a0`, not `x10`.

---

### Slide 72 — Naming Convention — Decode This
```
RV32IMC_Zicsr
│ │ ││└─ Zicsr : CSR access instructions
│ │ │└── C     : compressed 16-bit instructions
│ │ └─── M     : multiply / divide
│ └───── I     : base integer
└─────── RV32  : 32-bit registers
```
**"G" is shorthand for `IMAFD_Zicsr_Zifencei`** — the "general purpose" bundle. `RV64GC` is the typical Linux target.

**Our Ibex config is exactly `RV32IMC_Zicsr`** — you'll see this string in `sw/Makefile`:
```make
CFLAGS = -march=rv32imc_zicsr -mabi=ilp32 ...
```

---

### Slide 73 — The M Extension (Multiply/Divide)
`MUL MULH MULHSU MULHU DIV DIVU REM REMU`

**Edge cases that are actual spec requirements — and actual test cases:**
```
DIV by zero      → quotient = 0xFFFFFFFF (all ones), remainder = dividend
                   NO exception is raised (unlike x86!)
Overflow DIV     → INT_MIN / -1 = INT_MIN, remainder = 0
MULH variants    → upper 32 bits of the 64-bit product
                   MULHSU: signed × unsigned — easy to get wrong
```
**Ibex config:** `RV32M = RV32MFast`. Alternatives: `RV32MNone`, `RV32MSlow`, `RV32MSingleCycle`.

---

### Slide 74 — The C Extension (Compressed)
- 16-bit encodings for the most common instructions
- Typically **25–30% code size reduction** — huge for embedded flash cost
- Any 16-bit instruction maps 1:1 to a 32-bit one; the decoder expands it

**Verification consequence — this is the important part:**
- Instructions may now start at any **2-byte** boundary
- A 32-bit instruction can **straddle a fetch boundary** (and a cache line)
- The prefetch buffer must handle misalignment

**Rich bug area.** Ibex has a dedicated `ibex_compressed_decoder.sv`.

---

### Slide 75 — Zicsr and the CSR Instructions
```asm
csrrw rd, csr, rs1    # rd ← csr;  csr ← rs1        (swap)
csrrs rd, csr, rs1    # rd ← csr;  csr ← csr |  rs1 (set bits)
csrrc rd, csr, rs1    # rd ← csr;  csr ← csr & ~rs1 (clear bits)
csrrwi/csrrsi/csrrci  # same, 5-bit immediate instead of rs1
```
**Read-modify-write is atomic in one instruction** — no interrupt can sneak in between.

Common idioms:
```asm
csrr  t0, mcause      # pseudo-op for csrrs t0, mcause, x0
csrsi mstatus, 0x8    # set MIE — enable interrupts
csrci mstatus, 0x8    # clear MIE — disable interrupts
```

---

### Slide 76 — M-Mode CSRs
| CSR | Addr | What it does |
|---|---|---|
| `mstatus` | 0x300 | MIE (global int enable), MPIE (saved), MPP (prev mode) |
| `misa` | 0x301 | Reports implemented extensions — reads `RV32IMC` for us |
| `mie` | 0x304 | Per-interrupt enable bits |
| `mtvec` | 0x305 | Trap vector BASE + MODE (direct vs vectored) |
| `mscratch` | 0x340 | Scratch for the handler (usually a stack pointer) |
| `mepc` | 0x341 | PC at time of trap — MRET returns here |
| `mcause` | 0x342 | Bit 31 = interrupt flag, bits 30:0 = cause code |
| `mtval` | 0x343 | Faulting address or instruction word |
| `mip` | 0x344 | Pending interrupts (read-only) |
| `mcycle` | 0xB00 | Free-running cycle counter |
| `minstret` | 0xB02 | Retired instruction counter |

**WARL** = Write Any Values, Read Legal Values. *A classic source of CSR bugs — and a classic test.*

---

### Slide 77 — Exception and Interrupt Cause Codes
**Exceptions (bit 31 = 0):**
| mcause | Exception | How to trigger |
|---|---|---|
| 1 | Instruction access fault | Fetch from PMP-denied region |
| 2 | Illegal instruction | `.word 0x00000000` |
| 3 | Breakpoint | `EBREAK` |
| 4 | Load address misaligned | `lw` at an odd address |
| 5 | Load access fault | Load from PMP-denied region |
| 6 | Store address misaligned | `sw` at an odd address |
| 7 | Store access fault | Store to PMP-denied region |
| 11 | Environment call (M-mode) | `ECALL` |

**Interrupts (bit 31 = 1):**
```
0x80000003 software   0x80000007 timer   0x8000000B external
0x80000010 fast IRQ 0  ...  0x8000001E fast IRQ 14
```
**Ibex has 19 interrupt lines:** software, timer, external, `irq_fast_i[14:0]`, and `irq_nm_i` (NMI — fires even with `mstatus.MIE=0`). The 15 fast local interrupts are a **non-standard Ibex extension**.

---

### Slide 78 — PMP and Debug
**Physical Memory Protection** — region-based access control, checked on every fetch/load/store.
```
TOR    — Top Of Range: spans from previous pmpaddr to this one
NA4    — Naturally Aligned 4-byte region
NAPOT  — Naturally Aligned Power-Of-Two
         pmpaddr = base | ((size/2) - 1)
         e.g. 1 KB region: pmpaddr = base | 0x1FF
```
Lowest-numbered matching region wins. The `L` (lock) bit makes a region immutable **even in M-mode** until reset.

**Debug** — external debugger asserts `debug_req_i` → core enters debug mode. `dcsr` (incl. `step` bit), `dpc`. Halt, single-step, read/write GPRs and CSRs, resume. Triggers via `tdata1`/`tdata2`. *Phase 10.*

---

# MODULE 10 — Enter Ibex (40 min)

### Slide 79 — lowRISC and OpenTitan
- **lowRISC** — a not-for-profit in Cambridge, UK, building open silicon
- **OpenTitan** — the first open-source silicon **root of trust**, backed by Google, Nuvoton, Western Digital, Winbond, ETH Zurich
- **Ibex is the CPU inside OpenTitan**

**Consequence:** Ibex is not a toy. It's verified to production standards, with a real DV team, real coverage closure, and real security requirements. That's why we train on it.

**Callback to slide 28:** this is the open-core column — and OpenTitan is what "you own the verification burden" looks like when someone actually does the work properly.

---

### Slide 80 — Ibex Lineage
```
ETH Zurich / Univ. Bologna — PULP Platform
              │
        "zero-riscy" core
              │
     adopted by lowRISC (2018)
              │
          ── Ibex ──
              │
     deployed in OpenTitan
```
Design goals: **small area, low power, deterministic, security-hardenable.** Explicitly *not* aiming for high IPC.

---

### Slide 81 — Ibex Microarchitecture
```
   ┌──────────────────┐        ┌────────────────────────────┐
   │       IF         │        │           ID/EX            │
   │                  │        │                            │
   │  PC              │        │  Decoder                   │
   │  Prefetch buffer │───────►│  Register file (x0-x31)    │
   │  Compressed      │ instr  │  ALU                       │
   │    decoder       │        │  Multiplier / Divider      │
   │                  │        │  CSR block                 │
   │  (opt. ICache)   │        │  Load-Store Unit           │
   │                  │        │  Controller / FSM          │
   └────────┬─────────┘        └──────────┬─────────────────┘
            │                             │
      instr bus (OBI)               data bus (OBI)
```
**Two stages.** Optional third writeback stage. In-order. No branch prediction by default. No data cache, ever.

---

### Slide 82 — The Configuration Space
This is what makes Ibex a great *training* DUT — you turn features on as you learn them.

| Parameter | Our value | What enabling it unlocks |
|---|---|---|
| `RV32M` | `RV32MFast` | Multiply/divide |
| `RV32B` | `RV32BNone` | Bit-manipulation extension |
| `RegFile` | `RegFileFF` | FF vs latch vs FPGA register file |
| `ICache` | `0` | Instruction cache + ECC + scrambling |
| `SecureIbex` | `0` | Lockstep shadow core, dummy instrs, RF ECC |
| `WritebackStage` | `0` | 3rd pipeline stage, new hazard classes |
| `PMPEnable` | `0` | Physical memory protection |
| `BranchPredictor` | `0` | Branch prediction + misprediction recovery |

**Each row is a phase of your training plan.**

> **Discussion prompt (5 min):** "Which one would you enable first, and why?"

---

### Slide 83 — The OBI Bus Protocol
**O**pen **B**us **I**nterface — from the PULP/OpenHW ecosystem. Simpler than AXI, same handshake instincts.
```
Cycle 1:  req = 1, addr = X          CPU requests
Cycle 1:  gnt = 1                    memory grants (zero wait state)
Cycle 2:  rvalid = 1, rdata = Y      memory responds

With wait states:
Cycle 1:  req = 1, addr = X
Cycle 2:  gnt = 0    ← CPU MUST hold req=1 and addr stable
Cycle 3:  gnt = 0
Cycle 4:  gnt = 1
Cycle 5:  rvalid = 1, rdata = Y
```
**Two independent phases:** address (`req`/`gnt`) and response (`rvalid`/`rdata`). They can overlap across transactions.

**Your first UVM task (Phase 4):** randomise the `gnt` delay and prove the CPU holds `req` and `addr` stable.

---

### Slide 84 — Everything You Learned Today, Located in Ibex

| Concept from today | Where it lives |
|---|---|
| Instruction fetch | `ibex_if_stage.sv`, `ibex_prefetch_buffer.sv` |
| Compressed decode | `ibex_compressed_decoder.sv` |
| Instruction decode | `ibex_decoder.sv` |
| Register file | `ibex_register_file_ff.sv` |
| ALU | `ibex_alu.sv` |
| M extension | `ibex_multdiv_fast.sv` |
| CSRs, traps | `ibex_cs_registers.sv` |
| Trap sequencing, stalls, flush | `ibex_controller.sv` |
| Loads/stores, byte enables | `ibex_load_store_unit.sv` |
| PMP | `ibex_pmp.sv` |
| ICache | `ibex_icache.sv` |
| Top-level, config params | `ibex_top.sv`, `ibex_pkg.sv` |

---

### Slide 85 — Our Testbench Architecture
```
             ┌──────────────────────────────────────┐
             │           UVM Testbench              │
 ibex_base_  │  ibex_env                            │
   test      │    ibex_agent                        │
             │      ibex_driver  ── reset, IRQs,    │
             │                      debug_req       │
             │      ibex_monitor ── watches tohost  │
             │    ibex_scoreboard ─ checks tohost==1│
             └──────────────────┬───────────────────┘
                                │ virtual ibex_if
             ┌──────────────────▼───────────────────┐
             │              tb_top.sv                │
             │  256 KB flat byte-addressed SRAM     │
             │  instr port: comb gnt, 1-cyc rvalid  │
             │  data  port: comb gnt, 1-cyc rvalid  │
             │  tohost monitor @ 0x00010000         │
             └──────────────────┬───────────────────┘
                                │
             ┌──────────────────▼───────────────────┐
             │            ibex_top (DUT)             │
             └──────────────────────────────────────┘
```

---

### Slide 86 — Repo Layout
```
Training-FE/
├── RTL/ibex/          ← lowRISC ibex (submodule)
├── sw/
│   ├── crt0.S         ← startup: clear BSS, set sp, call main
│   ├── link.ld        ← ROM@0x0, RAM@0x10000
│   ├── common/uart_simple.h
│   ├── tests/hello_world.c
│   └── Makefile       ← ELF → vmem → dis
├── tb/
│   ├── top/           ← ibex_if.sv, tb_top.sv
│   ├── env/           ← agent, driver, monitor, scoreboard, env
│   └── tests/         ← ibex_base_test.sv, ibex_pkg.sv
├── sim/
│   ├── Makefile       ← sim, waves, clean
│   └── runs/          ← run_YYYYMMDD_HHMMSS_seedN/
└── filelist.f         ← Xcelium compile list
```

---

### Slide 87 — The Full Boot-to-PASS Flow
```
make sim TEST=hello_world
      │
      ├─ sw/Makefile: riscv32-gcc → hello_world.elf
      │                objcopy    → hello_world.vmem
      │                objdump    → hello_world.dis
      │
      └─ xrun:
           tb_top $readmemh loads .vmem into mem_b[]
           UVM build/connect/run phases start
           ibex_driver: rst_n=0 for 10 cycles → rst_n=1
           ibex_top begins fetching at PC=0x0 (boot_addr_i=0)
           crt0.S → clear BSS, set sp → call main()
           main() → uart_puts() → *tohost = 1
           tb_top tohost monitor fires
           UVM_INFO "TEST PASSED" → $finish after 100ns
```

---

### Slide 88 — The 10-Phase Training Roadmap
| Phase | Topic | Deliverable |
|---|---|---|
| 1 | Understand the DUT | 1-page architecture summary |
| 2 | Run the existing TB | Annotated waveform screenshot |
| 3 | Write a C test | `isa_arithmetic.c` passing |
| 4 | OBI bus protocol | Driver with wait-state injection |
| 5 | Exceptions | Test covering 5+ exception types |
| 6 | Interrupts | Hybrid UVM-seq + C-handler test |
| 7 | PMP | All 3 address modes, all permission bits |
| 8 | ICache | Perf benchmark + ECC fault injection |
| 9 | Coverage closure | >90% functional coverage on interrupts |
| 10 | Security & Debug | Lockstep injection + halt/resume |

**~1–2 weeks per phase.**

---

# 🖥 LAB (25 min)

### Lab Slide — Run It Yourself
```bash
git clone --recurse-submodules <repo-url>
cd Training-FE/sim

make sim                    # basic run
make sim WAVES=1            # with waveforms
make sim SEED=12345 WAVES=1 # reproducible + waves

grep -E "PASSED|FAILED" ../runs/run_*/xrun.log | tail -3
```

**Checklist — everyone must reach these three:**
1. ☐ See `TEST PASSED` in the log
2. ☐ Open `waves.shm` in SimVision; find `clk`, `rst_n`, `instr_req`, `instr_addr`
3. ☐ Open `hello_world.dis`, find `main`, match its address to `instr_addr` in the waveform

> **Prep note:** verify the Xcelium licence, `CDNS-1.2` UVM home, and the RISC-V toolchain path (`sw/Makefile` hardcodes `/home/user1/riscv/bin/`) on every trainee machine **the day before**. This is the #1 way this lab fails.

---

# MODULE 11 — Wrap (15 min)

### Slide 89 — The Day in One Line
```
MORNING   what an ISA is → RISC-V's history → the licensing economics
          → geopolitics → the market → India

AFTERNOON why CPU DV is different → how a CPU works → what RISC-V says
          → Ibex → running silicon on your laptop
```
**The through-line:** the ISA is a contract separable from its implementation. That one idea is why RISC-V is free, why governments care, why the value moved to implementers — and why you spent the afternoon learning to verify one.

---

### Slide 90 — Resources
- **Ibex docs** — https://ibex-core.readthedocs.io
- **Ibex source** — https://github.com/lowRISC/ibex
- **RISC-V specs** — https://riscv.org/technical/specifications/
- **RVA23 profile** — https://docs.riscv.org/reference/rva23/
- **RISC-V International** — https://riscv.org
- **OpenTitan** — https://opentitan.org
- **Book:** *Computer Organization and Design, RISC-V Edition* — Patterson & Hennessy
- **Book:** *The RISC-V Reader* — Patterson & Waterman (short, excellent)
- **Spike ISS** — https://github.com/riscv-software-src/riscv-isa-sim

---

### Slide 91 — Homework Before Session 2
1. Read `ibex_top.sv` — be able to explain **every** port
2. Read `ibex_pkg.sv` — understand every parameter enum
3. Draw the Ibex 2-stage pipeline from memory, no references
4. Get `make sim` passing on your own machine if you didn't in the lab
5. Write down 3 questions you couldn't answer today

**Next session: Phase 1 + 2 — deep-dive the DUT and trace `hello_world` in the waveform.**

---
---

# Production Notes

## The seam to watch
The morning is now self-contained and low-risk — it's narrative, and narrative compresses gracefully if you run long. **The afternoon is the tight half:** 48 slides plus a 25-minute lab in ~3h40m. If you overrun before lunch, you will eat the lab, and the lab is the thing they'll remember. Protect it.

## Diagrams to draw properly (do not ship ASCII)
Priority order — these carry the most teaching load:
1. **Slide 7** — separability (one ISA, four implementations). *The morning's anchor.*
2. **Slide 53** — the datapath. *The afternoon's anchor.*
3. **Slide 81** — Ibex 2-stage microarchitecture
4. **Slide 83** — OBI timing. Draw as a real timing diagram — use **WaveDrom**, it renders from JSON and looks professional
5. **Slide 22** — RISC-V value-capture stack
6. **Slide 65** — trap sequence flow
7. **Slide 85** — testbench architecture
8. **Slide 15** — modular ISA tree

Suggested tools: draw.io or Excalidraw for block diagrams; WaveDrom for timing.

## Interactive checkpoints — do not cut
- Slide 4 — "what does your company pay per chip for its CPU core?" (2 min)
- Slide 9 — "name an open-source x86" (3 min)
- **Slide 70 — hand-decode three instructions (10 min) ← highest value of the day**
- Slide 82 — "which parameter would you enable first?" (5 min)
- The lab (25 min)

## Cut list — drop in this order if you run long
**Morning (cut only if badly over):**
1. Slide 8 (CISC vs RISC) — compress to 90 seconds of narration
2. Slide 25 (counter-pressure) — fold one line into slide 24

**Afternoon (where you will actually need this):**
3. Slide 57 (structural hazards) — Ibex largely avoids them anyway
4. Slide 67, addressing-modes half — one spoken line
5. Slide 78 (PMP + Debug) — it's Phases 7 and 10, far away
6. Slide 51 (stored-program) — most of them know this
7. Slide 55 (laundry analogy) — cut if the room already gets pipelining

**Never cut:** Slides 7, 20, 21, 44, 50, 69, 70, 83, or the lab.

## Fact-check before delivery
Current as of Aug 2026, but this moves fast — re-verify the week you deliver:
- ARM royalty ranges (slide 19) — **state the NDA caveat out loud**; these are publicly reported, not authoritative
- Market size figures (slide 29) — the analyst-variance caveat *is* the lesson, so this one ages well
- DHRUV64 / THEJAS64 status (slide 36)
- Dholera fab and Micron Sanand milestones (slide 38)
- Salary and talent-gap figures (slide 39) — **weakest sourcing in the deck**; present as directional
- US regulatory posture on RISC-V (slide 25) — genuinely volatile
- Any new profile ratifications past RVA23

## Handouts to print
- Slide 10 (three ISA business models) — the morning's one-pager
- Slide 50 (C vs UVM vs Hybrid decision matrix)
- Slide 71 (ABI register table)
- Slide 68 (six instruction formats)
- Slide 76 (M-mode CSR table)
- Slide 77 (exception and interrupt cause codes)
