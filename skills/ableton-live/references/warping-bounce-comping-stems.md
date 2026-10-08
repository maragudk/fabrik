# Warping, Bounce to Audio, Comping, Stem Separation and Video

Distilled from the Ableton Live 12 Reference Manual. Keys are macOS (CMD, ALT/OPTION, SHIFT, CTRL).

## Contents

- Chapter 9: Audio Clips, Tempo, and Warping
- Chapters 20-22: Bounce to Audio, Comping, Stem Separation
- Chapter 28: Working with Video

## Chapter 9: Audio Clips, Tempo, and Warping

Warping time-stretches audio to follow the Set tempo. Controls are in the Clip View's **Audio Utilities** panel (double-click a clip).

### Set Tempo

- **Tempo field** (Control Bar): coarse BPM and fine (0.01) parts can be key- or MIDI-mapped separately. Automate tempo in the Main track for ramps or jumps. External sync (Link, MIDI Clock, Tempo Follower) is in the sync chapter.
- **Tap Tempo**: click once per beat. More taps give more accuracy.
  - To tap with a key: turn **Key** on in the Control Bar, click Tap, press a key, then turn Key off. MIDI Map works the same way for a footswitch.
  - With **Start Playback with Tap Tempo** on (Settings > Record, Warp & Launch), four taps in 4/4 also start the transport, phase-aligned with Link peers.
- **Phase Nudge Up/Down**: briefly speeds up or slows down playback to stay with unlocked sources (live players, vinyl). The Set must already be near their tempo. Mappable.

### Clip Tempo Leader (Arrangement only)

- Warped clips **Follow** the Set by default. Set a clip's **Lead/Follow** toggle to **Lead** and the Set takes its tempo from that clip's Warp Markers. The clip plays as if unwarped, and the tempo field is disabled.
- Several clips can lead, but the playing leader on the **bottom-most track** controls the tempo.
- Live writes read-only tempo automation to the Main track, and it moves with the clips. To edit it, right-click the tempo field > **Unfollow Tempo Automation**. This turns all leaders back into followers.
- Leader automation overrides Tempo Follower. Lead/Follow is disabled while **EXT** sync is on.

### Warp Switch and Import Defaults

- **Warp off**: original speed. Use it for one-shots, FX, and speech. **Warp on**: use it for loops and songs.
- Settings > **Record, Warp & Launch** sets defaults for first import (Live classifies each file as short or long):
  - **Loop/Warp Short Samples**: Unwarped One Shot, Warped One Shot, Warped Loop, or **Auto** (default).
  - **Auto-Warp Long Samples** (on by default): adds a marker on each bar's first beat.
  - **Default Warp Mode**: Beats out of the box. Change it to Complex/Complex Pro if you mostly import full tracks.
- Import by dragging, or use **Create > Import Audio File...** with an audio track selected. The file goes to the insert marker or the selected slot. You can't play or edit a new file until its analysis finishes.

### Warp Markers

- A Warp Marker pins a point in the audio (usually a transient) to a point in the timeline.
- **Add**: double-click the upper half of the Sample Editor, or press **CMD+I** at the insert marker. With a time selection, CMD+I marks every transient in it, or only the selection's edges if it has no transients.
- **Move**: drag or use the arrow keys. CMD+click selects several markers to move together. **SHIFT+drag** a selected marker slides the waveform under it.
- **Delete**: double-click the marker, or select it and press Delete.
- **Transients** (gray ticks along the top): add with **CMD+SHIFT+I**, delete with **CMD+SHIFT+Delete**. Right-click > **Reset Transients** removes manual ones.
- **Pseudo-Warp Markers**: gray markers that appear when you hover over a transient. Double-click or drag one to make it real. Hold **CMD** to also pin the neighboring transients. SHIFT+drag moves the transient itself. If no markers come after it, the clip tempo changes too.
- **Follow** (Control Bar) scrolls the editor, but editing pauses it. Relaunch or click the scrub area to resume.
- **Save** (clip title bar) stores markers with the file, for your own samples only (not Core Library or Packs). Auto-Warp then skips the file, but Warp From... still works.

### Short Loops

- **Even loops**: Live assumes a clean 1/2/4/8/16-bar loop and places start and end markers.
  - Type the real BPM into the **BPM** field, or SHIFT+drag it for fine steps. In Arrangement, SHIFT+drag a clip edge to stretch it.
  - Fix half or double tempo with **x2** / **÷2**.
- **Odd bar counts** drift because Live assumes an even count in 4/4. Add or move a marker at the correct bar. If the last bar is hidden (9 bars read as 8), drag the end marker right until it appears.
- **Badly cut loops**: put the insert marker on the first downbeat, then right-click > **Set 1.1.1 Here**, then **Warp From Here**. Add a marker before trailing silence to cut it.
- **Multi-clip warping**: select clips of the **same length** and edit markers in one to apply the edit to all. Ideal for tightening a multitrack drum recording.

### Long Samples and Full Songs

- Turn the **metronome** on while checking.
- **Right tempo, wrong downbeat**: SHIFT+drag a marker, or use **Set 1.1.1 Here** at the downbeat, or add a marker on the downbeat and drag it to bar 1.
- **Warp Sample as...** (right-click): suggests a loop length for a cleanly cut loop.
- **Warp Selection as...**: select a region (e.g. a break inside a song). Live auto-warps it, sets loop brackets, and fills the loop.
- **Hard material**: work **left to right**. Pin each correct section with markers before moving on.
- **Warp From Here** commands re-warp only what is right of the selected marker or grid point, at any position:
  - **Warp From Here**: runs Auto-Warp.
  - **(Start At ...)**: uses the Set tempo as the baseline. Workflow: Warp off, tap the clip's tempo, Warp on, then run the command.
  - **(Straight)**: one marker at the estimated BPM, for steady-tempo tracks.
  - **Warp ... BPM From Here**: one marker, clip assumed at the Set tempo. Type the known BPM first.

### Groove Edits and Audio Quantize

- **Fix timing**: pin a late hit and drag it onto the beat. Pin its neighbors too so nearby audio doesn't stretch.
- **Quantize**: click into the Sample Editor, then **CMD+U** (Edit > Quantize). Moves the nearest transients to the grid set in the Quantize panel (grid or a specific division, triplets included). **Amount** sets partial quantizing as a percentage of the move.

### Warp Modes

All modes are granular. Match the mode to the material.

- **Beats**: drums and most EDM. Keeps transients.
  - **Preserve**: Transients (most accurate for percussion) or a fixed grid division. Large divisions plus transposition give rhythmic artifacts.
  - **Transient Loop Mode** fills the gap after each segment. **Off** leaves silence (choppy when slowed). **Forward** loops from a zero-crossing mid-segment. **Back-and-Forth** ping-pongs and often sounds best at slow tempos.
  - **Transient Envelope**: 100 means no fade. Lower values give faster decay, useful for gating. Higher values reduce clicks.
- **Tones**: pitched, mostly monophonic sources (vocals, bass, leads). **Grain Size** adapts to the pitch. Small suits fast pitch changes. Large cuts noise but can add artifacts.
- **Texture**: unpitched or dense material (pads, drones, noise, orchestral) and sound design. **Grain Size** ignores pitch. **Fluctuation** adds randomness.
- **Re-Pitch**: varispeed like a turntable or tape (2x speed = +1 octave). Transpose is disabled.
- **Complex / Complex Pro**: mixed material and full songs. Pro often sounds better.
  - **Formants**: 100% keeps the original formants when transposing (no chipmunk sound). It does nothing without transposition.
  - **Envelope**: default 128. Go lower for high-pitched material, higher for low-pitched material.
- **CPU**: Complex and Complex Pro are the heaviest. Freeze or resample tracks that use them.

## Chapters 20-22: Bounce to Audio, Comping, Stem Separation

### 20. Bounce to Audio

**Use it to** print to audio for mangling, lock in sound design before mixing, or save CPU. The new track appears in both views.

**Individual tracks**
- *Bounce Track in Place* (track title bar or clip context menu) replaces the source with an audio track and bounces both its Arrangement and Session clips. It replaces Freeze/Flatten, which Live 12 removed.
- *Bounce to New Track* (clip/selection menu, **CMD+B**) renders the selected clips or time range to a new audio track and mutes the source. Use it when you want to keep the original.
  - A multi-track Arrangement selection gives one new track per source track.
  - From Session, only the selected clips are bounced, and the Arrangement copy of the new track is empty.
- Signal point: **post-FX, pre-mixer**. Devices are printed. Volume, pan and sends are copied to the new track's mixer, not printed.

**Group Tracks**
- *Bounce Group in Place* (group title bar, Session group slot, or Arrangement group main lane menu) replaces the whole group.
- *Bounce Group to New Track* (group slot or main lane menu, **CMD+B**) renders clips or a range.
- Groups render **post-mixer** at the group output: effects and sends inside the group are included, Main track processing is not.
- Gotcha: a child track routed outside the group is left out, which can give silence. A return inside the group is included only if its output reaches Main.

**Paste Bounced Audio**
- Copy the source (**CMD+C**), then paste into an audio track, an empty MIDI track (it converts to audio), or a take lane with **CMD+OPT+V**.
- Live renders the source *at paste time*. Tweak its FX and paste again for quick variations, or collect parts from several tracks onto one track.

**Naming and files:** the new item is named "<source> (Bounce)" and keeps the source color. Files go to `Project/Samples/Processed/Bounce`.

### 21. Comping

**Use it to** build a composite from the best parts of several takes, keep alternate arrangements, or chop samples creatively on lanes. It works in the Arrangement on audio and MIDI tracks.

**Lanes**
- You hear the **main lane**. **Take lanes** play only when you audition them.
- Show/hide: use Show Take Lanes in the track header menu, the main-lane toggle, or **CMD+OPT+U**. The left arrow jumps to the main lane and folds the takes.
- Take lanes are hidden in Automation Mode. Showing or inserting a lane exits that mode.
- Insert with **SHIFT+OPT+T** (or Create > Insert Take Lane). Duplicate with **CMD+D**. Rename with **CMD+R** (Tab moves to the next lane). Reorder with **CMD+up/down**. Resize with **OPT+plus/minus** or OPT+wheel.
- *Delete All Unused Take Lanes* keeps only the lanes that the main-lane comp uses.

**Recording:** each Arrangement pass or loop cycle on an armed track goes to a new take lane. The latest take is copied to the main lane. To color takes differently, set Settings > Theme & Colors > Clip Color to Random.

**Samples:** drag files onto take lanes. Hold **CMD** while you drag several files to put each one on its own track.

**Audition:** click the speaker button in the lane header or press **T**. You can audition one lane per track, and several tracks at the same time.

**Building the comp**
- Select a range on a take lane and press **Enter** to copy it to the main lane.
- Select on the main lane or a take lane and press **CMD+up/down** to swap in the previous or next take for that range. Empty lanes are skipped.
- Fastest: in **Draw Mode**, drag across a take lane to comp that range. Or select a range on the main lane, then click a take to fill it.
- Main-lane clips are independent copies, so edits do not affect the takes.
- To avoid clicks, turn on *Create Fades on Clip Edges* (Settings > Record, Warp & Launch) for automatic 4 ms crossfades, or select clips and press **CMD+OPT+F**.
- **Source highlights** show used take material in the track color and unused material desaturated. Drag a highlight edge to move the split point between two comp segments.

### 22. Stem Separation

**What it is:** an offline, on-device model that splits any mono or stereo audio into **Vocals, Drums, Bass, Others**. Use it for acapellas, remixes, sampling single instruments, and DJ blends. The stems are normal audio clips. It arrived in Live 12.3; the manual does not state edition availability.

**Running it**
- Right-click a browser file or a Session/Arrangement clip and choose *Separate Stems to New Audio Tracks* (also in the Create menu).
- For part of an Arrangement clip, make a time selection in the clip and choose *Separate Stems for Time Selection*. Live splits the clip at the selection edges.
- Dialog: stem toggles; *Merge to Single Track*, which works only with 2-3 stems; *High Speed* / *High Quality*. Playback stops when separation starts.
- Only the active clip region is processed: start to end marker, or start marker through the loop for a looped warped clip.

**Results**
- The stems go on tracks in a new Group Track. A single stem or a merged result goes on a plain track.
- The source track's FX go on the group, not printed. Track automation goes to the group, and clip envelopes go to each stem clip.
- The source clip is deactivated. Press **0** to turn it back on.
- In an empty Set, the tempo follows the source if auto-warp is on.
- Files go to `Project/Samples/Processed/Stems` and are always **44.1 kHz** at the source bit depth. Merging also keeps the separate stem files.

**Speed vs. quality**
- High Speed separates everything in one pass. High Quality runs separate passes for Vocals, Drums and Bass, so it is slower but gives a better SDR. Others is what remains.
- To save time, crop first with **CMD+SHIFT+J**: *Crop Clip Sample to Time Selection* in the Sample Editor, or *Crop Clip* in the Arrangement.
- In High Quality, fewer stems means a faster run, **unless Others is included**. Then all passes run, and the stems you did not ask for are saved to disk only.
- Apple silicon uses the GPU. Intel Macs use the CPU only and are slow.

**Limitations:** sound can bleed between stems, e.g. hi-hat highs in Others or chorused synths in Vocals. Try both modes and keep whichever sounds better.

## Chapter 28: Working with Video

Scoring to picture: place a movie in the Arrangement, lock hit points to frames with Warp Markers, then export audio (and optionally video). Requires warping knowledge. External video gear sync is in the Synchronization chapter.

### Importing video
- Supported format: **QuickTime `.mov` only**. Drag it from the browser into the Set.
- Video displays **only for clips in the Arrangement View**. A movie dropped into the Session View becomes a plain audio clip.

### Video clips
- Look like audio clips with "sprocket holes" in the title bar. Edit them the same way (for example, drag edges to trim).
- **Gotcha:** **Consolidate, Reverse and Crop** turn a video clip into an audio-only clip. The source file is never changed.
- QuickTime gaps: missing video shows black, missing audio plays silence.
- Embedded QuickTime markers appear on the clip as cues for Warp Markers.

### Video Window
- Floats above Live. Toggle in the **View** menu. Resize from the bottom-right corner.
- Size and position are global, not saved per Set.
- **Double-click** the window for full screen (it can go on a second monitor). **ALT + double-click** returns it to the video's native size.

### Syncing music to picture (Tempo Leader)
- Default Arrangement setup: **video clip is Tempo Leader**, audio clips follow the video's natural playback rate.
- In the Clip View Audio tab, the video clip's **Warp** must be on before you can set Leader.
- Warp Markers on the video clip are **hit points** the music syncs to. Dragging one scrubs the Video Window to that frame.
- Only the **bottom-most playing clip with Leader on** actually leads. A non-leading video clip can get warped, so the picture plays stretched.

#### Typical workflow
1. Press **Tab** to switch to the Arrangement View.
2. Drag the `.mov` onto an audio track (the Video Window opens) and your music into the drop area. Unfold both tracks.
3. Double-click the video clip's title bar. In Clip View, turn Warp on and set Leader.
4. Add Warp Markers on the video at the sync points. Optionally loop a section with the Arrangement Loop.
5. **File > Export Audio/Video**: mixes all audio down to one file and can render the video as well.

### Handling pre-roll ("two-beep")
Delivered movies often start with seconds of sync leader that the mix engineer expects in your stems too. To compose with the action at 1.1.1 / 00:00:00:00:
1. Drop the movie at 1.1.1. In Clip View, drag the **Start Marker** right to where the action begins.
2. Compose.
3. Before export: **CMD+A** (Edit > Select All), then drag everything a few seconds to the right.
4. Click only the video clip's title bar. Drag its left edge fully left to bring the pre-roll back.
5. Export. Length defaults to the Arrangement selection, so with the video clip selected the file matches the full movie, pre-roll included.
