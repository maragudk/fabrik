# Max for Live and Bundled Devices

Distilled from the Ableton Live 12 Reference Manual. Keys are macOS (CMD, ALT/OPTION, SHIFT, CTRL).

## Max for Live and Its Bundled Devices (Live 12 Manual, Ch. 32-33)

### 32. Max for Live

**What it is for**
- Max for Live (M4L) embeds Cycling '74's Max inside Live. Use it to build instruments, audio/MIDI effects, modulators and MIDI Tools (clip Transformations/Generators). It can also script the Set or extend control surfaces through the Live API.

**Editions and setup**
- M4L comes with **Suite**, or with **Standard plus the M4L add-on**. Intro and Lite do not have it. Max is bundled, so there is nothing extra to install.
- To use a different Max version, set its path in **Settings > File & Folder** and **restart Live**.

**Where devices live**
- Bundled devices are in the browser under Instruments, Audio Effects, MIDI Effects and **Modulators**. Modulators are devices that drive other parameters.
- The **Max for Live** browser label lists all M4L content: bundled devices, third-party Packs, your saved devices and M4L MIDI Tools.

**Editing and creating devices**
- New device: drag **Max Instrument**, **Max MIDI Effect** or **Max Audio Effect** into a track. The audio template is `plugin~` → `plugout~`.
- To open the patcher, choose **Edit in Max** from the title bar's context menu or Show Options menu. Before 12.2 this was an Edit button. Add `-MaxForLiveDeveloperMode` to `Options.txt` to restore it.
- To save, use Max's File menu:
  - **Save** updates every instance of the device in the Set.
  - **Save As** asks whether to update only this preset or all instances.
- Devices save as **.amxd** files in the matching User Library folder (Max Audio Effect, Max MIDI Effect and so on).
- **Gotcha:** the Set only references the .amxd file. If you move or rename the file, the Set breaks. Keep the default location, and use **File Manager** to repair missing devices.

**Building M4L MIDI Tools**
- Start from the **Max MIDI Transformation** or **Max MIDI Generator** template in the Clip View's Transform/Generate tabs, or edit an existing tool. Then click **Edit**.
- Save to one of these default paths, or to any folder in **Places**:
  - `~/Music/Ableton/User Library/MIDI Tools/Max Transformations`
  - `~/Music/Ableton/User Library/MIDI Tools/Max Generators`
- **Gotcha:** a tool saved anywhere else is not indexed and does not appear in the Transform/Generate menus.

**Dependencies and learning**
- A device can need samples, images or sub-patches. **Freeze** the device in Max to bundle them into it. This is not the same as Live's Freeze Track.
- To learn Max, see Help > Reference > Max for Live (includes the MIDI Tools guide) or the **Building Max Devices** Pack.

### 33. Max for Live Devices

Granulator, Convolution Reverb, Color Limiter and similar devices ship as Packs rather than in the core device set, so they are not covered here.

#### Drum Synths (instruments)
- Light one-shot drum synths for Drum Rack pads.
- Every DS device has:
  - **Pitch/Tune**, **Decay** (length) and **Volume**.
  - Tone/Color sliders: a higher value gives a brighter sound.
  - Audition: click the upper half of the display.
- **DS Kick:** a modulated sine wave.
  - Pitch is set in Hz. **Env** sets the pitch-envelope depth.
  - **Drive** adds distortion and **OT** adds overtones.
  - **Attack** softens the start. **Click** sharpens the transient.
- **DS Snare:** an oscillator plus noise.
  - **Color** sets the oscillator tone. **Tone** sets the amount of noise.
  - The noise filter can be LP, HP or BP.
- **DS Clap:** noise and an impulse through panned delays.
  - **Sloppy** sets how loose the claps are, for a humanized feel.
  - **Tail** adds a noise tail.
  - **Spread** sets the width, from mono to wide.
- **DS HH:** noise plus sine, from closed hats to open hats.
  - Choose white or pink noise.
  - The pitched part goes through a resonant HP filter with a 12 or 24 dB slope and an **Attack** control.
- **DS Cymbal:** sine/pulse waves plus HP noise, from ride to crash.
- **DS Tom:** an impulse plus oscillators.
  - **Bend** sets the pitch envelope.
  - **Tone** sets band-pass "membrane" resonances.
- **DS Clang:** cowbell and clave.
  - Set the two tones with **Tone A/B** and add **Noise**.
  - Turn on **Clave** to get **Repeat** flams.
- **DS FM:** a classic Japanese FM style, for noise bursts and metallic lasers.
  - **Feedb.** adds noise and **Amnt** sets the FM depth.
  - **Mod** blends modulation types.
  - Tone is a low-pass filter.

#### Modulators: shared mapping model
LFO, Shaper, Envelope Follower, Envelope MIDI and Shaper MIDI all work like this:
- **Mapping:** click **Map**, then click any automatable device or mixer parameter. **Multimap** gives **up to 8 targets**. **Unmap** clears a target.
- **Mod mode** (the default):
  - You can still move the target's base value by hand.
  - **Bipolar** moves around the base value. **Unipolar** moves in one direction from it.
  - **Modulation Amount** sets the depth for each target.
- **Remote Control mode:** the modulator owns the parameter, so you cannot move it by hand. **Min/Max** set the range.
- Common controls:
  - **Depth/Amount:** global depth.
  - **Offset:** moves the center point.
  - **Jitter:** adds randomness.
  - **Smooth:** removes jumps.
  - **Rate:** in Hz or synced.

#### Modulators: audio-effect slot
- **LFO:** periodic movement, such as filter sweeps, tremolo, auto-pan and wobble.
  - Nine waves: Sine, Up, Down, Triangle, Square, Random, Bin, Stray and Glider.
  - **Shape** skews the wave. It is disabled for Random, Bin, Stray and Glider.
  - **Steps** adds up to 24 steps. It is disabled for Random, Bin and Square.
  - Rate is in Hz (with **×10**) or synced.
  - **Phase** sets the start point and **R** retriggers to it. **Hold** freezes the output.
- **Shaper:** a breakpoint envelope that you draw, for custom rhythmic or one-off movement.
  - Click to add a point. Option+drag curves a segment. Shift+click deletes a point.
  - Use **Grid/Snap** to align points. There are six preset shapes, and **Clear** removes the envelope.
  - Modes: **Loop** (runs at Rate), **1-Shot** (fires from the mappable **T** button) and **Manual** (you scrub through it, which is useful for macro control).
  - **Gotcha:** R is disabled when Rate is synced.
- **Envelope Follower:** turns input level into a control curve. Use it for auto-wah, ducking and dynamics-driven effects.
  - **Gain** sets the input level. **Rise/Fall** smooth the curve. **Delay** offsets it in time or beats.
  - **Sidechain** (triangle panel): choose a source track and a tap point (Pre FX, Post FX or Post Mixer).
  - **Sidechain Mix:** 0% uses only the track input and 100% uses only the external source.
  - Example: key it from a Drum Rack to pump any parameter.

#### Modulators: MIDI-effect slot (note-triggered)
- **Envelope MIDI:** an ADSR triggered by each note. Use it to add envelopes to effects or to devices that do not have them.
  - Modes:
    - **Free:** triggers on every note.
    - **Sync:** retriggers at a beat division.
    - **Loop:** cycles at Global Time.
    - **Echo:** repeats, set by Echo Time and Feedback.
  - **Global Time** scales the envelope length (1.00 is unchanged). **Slope** curves the A, D and R stages.
  - **Velocity** scales the peak level.
  - Turn **Sustain** off for one-shot behavior.
- **Shaper MIDI:** a breakpoint envelope that each note retriggers.
  - Cmd+click sets one **sustain point**, where the envelope holds while the note is held.
  - **Velocity** sets how much velocity scales the depth.
  - **Loop** repeats the envelope while the note is held and ignores the sustain point.
  - **Echo/Time** add decaying repeats.
- **Expression Control:** maps MIDI and MPE expression to any parameter, with 5 source tabs.
  - Sources: Velocity, Modwheel, Pitchbend, Pressure, Keytrack, Expression, Random, Increment, Slide and Sustain.
  - Each source has a linear or S-curve, Min/Max and X-Y breakpoint controls, and Rise/Fall smoothing (0-1000 ms).
  - **Increment** steps through the range over 1-32 notes. Stopping the transport resets it.
  - **Random Amount** sets the random deviation for each note.

#### MIDI utilities and effects
- **MPE Control:** reshapes MPE data. Press, Slide and NotePB each get their own curve and smoothing.
  - Bridges an MPE controller to non-MPE instruments:
    - **Press to AT:** pressure becomes channel aftertouch.
    - **Slide to Mod:** CC74 becomes CC1.
    - **NotePB to PB:** per-note pitch bend becomes global pitch bend.
  - Slide modes:
    - **Abs:** uses the absolute finger position.
    - **Rel:** starts at mid-range wherever the finger lands.
    - **Ons:** updates only at note-on, and turns off smoothing.
  - **Centered** is for pads: the center of the pad gives zero.
  - **Swap to Slide** sends poly aftertouch to Slide.
  - **Default** sets the value used for non-MPE notes.
  - **Pitch Range** (for example 2x) fixes mismatched bend ranges.
- **Note Echo:** a MIDI delay that adds echo notes with decaying velocity.
  - **Sync** sets the time in 16ths, and the % field adds swing. With Sync off, the time is in ms.
  - **Mute** plays only the echoes.
  - **Pitch** transposes each repeat, which makes arpeggio-like trails.
  - **Fback** sets how many repeats you get.
  - With **MPE** on, it also echoes Press, Slide and NotePB, each with its own feedback.
- **MIDI Monitor:** shows what a controller or MIDI chain actually sends.
  - **Note:** keyboard view with velocity and chord names.
  - **Flow:** a stream of notes, pitch bend and aftertouch, with Freeze and Clear.
  - **MPE:** per-note data.

#### Audio utility
- **Align Delay:** delays the signal by time, samples or distance.
  - **Time** (ms): A/V sync or Haas-style widening.
  - **Samples:** manual latency compensation.
  - **Distance** (m or ft): PA alignment. Set the room temperature (°C or °F) for accuracy.
  - **Link L/R:** the left channel's delay controls both channels.
