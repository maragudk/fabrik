# Routing and I/O, Mixing, Recording

Distilled from the Ableton Live 12 Reference Manual. Keys are macOS (CMD, ALT/OPTION, SHIFT, CTRL).

## Contents

- Chapter 17: Routing and I/O
- Chapter 18: Mixing
- Chapter 19: Recording New Clips

## Chapter 17: Routing and I/O

### In/Out section
- Show or hide it with CTRL+ALT+I, View > Mixer Controls > In/Out, or the mixer view-control menu at the bottom right.
- Per track: **From** pair (input), **Monitor** buttons, **To** pair (output).
- Each pair has a **Type** chooser (Ext. In, Resampling, a track, No Input, Sends Only) and a **Channel** chooser (hardware channel, tap point, device input, MIDI channel).
- Changes apply to every selected track.
- Return tracks are fed by their sends. MIDI tracks without an instrument have no audio out.

### Monitoring
- **Auto**: you hear the input when the track is armed and no clips are playing. Use it for most recording.
- **In**: you always hear the input, and the clips are muted. It makes the track an "Aux" for live inputs or a monitor/FX track. The Activator turns blue.
- **Off**: use it for acoustic sources, an external console, or your interface's direct monitoring. When you record with Off, set Overall Latency in Settings > Audio.
- **Keep Monitoring Latency in Recorded Audio** (on by default with In/Auto) lines up the recording with what you heard. Toggle it by right-clicking In or Auto.
  - Keep it on for software instruments and effects. Turn it off for acoustic sources or external monitoring.
- Reset: select tracks and press Delete (or Edit > Return to Default). Audio tracks go to Off and MIDI tracks to Auto.

### External audio
- Input Type **Ext. In**, then pick the channel. The meters show signal, and red means overload.
- Enable channels and set mono or stereo pairs in Settings > Audio > Input/Output Config. You can also reach it from "Configure..." in the chooser.
- You can rename channels there (Tab moves to the next one). The names are saved per audio device.
- A mono input records mono files, but the device chain is always stereo.
- Routing to a mono output sums L+R at -6 dB.

### External MIDI
- Input: a port or **All Ins**, then a channel or **All Channels**.
- Port switches are in Settings > Link, Tempo & MIDI:
  - **Track**: notes and CCs. Turn it on for input to play or record notes or CCs, including hardware knob moves. Turn it on for output to drive hardware or other apps through a virtual bus.
  - **Sync**: MIDI Clock in/out, Timecode in. Controllers rarely need it.
  - **Remote**: mapping and launching clips (input), LED or motor-fader feedback (output).
- **Sync output options** (the triangle next to the port):
  - **MIDI Clock Sync Delay** (ms) fixes timing offsets with hardware.
  - **Clock Type**: **Song** sends SPP + Continue, **Pattern** sends Start only, at the next bar. Use Pattern if the device ignores SPP.
  - **Hardware Resync** enables a Control Bar **Resync External Hardware** button for drifting gear. Choices: Stop and Start (default), Start Only, Don't Resync.
- **External synth**: set Output Type to the synth's port and Output Channel to its MIDI channel. Or use **External Instrument** for MIDI out and audio return in one track.
  - A keyboard synth used as both controller and sound source needs **Local Off**.
- **Control Bar MIDI LEDs** (upper = in, lower = out): Sync (only shown when sync is on), Remote, Track.
  - Gotcha: MIDI that is mapped to a control never reaches the tracks. Check the LEDs when notes go missing.

### Computer MIDI keyboard
- Toggle it with **M**.
- The home row (A S D F...) plays white keys from C3, and the row above plays black keys. Z/X shift the octave, and C/V change velocity in steps of 20.
- In the C3-C4 range, the keys match the Impulse slots, so you can drum on the keyboard.
- Gotcha: it takes over single-letter shortcuts. Use SHIFT (for example SHIFT+S to solo) or turn it off.

### Resampling
- Set an audio track's Input Type to **Resampling** to record the Main output.
- Uses: new samples from the mix, committing CPU-heavy chains, quick previews.
- Mute or solo the sources and keep the Main meter below red. Then arm the track and record into an empty slot.
- The recording track's own output is not captured.
- Files go to Project/Samples/Recorded after you save. Before that, they stay in the Temporary Folder.

### Track-to-track routing
- **A Output Type -> B**: many-to-one (submixes, several MIDI tracks on one instrument). Soloing B still lets you hear its feeders.
- **B Input Type <- A**: one-to-many (layering, tapped recording). A is not changed.
- **Tap points** (B's Input Channel):
  - **Pre FX**: before devices and the mixer.
  - **Post FX**: after devices, before the fader and pan.
  - **Post Mixer**: the final output.
  - Soloing B lets you hear the tapped signal with Pre FX and Post FX, but **not** with Post Mixer.
- **Rack taps**: every chain of an Instrument or Effect Rack, and every Drum Rack return chain, shows as "Rack | Chain | Pre FX/Post FX/Post Mixer". Post Mixer is taken before the chains are summed.
- MIDI tapped from a track is taken after its MIDI effects, just before the instrument.

### Recipes
- **Record through effects**: a Guitar track holds the gate or amp and is set to Monitor **In**. Recording tracks take input from its **Post FX** (or **Post Mixer** to keep level and pan), with Monitor **Off**.
- **MIDI to audio**: an audio track takes input from the instrument's MIDI track. Use it for evolving patches that are easier to edit as audio.
- **Submix**:
  - Route the tracks to a submix track, or make a Group Track (it routes automatically and can be collapsed).
  - Or set Output Type to **Sends Only** and use a return track as the bus.
- **Several MIDI tracks, one instrument**: set Output Type to the instrument track and Output Channel to **the instrument's name**, not "Track In". This skips the target's record and monitor stage.
  - To mute the clips separately, move them to their own track.
  - Set the instrument-only track's input to **No Input** to hide its Arm button.
- **Multi-output instruments**: an audio track takes input from the instrument track and picks one output (for example an Impulse slot).
  - Impulse removes a tapped slot from its own mix. Most plug-ins don't.
- **Multi-timbral plug-ins**: feed each part from a MIDI track with Output Type set to the host track and Output Channel set to the part's MIDI channel. Tap each output with an audio track.
  - Or use one **External Instrument** per part: MIDI To = host track + channel, Audio From = an auxiliary output. These can share one track inside a Rack.
  - The plug-in's main outs always play through the host track.
- **Plug-in sidechain**: set the source track's Output Type to the effect's track and Output Channel to the plug-in's sidechain input (for example speech into a vocoder on strings).
  - Put vocoders with a built-in synth on a MIDI track.
  - Live's built-in sidechain devices have their own routing choosers.
- **Layering**: a second instrument track takes MIDI input from the first track (Post FX).

## Chapter 18: Mixing

### Showing the mixer
- **Show or hide it** with the mixer view control at the bottom right of the window. Its drop-down, or **View > Mixer Controls**, toggles sends, returns, crossfader, Track Options (Track Delay), and Performance Impact.
- **Detailed meters:** drag the mixer's top edge upward to add tick marks, a numeric volume field, and resettable peak holds. Widen the track as well to get a dB scale.

### Channel strip
- **Meter:** shows peak (transients) and RMS (perceived loudness). While the track is monitoring, it shows the *input* level.
- **Pan** (right-click to change mode):
  - *Stereo Pan* (default) works like a balance control.
  - *Split Stereo Pan* gives independent L and R sliders, which is useful for narrowing a wide source.
  - To reset, double-click the knob or click the triangle above it. Panning changes the audio; it is not neutral.
- **Track Activator** mutes the track.
- **Solo:** click it or press **S**. Solo is exclusive; hold **CMD** to add tracks, or turn off *Exclusive Solo* in Settings > Record, Warp & Launch.
- **Arm** works the same way (*Exclusive Arm*). With that option on, dropping an instrument on a new or empty MIDI track arms it automatically.
- **Multi-selection:** changing a control on one selected track changes it on all of them, and the level differences between them are kept.

### Headroom
- Live's engine is 32-bit floating point, so tracks can go over 0 dB internally without clipping. Overs matter only where audio leaves Live: hardware I/O, the **Main** track, and exported or rendered files. Watch Main and your exports.

### Tracks
- **CMD+T** creates an audio track; **CMD+SHIFT+T** creates a MIDI track. Dropping a browser item or clips into the empty area beside or below the tracks creates the right track type. Dropped clips also bring a copy of the source track's devices.
- **Rename:** press **CMD+R**, then **Tab** to move to the next track. A `#` in a name becomes an auto-updating track number, and `##` adds zero padding. Use **Edit Info Text** to add notes.
- **Select:** SHIFT-click selects a range; CMD-click picks nonadjacent tracks. Dragging nonadjacent tracks collapses them together, so move them with modifier+arrow keys to keep the gaps (the manual names Ctrl).

### Group Tracks
- **Create:** select tracks, then **Edit > Group Tracks** (**CMD+G**). The same command nests groups. **Ungroup Tracks** reverses it.
- **Deleting a group deletes all its contents**, so ungroup first.
- Groups hold no clips but have a full mixer strip and can host audio effects, so they work as submix buses.
- **Routing:** grouped tracks auto-route to the group, unless they were already routed somewhere other than Main. To use a group only as a folder, re-route the tracks inside it.
- **Unfold** shows or hides the tracks inside. A folded Arrangement group shows an overview of its clips.
- **Session group slots** launch or stop all clips in the group for that scene, and clicking a slot selects those clips.
- **Recolor:** right-click the header > *Assign Track Color to Grouped Tracks and Clips*. This affects only the current view's clips.
- A half-lit Solo button means a track inside the group is soloed.

### Returns and sends
- **Put shared effects (reverb, delay) on a return** so many tracks can feed one instance. Add one with **Create > Insert Return Track** (**CMD+ALT+T**). Show or hide returns via View > Mixer Controls > Return Tracks.
- **Pre/Post** (one per return):
  - *Post* (after the track's volume, pan, and activator) is the normal setting.
  - *Pre* taps the signal before them, for an independent aux or monitor mix, such as a performer's headphone mix on a separate output.
- **Return-to-return sends (feedback)** are disabled by default. Right-click the send > *Enable Send* or *Enable All Sends*.

### Main track
- The **Main track** (formerly Master) is the single default destination for every track. Put mastering-style processing here, such as bus compression, EQ, and a limiter.

### Crossfader
- **DJ-style crossfader** that fades between any number of tracks, returns included.
- **A/B assign per track:**
  - With neither on, the crossfader does not affect the track.
  - With A on, the track is at full level on the left half, fades past center, and is silent hard right. B is the mirror image.
- **It works as a gain stage, like a VCA, not as routing.**
- **Curves:** right-click the crossfader to choose one of seven.
- **MIDI mapping:** the slider maps to absolute or relative MIDI controllers. Its left, center, and right positions can each be mapped to keys:
  - One mapped key toggles the fader between hard left and hard right.
  - Two mapped keys give a snap-back: hold one, tap the other.
- **Automation:** for the fader, choose Main > Mixer > Crossfade. For a track's assignment, choose Mixer > X-Fade Assign.

### Solo and Cue
- **Default solo** mutes the other tracks; outputs and panning are kept.
- **Solo in Place** (Solo context menu, or set as the default in the Options menu) keeps returns audible, so a soloed sound keeps its reverb.
- **Cue mode** (DJ-style headphone preview) needs at least four outputs (two stereo pairs). Show the mixer and In/Out sections, then on the Main track:
  1. Set **Main Out** to the speakers.
  2. Set **Cue Out** to a different pair. Check Settings > Audio if outputs are missing.
  3. Set the **Solo/Cue switch** to *Cue*. Solo buttons become headphone Cue buttons, and the Track Activator still controls what reaches Main.
  4. Use **Cue Volume** to set the headphone level.
- Browser previews also play through Cue Out.

### Track Delay
- **What it does:** delays the whole track, or pulls it earlier with a negative value, to correct player, mic-distance, or hardware timing.
- **Where it is:** View > Mixer Controls > Track Options, or Arrangement Track Controls > Track Options. A toggle switches the units between ms and samples.
- **Gotchas:**
  - Changing it during playback can click, so don't adjust it live.
  - For Session clip offsets, use the clip's Nudge buttons instead.
  - Track Delay is **unavailable when device delay compensation is off**.
  - Large values or high-latency plug-ins can make Live sluggish.

### Keep Monitoring Latency in Recording
- **What it does:** on by default for In and Auto monitoring. It aligns the recording with what you heard through Live.
- **Keep it on** for software instruments and recording through effects. **Turn it off** for acoustic sources or external (direct) monitoring.
- Change it with the toggle, or right-click the In or Auto button.

### Performance Impact
- **Per-track six-segment CPU meters**, shown from the Mixer Controls menu.
- **To reduce CPU load,** freeze the heaviest track or remove devices from it.

## Chapter 19: Recording New Clips

### Setup
- Mics, guitars and turntables need a preamp (interface or external).
- **Input:** View > In/Out (unfold the track in the Arrangement). The default is mono input 1/2 for audio and all MIDI inputs for MIDI. You can also pick a stereo input, a MIDI channel or another track. The computer MIDI keyboard works without hardware.
- **Settings > Record, Warp & Launch:** File Type, Bit Depth and default Warp Mode. Set the Warp Mode to suit your usual material.
- **Storage:** `<Project>/Samples/Recorded`. Before the first save, files go to the Temporary Folder (Settings > File/Folder). Keep it on a drive with free space.

### Arming
- Click a track's Arm button. The Session and Arrangement share the same tracks.
- One click disarms all other tracks. Hold **CMD** to arm several. If several tracks are selected, clicking one Arm button arms them all.
- Armed tracks auto-monitor by default (you can change this). Supported control surfaces lock to the armed instrument.
- Use the Arrangement to record many tracks on a timeline. Use the Session for gapless clips or to record while you launch clips.

### Arrangement Recording
- Arrangement Record creates clips on all armed tracks. With **Start Playback with Record** on (Record, Warp & Launch), recording starts at once. With it off, recording waits for Play or a clip launch. **SHIFT**-click does the opposite of the setting.
- **MIDI Arrangement Overdub:** merges new notes into existing MIDI. It works on MIDI only.
- **Punch-In / Punch-Out:** recording only happens between the Arrangement Loop start and end. This protects other material and gives you a pre-roll.
- **Loop recording:** every pass goes into one long sample. Press CMD+Z to undo passes, or double-click the clip and drag the loop brace left in the Sample Editor to hear earlier passes.

### Session Recording
1. Set Global Quantization to any value other than None, so clips cut cleanly.
2. Arm the tracks. Clip Record buttons appear in their empty slots.
3. **Session Record** records into the selected scene on all armed tracks. Press it again to go straight into loop playback. Or click one slot's Clip Record button, then that clip's Launch button to go to playback.
4. To stop, use Clip Stop or the Control Bar Stop.
- **New** stops armed tracks and selects an empty scene, or creates one, for the next take. It is only available through Key Map or MIDI Map.
- Launching a scene does not record into its empty armed slots unless **Start Recording on Scene Launch** is on.

### MIDI Overdub Pattern Building
1. Set Global Quantization to 1 Bar, and set Record Quantization if you want it.
2. Double-click an empty MIDI slot to create a one-bar clip. Change its length in Clip View.
3. Arm the track and press Session Record. Notes are added on each loop pass.
4. Press Session Record to switch between overdub and playback. Use playback to rehearse with nothing recorded.
- **ALT**+double-click an empty slot creates the clip, arms the track and launches the clip.
- Undo removes the last take.

### Step Recording (Transport Stopped)
- Arm the track, turn on **Preview** in the MIDI Editor, then click to place the insert marker.
- Hold notes and press **Right Arrow**. The marker moves one grid step and writes the held notes. Press it again while holding to make them longer. **Left Arrow** while holding deletes them.
- You can MIDI-map the step arrows, for example to foot pedals so both hands stay on the keys.

### Record Quantization
- Edit > Record Quantization snaps MIDI to the grid as you record.
- **Arrangement:** quantization is a separate Undo step. Undo removes only the quantization and keeps the raw take.
- You cannot change the setting during a recording.
- **Gotcha:** in a looping overdub, a change takes effect at once and you cannot undo it separately.
- To quantize after recording, use Edit > Quantize.

### Metronome and Count-In
- The Control Bar switch turns the metronome on. The mixer's **Preview Volume** knob sets its level.
- Open the settings from the dropdown next to the switch, or right-click the switch.
  - **Count-In:** recording waits until the count-in ends. The Control Bar shows it in blue, counting from a negative position (e.g. -2.1.1 for 2 bars) up to 1.1.1.
  - **Sound:** changes the tick sound.
  - **Rhythm:** sets the tick division. Auto follows the time-signature denominator. Divisions that do not fit a bar are disabled. The metronome falls back to Auto when a meter change makes the division stop fitting.
  - **Enable Only While Recording:** the metronome sounds only while recording, and after the punch-in point when Punch-In is on.

- **Sync:** recordings follow later tempo changes. Slow down for a hard part, then speed back up. Warp Markers fix timing or feel afterwards.

### Capture MIDI
Live always listens on armed or monitored MIDI tracks. The Control Bar's **Capture MIDI** button turns what you just played into a clip. On Push 1 and 2, use Record+New. Push 3 has a Capture button.
- Clips go only into the view that has focus, on each monitored MIDI track.
- **Empty Set, transport stopped:** Live detects the tempo and sets it, always within **80-160 BPM**. Fix it by hand if needed. Live sets the loop, quantizes to the grid and starts playback, ready for overdubs. End your phrase on the next bar's downbeat to help detection. A single note sets the loop to that note's length, with a tempo that gives a 1-, 2-, 4- or 8-bar loop. This is handy for one-note rhythmic samples.
- **Existing Set** (transport running, other clips, or tempo automation): Live keeps the tempo and only finds a phrase to loop. Play over a playing clip on the same track, then press Capture to add your notes to it.
- Every note is kept. Notes before the phrase sit before the start marker, so you can move the markers. Right-click > **Crop Clip** removes material outside the loop.

### Remote Control
- Key Map and MIDI Map can map record, transport, Arm, Session Record, New, slots, scene up/down and the step arrows. Example: one key for the next scene, another to start and stop recording on a track.
