# Live Concepts, Arrangement, Session, Clip View and Launching

Distilled from the Ableton Live 12 Reference Manual. Keys are macOS (CMD, ALT/OPTION, SHIFT, CTRL).

## Contents

- Chapter 3: Live Concepts
- Chapter 6: Arrangement View
- Chapter 7: Session View
- Chapter 8: Clip View
- Chapter 16: Launching Clips

## Chapter 3: Live Concepts

### Mental model
- A **Live Set** is the document, saved inside a **Live Project** folder.
- **Clips** hold the music. **Tracks** host clips and devices and route signal. **Scenes** are Session rows that launch together.

### Control Bar and Status Bar
- Left to right, the Control Bar holds: the browser toggle; Link, tempo, time signature, metronome and Tempo Follower; scale; Follow; transport; overdub, Automation Arm, Re-Enable Automation, Capture MIDI and Session Record; loop and punch; Draw Mode, Computer MIDI Keyboard, Key/MIDI Map, sample rate and CPU; and the view selector.
- In the MIDI Note Editor, the Status Bar shows the selected note's position, pitch, velocity and probability.

### Session vs Arrangement
- **Arrangement** is a linear timeline. **Session** is a grid of launchable clips for jamming and live sets.
- Switch views with **Tab**. If "Use Tab Key to Navigate" (Display & Input) is on, use **ALT+1** (Session) and **ALT+2** (Arrangement) instead.
- Each view has its own clips, but both share the same tracks and mixer. Switching views during playback changes only the UI.
- **One clip per track at a time.** Put alternative clips in the same column and clips that play together in the same row (scene).
- **Session clips beat Arrangement clips.** Launching a Session clip stops that track's Arrangement playback; other tracks keep playing the Arrangement.
- **Gotcha**: the track stays on the Session clip until you click **Back to Arrangement**. The button is on the Main track (Session) or at the top right of the scrub area (Arrangement), and lights when any track has left the timeline. Each track also has its own button.
- **Workflow**: improvise in Session with **Arrangement Record** on to log the performance, then edit it on the timeline.

### Audio and MIDI clips
- Audio clips live only on audio tracks, and MIDI clips only on MIDI tracks. MIDI needs an instrument to make sound: Simpler is chromatic, Impulse has one drum per key.
- An **audio clip** references a sample on disk plus playback settings. All edits are non-destructive. Double-click a clip to open the **Clip View**.
- **Warping** changes speed without changing pitch, to follow the tempo. Auto-Warp handles most loops.
- An imported **.mid file** is copied into the Set and is not referenced afterwards.

### Browser and Sound Similarity
- Show or hide the browser with **CMD+ALT+5**.
- **Similarity Search** finds similar sounds in the Core and User Libraries. It works on samples up to 60 s, instrument presets and drum presets. Use the Show Similar Files icon, right-click > Show Similar Files, or **CMD+SHIFT+F**.
- **Similar Sample Swapping** replaces samples in Drum Rack, Simpler or Drum Sampler with similar ones.
- **Gotcha**: your own audio must be analyzed in the background first; progress shows in the Status Bar and can be paused.

### Devices, Clip View and Device View
- Double-click a track title for the **Device View**. Audio, return and group tracks take audio effects only. MIDI tracks run MIDI effects -> instrument -> audio effects.
- Add a device: drag it from the browser to a track or the Device View, or select it and press **Enter**. Plug-ins (VST, and AU on macOS) are under **Plug-Ins**.
- **Clip View**: start/end, loop and scale. Audio clips add warping and transformation tools; MIDI clips add Pitch and Time Utilities, Transformations and Generators.
- **CMD+ALT+3** shows Clip View and **CMD+ALT+4** shows Device View. To see both, use the triangle toggles at bottom right.
- A MIDI track with no instrument outputs raw MIDI and has no volume or send controls.

### Scale awareness (Live 12)
- Turn on **Scale Mode** in the Control Bar or Clip View, then set Root Note and Scale Name.
- The scale applies to the selected clip. With no clip selected, it applies to clips you create next. From the Control Bar you can set one scale on several selected clips.
- **Fold to Scale** shows only in-scale rows. **Highlight Scale** shades them purple, Live's color for scale-aware.
- MIDI Tools and Pitch/Time Utilities follow the scale.
- Arpeggiator, Chord, Pitch, Random and Scale have a **Use Current Scale** toggle, which switches pitch parameters from semitones to scale degrees. Auto Shift's Quantizer and Meld's oscillators and filters can also follow the scale.

### Mixer, Racks and routing
- Device chains are always stereo internally. Devices per track are limited only by CPU.
- **Sends** feed **return tracks**, which hold only effects, for shared reverb and delay. The **crossfader** blends any number of tracks, returns included, through A/B assigns.
- Device presets save to the User Library and work in any Set. Instrument, Drum and Effect **Racks** save a whole device chain as one preset.
- The **In/Out section** (View > Mixer Controls > In/Out) is the patchbay. Use it for resampling, submixes, layering, and routing to hardware or other apps.
- **Group tracks** act as submixers. **Monitoring** sets when the input is heard. **External Audio Effect** and **External Instrument** put hardware inside a chain.

### Recording
- Click **Arm** to enable recording. Arming one of several selected tracks arms them all; **CMD+click** to arm extra tracks.
- With **Exclusive Arm** on (Record, Warp & Launch settings), loading an instrument into an empty MIDI track arms it.
- **Arrangement Record** records every armed track to the timeline, one clip per track per take.
- **Session Record** records into the selected scene without stopping playback. Press it again to stop and launch the new clips. Launch quantization trims them to the beat.
- For drum patterns, loop Session Record + overdub + Record Quantization, adding hits each pass.

### Automation and clip envelopes
- Almost any control can be automated, tempo included.
- To record automation, turn on **Automation Arm** and move controls:
  - With **Arrangement Record** on, it goes to the timeline.
  - While Session-recording, it goes to the clip.
- **Gotcha**: moving an automated control during playback overrides its automation. Restore it with **Re-Enable Automation**, or by launching a Session clip that has automation.
- **Clip envelopes** modulate devices and mixer controls from inside a clip. Audio clips add pitch and volume envelopes; MIDI clips add CC envelopes.
- **Unlink** an envelope to give it its own loop length, for a long fade over a short loop or a fast gesture.

### Mapping
- **MIDI Map Mode** (the Control Bar MIDI switch, **CMD+M**): click a control, then move a hardware knob. Clips can map to a key range for chromatic play.
- **Gotcha**: mapped notes and CCs are filtered out and never reach MIDI tracks.
- **Key Map Mode** (**CMD+K**) maps computer keys to clips and buttons.

### Saving and exporting
- Audio is saved by reference, so moving or deleting a sample breaks its clip. **File > Collect All and Save** copies all samples into the project; do this before archiving.
- The clip **Save** button stores default settings, such as warp markers, with the sample.
- **Export Audio/Video** (**CMD+SHIFT+R**) renders the Main output by default. You can also export a single MIDI clip as .mid.
- **Live Clips**: drag a Session clip to the User Library. The file keeps the clip, its envelopes and the track's device chain.

## Chapter 6: Arrangement View

This is the linear timeline where you build the finished song. Editing works by selection: select clips or time, then run a command. Recording, comping, automation, and Group Tracks are covered in other chapters.

### Layout
- **Overview** (top strip) and **beat-time ruler**: drag horizontally to scroll, vertically to zoom. Double-click the ruler to zoom to the selection, or to the whole song if nothing is selected.
- **Scrub area**: click to play from that point. Hold the mouse down to loop there at the global quantization length.
- **Lock Envelopes** keeps automation fixed to song time, so moving clips leaves their automation in place. The **Automation Mode** toggle shows or hides automation lanes.
- **Mixer Drop Area** (below the tracks): drop an instrument or MIDI effect to make a MIDI track, or an audio effect to make an audio track.
- `H` / `W` fit all tracks to the window height / width. The **Waveform Vertical Zoom** slider makes waveforms bigger without changing the gain.
- Choose which track controls show in View > Arrangement Track Controls.

### Navigation and zoom
- `+`/`-` or CMD+scroll: zoom. CMD+OPTION+drag: pan. OPTION+scroll in a lane: zoom that track vertically.
- `Z` zooms to the selection. `X` steps back one zoom level per press.
- **Follow** (Control Bar) scrolls the view with playback. It pauses when you edit, scroll, or click the ruler, and resumes on stop/restart or a click in a scrub area.

### Transport
- Space plays/stops. SHIFT+Space continues from where playback stopped instead of from the insert marker.
- Playback starts at the flashing **insert marker**. Double-click Stop or press FN+LEFT ARROW to return to the start.
- You can drag, type into, or arrow-step the **Arrangement Position** fields.
- **Permanent Scrub Areas** (Settings > Display & Input) is on by default. When it is off, SHIFT-click to scrub.
- **Chase MIDI Notes** (Options menu, on by default) plays notes that started before the play position.

### Locators
- **Set Locator** adds a locator, quantized, during playback. With the transport stopped, it adds one at the insert marker or the selection start. You can also use the scrub-area context menu or the Create menu. When a locator is selected, the button deletes it (as does the Delete key).
- **Previous/Next Locator** buttons jump with quantization. These buttons and the locators themselves can be MIDI- or key-mapped. When stopped, double-click a locator to play from it.
- CMD+R renames a locator. Edit > Edit Info Text adds notes. Arrow keys move it.
- Context menu: **Loop to Next Locator** loops one section quickly. **Set Song Start Time Here** makes playback always start at that locator.

### Time signature changes
- To add a meter change: Create > Insert Time Signature Change (adds it at the insert marker). You can also type into the Control Bar meter fields during playback. The numerator is 1-99, and the denominator is 1, 2, 4, 8, or 16.
- CMD+R edits a meter marker. Markers snap to the grid but are not quantized to bars. A marker placed mid-bar makes a crosshatched **fragmentary bar**. Its context menu offers Delete Fragmentary Bar Time or Complete Fragmentary Bar. Gotcha: both commands change time on **all tracks**.
- When you import a MIDI file, Live can import its meter changes as markers.

### Arrangement loop
- CMD+L loops the selection. Press it again to toggle the loop. You can also use the Control Bar's loop toggle and the Start/Length fields.
- Loop brace keys: LEFT/RIGHT nudge it by the grid. UP/DOWN move it by its own length, which is handy for auditioning section after section. CMD+LEFT/RIGHT resize it by the grid. CMD+UP/DOWN double or halve it.
- Drag the edges to change the start or end. Drag the bar to move the loop. Click the brace to select its contents.

### Clips: move, resize, slide
- Drag the clip's title bar (not the waveform) to move it. Drag an edge to resize it. Clips snap to the grid, clip edges, locators, and meter markers.
- SHIFT+OPTION+drag the contents slides warped audio or MIDI inside the clip. Add CMD to slide without snapping.

### Selection
- Click the background to place the insert marker. Arrow keys move it in time or between tracks. OPTION+LEFT/RIGHT snaps it to clip edges and locators.
- Drag to select time. SHIFT-click or SHIFT+arrows extend the selection, also across tracks.
- `U` unfolds the selected track, so you can select time inside clips. OPTION+U unfolds all tracks. OPTION+`+`/`-` sets track height. Hold OPTION while resizing one track to resize all of them.
- `0` deactivates the selection (or the whole track if a track header is selected). `R` reverses an audio selection across clips; MIDI can't be reversed this way. LEFT/RIGHT nudge the selection.

### Editing grid
- CMD+1 makes the grid finer and CMD+2 makes it coarser. CMD+3 toggles triplets, CMD+4 turns snapping on/off, and CMD+5 switches between fixed and zoom-adaptive.
- Hold CMD while dragging to bypass snapping (if the grid is off, holding CMD turns it on temporarily). The current grid spacing shows at the bottom right.

### "…Time" commands (all tracks)
- **Cut/Delete Time** removes time and closes the gap, so the song gets shorter. **Paste/Duplicate Time** inserts time, so the song gets longer. **Insert Silence** adds empty time at the insert marker.
- Use these to make a section longer or shorter on every track at once. Meter markers in the range are affected too. Plain Cut/Copy/Paste affect only the selection.

### Split and consolidate
- **Split** (CMD+E): cut the clip at the click point, or make the selected range its own clip.
- **Consolidate** (CMD+J): merges adjacent selected clips into one clip per track. Good for printing a new loop.
- Gotcha: consolidated audio is rendered **before the track's effects and mixer**. It includes warp, pitch, clip gain, and clip envelopes. For a render with effects, use File > Export Audio/Video. Files go to Samples/Processed/Consolidate (or to the Temporary Folder if the Set is unsaved).

### Fades and crossfades (audio)
- Fade handles appear at clip edges when the track is tall enough. In Automation Mode, hold `F` to show them. Drag the edge handle to set the length, and the **Fade Curve** handle to shape the fade.
- CMD+OPTION+F creates a fade from a selection that includes the clip's start or end. To crossfade, drag a handle over the next clip, or select across the boundary and choose Create > Create Crossfade.
- **Create Fades on Clip Edges** (Settings > Record, Warp & Launch) adds automatic 4 ms anti-click fades and crossfades. With it on, Delete resets a fade to 4 ms instead of removing it.
- Limits: a fade can't cross the clip's loop boundary, and a clip's fade-in and fade-out can't overlap. A dotted line shows the limit. Fades belong to the clip and are separate from automation.

### Linked-track editing (new in Live 12)
- Use it for phase-locked multitrack edits and comping, for example on drum mics.
- To link tracks, select their headers, then choose context menu > **Link Tracks**. This works on a Group Track header too. A track can be in only one linked set. To add tracks to a set, CMD-click Link Tracks in a header of that set. Remove tracks with **Unlink Track(s)**.
- Shared edits: move/resize, selection, …Time, split/consolidate, arming, and take-lane management. Fades change together only when they start at the same position.

### Mixer in Arrangement View
- CMD+OPTION+M opens it. Choose controls in View > Mixer Controls. The mixer shares its values with the track controls. Only the mixer has track delay, crossfader, and Performance Impact meters.

## Chapter 7: Session View

The Session View is a non-linear clip grid for live sets, DJing, theatre cues and jamming ideas before you commit them to a song. Tracks are columns and scenes are rows. Grid position does not set playback order. TAB toggles Session/Arrangement.

### Clips and slots
- **Launch:** click the clip's triangle, or select the clip and press ENTER. Arrow keys move to neighbouring clips. Launch behaviour comes from the clip's Launch settings.
- **Stop:** use a slot's square Clip Stop button or the one in the Track Status field.
- **Deactivate:** select clips and press 0.
- Clips can be mapped to keys or MIDI, including MIDI note ranges for chromatic play.
- The transport and Arrangement Position keep running when every clip is stopped, so song time continues. Press Stop **twice** to stop the Set and reset to 1.1.1.
- **Rename** with CMD+R (several selected clips are renamed in turn). Edit Info Text and colour are in the context menu.
- **Select:** SHIFT-click selects adjacent clips, CMD-click selects non-adjacent ones, or rubber-band from an empty slot. Drag to move.
- **Group Track slots:** shading means a child track has a clip in that scene. The group slot's launch button fires all of them, and clicking the slot selects them.

### Tracks and scenes
- A track plays **one clip at a time**, so put alternatives (song sections, loop variations) in the same column.
- Resize a track by dragging its title-bar edge. ALT+drag resizes all tracks. Select a track header and press 0 to deactivate the track.
- Scene Launch buttons sit in the right-most Main track. To cancel a scene that is queued, use **Cancel Scene Launch** in the Main track's context menu.
- **Select Next Scene on Launch** (on by default, Settings > Launch) moves the selection down after each launch, so ENTER or one MIDI button steps through a set.
- Rename scenes with CMD+R, then press TAB to go to the next scene.
- Dragging non-adjacent scenes collapses them together. Use CMD+UP/DOWN to move them and keep their spacing. Scene numbers follow position.

### Scene tempo and time signature
- These fields are hidden by default. Drag the **left edge of the Main track's title header** to show them. Drag in a field, or type a value and press ENTER. The Set changes when the scene launches.
- Ranges: 20-999 BPM. Numerator 1-99, denominator 1, 2, 4, 8 or 16.
- To clear a value, press DELETE, double-click the field, or choose Return to Default.
- Keyboard: LEFT/RIGHT arrows move from a slot to the fields. TAB/SHIFT+TAB move through name, tempo and signature, then wrap to the next scene. With a field selected, press ENTER once to select the scene and again to launch it.
- Scenes with a tempo or signature show a coloured launch button.
- Pre-Live 11 Sets that had "120 BPM"-style scene names are converted to these fields automatically.

### Scene View
- To open it, select scenes or click the Main track title bar. It edits tempo, signature and **scene Follow Actions** for one or more scenes, plus their names and colour.

### Track Status field
- **Pie chart:** a looping clip is playing. It shows the loop length in beats (right) and the number of passes (left). On a Group Track, a pie with no numbers means a child clip is playing.
- **Progress bar:** a one-shot clip is playing. It shows the time remaining.
- **Mic or keyboard icon:** the track is monitoring its input.
- **Mini timeline:** the track is playing the Arrangement.

### Building the grid
- If you drop several files at once, they stack in one track. Hold **CMD before dropping** to spread them across tracks. This works for audio and MIDI files, not Live Clips.
- Turn off **Select on Launch** (Launch settings) to keep your current view, for example a return track's devices, when you launch clips.
- **Edit > Add/Remove Stop Button:** a slot with no stop button lets that scene leave the track playing.
- **Insert Scene** (CMD+I) adds an empty scene.
- **Capture and Insert Scene** (SHIFT+CMD+I) copies the playing clips into a new scene and launches it without a gap. Use it to save a good combination and keep jamming.
- Copy, paste and duplicate (CMD+D) also work on scenes.

### Recording Session into Arrangement
- Turn on **Arrangement Record** and perform. Live records clip launches, clip property changes, mixer and device automation, and tempo/signature changes. To finish, press it again or stop.
- The recording **places clips only**. It creates no new audio.
- **Gotcha:** launching a Session clip overrides that track's Arrangement. Pressing Clip Stop gives silence, not the Arrangement. Click **Back to Arrangement** (lit in both views) to resume. **Stop All Clips** in the Main track stops every clip.
- Session and Arrangement clips are independent, so you can record new passes until a take works.

### Moving material between views
- Copy and paste, drag clips onto the view selectors, or drag between windows with **Second Window** (SHIFT+CMD+W).
- Arrangement clips pasted into the Session are laid out top to bottom in time order. Launching the scenes in order rebuilds the song.
- **Consolidate Time to New Scene** (Create menu or the selection's context menu) turns a time range into one clip per track in a new scene. It **renders new samples** for audio tracks.

## Chapter 8: Clip View

In Live 12 the Clip View has **clip panels** on the left and an **editor** on the right. The panels replace the old Clip, Launch, Sample and Notes "boxes". Envelope editing is covered in its own chapter.

### Opening and layout
- Open it by double-clicking a clip, using the Clip View Selector, or pressing **CMD+OPTION+3**. In Session, clicking a Track Status Display opens the clip that is playing.
- Drag the top border to resize. Dragging it to the bottom closes the view.
- **Second window:** press **F12** to move the Clip View between windows. The view always shows the selected clip, so one window can stay a dedicated editor.
- **Panel layout:** drag the panels' right edge left for a vertical layout and right for horizontal. The View menu also has Arrange Clip View Panels Vertically/Horizontally/Automatically. Double-click the title bar to fold the panels.
- **Editor modes:** audio clips have Sample and Envelope. MIDI clips have Note, Envelope and MPE. Cycle with **OPTION+TAB**.
- **Panels:** both clip types get Main and Extended Clip Properties. Audio adds Audio Utilities and Transform. MIDI adds Pitch and Time Utilities, Transform and Generate.

### Title bar
- **Clip Activator:** a deactivated clip stays silent. Press **0** on a selection.
- **Rename:** use the context menu or Edit > Rename. This does not rename the sample file. Rename the file in the browser.
- **Color:** new clips take the track color. Assign Track Color to Clips, or the Group Track version, reverts the colors. **Gotcha:** it only affects clips in the current view (Session or Arrangement).
- **Save Default Clip** (audio): stores the clip settings, especially Warp Markers, in the sample's `.asd` file so future drops reuse them. It does not change existing clips. It also differs from a Live Clip, which saves devices too. Use it after you warp a long track.

### Main Clip Properties
- **Start/End:** type values, or press **Set** during playback to grab the playhead (snapped to global quantization). Warped audio shows bars-beats; unwarped audio shows time.
- **Loop:** enable the Clip Loop toggle and set Position and Length. **Audio clips must be warped before they can loop.**
- **Capture a loop live:** Set Loop Position moves the loop start to the playhead and enables looping. Set Loop Length then sets the end. All of these controls are MIDI-mappable, so an encoder can step a loop through a sample.
- **Time Signature:** affects display only and is independent of the Set. Use it to plan polymeters.
- **Groove:** choose from the Groove Pool. Hot-Swap loads a groove from the browser and also replaces it in the pool. **Commit** writes the groove into the clip. On audio, a groove with positive velocity creates a volume envelope that **overwrites** any existing one.
- **Scale:** the Scale toggle plus Root and Name. On MIDI clips the piano ruler highlights in-scale keys and pitch tools work in scale degrees. On audio clips the scale has no effect on playback, but Live passes it to scale-aware devices.

### Extended Clip Properties
- Launch controls and Follow Actions, for Session clips only (see the Launching Clips chapter). The panel is hidden for Arrangement audio clips.
- **Bank/Program Change (MIDI):** sends bank/sub-bank/program (128 each) on launch, so each clip can recall its own synth patch. Set the choosers to "—" to send nothing.

### Audio Utilities
- **Warp:** off keeps the original speed. Use that for one-shots, atmospheres and FX. Turn it on so loops and full tracks follow the tempo (see the Warping chapter).
- **Reverse:** writes a new file to `Samples/Processed/Reverse`. Warp Markers and the loop/region flip with the audio, but clip envelopes stay put in time. You can reverse only one clip at a time in Session. In Arrangement, select a range across clips and press **R**. **Don't reverse live**, because it can glitch.
- **Edit:** opens the sample in the external editor set in Settings > File & Folder. Stop playback first. Warp Markers survive only if the length is unchanged. The edit affects every clip that uses the sample.
- **Clip Fade:** adds a 0–4 ms anti-click fade at the edges. It exists only in Session; Arrangement uses fades or envelopes. To make it the default, use Settings > Record, Warp & Launch > Create Fades on Clip Edges.
- **RAM Mode:** plays the clip from memory instead of disk. Use it for slow disks or dropouts in Legato Mode. Use it sparingly: if memory swaps to disk, you get mutes and timing hiccups, which is worse than a disk overload.
- **Hi-Q:** better sample-rate conversion at a higher CPU cost. It cuts high-frequency aliasing and allows about ±19 semitones of clean transposition.
- **Gain** (dB) and **Pitch** (semitones, plus a cents field). A multi-selection shows the range of values.

### Pitch and Time Utilities (MIDI)
These act on the selected notes or time range. With nothing selected, the buttons affect the whole clip.
- **Transpose:** semitones, or scale degrees when a scale is set. **Fit to Scale** snaps notes into the scale and needs a scale. **Invert** flips the pitches upside down.
- **Interval Size + Add Interval:** stacks notes at the chosen interval. Quick for octaves and harmonies.
- **Stretch, ×2, /2:** scale durations, the selection or the loop. **Duration + Set Length** sets every selected note to one length.
- **Humanize:** randomizes start times by up to half a grid step. **Reverse** flips the note order. **Legato** extends each note to the next one.

### Transform and Generate
- **Audio:** the Quantize tool (warped clips only) snaps to the grid or a value. **Amount** sets the percentage that Warp Markers move. Audio clips have no Generate panel.
- **MIDI Tools:** transforms replace the original notes. Generators fill the time selection or the loop. With Scale Mode on, both work in scale degrees and stay in key. See the MIDI Tools chapter.

### Navigation, scrubbing, looping
- **Zoom:** drag vertically in the ruler to zoom and horizontally to scroll. **Z** zooms to the selection and **X** steps back. The **Follow** toggle auto-scrolls and pauses when you edit.
- **Markers:** drag them or use the arrow keys. **OPTION+arrows** moves the whole region.
- **Scrub:** click the lower half of the waveform (needs Permanent Scrub Areas) or SHIFT-click the ruler. Jumps follow global quantization, set with **CMD+6/7/8/9/0**. Hold the mouse button to repeat a slice; a quantization of None gives true scrubbing. Options > Chase MIDI Notes sounds notes that started before the playhead.
- **Loop brace:** LEFT/RIGHT nudge by the grid. UP/DOWN jump by the loop's length. **CMD+LEFT/RIGHT** resize by the grid. **CMD+UP/DOWN** double or halve the length.
- **Duplicate Loop** (Edit menu) doubles the loop and its contents. Later MIDI notes shift along.
- **Run into a loop:** playback starts at the start marker, so put it before the loop brace for an intro.

### Cropping and replacing
- **Crop: CMD+SHIFT+J.** For looped clips, the region runs from the earlier of start or loop start to the loop end. You can also crop to a time selection. Audio crops write a new file to `Samples/Processed/Crop`.
- **Replace a sample:** drop a file onto the Clip View, or select it in the browser and press ENTER. Pitch and volume are kept. Warp Markers survive only if the length matches exactly.
- Sample Editor context menu: **Show Similar Files** finds similar sounds. **Manage Sample File** edits destructively for every clip that uses the file.

### Multi-clip editing and defaults
- Select by dragging from an empty slot, or CMD- or SHIFT-click. Only shared properties are shown.
- Controls offset all values together. Drag to the min or max to make every value the same.
- Settings > Record, Warp & Launch sets the **Clip Update Rate**, the quantization for edits to a playing clip. It also sets the defaults for new clips, such as Launch Mode and Warp Mode.

## Chapter 16: Launching Clips

### Where the launch settings live
- Session View clips only. Arrangement clips ignore these settings.
- Double-click a clip to open Clip View, then open the **Launch** tab (the one with the Clip Launch button icon).
- Select several clips first to edit all of their launch settings at once.

### Launch Mode
- **Trigger** (default): press starts the clip, release does nothing.
- **Gate**: press starts it, release stops it. Use it for momentary stabs and FX hits.
- **Toggle**: one press starts it, the next press stops it.
- **Repeat**: while held, the clip retriggers at its quantization rate. Pair it with 1/16 for stutters and rolls.

### Legato Mode
- A Legato clip takes over the play position of the previous clip in the track. You can switch loops at any moment, even with quantization set to None, without losing sync.
- Use it for breaks: jump to an alternate loop and back.
- Gotcha: if the clips use different samples, you can hear dropouts, because Live can't preload the jump point. Turn on **Clip RAM Mode** for those clips.

### Launch Quantization
- **None**: launches are immediate.
- **Global**: follows the Control Bar setting.
- A fixed value overrides Global.
- **CMD+6, 7, 8, 9, 0** quickly change Global Quantization.
- Any value except None also quantizes launches made by Follow Actions.
- Below 1 bar, launching, nudging, or scrubbing can push a clip out of phase with the master clock.

### Velocity
- **Velocity Amount** sets how much MIDI note velocity scales the clip's volume.
- 0% = no effect. 100% = the softest notes are silent.

### Nudge and Scrub
- The **Nudge Backward/Forward** buttons jump the playing clip by one Global Quantization step.
- You can map them to keys or MIDI. In MIDI Map Mode, a scrub control appears between them. Map it to an endless encoder for continuous scrubbing.

### Follow Actions: controls
- Follow Actions launch another clip or scene automatically after the current one plays.
- A **group** = clips in consecutive slots of one track. An empty slot ends the group.
- Scenes have Follow Actions too (in Scene View).
- **Follow Action button**: off by default. Toggle it with **SHIFT+ENTER**.
- **Action A / B**, each with a **Chance**. Drag the slider between them to rebalance. The values are relative: A 100 / B 90 makes A fire only about 1 time in 10.
- **Linked/Unlinked** (clips only, Linked by default):
  - Linked: the action fires at the clip end, or after the loop count in the **Multiplier**.
  - Unlinked: the action fires after the **Follow Action Time**.
- **Follow Action Time**: in bars.beats.sixteenths from the play start (default 1 bar). You can drag its marker in the clip editor.
- Clips and scenes with Follow Actions show a striped launch button.

### The ten actions
- **No Action**: once it is picked, the other action can't fire, even at 100%. The clip just plays on.
- **Stop**: stops the clip after the Follow Action Time, even if it is looped.
- **Play Again**: restarts the clip.
- **Previous** / **Next**: play the clip above or below. Next wraps from the last clip to the first.
- **First** / **Last**: play the top or bottom clip of the group.
- **Any**: plays a random clip, which can be the same one.
- **Other**: plays a random clip but never repeats the current one.
- **Jump**: goes to a specific slot or scene number, set with the **Jump Target** slider (drag, or click and type).

### Timing and precedence gotchas
- Follow Actions ignore Global quantization but obey a clip's fixed quantization. With None or Global, they fire exactly at the Follow Action Time.
- The **Enable Follow Actions Globally** button (next to Back to Arrangement) turns all Follow Actions in the Set on or off. Turn it off to edit running clips without playback jumping away. It is grayed out if the Set has no Follow Actions.
- Scene Follow Actions take precedence once they fire. Clip Follow Actions keep running until then.
- **Create Follow Action Chain** (clip context menu) makes the selected clips play in a loop. The selection doesn't need to be contiguous.

### Recipes
- **Intro, then loop the tail**:
  1. In Arrangement, turn Loop off and **Edit > Split** at the loop point.
  2. Drag both pieces into adjacent Session slots (hover over the Session selector to switch views).
  3. On clip 1, set Time = clip length, A = Next at 100%, B = No Action.
  4. Turn Loop on for clip 2.
- **Cycles**: set every clip or scene to Next. Add Any at a low Chance for occasional surprises.
- **Temporary loop**: on a long sample, set Time = 1 bar, A = Play Again 80%, B = No Action 20%. Bar 1 repeats a few times, then the clip plays through.
- **Evolving parts**: put identical clips in Legato Mode and chain them with Follow Actions. Then slowly change each copy's notes or envelopes. The part morphs while staying in sync.
- **Random remixes**: make copies with different start/end points and envelopes. Set Time = the length you want to play, and use two actions with different Chances.
- **Generative/installation pieces**: odd Follow Action Times make the clips' order and phase never quite repeat.
