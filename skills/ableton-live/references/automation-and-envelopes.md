# Automation and Clip Envelopes

Distilled from the Ableton Live 12 Reference Manual. Keys are macOS (CMD, ALT/OPTION, SHIFT, CTRL).

## Contents

- Chapter 26: Automation
- Chapter 27: Clip Envelopes

## Chapter 26: Automation

### Core concepts
- Nearly every mixer and device control can be automated, including tempo.
- An automated control shows a colored LED (red in most themes). A **blue** LED means *modulated*, not automated.
- **Session View**: automation is clip-based and is edited in the Clip View's Envelope Editor. **Arrangement View**: automation is track-based and is edited in automation lanes.

### Recording
- **Session clips**: enable **Automation Arm** (Control Bar), arm the tracks, click **Session Record**, and move controls. Click Record again to stop recording but keep playing, or Stop to stop everything.
- To write automation into every playing clip, including clips on unarmed tracks, set Settings > Record, Warp & Launch > "Record Session automation in" to **All Tracks**. Use this to overdub automation onto a MIDI clip without recording notes.
- Recording the Session into the Arrangement writes track automation, including existing clip automation. It is the only way to capture tempo moves made from Session View. Copying automated clips into the Arrangement also converts their envelopes to track automation.
- **Arrangement**: with Automation Arm on, automation records on **all** tracks without arming them. Click **Arrangement Record**, move tempo, mixer, or device controls, then click Record again (playback continues) or Stop.

### Overwrite: touch vs. latch
- New moves made while recording replace existing data for that parameter. In a loop, each later pass overwrites the earlier one.
- In Session clips, the **mouse uses touch**: the value snaps back to the recorded data on release. A **MIDI controller uses latch**: the last value holds until the clip or loop ends. The **first** pass into a clip always uses latch.

### Override and Re-Enable
- Moving an automated control while not recording overrides its automation: the LED turns **gray** and the envelope is kept. Use this to audition alternatives safely.
- The Control Bar's **Re-Enable Automation** button lights up while anything is overridden. Click it to restore everything. To restore one parameter, right-click it > Re-Enable Automation. In Session View, relaunching the clip also restores it.
- Gotcha: if automation "stopped working", look for a gray LED or a lit Re-Enable button.

### Viewing automation
- **Session**: open Clip View > Envelope Editor and enable the **Automation** toggle. Choose the parameter with the Device chooser (devices, Mixer, MIDI Ctrl) and the Control chooser. With Clip and Device View stacked, click any control to show its envelope.
- **Arrangement**: press **A** (or click **Automation Mode** above the track headers), then pick the parameter in the lane's choosers. Shortcuts: click a control in Automation Mode, or right-click it > **Show Automation** / **Show Automation in New Lane**, which also turns Automation Mode on.
- A **dashed** line means the parameter is not automated yet and shows its current value.
- "Show Adjusted Envelopes Only" (Session) / "Show Automated Parameters Only" (Arrangement) limits the choosers to automated controls. While it is on, clicking an unautomated control does not open its envelope.

### Multiple lanes (Arrangement)
- **Add Automation Lane** (+) moves the current envelope to its own lane and frees the main lane for another parameter.
- OPTION-click + adds a duplicate of the main lane's envelope (maximum two).
- CMD-click +, or right-click > **Add Lane for Each Automated Envelope**, shows every automated parameter.
- **Remove Automation Lane** (-) removes a lane. Select several headers with CMD-click or SHIFT-click, then remove them together. CMD-click - removes that lane and all lanes below it.
- A main-lane toggle shows or hides extra lanes. Drag to reorder. Up/Down arrows move between lanes. Left/Right in the main lane hides or shows the extras.

### Creating envelopes
- **Breakpoints**: click the dashed line to start the envelope. Drag before releasing to set the value; SHIFT gives fine control. Double-click off the line to add a point there. For an exact value, right-click > **Add Value**.
- Points snap to the grid. Hold **CMD** to bypass snapping.
- **Draw Mode**: press **B** (hold B to enable it temporarily) or use the Control Bar toggle. Drag to draw freehand. Each step is one grid unit wide, so change the grid size to change the step resolution. For smooth curves, turn off snapping with **CMD-4** or hold CMD while drawing.
- **Automation shapes**: right-click the lane or Envelope Editor and choose a shape. It fills the time selection, or one grid unit if nothing is selected, and is scaled to the full parameter range.
  - Top row: sine, triangle, saw, inverse saw, square. These insert as-is.
  - Bottom row: ramps and ADSR. Ramps connect to the values on either side of the selection, so the result depends on the surrounding automation.
  - Use shapes for rhythmic gating and filter patterns, and long ramps for builds and swells.
- Discrete parameters (toggles, radio buttons) produce stepped envelopes and accept only the square shape.

### Editing envelopes
- **Points**: drag to move (CMD bypasses snapping; SHIFT locks horizontal moves or gives fine vertical values). Click a point to delete it. Drag in the background to multi-select, then drag or right-click > **Delete**.
- **Move a segment**: drag near (not on) the line, or SHIFT-click the line, then release SHIFT and drag. Within a time selection, points are added at the selection edges. Dropping onto existing points overwrites them.
- **Curves**: OPTION-drag a diagonal segment to bend it. OPTION-double-click makes it straight again. Flat segments cannot be curved.
- **Exact value**: right-click > **Edit Value** and type it. Other selected points shift by the same relative amount.
- **Stretch/skew**: hover over a time selection to show handles. Top and bottom handles scale values (SHIFT for fine control), side handles stretch in time, and corners skew. OPTION mirrors the movement on the opposite handle. Gotcha: dragging over points outside the selection deletes them.
- **Simplify Envelope**: select a range, then right-click > Simplify Envelope. It removes redundant points and replaces them with lines or curves. Use it on dense recorded moves.
- **Edit menu**: Cut, Copy, Duplicate, and Delete on a lane time selection affect only the envelope, not the clip, and can span several lanes. Pasting onto a different parameter can give creative results.

### Deleting automation
- Right-click the parameter > **Delete Automation**, or select it and press **CMD-Delete**. The parameter returns to its **default** value, not its last value.
- Context menus offer **Clear Envelope** (one parameter), **Clear All Envelopes of...** (one device, lane headers only), and **Clear All Envelopes**, which clears the **whole Set**. Use the last one with care.

### Tempo automation
- Arrangement View > Automation Mode > **Main** track > Device **Mixer** > **Song Tempo**. Tempo changes made during Arrangement recording are captured.
- The **Tempo Minimum/Maximum** sliders set the BPM range shown in the lane. They also set the range of any MIDI controller mapped to tempo, so narrow them for finer hardware control.

### Lock Envelopes
- Arrangement automation moves with clips by default. Enable the **Lock Envelopes** toggle or Options > Lock Envelopes to keep automation fixed to the timeline while you rearrange clips.

## Chapter 27: Clip Envelopes

Clip envelopes live inside a clip and travel with it. They hold MIDI CC data, modulate sample controls (gain, transpose, sample offset), and automate or modulate device and mixer parameters. Use them for per-clip variation, loop sound design, and synced LFO-style movement.

### Envelope Editor

- Open the Clip View **Envelopes** tab. Two choosers sit there:
  - **Device chooser**. Audio clips list "Clip", the track's effects, and "Mixer". MIDI clips list "MIDI Ctrl", the track's devices, and "Mixer".
  - **Control chooser**, which picks the parameter. An LED marks an edited envelope. "Only show adjusted envelopes" hides the rest.
- **Session clips** get **Automation / Modulation** toggles. **Arrangement clips** take modulation only; draw their automation on the track's automation lane.
- Drawing works as for automation: Draw Mode (B) draws grid steps, and with it off you edit breakpoints.
- **Shift** while drawing or moving breakpoints gives finer values. **CMD+OPTION+drag** scrolls.
- **Clear Envelope**: right-click in the editor, or press CMD+Delete.
- **MIDI Envelope Auto-Reset** (Options menu or context menu) resets certain CCs when a new clip starts, so values don't carry over.
- Markers, loop braces and drawing snap to the zoom-adaptive grid. Hide the grid to place them freely.

### Automation vs Modulation

- **Automation** (red; moves the knob needle) sets an **absolute** value.
- **Modulation** (blue; ring segment) only changes the current value **relative** to it, so it can never set a value like a preset does.
- Both can act on one parameter, and automation sets the ceiling. A 4-bar automated fade plus a rising modulation gives a crescendo until the two lines meet; then the fade wins.
- Control chooser LEDs show red for automation and blue for modulation. Both can show at once.

### Audio Clip Envelopes ("Clip")

- They are non-destructive and computed live, so many clips can share one sample. To print the result, render, resample, or use **Consolidate** in the Arrangement.
- **Transposition** (Warp must be on): per-note re-pitching.
  - Additive to the Transpose knob, clipped at ±48 st.
  - Draw steps, then nudge breakpoints sideways to get glides.
  - For tighter tracking, lower **Grain Size** (Tones/Texture) or **Granulation Resolution** (Beats).
- **Gain**: a percentage of the Clip Gain slider. It can duck or mute hits but never boost.
- **Sample Offset** (Beats mode only; for drum loops):
  - It jumps the playhead: positive values move ahead, negative values move back. One grid line equals 1/16, and the range is ±8 sixteenths.
  - A descending "escalator" repeats the first step. A downward ramp slows time; just off 45 degrees with 1/32 Granulation, it slurs.
  - Use it for quick variations. For precise slicing, edit in the Arrangement instead.
- **Clips as templates**: drag a new sample onto the Clip View. All settings and envelopes stay; only the audio changes.

### Mixer and Device Envelopes

- **Clip Gain** acts before the effects. **Track Volume** modulation acts after them, and a dot under the fader shows the real level.
- **Sends**: relative. Modulation can pull a send to −inf dB but never above the knob.
- **Pan**: the knob sets the depth. Centred, the envelope sweeps hard L to hard R; the range shrinks off-centre, and at hard L/R it has no effect.
- **Device parameters**: same relative behaviour against the current or automated value.

### MIDI Controller Envelopes

- Select **MIDI Ctrl**, then a CC (most up to 119; scroll the menu). Draw steps or breakpoints.
- Recorded or imported CC data appears here as editable envelopes, marked with LEDs.
- Gotcha: the target synth may not follow standard CC assignments, so "Pan" or "Pitch Bend" may do something else.

### Unlinked Envelopes and Polyrhythms

- **Unlink** an envelope to give it its own start, loop and region, separate from the clip. Its braces change colour and its Loop switch works on its own.
- **8-bar fade over a 1-bar loop**:
  1. Unlink Clip Gain or Track Volume, then turn the envelope's Loop off.
  2. Set the loop length to 8, and zoom out by dragging up on the time ruler.
  3. Add a breakpoint at the region end and drag it to the bottom.
- **Long loops from short ones**: turn the envelope's Loop on, and the 8-bar shape repeats over the 1-bar audio. Try it on other parameters too, for example a filter sweep every 4 bars.
- **Odd lengths** (such as 3.2.1) give phasing, polyrhythmic movement. Each envelope's **start marker** is the shared reference for launch, so check it when several odd-length envelopes start to confuse.
- **Rhythm gating**: put a 1-bar looped volume envelope on a full song to cut holes in it, for example to drop every third beat.
- **Envelopes as LFOs**: a looped, unlinked envelope is a tempo-synced LFO. Hide the grid for odd, unsynced periods. Shape the waveform with the Stretch/Skew handles and the automation shapes.

### Linked Envelopes and Warping

- **Linked** envelopes follow Warp Markers: moving a marker stretches the envelope with it. You can also edit Warp Markers from the envelope editor.
