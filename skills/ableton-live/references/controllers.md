# MIDI/Key Remote Control, Push 1 and Push 2

Distilled from the Ableton Live 12 Reference Manual. Keys are macOS (CMD, ALT/OPTION, SHIFT, CTRL).

## Contents

- Chapter 34: MIDI and Key Remote Control
- Chapter 35: Using Push 1
- Chapter 36: Using Push 2

## Chapter 34: MIDI and Key Remote Control

### What can be mapped
- Mappable controls: Session slots, switches (Track/Device Activators, tap tempo, metronome, transport), radio buttons (e.g. crossfader A/off/B assign), continuous controls (volume, pan, sends) and the crossfader.
- A slot mapping belongs to the **slot**, not to its clip, so it survives clip changes.

### Gotchas
- A MIDI key mapped to a control stops playing notes into MIDI tracks. If notes go missing, watch the Control Bar's MIDI indicators, which flash on incoming messages.
- Key remote control (KEY mode) is not the computer MIDI keyboard, which turns keystrokes into notes.

### Setup: Settings > Link, Tempo & MIDI (CMD+,)
- **Native surfaces:** Pick the device in a Control Surface chooser and set its Input/Output ports. Up to **six** at once. If **Dump** is enabled, prepare the hardware to receive a preset dump (see its docs), then press Dump.
- **Instant mappings:** Native surfaces auto-map to the selected device. They don't appear in the Mapping Browser. To override them with your own mappings, turn on **Remote** for the surface's ports.
- **Lock to device:** Right-click a device title bar and choose **Lock to…** > surface to keep control wherever focus goes (hand icon shown). Arming a MIDI track locks its instrument by default. Some surfaces can't lock.
- **Unsupported controllers:** In the MIDI Ports table, set **Remote = On** for the input port. Live merges input from any number of ports. Enable Remote on the **output** port too for motorized faders or LED feedback.
- **Takeover Mode** (same tab) handles absolute faders in bank-switching setups:
  - **None:** The value jumps at once.
  - **Pick-Up:** No effect until the control reaches the parameter value, then it tracks 1:1. The pickup point is hard to predict.
  - **Value Scaling:** Converges smoothly, then tracks 1:1. Usually the best choice.

### MIDI Map Mode (blue) and Key Map Mode (red)
- Click the **MIDI** or **KEY** switch at the top right. Mappable controls highlight. Show the browser (CMD+ALT+B) to see the Mapping Browser.
- Click a parameter, then move a knob, hit a note, or press a computer key. Click the switch again to exit.
- In Key mode, keys launch slots according to Launch Mode, toggle switches, and cycle radio buttons.

### Mapping Browser
- Lists every manual MIDI, Key or Macro mapping for the active mode: control, parameter path, name, Min/Max.
- Edit **Min/Max** to limit range. Use the context menu to **invert** it. Press **Delete** to remove a mapping.

### How MIDI message types behave
- **Notes:** Slots follow Launch Mode. Switches toggle and radio buttons cycle. One note on a continuous parameter toggles Min/Max. A **note range** gives evenly spaced discrete values.
  - **Chromatic clip playing:** Click the slot, press the root key (untransposed), and, still holding it, press one key below and one above to set the range.
- **Absolute CC (0-127):**
  - Slots: 64 and above = Note On, 63 and below = Note Off.
  - Track/device on-off switches: inside Min..Max = on. Set Min > Max to invert. Other switches (e.g. transport): 64 and above = on.
  - Radio buttons/continuous controls: the full range spreads across options or values.
  - Pitch bend and **14-bit Absolute** (0-16383) work the same, centered at 8191/8192.
- **Relative CC (encoders):** No jumps when hardware and Live disagree. Types: Signed Bit, Signed Bit 2, Bin Offset, Twos Complement, each also "linear". Some encoders accelerate.
  - Live auto-detects type and acceleration. **Turn the encoder slowly left** while mapping to help. Override in the Status Bar's **mode** chooser.
  - Increment = on/next/Note On. Decrement = off/previous/Note Off.

### Relative Session navigation
- In either map mode, a strip below the Session grid offers: scene up/down, a scene-number box (map to an endless encoder), launch highlighted scene, cancel triggered launch, and per-track launch of the highlighted scene's clip.
- Pair it with **Select Next Scene on Launch** (Settings > Record, Warp & Launch) to step through a set. The highlighted scene stays centered, which suits large live sets.

### Clip View caution
- Clip View controls act on the selected clip(s), so a mapping can hit any clip. Use **relative** encoders.

## Chapter 35: Using Push 1

### Basics
- The pads follow the mode (**Note** or **Session**) and the track type (instrument or Drum Rack). Holding a mode button switches to it only while held.
- **Shift** gives second functions. Shift plus an encoder fine-tunes.

### Browse and add
- **Browse**: Selection row (first row under the display) goes up a level, State row opens a subfolder, **In/Out** shift columns, encoders scroll.
- Right green button loads the preset; left loads the device's default. Pressing the amber (loaded) button loads the next entry, for quick auditioning.
- Samples show only when one Drum Rack pad is selected.
- **Add Track** adds a MIDI track and opens Browse; hold it for Audio/MIDI/Return. Inside a Group, the new track goes into it.
- **Add Effect** inserts after the selected device; **Shift+Add Effect** inserts before it (select the instrument first to add a MIDI effect).

### Drums (Drum Rack track)
- **Note** cycles the layouts: **Loop Selector** (bottom-left 4x4 plays, bottom-right 4x4 sets loop length, top 4 rows sequence), then **64-pad** (whole grid plays), then **16 Velocities**.
- Touch strip or Octave Up/Down moves 16 pads; with Shift, one row.
- **Load one pad:** Device, tap the pad, its Selection button, then Browse. Tap other pads to load them too.
- **Copy a pad:** Duplicate + source pad + destination pad. This replaces sounds but not notes.

### Step sequencing
- Tap a pad to sequence it (Select+pad picks it silently). Tap a step to add or remove a note.
- **Scene/Grid** buttons set step size (16th by default). Triplets make the right two columns red and inactive.
- Hold **Mute** and tap a step to mute it. **Solo+pad** solos. **Delete+pad** clears the pad's notes in the current loop only.
- **Hold step(s) + encoders** sets Nudge, Length and Velocity. **Select+drum pad** edits all that pad's notes.
- **Per-step automation:** in Device or Volume mode, hold steps and turn encoders (empty steps work).

### Loop length pads
- One pad is one page (one bar of drums or two beats melodic at 16ths). Hold one and tap another to set a range; double-tap for one page; single-tap to lock the view (reselect the loop to follow again).
- Hold **Note** to show them briefly. **Shift+Note** locks them (per track); Note unlocks.
- **Duplicate+page+page** merges notes into the destination, so clear it first with **Delete+page**.

### Melodies and scales
- The default is C major in 4ths: up a 4th per row, a scale step to the right, bottom-left = C1.
- **Scales**: key with display buttons, scale with encoder 1. With **Fixed** on, notes stay put on a key change; off, bottom-left is the root. **In Key** hides out-of-scale notes; **Chromatic** shows all, lighting in-key notes. **Shift** in Scales: 4th/3rd layouts upward or rightward, or **Sequent** (no duplicates). Saved with the Set.
- **Note** cycles: real-time play, **Melodic Sequencer** (rows = pitches), **Sequencer + 32 Notes** (bottom selects notes, top steps add them; hold a step to see its notes).
- Touch strip is pitch bend; **Select+strip** switches to mod wheel. When sequencing, it moves the note range.
- **Delete+pad** clears that pitch in the loop.

### Recording
- **Record** presses go: record, play, overdub. **Metronome** toggles the click.
- **New** stops the clip and readies an empty slot. **Record+New** on an armed MIDI track captures MIDI.
- **Fixed Length**: hold to set bars. Turning it on mid-recording stops and loops the last bars.
- **Repeat**: tap latches, hold is momentary. Scene/Grid sets the rate, pressure sets volume. Swing knob swings it.
- **Quantize**: tap applies (audio: transients). Hold for Swing, Quantize To, Amount and Record Quantize. **Quantize+drum pad** affects only that pad.
- **Accent** forces full velocity; **Double** doubles the loop.
- **Automation** arms automation recording. **Delete+touch encoder** clears that parameter's automation (or resets it). **Shift+Automation** re-enables overrides; **Delete+Automation** clears the clip's automation.

### Devices and mixing
- **Device**: Selection picks a device, State toggles it, In/Out reach banks and Rack chains.
- **Volume**: 8 track volumes. **Pan & Send**: press again to cycle sends. **Track**: one track's volume, pan and sends 1-6; **Master** picks Main. Hold a Group's Selection button to fold it.
- **Clip**: loop settings; audio adds warp, detune, transpose, gain.
- 9th encoder: Main (Shift: Pre-Cue). Tempo: Shift for 0.1 BPM.
- Gotcha: with Split Stereo Pan, the pan encoder is dead in Pan & Send.

### Session Mode
- Pads launch clips, Scene buttons launch scenes; an empty slot on the selected track records.
- Arrows move 1, Shift+arrows 8; Octave moves 8 scenes. Hold **Shift** for **Session Overview** (pad = 8x8 block; amber current, green playing).
- **Stop+State button** stops a track; **Shift+Stop** stops all. **Select+clip/scene** selects without launching; **Delete+clip** deletes.
- In Note Mode, Left/Right picks tracks and auto-arms MIDI tracks. Up/Down launches the next scene seamlessly (legato).

### Preferences (hold User)
- **Pad Threshold**: too low and pads trigger or stick. **Velocity Curve**: higher Log gives more soft-playing range. **Aftertouch Threshold** ignores values below it and rescales the rest.
- **Workflow**: in **Scene** (default), Duplicate captures playing clips into a new scene, New does the same with an empty slot, Up/Down change scenes. In **Clip**, Duplicate copies the clip to the next slot (Shift+Duplicate captures a scene); New and Up/Down affect only the selected track.
- User Mode disables built-ins for custom mapping; set encoders to Relative (2's Comp.) by turning one slowly left.

### Misc
- **Shift+Undo** redoes; **Shift+Play** returns to 1.1.1.
- Footswitch 1 is sustain; footswitch 2 taps Record, double-taps New. Reversed polarity: plug in with it held.

## Chapter 36: Using Push 2

### Setup and conventions
- Plug in USB and power. Live auto-detects Push 2. Firmware updates ship with Live.
- **Shift + encoder** = fine adjust. The far-right encoder = Main volume (Pre-Cue/click with Shift).
- **Hold** Device, Mix, Clip, Session or Note for momentary access. Accent and Repeat latch on a tap and are momentary on hold. Holding Mute, Solo or Stop Clip locks them on.
- **Select + pad/clip/scene** selects without triggering.
- **Shift+Undo** = redo. **Shift+Play/Stop** (while stopped) returns to 1.1.1.

### Browsing and loading
- **Browse**: encoders or arrows scroll the columns. The two rightmost upper buttons move up and down the hierarchy. **Load** loads. Afterwards, **Load Next/Previous** step through neighbouring presets.
- The list depends on the last-selected device (instrument or effect). An empty MIDI track shows everything.
- **Add Track**: MIDI/Audio/Return plus an optional device. It goes inside the current group if a grouped track is selected.
- **Add Device**: MIDI effects always land before the instrument, audio effects after it. Gotcha: an instrument loaded here *replaces* the current one.

### Drum Rack layouts
**Layout** cycles through:
- **Loop Selector**: 4x4 play pads (lower-left), loop-length pads (lower-right), 32 steps (top four rows).
- **16 Velocities**: the lower-right 16 pads enter steps at fixed velocities.
- **64-pad**: whole-grid playing for big kits or slices. Gotcha: the 16-pad window doesn't follow when you switch back.
- **Hold Layout** for momentary access to the alternate section. **Shift+Layout** locks it, **Layout** unlocks it.
- Touch strip or Octave buttons scroll 16 pads at a time. With Shift, they scroll one row.

#### Pad operations
- **Load or replace one pad**: in **Device** mode, tap the pad, then press the second upper button (pad icon), then **Browse**. Tapping other pads retargets.
- **Duplicate + pad + pad** copies devices. Destination notes are kept.
- With one pad selected: encoder 1 = choke group, encoder 2 = transpose.

### Step sequencing beats
- Tap a pad to select it, then tap steps to toggle notes. The clip starts playing. **Scene/Grid** sets the step size: 1/16 by default. Triplets disable the right two columns.
- **Mute + step** deactivates the step. **Solo + pad** solos the sound.
- **Delete** deletes the clip. **Delete + pad** clears its notes, or its devices if it has no notes.
- **Hold step(s) + encoders** (Clip Mode): Nudge, Length, Fine and Velocity. Holding an empty step creates a note with those values. **Select + pad + encoders** edits all notes of that pad.

### Real-time recording
- **Metronome** toggles the click. A count-in shows as a bar in the display.
- **Record** cycles record → play → overdub → play.
- **Accent** forces velocity 127 and overrides the 16 Velocities pads.
- **New** stops the clip and readies an empty slot for practice. In Scene Workflow it also captures the playing clips into a new scene.
- **Fixed Length**: hold it to set the bars. When it's off, recording runs until Record, New or Play/Stop. Enabling it mid-record stops recording and loops the last N bars.
  - **Phrase Sync** starts at the matching phrase position. Example: bar 7 with a 4-bar length starts at clip bar 3.
- **Repeat** retriggers held pads at the Scene/Grid rate. Pressure sets volume, and the **Swing** knob adds swing. The setting is remembered per track.
- **Quantize**: tap to quantize the selection (or the whole clip). **Quantize + pad** quantizes that drum only. Hold it for settings: Swing, Quantize To, Amount, and Record Quantize (encoder 5). Gotcha: Record Quantize ignores swing. Audio clips get transient quantize.
- **Arrangement**: Record arms arrangement recording when Arrangement View is focused in Live. **Shift+Record** acts on the other view.

### Melodies and scales
- Default: C major, In Key. The bottom-left pad is C1, rows go up in 4ths, columns step through the scale. Colors: track color = root, white = in scale, green = playing, red = recording.
- **Scale** settings:
  - Display buttons pick the key. Encoders 2-7 pick the scale.
  - Encoder 1 = Layout (4ths, 3rds, or Sequent with no duplicate notes). Encoder 8 = Direction (Vert/Horiz).
  - **Fixed** on keeps C at the bottom-left. Off puts the root there.
  - **In Key/Chromatic**: Chromatic shows out-of-key notes unlit.
  - Scale settings save with the Set. To make your own default, save it in the Default Set.
- **Delete + pad** deletes all notes of that pitch in the loop.
- **Touch strip**: pitch bend, or mod wheel via **Select + tap strip**, in real-time play only. On drum tracks it scrolls banks.

### Melodic step sequencing
- **Layout** cycles: 64 Notes → Melodic Sequencer → Sequencer + 32 Notes.
- **Melodic Sequencer**: rows = scale pitches (white = root), columns = steps. One page = 8 steps.
  - Octave buttons or the strip shift the range. Shift+strip moves by octaves, Shift+Octave by one scale degree.
- **+32 Notes**: the bottom half plays and selects pitches. Tapping a top-half step adds all selected notes.
  - Hold a step to reveal its notes, then tap a note to remove it.
  - Hold several steps to fill them all. **Duplicate + step + step** copies.
- In Device or Mix mode, **hold step(s) + turn an encoder** to write per-step automation. This works on empty steps too.

#### Loop length and pages
- One pad = one page. **Hold + tap** sets the loop range. **Double-tap** = a one-page loop. **Single-tap** inside the loop locks the view (stops auto-follow). Reselect the loop, or hold Page Left/Right, to resume.
- **Page Left/Right** steps through pages. Loop pads appear while **Layout** is held: top row in the sequencer, fifth row in +32. **Shift+Layout** locks them (per track).
- **Duplicate + page + page** merges a page into another. **Delete + page** clears it.

### Samples (Simpler)
- Load via Browse on a MIDI track. Simpler picks the mode from length: short → one-shot, long → looped and warped. Warp markers carry over from clips.
- **Classic**: polyphonic, ADSR, looping. Start/End define the region. S Start, S Length and S Loop Length are percentages of it.
- **One-Shot**: mono, no loop. Trigger plays the full sample, Gate fades on release (Fade In/Out). Transpose ±48 st. **Shift+Play/Stop** kills playback.
- **Slicing**: up to 64 slices on the 64-pad layout. Slices fill in fours from the bottom-left up the left half, then the right half.
  - **Slice By**: Transient (Sensitivity), Beat (Division), Region (count), or Manual (enable **Pad Slicing**, tap empty pads during playback, then disable it).
  - **Playback**: Mono, Poly, or Through (continues to the region end).
  - **Nudge** moves markers (Shift = tiny moves). **Split Slice** halves a slice. **Delete + pad** removes a slice.
- **Zoom** focuses on the last-touched position control.
- **Edit Mode** (press Simpler's upper button again): Loop, Warp as N bars (÷2/×2 fixes wrong guesses), Crop and Reverse. Crop and Reverse are non-destructive because they process copies.
- **Legato repitch**: Edit → Global bank → Glide Mode = Glide, Voices = 1. Turn Warp on (Complex Pro usually works best).
- **Convert**:
  - Classic/One-Shot Simpler → new Drum Rack track with the sample on pad 1.
  - Slicing Simpler → Drum Rack of slices.
  - Drum pad → new track with that pad's devices.
  - Audio clip → Simpler or Drum Rack track, or Harmony/Melody/Drums to MIDI.

### Devices
- **Device**: upper buttons select devices and the encoders control them. Press a device again for Edit Mode, where the lower buttons pick parameter pages and the leftmost upper button exits.
- **Delete + device button** removes it. **Mute + device button** bypasses it. **Hold the device button + an encoder** reorders effects.
- **Racks**: press again to unfold. With the Rack selected, the encoders = Macros. **Hold the Rack button** to pick chains with the lower buttons. Gotcha: Drum Racks can't be unfolded from Push.

### Mixing
- **Mix** toggles Track Mix (volume, pan and sends for one track, plus an **Input & Output** routing page) and Global Mix (one parameter across eight tracks, arrows scroll).
- **Master** toggles the Main track. With more than six returns, arrows scroll the sends. Gotcha: in Split Stereo Pan, the Global Mix pan is disabled.
- **Press a selected group or Rack track's lower button again** to unfold it. With an unfolded Drum Rack, **Select + pad** jumps to that chain.
- Selecting a MIDI track auto-arms it (pink in Live). To manually arm, e.g. an audio track, **hold its lower button** or **Record + lower button** (red).

### Automation
- **Automate** (red) records encoder moves into playing Session clips.
- **Delete + touch encoder** clears that parameter's automation, or resets it to default if it has none. **Delete + Automate** clears all clip automation.
- White dot = automated, gray dot = overridden. **Shift+Automate** re-enables overridden automation.

### Clip Mode
- **Clip**: Loop on/off, Loop Position, Loop Length, and Start Offset. With the loop off: Start/End. Shift = 1/16 steps.
- Audio clips add Warp Mode, Gain and Transpose (Shift = cents). MIDI clips add **Crop** (trims outside the loop).

### Session Mode
- **Session**: pads launch clips and Scene/Grid buttons launch scenes. Tapping an empty slot on the selected track records.
- **Navigation**: Up/Down arrows move one scene, Octave buttons eight. Left/Right arrows move one track, Page buttons eight. **Hold Layout** for Session Overview: each pad = an 8x8 block, green = playing. **Shift+Layout** locks it.
- **Mute/Solo/Stop Clip + track's lower button** act on that track. **Shift+Stop Clip** stops all clips. **Duplicate + clip + slot** copies, **Delete + clip** deletes.
- In Note Mode, Up/Down arrows launch the next scene immediately, legato.

### Setup menu
- **Pad Sensitivity, Gain and Dynamics** all default to 5. For a **linear curve, set Gain to 4 and Dynamics to 7**. Gotcha: low LED Brightness distorts colors.
- **Workflow**:
  - **Scene** (default): Duplicate captures the playing clips to a new scene. New does the same but leaves an empty slot. The arrows launch whole scenes.
  - **Clip**: Duplicate copies the selected clip to the next slot (Shift+Duplicate = scene capture). New and the arrows affect only the selected track.
- **User** mode frees Push for custom mapping. For Relative (2's Comp.) encoders, turn slowly left while mapping.
- **Footswitches**: FS1 = sustain. FS2: tap = Record/overdub, double-tap = New. If polarity is reversed, plug the switch in while it's pressed.
