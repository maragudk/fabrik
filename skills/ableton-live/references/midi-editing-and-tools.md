# MIDI Editing, MIDI Tools, MPE, Audio to MIDI, Grooves and Tuning

Distilled from the Ableton Live 12 Reference Manual. Keys are macOS (CMD, ALT/OPTION, SHIFT, CTRL).

## Contents

- Chapter 10: Editing MIDI
- Chapter 11: MIDI Tools
- Chapters 12-15: Editing MPE, Converting Audio to MIDI, Using Grooves, Using Tuning Systems

## Chapter 10: Editing MIDI


### Layout and navigation
- Open: double-click a clip, or press CMD+OPTION+3, then select the **Notes** tab. CMD+OPTION+E maximizes Clip View.
- **Preview** switch (above the piano ruler): you hear notes as you click, add, or move them. On an armed track, it also enables step recording. The switch is global.
- Lanes below the editor: **Velocity**, **Release Velocity**, and **Chance** (hidden by default). Toggle them with the triangular **Lane Selector**.
- Zoom:
  - Drag vertically in the time ruler, or CMD+scroll.
  - Drag horizontally in the note ruler, or OPTION+scroll, to change key-track height.
  - Double-click a ruler to zoom to the selection or to all notes.
  - **Z** zooms to the selection, **X** shows the whole clip, and +/- zooms in steps. Page Up/Down moves one octave (SHIFT: one row).
- Options > **Chase MIDI Notes**: notes sound even when playback starts mid-note.

### Grid snapping
- When you drag a note, it moves freely up to the first grid line, then snaps. Notes keep their original offset from the grid, so the groove survives a move.
- **CMD+4** toggles snap. Hold **CMD** while you edit to bypass snap, or to enable it when it is off.

### Creating and drawing
- **CMD+SHIFT+M** inserts an empty MIDI clip (selected Session slot or Arrangement range). You can also double-click an empty slot.
- To add notes, double-click the grid, or use **Draw Mode (B)**. In Draw Mode, a click on a note deletes it. With Draw Mode off, double-click a note to delete it.
- The Display & Input setting "Draw Mode with Pitch Lock" makes drawing stay on one row. Hold **OPTION** to switch temporarily between pitch-locked and freehand drawing.
- A new note over another note's start replaces that note. A new note over its end shortens it.

### Selecting
- Drag to select a time range and the notes inside it. **Enter** toggles between time and notes. **Esc** deselects.
- SHIFT+arrows extends the time selection (add CMD: off-grid; OPTION+SHIFT: to note boundaries).
- OPTION+up/down steps through notes. OPTION+left/right moves along the same row. OPTION+SHIFT+up/down adds to the selection.
- SHIFT-click a note to add or remove it. SHIFT-click a piano key to select the whole row.
- CMD+A selects all. **CMD+SHIFT+A** inverts the selection.

### Find and Select Notes
- Turn on the toggle in the Clip View header, then choose filters. Filters select notes live and can be combined. Each filter has **Invert** and **Select** (re-apply).
- Filters:
  - **Pitch:** in all octaves.
  - **Time:** Start/Length/Repeat in beats.
  - **Chance** and **Velocity:** a min-max range.
  - **Duration:** a length range.
  - **Condition:** Active, Chance below 100%, or has Velocity Deviation.
  - **Count:** every nth note or chord, with an Offset. Quantized counts per grid step.
  - **Scale:** the clip scale, or any other scale.

### Moving, length, stretch
- Arrow keys nudge or transpose. SHIFT+up/down transposes by an octave. CMD+left/right nudges off-grid.
- OPTION-drag copies. You can press OPTION after the drag has started.
- To change length, drag a note's edge, or press SHIFT+left/right (add CMD to ignore the grid). **CMD+OPTION+J** (Fit to Time Range) fills the selection.
- **Note Stretch markers** appear under the scrub area for a multi-note or time selection. Drag them to scale timing proportionally. A "pseudo" marker between them warps the inside material. Linked clip envelopes follow.
- **0** deactivates (mutes) the selected notes.

### Split, Chop, Join
- **Split:** hold **E** and draw across notes (add CMD to snap). With no selection, **CMD+E** splits at the insert marker or time selection.
- **Chop:** select notes and press **CMD+E** to chop at the grid. Keep holding CMD and press up/down to change the number of parts (SHIFT: powers of 2). With the mouse: E+OPTION, then drag on a note.
- **Join:** **CMD+J** merges the selected notes of one pitch and keeps their MPE data.

### Pitch and Time Utilities panel
- These act on the selection. With nothing selected, they act on the whole clip.
- **Transpose:** semitones, or scale degrees when Scale Mode is on.
- **Fit to Scale:** snaps each note to the nearest scale degree; a tie goes down. Needs an active clip scale.
- **Invert:** flips the pitches upside down (scale-aware). Not the same as Invert Selection.
- **Interval Size + Add Interval:** stacks a note at that interval. With notes selected, the slider adds notes immediately.
- **Stretch factor, x2, /2:** scale note lengths. x2 and /2 also scale the time selection or loop.
- **Duration + Set Length:** gives all notes one length (fixed, grid, or fit to range).
- **Humanize:** randomizes start times by up to ±1/4 grid division, scaled by Amount.
- **Reverse:** mirrors the selection in time.
- **Legato:** each note reaches the next; the last note reaches the loop end.

### Quantize
- **CMD+U** quantizes with the Quantize MIDI Tool's settings. **CMD+SHIFT+U** opens those settings.
- In the tool (Transform panel), set the grid value, start and/or end quantize, and **Amount**. A partial Amount tightens timing without a robotic feel.

### Velocity
- Drag a marker in the Velocity lane, or **CMD-drag** a selected note vertically.
- Select markers and type a value + Enter. CMD+up/down: ±10 (add SHIFT for fine steps).
- Draw Mode in the Velocity lane sets the selected notes, or all notes in each grid cell. Hold CMD, or turn off snap, to draw each note separately. **OPTION-drag** draws a straight ramp (crescendo); add SHIFT for a flat line. To ramp one drum, SHIFT-click its piano key first.
- Velocity Controls (appear with the Velocity lane):
  - **Randomize ± Amount:** random velocity changes.
  - **Ramp Start/End:** an even ramp across the selection.
  - **Velocity Deviation:** a per-note random range, applied each time the note plays. For example, 60 with +20 plays at 60-80; a negative value goes softer. CMD-drag from a marker to set it. Double-click the marker to reset.
- **Release Velocity:** Note Off velocity. Only some devices respond, for example Sampler.

### Probability (Chance lane)
- Values are 0-100%. Type a value, or use up/down for ±10% (SHIFT: fine). A corner triangle marks notes below 100%; it shows only on tall rows.
- Randomize Amount gives ± a range around each note's value. For example, 50% ±25% gives 25-75%. With notes selected, it applies instantly; otherwise, press Enter or Randomize.
- **Probability groups** share one probability:
  - **Play All:** the group fires together, for example a chord that plays or drops out as one.
  - **Play One:** one random note of the group plays, for example alternating hats or variation fills.
  - To create a group, use the toolbar buttons, the context menu, or **CMD+G** (repeats the last group type).
  - To ungroup, use **CMD+SHIFT+G**. Right-click the marker to change the group type. A diamond handle means Play All; a triangle means Play One.

### Folding and scales
- **Fold (F):** hides empty rows. Essential for drums. On a Drum Rack, unfolded rows show pads that have devices.
- **Scale Mode:** turn it on in Main Clip Properties or the Control Bar, then choose a root and a scale. Transpose, Invert, Intervals, and Fit to Scale then work in scale degrees.
- **Highlight Scale (K):** shades the in-scale rows and marks the root. This setting is global.
- **Fold to Scale (G):** shows only in-scale rows. Rows that already hold out-of-scale notes stay visible.
- New clips inherit the last selected clip's scale, but inactive if Scale Mode was off.

### Clip-level edits
- **CMD+SHIFT+J** (Crop Clip) deletes notes outside the loop or time selection. It creates no new file.
- **Duplicate/Delete/Insert Time** shift the notes inside the clip. They leave the clip start/end and the loop brace unchanged.
- Select the loop brace and press **CMD+D** to double the loop and its notes. Later notes shift to keep their position.

### Multi-clip editing
- Select up to **8** clips to edit together:
  - **Session View:** all clips must be looped. The editor shows enough cycles for the clips to realign.
  - **Arrangement View:** up to 8 tracks across a time range. You can draw across clip boundaries (not in Focus Mode).
- Each clip has a colored loop bar. Click a note or a bar to make that clip active. CMD-click or SHIFT-click bars to multi-select them. CMD+D duplicates bars.
- Loop, time signature, groove, scale, and fold settings apply to all selected clips. **Velocity and Chance edits apply only to the foreground clip.**
- **Focus Mode (N, or hold N for a temporary switch):** only the active clip can be edited, and other clips are gray. With Focus Mode off, you can edit all clips, and cut, copy, or paste across clips and loop boundaries.

## Chapter 11: MIDI Tools

### Overview
- MIDI Tools are scale-aware note utilities in the Clip View's **Transform** and **Generate** tabs/panels.
- **Transformations** edit the notes you select. **MPE Transformations** (Glissando, LFO) write per-note expression, which shows only in the MPE view.
- **Generators** create new notes in the time selection, or in the clip loop when there is none.
- **Native** tools cannot be edited. **Max for Live** tools (`.amxd`) can be opened in Max, and you can build your own or install third-party ones.

### Applying
- Pick a tool from the selector and adjust it. **Auto Apply** (on by default) rewrites the notes live.
- Switch Auto Apply off to set up without changes, then press **Apply**. Switching it off **reverts the notes to their original state**.
- **CMD+Enter** applies the current tool without leaving the note editor.
- **Scope:**
  - Transformations act on the time selection, else the note selection, else the clip loop, and replace the originals.
  - Generator output sits beside non-overlapping notes and **replaces overlapping ones**.
- **Scale:** with a clip scale on, pitch parameters work in scale degrees and range sliders turn purple.
- **Undo** (CMD+Z) reverts note changes but not parameter changes. **Reset** returns parameters to defaults and leaves notes alone.
- **ALT+click the piano ruler** picks a pitch, drum pad, or chord root (Rhythm, Seed, Shape, Stacks). ALT+drag picks a range.

### Max for Live tools and editions
- **Velocity Shaper** and **Euclidean** come with Standard and Suite only, not Intro.
- Editing or building tools needs Suite, or Standard with the Max for Live add-on.
- Custom tools go in `~/Music/Ableton/User Library/MIDI Tools/Max Transformations` or `.../Max Generators`, or in any browser **Places** folder.
- Find them with the browser's **MIDI Tools** filter group or the **MIDI Tool** Content tag.

### Transformations
- **Arpeggiate:** prints an arpeggio as editable notes, using the Arpeggiator's 18 **Styles**.
  - **Distance** is the transposition per step and **Steps** the number of transposed repeats.
  - **Rate** sets the speed, which also sets note length. **Gate** <100% shortens notes, >100% lengthens them.
- **Chop:** splits notes into 2–64 **Parts**, for rolls, stutters, and gated rhythms.
  - **Gaps**: +N puts a gap after every N notes, −N puts N gaps after each note.
  - The pattern holds at most 16 elements and repeats beyond that.
  - **Pattern** toggles edit gaps by hand, and moving Gaps overwrites those edits.
  - **Emphasis** plus **Stretch Chunk(s)** make chosen elements 2–8x longer. **Variation** randomizes start and end times.
- **Connect:** fills gaps between notes with random passing notes.
  - **Spread** is the maximum pitch deviation. **Density** is the % of each gap filled.
  - **Rate** sets the new notes' length. **Tie** is the probability of extending to the next original note.
- **Glissando (MPE):** bends pitch into the next note. Select **at least 2 notes**.
  - **Start** (% of the note) and **Curve** shape the bend. Drag the yellow point or the line.
  - **Gotcha:** the curve is invisible in the normal note editor. Use the MPE view or the Pitch Bend expression lane, and an MPE-capable synth.
- **LFO (MPE):** modulates **Pitch Bend**, **Slide**, or **Pressure** per note, for vibrato, wobble, or evolving timbre.
  - Shapes are Sine, Square, Triangle, or Random (**Reseed** draws a new random shape).
  - **Rate** runs 1–1/128 (1 = 4 beats). **Time Shift** delays the start (+) or shifts the phase (−).
  - **Attack/Decay** depend on each other. **Amount** reaches ±2x the pitch-bend range (±127 for Slide/Pressure). **Amplitude Base** sets the center.
- **Ornament:** adds **Flam** (one note) or **Grace Notes** (N equal notes) before each note. Applying it again adds more.
  - **Position**: + overlaps the original's start, − puts ornaments before it. The value is a % of the **grid** (100% = one division), not of the note length.
  - **Velocity** is relative to the original note.
  - Grace **Pitch** is Same, High, or Low (every other note ±1 step). Grace **Chance** scales each note's probability. **Amount** sets the count.
- **Quantize:** snaps note starts, ends (stretching the note), or both to the grid or a set meter value, triplets included.
  - **Amount** <100% tightens timing without the robotic feel.
  - **CMD+SHIFT+U** quantizes the selection with the current settings. **Edit > Quantize Settings…** opens the tool.
- **Recombine:** permutes one **Dimension** (Position, Pitch, Duration, Velocity) across the selected notes.
  - **Shuffle** is random and new on every Apply. **Mirror** reverses. **Rotate** shifts by up to notes−1 steps (+ is clockwise).
  - They run in the order Shuffle, Mirror, Rotate. **Rotate on Grid** (Position only) steps by grid cells.
  - Example: Pitch + Rotate reorders a melody and keeps its rhythm.
- **Span:** sets articulation.
  - **Legato** extends to the next note, and the last note to the selection or loop end. **Tenuto** keeps lengths. **Staccato** uses half the smallest start-to-start gap.
  - **Offset** moves ends by ±1 grid step. **Variation** randomizes lengths (+ shorter) and changes on every apply.
- **Strum:** staggers chord note starts.
  - **Strum Low** offsets from the lowest note and **Strum High** from the highest, up to ±1 grid step each. At least one must be non-zero.
  - **Tension** curves the spacing: + starts wide, − starts tight.
- **Time Warp:** stretches time along a speed curve (1–3 breakpoints) over the selection, for accelerando or ritardando.
  - **Quantize** snaps the output. **Preserve Time Range** keeps it within the original span. **Include Note End** also warps durations.
- **Velocity Shaper (M4L):** draws a velocity envelope (click to add points).
  - **Min/Max Velocity** set the range. **Loop** repeats the shape.
  - **Rotate** shifts it by steps of size **Division** (e.g. Grid). Good for crescendos and hi-hat dynamics.

### Generators
- **Rhythm:** a one-pitch step pattern repeated over the selection. It is the fastest way to program drums.
  - **Steps** (up to 16), **Density** (number of hits), **Pattern** (where the hits fall).
  - **Step Duration** sets how often the pattern repeats (1 bar, 8 steps: 1/8 = once, 1/16 = twice) and caps Steps.
  - **Split** is the chance a step halves. **Shift** rotates the pattern.
  - **Velocity**, **Accent**, **Accent Frequency** (1 = every note), and **Accent Offset** shape the dynamics.
  - **Layer kits:** deselect the generated notes, pick another pad, and generate again.
- **Seed:** random notes within **Pitch**, **Duration** (1/128–1 bar), and **Velocity** ranges.
  - Merging the slider handles locks a single value. Click the slider to split them again.
  - **Voices** sets the maximum polyphony. **Density** is the % of the pitch range filled.
  - Use it for ideas, then curate with Transformations.
- **Shape:** a melody that follows a contour from **Shape Presets** or one you draw, within **Min/Max Pitch**.
  - **Rate** is the minimum note length. **Tie** is the chance of extending a note to the next. **Density** is the % of the shape filled.
  - **Jitter** randomizes pitch within the range.
- **Stacks:** chords and progressions that fill the selection or loop.
  - Pick chords on the **Chord Selector Pad** (Tonnetz diagrams) or with **CMD+Up/Down**. Hovering shows the chord name in the Status Bar.
  - **+/−** add or remove chords. Displayed parameters apply to the **selected chord only**.
  - **Chord Root**: knob, ALT+click the ruler, or arrow keys. With a clip scale on, it defaults to the scale root and only allows notes in the scale.
  - **Inversion**: − gives the same inversions an octave lower. **Duration** and **Offset** work in eighths of the chord slot.
  - **Custom banks** are JSON `.stacks` files. Put one in a Places folder and double-click it in the browser to load it. Find them with the **Stacks** tag.
- **Euclidean (M4L):** Euclidean rhythms for up to 4 voices, for polyrhythmic percussion.
  - The **Pattern** tab has per-voice toggles and **Rotation** sliders (the center button randomizes them).
  - The **Voices** tab sets the pitch or pad and the **Velocity** per voice.
  - **Steps** is the length (it repeats or wraps), **Density** the repeats, and **Division** the step size.

## Chapters 12-15: Editing MPE, Converting Audio to MIDI, Using Grooves, Using Tuning Systems

### 12. Editing MPE

**Purpose:** MPE gives each note its own pitch bend, slide (Y-axis), and pressure. Any MIDI clip can hold it, even one not recorded from an MPE controller.

**Setup and viewing**
- Turn on MPE Mode for the controller in Settings > Link, Tempo & MIDI. The track's input channel then locks to "All Channels".
- In Clip View, open the Note Expression tab (OPT+3). Pitch draws over the notes. Slide, Pressure, Velocity, and Release Velocity get their own lanes, and only Slide and Pressure show by default.
- Use the lane toggles on the left. The triangle button shows or hides all lanes (OPT+click shows every lane).

**Editing** (click a note first; its envelopes then become editable)
- Click a segment to add a breakpoint. Click a breakpoint to delete it. Drag in the background to select, and drag any selected point to move the whole selection.
- Right-click > Edit Value or Add Value sets exact values.
- To grab a segment, click near it or SHIFT+click it. SHIFT+drag locks the axis and gives finer vertical resolution.
- OPT+drag curves a segment. OPT+double-click straightens it.
- To scale a whole envelope proportionally (all lanes except Pitch), click outside the note, hover until the envelope turns blue, then drag. To offset instead, press CMD+A, then drag.
- With the grid off, CMD snaps Pitch to semitones. This tab has its own grid: off by default, saved with the clip, toggled with CMD+4.
- Envelopes follow note moves and stretches (stretch markers, ÷2/x2).
- Right-click > Clear All Envelopes wipes expression.
- Press B (or hold it) for Draw Mode to draw freehand in Pitch, Slide, and Pressure. With the grid on, drawing makes grid-wide steps.

**Plug-ins and hardware**
- A plug-in's MPE Mode is saved with its default configuration. Plug-ins with MIDI outputs can send MPE.
- Open the MPE/Multi-channel Settings dialog in one of three ways:
  - Ext. Instrument: set MIDI To, choose "MPE", reopen the menu > MPE Settings….
  - Track I/O: the same steps in MIDI To.
  - A plug-in's title-bar context menu.
- Choose the lower zone (global channel 1) or upper zone (global channel 16). More note channels means more polyphony. Multi-channel mode allows any channel range, which helps multi-timbral plug-ins that lack MPE.
- **Gotcha:** zones apply only to MPE output, and each track outputs to one zone. To use both zones, give each its own track on the same output.

### 13. Converting Audio to MIDI

All four commands are in the Create menu or an audio clip's right-click menu. The manual does not mention editions; from general knowledge, Live Intro has no audio-to-MIDI conversion.

**Slice to New MIDI Track**
- Splits audio by time, without analyzing pitch. It creates a Drum Rack with one Simpler chain per slice and a chromatic "staircase" clip that triggers them.
- The dialog sets the division (beat resolution, transients, or Warp Markers) and a Slicing Preset. Save your own presets in User Library > Defaults.
- "Preserve warped timing": on keeps your warp edits; off slices the raw audio.
- **Limit:** 128 slices maximum. Use a coarser division or slice a smaller region.
- The preset maps Macros across all the Simplers (envelope, loop, crossfade).
- To resequence, edit the notes or swap Drum Rack pads by dragging.
- To share effects across slices, select the chains, press CMD+G, and place effects after the nested Rack. Try Arpeggiator or Random before the Drum Rack.

**Convert commands** (these extract notes to play a new sound)
- **Harmony:** polyphonic sources such as piano or guitar. Loads a piano Rack.
- **Melody:** monophonic sources such as voice, whistling, or a solo instrument. Loads a synth Rack with a "Synth to Piano" Macro.
- **Drums:** unpitched percussion such as breaks, beatboxing, or tapping. Detects kick, snare, and hi-hat and maps them to a Drum Rack.

**Quality tips**
- Use sources with clear attacks, since swells get missed.
- Use isolated sources and WAV or AIFF files. Low-bitrate MP3 gives unpredictable results.
- **Key workflow:** notes split at the clip's transient markers. Edit the transients *before* converting.

### 14. Using Grooves

**Purpose:** non-destructive swing, feel, and humanization. Grooves work on MIDI clips, and on audio clips only when Warp is on. Groove files use the .agr format.

**Applying**
- Drag a groove from the browser onto a clip.
- To audition grooves, enable Hot-Swap above the Clip Groove chooser and step through the browser while the clip plays.
- Open the Groove Pool with CMD+OPT+6. Double-click a groove in the browser to load it without assigning it.

**Groove Pool parameters** (all real-time, shared by every clip using that groove)
- **Base:** the grid the groove is measured against. Notes move toward the groove's offsets from it. Groove notes on the grid move nothing.
- **Quantize:** straight quantize applied before the groove (0-100%).
- **Timing:** how strongly the groove's timing applies.
- **Random:** random timing per voice, so notes that were together drift apart. Use low values for subtle humanizing.
- **Velocity:** ranges -100 to +100. Negative values invert accents.
- **Global Amount:** scales Timing, Random, and Velocity for all grooves, up to 130%. It also appears in the Control Bar once grooves are in use.

**Commit, edit, extract**
- **Commit** (above the Clip Groove chooser) bakes the groove in: MIDI notes move, audio gets Warp Markers. The chooser then resets to None.
- To edit a groove, drag it onto a MIDI track. It becomes an editable clip you can turn back into a groove.
- To extract a groove, drag a clip into the Groove Pool or right-click > Extract Groove. Only the playing region is used, and timing plus volume are captured.

**Tips**
- **Groove one voice** (such as a laid-back snare): extract that Drum Rack chain to its own track, then give it its own groove.
- **Non-destructive quantize:** set Timing, Random, and Velocity to 0% and use only Quantize and Base.
- **Thicken:** duplicate the track and add a groove with Random up on one copy, so the two drift apart. Works well for strings.

### 15. Using Tuning Systems (new in Live 12)

**Purpose:** microtonal and non-12TET tunings, including pseudo-octaves. Live 12 loads Scala .scl files and Ableton's extended .ascl files. Core Library tunings sit under the browser's Tunings label.

**Compatibility**
- All built-in instruments work.
- MPE-enabled plug-ins and Max for Live instruments work **only with pitch bend range set to 48 semitones**. Other instruments will likely play out of tune.
- Drum Rack tracks bypass tuning automatically.

**Loading**
- Double-click a tuning or press Enter on it. This opens the hidden Tuning section.
- You can also drag a .scl or .ascl file into the Tuning section. A loaded tuning is saved with the Set.
- Your own tuning files in any Places folder appear under Tunings > User.
- Select the tuning and press Delete to return to 12TET.
- The piano roll then shows tuning notes. Hover a note to see its pitch and frequency in the Status Bar.

**Gotchas**
- Changing or removing a tuning keeps note positions, so pitches change. Options > "Retune Set On Loading Tuning Systems" remaps notes to the nearest pitch instead. This can shorten or delete overlapping notes that collide on the same pitch.
- With a tuning loaded, the Scale Mode choosers disappear and "Use Current Scale" is disabled in devices.

**Tuning section controls** (expand with the triangle)
- Octave and Note pick the reference note. They change only the displayed frequency; nothing sounds different until you change Ref. Pitch/Freq.
- Ref. Pitch/Freq transposes the whole Set.
- Lowest Note and Highest Note set the range. They are linked, so the note count stays the same.
- The floppy disk button saves the tuning as .ascl.

**Per-MIDI-track I/O options** (shown only when a tuning is loaded)
- **Bypass Tuning:** the track ignores the tuning and its piano roll shows 12TET.
- **MIDI Controller Layout:** maps keyboard keys to tuning notes:
  - All Keys
  - Black Keys Only, centered on C#3
  - White Keys Only, centered on C3
  - Closest in Pitch to Keyboard
  - Custom: click "…" to open Configure MIDI Layout. The layout is saved with the Set.
