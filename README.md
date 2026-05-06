# LTRA

**Polyphonic Morphing Synthesizer for Monome Norns**

v3.0.0 · [Norns](https://monome.org/docs/norns/) · [Grid 128](https://monome.org/docs/grid/) · [16n Faderbank](https://16n-faderbank.github.io/)

---

## What is LTRA?

LTRA is an **8-voice polyphonic synthesizer** — 4 user voices with independent **twin oscillator doubling** (each voice spawns a second detuned oscillator for stereo spread). Continuous oscillator morphing smoothly transitions between 11 shapes: Dust, Pink Noise, Tuned Noise, Saw+PM, Pure Saw, Square, Pulse, Skewed Triangle, Sine, Buchla Folded, and Buchla Asymmetric.

A **5×16 modulation matrix** routes 4 LFO/Chaos sources (3 dedicated + 1 mixed into the Outline follower) + an Envelope Follower + an Arpeggiator to 16 destinations including pitch, morph, amplitude, filter cutoff, delay time, and feedback.

Built-in **Tape Echo** and **Reverb** effects. Three **stereo loopers** with overdub. Four **gesture loopers** record and replay your grid interactions. Six **snapshots** for instant recall. Full **MIDI/MPE** support with velocity, aftertouch, and slide mapping.

---

## Requirements

| Hardware | Required? | Notes |
|---|---|---|
| Monome Norns (or Shield) | **Yes** | Hosts the synth engine |
| Grid 128 (16×8) | **Yes** | Primary interface |
| 16n Faderbank | Recommended | 16 CC faders, auto-detected |
| MIDI Controller | Optional | Keys, MPE, or CC input |

## Installation

1. Copy the `ltra/` folder to `~/dust/code/` on your Norns
2. Restart Norns: `SYSTEM > RESTART`
3. Load script: `SELECT > LTRA`
4. Wait for "LTRA v3.0.0" on screen — the engine takes ~2 seconds to load

---

## Quick Start (5 Minutes)

### 1. Make Sound

The synth starts silent. You have three ways to trigger voices:

**Grid (Latch Mode):**
- Press button **5 on Row 8** to enable Latch mode
- Press any **Voice button (1–4, Row 8)** to latch/unlatch a voice

**Grid (Manual):**
- Hold any **Voice button (1–4, Row 8)** to gate a voice

**MIDI:**
- Send note-on messages — LTRA responds with voice allocation

**Then raise volume:**
- On the 16n: push faders **5–8** (oscillator volume) and **9–10** (filter cutoff)
- Or use Norns **E1** on the home screen for master volume

### 2. Navigate the Grid

```
 GRID LAYOUT — PAGE 1 (MAIN)
          1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16   ← Destinations
         P1 P2 P3 P4 A1 A2 A3 A4 M1 M2 M3 M4 F1 F2 DT DF   (P=Pitch A=Amp M=Morph F=Filter)
 ┌───────────────────────────────────────────────────────────┐
 │ Row 1 │ █ █ █ █ █ █ █ █ █ █ █ █ █ █ █ █ │   MOD 1 Source  │
 │ Row 2 │ █ █ █ █ █ █ █ █ █ █ █ █ █ █ █ █ │   MOD 2 Source  │
 │ Row 3 │ █ █ █ █ █ █ █ █ █ █ █ █ █ █ █ █ │   MOD 3 Source  │ 
 │ Row 4 │ █ █ █ █ █ █ █ █ █ █ █ █ █ █ █ █ │   OUTLINE Src   │
 │       │  ↑ Modulation Matrix (5 sources × 16 dests) ↑     │
 │ Row 5 │ ● ● ● ● · · · · · · · · ○ ○ ○ ○ │   MIDI | Masks  │
 │ Row 6 │ · · · · · ▓ ▓ ▓ ▓ · · · · · · · │   Mod Dashboard │
 │ Row 7 │ ● ● ● ● · ◇ ◇ ◇ ◇ ◇ ◇ · △ △ △ △ │   ENV|SNAP|GEST │
 │ Row 8 │ ▼ ▼ ▼ ▼ L · · ▣ ▣ ▣ · T P P · S │   Nav Bar       │
 └───────────────────────────────────────────────────────────┘
   Voice 1-4  L=Latch    Loopers  T=Tap  P=Pages  S=Shift
```

**Page Navigation (Row 8):**
- **Button 13** → Page 1: MAIN (matrix + dashboard)
- **Button 14** → Page 2: SCALES

**Nav Bar (Row 8) buttons:**
| Button | Function |
|---|---|
| 1–4 | Voice gates (latch or manual) |
| 5 | Latch mode toggle |
| 8, 9, 10 | Looper 1, 2, 3 |
| 12 | Tap tempo (short press) |
| 13, 14 | Page select |
| 16 | Shift modifier (hold for alternate functions) |

### 3. Add Modulation

On **Page 1**, the top 4 rows are the **modulation matrix**:

| Row | Source |
|---|---|
| 1 | MOD 1 (LFO / Chaos) |
| 2 | MOD 2 (LFO / Chaos) |
| 3 | MOD 3 (LFO / Chaos) |
| 4 | OUTLINE (Envelope Follower + MOD 4) |

| Column | Destination |
|---|---|
| 1–4 | Voice 1–4 Pitch |
| 5–8 | Voice 1–4 Amplitude |
| 9–12 | Voice 1–4 Morph (shape) |
| 13–14 | Filter 1–2 Cutoff |
| 15–16 | Delay Time / Feedback |

**Tap a cell** to cycle through 4 modulation levels: 100% → 66% → 33% → Off. The LED brightness reflects the current level.
**Hold a cell** (~0.3s) to enter the Matrix Edit menu — use E3 to adjust the amount precisely, and K2 to toggle Quantize mode (for pitched modulations).

### 4. Edit Parameters

**Hold any grid button** to enter its context menu. The Norns screen shows available parameters:

| Hold Location | Menu | Parameters |
|---|---|---|
| Row 5, buttons 1–4 | MIDI | Note on/off, velocity sensitivity, MPE settings |
| Row 6, buttons 1–4 | OSC | Tune, shape, octave, volume, drift, spread, glide, twin enable |
| Row 6, buttons 6–8 | MOD | LFO shape, rate/sync, depth, chaos slew/mix |
| Row 6, button 9 | OUTLINE | Source (gate/audio), gain, MOD 4 (LFO + chaos mixed in) |
| Row 6, buttons 11–12 | FILTER | Drive, cutoff, resonance, type (LP/HP) |
| Row 6, button 13 | DELAY | Send, time, feedback, drive, erosion, wow |
| Row 6, button 14 | REVERB | Mix, bloom, decay, predelay, damping, mod |
| Row 6, button 16 | LOOPER | Looper-specific settings |
| Row 7, buttons 1–4 | ENV | Pan, attack, release, velocity/pressure response |
| Row 8, button 12 (hold) | ARP | Gate length, division, chaos, BPM, length, octaves |

**In any menu:** E1/E2/E3 adjust parameters. K2 and K3 toggle options (varies by menu). K3 cycles pages when a menu has multiple pages.

---

## Pages

### Page 1 — MAIN

The primary performance interface. Top half is the modulation matrix, bottom half shows module status:

- **Row 5:** MIDI voice activity (left), snapshot mask toggles (right)
- **Row 6:** Real-time LFO/Outline amplitude visualization
- **Row 7:** ENV/Snapshots/Gesture Loopers (see below)
- **Row 8:** Navigation bar

### Page 2 — SCALES

```
 GRID LAYOUT — PAGE 2 (SCALES)
          1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16
 ┌───────────────────────────────────────────────────────────┐
 │ Row 1 │ ○ ○ ○ ○ ○ ○ ○ ○ ○ ○ ○ ○ ○ ○ ○ ○ │ TET scales 1-16 │
 │ Row 2 │ ○ ○ ○ ○ ○ ○ ○ ○ ○ ○ ○ ○ ○ ○ ○ ○ │ JI scales 17-32 │
 │ Row 3 │ · · · · · · · · · · · · · · · · │ Custom 33-48    │
 │ Row 4 │ · · · █ · █ · · █ · █ · █ · · · │ Black keys      │
 │ Row 5 │ · · █ · █ · █ █ · █ · █ · █ · · │ White keys      │
 │ Row 6 │ · · · · · · · · · · · · · · · · │ Root note (C-B) │ 
 │ Row 7 │ ● ● ● ● · ◇ ◇ ◇ ◇ ◇ ◇ · △ △ △ △ │ ENV|SNAP|GEST   │
 │ Row 8 │ ▼ ▼ ▼ ▼ L · · ▣ ▣ ▣ · T P P · S │ Nav Bar         │
 └───────────────────────────────────────────────────────────┘
   Row 4: █ = black key (C# D# F# G# A#)  |  Row 5: ○ = white key (C D E F G A B)
   Row 6: Root note selector (buttons 3-14 = C to B)
```

- **Rows 1–2:** 32 preset scales — 18 TET scales (Major, Minor, Dorian, Phrygian, Lydian, etc.) + 14 Just Intonation scales (Pythagorean, Partch, Overtone, Maqam Rast, Carlos Harmonic, etc.)
- **Row 3:** 16 custom scale slots — select one, then toggle notes in rows 4–5
- **Rows 4–5:** Piano-style note selector (toggle notes on/off for custom scales)
- **Row 6:** Root note selector (buttons 3–14 = notes C–B)

LTRA supports **Just Intonation** scales alongside standard 12-TET.

---

## Effects

### Tape Echo

A tape-style delay with saturation, wow/flutter, and erosion:

| Parameter | Control |
|---|---|
| Send level | Hold Row 6 button 13 → E1 |
| Delay time | E2 |
| Feedback | E3 |
| Drive | Menu page 2 → E1 |
| Erosion | E2 |
| Wow/Flutter | E3 |

**Modulation:** Matrix destinations 15 (delay time) and 16 (feedback) let any modulation source affect the tape echo.

### Reverb

A rich algorithmic reverb with modulation:

| Parameter | Control |
|---|---|
| Mix | Hold Row 6 button 14 → E1 |
| Bloom | E2 |
| Decay | E3 |
| Predelay / Damping / Mod | Pages 2–3 |

---

## Stereo Loopers

Three independent stereo loopers using Norns' Softcut engine. Each looper has ~110 seconds of recording time.

**Controls (Row 8, buttons 8–10):**

| Action | Result |
|---|---|
| Short press (empty) | Start recording |
| Short press (recording) | Close loop, start playback |
| Short press (playing) | Enter overdub mode |
| Short press (overdubbing) | Return to playback |
| Long press (>0.6s) | Fade out and stop |
| Shift + short press | Clear looper |

**Fade in:** Press a stopped looper — it fades in smoothly.
**Fade time** is configurable per looper via the params menu.

---

## Gesture Loopers

Four gesture loopers record and replay your grid interactions in real-time.

**Controls (Row 7, buttons 13–16):**

| Action | Result |
|---|---|
| Tap (empty) | Start recording gestures |
| Tap (recording) | Stop recording, start playback |
| Tap (playing) | Pause |
| Double-tap (playing) | Start overdubbing (add gestures) |
| Tap (paused) | Resume playback |
| Hold (>1s) or Shift+tap | Clear all gestures |

Recorded gestures play back in a loop, triggering the same grid buttons you pressed. Max 10,000 events per gesture.

---

## Snapshots

Six RAM-based snapshots for instant recall of all parameters.

**Controls (Row 7, buttons 6–11):**

| Action | Result |
|---|---|
| Short press (empty slot) | Save snapshot |
| Short press (filled slot) | Load snapshot |
| Long press (>0.8s, filled slot) | Update snapshot |
| Shift + press | Delete snapshot |

**Snapshot Masks (Row 5, buttons 13–16):** Toggle which parameter groups are protected from snapshot loads:
- Mask 1: Filters
- Mask 2: Shape & Volume
- Mask 3: Space, Tuning, Scale
- Mask 4: Everything else

---

## Arpeggiator

Hold **button 12 on Row 8** (~0.3s) to enter the ARP menu. Each oscillator can have its own arp enabled (OSC menu → K2).

| Parameter | Description |
|---|---|
| Gate length | Note duration (0–1) |
| Division | Clock division (1/1 to 1/32, dotted, triplet) |
| Chaos | Randomness in pattern |
| Length | Euclidean pattern length (bits) |
| Octaves | Octave range (1–4) |

**Tap tempo:** Short press button 12 on Row 8 twice to set BPM.

---

## MIDI / MPE / 16n

### MIDI Input
- Note On/Off with velocity sensitivity
- Channel Pressure → aftertouch mapping
- Pitch Bend with configurable range
- Mod Wheel → assignable per-voice (shape modulation)

### MPE (Multidimensional Polyphonic Expression)
- Per-voice pitch bend, slide (CC74), and press (channel pressure)
- Configurable bend range (default 48 semitones)
- Velocity, Slide, and Pressure each map to Volume and Shape independently

### 16n Faderbank
Auto-detected by name. Default mapping:

| Fader | Parameter |
|---|---|
| 1–4 | Oscillator Pitch |
| 5–8 | Oscillator Volume |
| 9–12 | Oscillator Shape |
| 13–14 | Filter 1–2 Cutoff |
| 15 | Tape Echo Time |
| 16 | Tape Echo Feedback |

**Soft-takeover:** Faders won't jump values — move them toward the current value to "catch" it.

---

## Norns Screen

When no menu is active, the screen shows:

```
 LTRA v3.0.0              P1    L
 E1 Vol: 0.85
 E2 Scl: Minor
 E3 Root: A          ██ ██
```

- **P1/P2** — Current grid page
- **L** — Latch mode active
- **VU meters** — Output level (right side)
- **E1/E2/E3** — Encoder functions for home screen

---

## PSETs (Presets)

LTRA saves sidecar data alongside Norns PSETs:

- **Custom scales** and scale selection
- **Matrix quantize** settings
- **Snapshots** (all 6 slots)
- **Gesture looper** recordings
- **Looper audio** (WAV files of the 3 stereo loopers)

Save/load via the standard Norns PSET menu (`PARAMETERS > PSET`).

---

## Documentation

| File | Content |
|---|---|
| `README.md` | This file — quick start & reference |
| `Manual_quick.MD` | 5-minute getting started guide (Español) |
| `Manual_usuario.MD` | Full user manual (Español) |
| `Manual_avanzado.MD` | Advanced techniques & architecture (Español) |

---

## Credits

LTRA is built for the [Monome Norns](https://monome.org/docs/norns/) ecosystem.

SuperCollider engine with continuous oscillator morphing, DFM1 + custom filters, tape echo, and algorithmic reverb.