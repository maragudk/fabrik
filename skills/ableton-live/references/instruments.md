# Instrument Reference

Distilled from the Ableton Live 12 Reference Manual. Keys are macOS (CMD, ALT/OPTION, SHIFT, CTRL).

## Contents

- Live 12 Instruments, Part 1 (Analog to Meld)
- Live 12 Instruments: Operator, Sampler, Simpler, Tension, Wavetable

## Live 12 Instruments, Part 1 (Analog to Meld)

### Analog

- **What it is:** Virtual-analog subtractive synth (with AAS). It models circuits in real time, with no samples or wavetables, so it does not alias. Good for warm vintage polys, brass, leads and basses. Uses more CPU than Drift.
- **Routing:** Osc 1, Osc 2 and Noise each have an **F1/F2** slider that splits them between Filter 1 and Filter 2. Each filter feeds its own Amp. Filter 1's **To F2** makes the chain serial. Four **Quick Routing** buttons set parallel, split, single or serial routing without touching the oscillators.
- **Oscillators:** Sine, saw, rect (Pulse Width and LFO PWM) or noise. Detune goes to ±300 cents. Each has a **Pitch Env** (Initial and Time) for zaps and blips.
- **Sub/Sync:** Sub is an octave-down square, or a sine for a sine oscillator. Sync has a **Ratio**; map the mod wheel to it for sync sweeps.
- **Osc Key:** Scales pitch tracking around a fixed C3. Set slightly off on one oscillator, the detune grows away from C3.
- **Filters:** 2nd/4th-order LP, BP, notch and HP, plus formant (Reso sweeps vowels). Filter 2 **Follow** tracks Filter 1's cutoff and its Freq knob becomes an offset. **Drive** has Sym, Asym or Off. Cutoff and Reso each take LFO, key and envelope modulation.
- **Envelopes:** Four ADSRs, one per filter and amp. Extras:
  - **S.Time** makes sustain sink while held.
  - **Free** is a trigger mode for percussion.
  - **Loop**: AD-R and ADR-R repeat while held, for rhythmic envelopes. ADS-R replays attack and release on note-off, which mimics dampers.
- **LFOs:** Two, with sine, tri, rect and noise shapes, plus Delay and Retrig. **Gotcha:** LFO amount sliders elsewhere stay greyed out until that LFO is on.
- **Global:** Vibrato (pitch LFO with Delay and mod-wheel amount), Unison (2 or 4 voices), Glide (Const or Prop), Stretch tuning, voice Priority.
- **MPE:** The MPE switch in Global gives Pressure and Slide (two destinations each) and a Note PB range.

### Collision

- **What it is:** Physical-modeling mallet percussion (with AAS). Good for marimba, vibes, glockenspiel, bells and plates, or unreal metallic or glassy hits and bowed textures.
- **Signal flow:** **Mallet** and **Noise** exciters feed two stereo resonators, which set most of the character.
- **Mallet:** **Stiffness** (soft is dull and long; hard is bright and short), **Noise** (felt "chiff"), Color.
- **Noise exciter:** Filtered noise with an ADSR. Long envelopes give washy, quasi-granular, bowed or crystal-glass sounds.
- **Resonator types:** Beam, Marimba, String, Membrane, Plate, Pipe, Tube.
- **Decay and Material:** They share an X-Y pad. Low Material sounds like wood or nylon (the lows ring); high sounds like glass or metal (the highs ring). Pipe and Tube use **Radius** in place of Material.
- **Inharm:** Positive values stretch the partials, which sounds bell-like; negative values compress them.
- **Hit:** Strike position; **Rnd** varies it per note.
- **Note Off:** 0% ignores note-off, like a real marimba; 100% mutes the note at release.
- **Bleed:** Adds dry exciter to restore highs.
- **Quality:** Eco to High trades overtones for CPU.
- **Structure:** **1 > 2** (serial; Res 1 is summed to mono into Res 2) is the realistic setup, where a mallet strikes a bar (Res 1) and a tube amplifies it (Res 2). **1 + 2** (parallel) suits hybrids. Copy buttons clone a resonator.
- **Modulation:** Two LFOs (two destinations each; they can modulate each other). The MIDI/MPE tab routes PB, per-note PB, mod wheel, pressure and slide to two targets each. Key and Vel sliders sit on most parameters. Velocity on Stiffness and Noise is the expressiveness lever.
- **Gotchas:** The idealized resonators can jump in level, so keep the output low while you experiment. Switch off unused sections and use **Retrig** to save CPU.

### Drift

- **What it is:** Lightweight, fully MPE-capable subtractive synth with a simple interface. The default for fast, low-CPU analog patches: basses, plucks, leads, pads.
- **Oscillators:** Osc 1 adds **Shark Tooth** (based on a Moog shape) and **Saturated** (good for bass). **Shape** is a PWM-like timbre control with its own mod source. **Gotcha:** Shape Mod still alters the wave when Shape is 0%. Osc 2 has Oct and Detune in semitones. Two Pitch Mod slots; an LFO in **Ratio** mode gives FM tones.
- **Mixer:** Gain above the default -6 dB drives the pre-filter saturation, and above 0 dB the post-filter saturation too, for analog grit. **R** resets phase per note.
- **Filter:**
  - LP **Type I**: 12 dB DFM-1, drive fed back internally.
  - LP **Type II**: 24 dB Cytomic MS2, soft-clipped resonance.
  - Also Res, Key tracking, a separate HP cutoff, and two cutoff mod slots.
- **Envelopes:** Env 1 is the amp envelope. Env 2 is a mod ADSR that can switch into a **Cycling Envelope**: a per-note looping shape with Tilt and Hold.
- **LFO:** Nine shapes, including Wander (smoothed S&H) and one-shot decay shapes, plus a mod source for its amount.
- **Mod section:** Three free slots, with sources including Key, Velocity, Modwheel, Pressure and Slide.
- **Voice modes:** Poly (up to 32 voices); **Mono** (four voices per note blended in with Thickness; Legato and Glide work only here); **Stereo** (two voices, panned by Spread); **Unison** (four detuned voices). The Voices setting caps total voices, so 32 gives 16 notes in Stereo and 8 in Unison.
- **Drift knob:** Per-voice random pitch and cutoff (analog wobble).
- **MPE:** Pressure and Slide are mod sources. **Note PB off** stops MPE finger position from bending the pitch.

### Drum Sampler

- **What it is:** A one-shot sample player built for Drum Rack pads. Quick per-hit shaping and lo-fi tricks without Simpler's depth.
- **Sample:** Start and Length (Shift-drag for fine control). **AHD** envelope; Hold set to **inf** plays the whole sample. **Trigger** mode ignores note length; **Gate** mode decays on release and disables Hold.
- **Similar Sample Swapping:** Hover over the waveform for next and previous similar-sample buttons, to audition alternatives fast.
- **Playback Effects:** One at a time, with two parameters on knobs or an X/Y pad:
  - Stretch (granular lo-fi), Loop, **Pitch Env** (808 and tom drops), **Punch** (transient ducking), 8-Bit, FM, Ring Mod, **Sub Osc** (30-120 Hz), Noise.
  - Frequency and time controls follow note pitch. FM and Ring Mod decay with the global Decay, so a short Decay affects only the transient.
- **Modulation:** One slot. Velocity or Slide (MPE) drives Filter, Attack, Hold, Decay, or an effect parameter.
- **Context-menu options:**
  - Per-note PB (on by default).
  - **Envelope Follows Pitch** keeps the envelope on the same part of the sample when transposed.
  - **Drum Sampler > Simpler** converts and keeps Start and Length.
- **Tip:** Right-click a Drum Rack pad and choose **Save as Default Pad** to load new samples into Drum Sampler.

### Electric

- **What it is:** Physical-modeling 1970s electric piano (with AAS). Good for tine keys, bell tones and driven pickup sounds. Extreme settings give new metallic keys.
- **Hammer:** **Stiffness** (harder is brighter) and **Force**, both with Vel and Key amounts. Velocity on Force gives dynamics. Noise adds impact noise.
- **Fork:** Tine **Color** sets the partial balance. Tine and Tone Decay set sustain while held. A shared **Release** sets the decay after key release.
- **Pickup:**
  - **Symmetry**: 50% is the brightest.
  - **Distance**: closer is more overdriven.
  - **Type**: R (electro-dynamic) or W (electro-static).
  - Low Input with high Output sounds clean; high Input with low Output sounds driven.
- **Damper:** Damper noise level, with **Att/Rel** placing it at note-on, note-off or both.
- **Global:** **Stretch** tuning (sharp highs and flat lows, as pianos are tuned) sounds more brilliant. Note PB range for MPE. Each voice costs CPU, so lower **Voices** if CPU is tight.

### External Instrument

- **What it is:** A routing device, not a sound source. It sends MIDI to a hardware synth or a multitimbral plug-in on another track and returns the audio to this track.
- **MIDI To:** A MIDI port and channel, or another track's plug-in and channel.
- **Audio From:** Interface inputs for hardware. For a plug-in, only its **auxiliary** outputs; the plug-in's main outputs still play on its own track.
- **Hardware Latency:** Compensates for delay Live cannot detect. Use **samples** for digital links and **ms** for analog links. If you fine-tune in samples, switch back to ms before you change the sample rate. The slider is disabled for internal routing (Live compensates by itself) and when Options > **Delay Compensation** is off.

### Impulse

- **What it is:** Legacy 8-slot drum sampler with per-slot velocity or random modulation. Fine for quick kits; Drum Rack is more flexible.
- **Mapping:** Slots map to C3 through C4; remap with the Pitch or Scale MIDI effect.
- **Per-slot controls:**
  - **Stretch**: Mode A for low sounds, Mode B for cymbals.
  - **Drive** on low sounds gives overdriven analog drums; lower the volume to compensate.
  - Decay up to 10 s in **Trigger** or **Gate** mode; Gate gives variable-length hats.
- **Link** on slot 8 makes slots 7 and 8 choke each other, like closed and open hats.
- **Global:** **Time** morphs stretch and decay for all slots.
- **Gotcha:** Parameter changes, including automation and clip envelopes, apply only from the **next note**. Use Simpler for sweeps within a note.

### Meld

- **What it is:** Dual-engine "macro oscillator" synth. It covers analog basics, swarms, FM and noise or texture generators (rain, bubbles, crackle). Good for expressive, scale-aware, unusual sound design.
- **Per engine (A and B):**
  - An oscillator with **two macros** that change with the oscillator type.
  - A filter with two macros.
  - Amp and Mod envelopes and two LFOs.
  - A Modulation Matrix with MIDI and MPE tabs.
  - Volume, Pan and a **Tone Filter** (positive cuts lows, negative cuts highs).
- **Engine controls:** Turning an engine off also turns off its filter. **Expanded View** shows all modulation.
- **Oscillators (24):** Analog shapes, Swarms (**Spacing** fades into chords), four FM types, Chip, **Shepard's Pi** (Rate 50 is static; below falls, above rises), noise and texture types, and **Chord** (four saws; follows the current scale, or major from the root if no scale is set).
- **Scale awareness:** **Use Current Scale** turns semitones into scale degrees. In the Settings tab you can make Dual Basic Shapes, the Swarms and Chip follow the scale, and also the Plate and Membrane Resonator filters.
- **Filters (17):**
  - SVF 12/24: the L-B-H-N macro morphs LP, BP, HP and notch.
  - MS2 LP and HP (soft clip); OSR band-pass (hard clip).
  - Lo-fi and drive types (Filther, Redux), plus Phaser, Vowel and Comb.
  - Plate and Membrane modal resonators.
  - Most filters have **Q** and **Drive** macros; Drive is applied before the filter.
- **Envelopes:** ADSR with slopes and loop modes: Trigger (ignores sustain), Loop, AD Loop. The Mod envelope adds Initial, Peak and Final levels. **Link Envelopes** makes the engines act as one instrument.
- **LFOs:** **LFO 1** has Basic Shapes, Ramp, Wander, Alternate, Euclid and Pulsate, each with two macros, and two serial FX slots (18 types). **LFO 2** is a classic LFO. LFO 1, LFO 1 FX and LFO 2 are three separate matrix sources.
- **Matrix:**
  - Click a parameter to add it, then drag its cell.
  - **Gotcha:** a negative amount on an envelope or LFO time makes it **faster**. Some targets add the modulation, others multiply by it.
  - Sources: velocity, pitch, per-note random, PB, pressure, mod wheel, and MPE note PB, slide and pressure. Without a controller, draw them in clip envelopes.
- **Settings tab:** **Osc Key Tracking off** holds the engine at C3 (or the scale root), for drones and percussion. Phase Reset and Spread. **Glide**: Porta or **Gliss** (stepped, in scale degrees when scale-aware). It works in Mono and Poly, but only with Glide Time above 0.
- **Output:** **Limit** is a per-voice limiter applied after the engine mix and Drive. Use it when both engines are loud. Mono/Poly switch, with Legato in Mono.

## Live 12 Instruments: Operator, Sampler, Simpler, Tension, Wavetable

### Operator

- **One line:** a 4-operator FM synth that also does subtractive and additive synthesis. Use it for bells, e-pianos, digital and sub basses, metallic plucks, and synthetic kicks, hats, and snares.
- **Architecture:** 4 oscillators (A-D), 1 LFO, a filter with a waveshaper, and 7 envelopes (one per oscillator, plus filter, pitch, and LFO).
- **Algorithms:** 11 fixed routings, chosen in the Global display. Signal flows top to bottom: an operator above another one modulates it, and the bottom row is what you hear. Side-by-side layouts are additive; a single chain gives the most complex FM. You can automate the algorithm.
- **What shapes FM timbre:**
  - **Modulator Level**: higher is brighter and noisier.
  - **Coarse ratio**: whole numbers sound harmonic. **Fine** offsets sound inharmonic, like bells or metal.
  - **Modulator envelope**: a short decay gives a pluck or tine.
  - **Feedback**: self-modulation for grit. It works only on operators that nothing else modulates.
- **Waveforms:** Sine (the FM default), Sine 4/8 Bit (retro), Saw D and Square D (digital bass), resynthesized Saw, Square, and Triangle (the number in the name is the harmonic count; lower is mellower and aliases less), and noise. "User" lets you draw partials. Export it as `.ams`, which Simpler and Sampler also load.
- **Fixed mode:** the oscillator ignores note pitch (Freq x Multi, down to 0.1 Hz). Use it for drums and for timbre that changes while the pitch stays constant.
- **Velocity:** put Vel on a *modulator's* level for velocity-dependent brightness. Osc < Vel shifts pitch by velocity; turn on **Q** for harmonic steps.
- **LFO:** effectively a fifth oscillator. Ranges are Low (50 s-30 Hz), Hi (8 Hz-12 kHz), or Sync. Dest A switches send it to each oscillator's pitch and to the filter; Dest B adds one target. Waves include S&H and noise. The manual's tip: **the noise LFO is the key to FM hats and snares.**
- **Envelopes:** each has 3 rates and 3 levels. Only the filter and pitch envelopes have slopes and an End level. Loop modes:
  - **Loop**: retriggers at sustain. It can run fast enough to work as an LFO.
  - **Beat**: repeats at a beat value, without quantizing.
  - **Sync**: snaps to 1/16 and locks to tempo. It works only while the transport runs.
  - **Trigger**: ignores Note Off. Use it for percussion.
- **Trick:** a looping pitch envelope sent only to the LFO becomes a second LFO on its rate.
- **Filter (shared by Sampler, Simpler, Wavetable):**
  - Types: LP, HP, BP, Notch, and Morph (sweeps LP > BP > HP > Notch), at 12 or 24 dB.
  - Cytomic circuits: **Clean** (the EQ Eight filter; cheap), **OSR** (hard-clipped resonance), **MS2** (soft clip), **SMP** (hybrid), **PRD** (ladder; resonance not limited). MS2, SMP, and PRD are LP/HP only.
  - **Drive** appears for LP, HP, and BP on any circuit except Clean.
  - Right-click Freq > **Play by Key** sets Freq < Key to 100% and cutoff to 466 Hz.
  - The manual says to try FM *without* the filter first.
- **Aliasing:** **Tone** reduces aliasing but darkens the sound.
- **Global:** up to 32 voices; 6-12 is realistic. **Voices = 1** gives automatic legato. A MIDI matrix routes Velocity, Key, Aftertouch, Pitch Bend, and Mod Wheel to 2 targets each.
- **Spread:** 2 detuned voices panned left and right. It is read at Note On, so you can sequence it per note. It is **CPU-heavy**.
- **To save CPU:** turn off the filter, LFO, and pitch envelope when unused. Reduce voices. Turn off Interpolation and Antialias. Gotcha: **turning off oscillators saves no CPU.**
- **Per-note pitch bend (MPE)** is on by default (title-bar menu).

### Sampler

- **One line:** a deep multisample instrument. It has zones, round robin, an FM/AM modulation oscillator, 3 LFOs, an aux envelope, and MIDI routing. Use it for realistic sampled instruments or heavily modulated single samples. It streams large libraries from disk.
- **Edition:** Sampler is not in every Live edition. Use **Sampler -> Simpler** in the title bar to share presets. **REX import needs Standard or Suite.**
- **Zone editor:** each sample is a layer with three ranges:
  - **Key zones**: a new import covers the whole keyboard by default. Drag zone corners to crossfade; Lin/Pow sets the curve.
  - **Velocity zones** (1-127): dynamic layers.
  - **Sample Select zones** (0-127): a selector that does not depend on MIDI, like Rack Chain Select. Use it for articulation switching. It does not change a note that is already playing.
  - Layer-list context menu: **Distribute Ranges Around Root Key** is the fastest way to map pitched samples.
- **Round Robin (RR):** layers that share a key zone take turns. Order is Forward, Backward, Other (random, never the same twice in a row), or Random. **Reset Interval** (for example, 1 bar) restarts the cycle so each bar is the same. Use it to humanize repeated hits.
- **Sample tab (applies to the selected layer):**
  - Sustain loop (forward or back-and-forth), and release that stays in the loop, plays to the end, or uses a release loop.
  - Loop **Detune** fixes pitch drift in short loops.
  - **Snap** uses only the left channel, so stereo files can still click; add crossfade.
  - **Reverse** is global and can be modulated; it writes no file.
  - Interpolation set to Good or Best costs a lot of CPU. **RAM mode** helps when you modulate start and end, but uses RAM.
- **Pitch/Osc tab:**
  - **Modulation oscillator**: FM or AM on the sample. You never hear it directly. Use it to make samples metallic or ring-modulated.
  - Spread: 2 voices at double the CPU.
  - **Key Zone Shift**: picks samples from other zones at the played pitch. Use it for artifacts.
  - Glide (mono) or Portamento (poly).
- **Filter/Global tab:**
  - The shared filter. Its envelope needs a non-zero Amount to have any effect.
  - **Shaper** (Soft, Hard, Sine, 4bit), placed before or after the filter.
  - The volume envelope can loop. **Retrigger** saves CPU on fast repeats with long releases.
- **Modulation tab:**
  - **Aux envelope** with 2 destinations, and **3 LFOs** with Attack for delayed vibrato.
  - LFO 1 has fixed Vol, Pan, Filter, and Pitch sliders. LFOs 2 and 3 route freely and add **stereo** modulation: Phase offset, or Spin (the right channel runs up to 50% faster).
- **MIDI tab:** Key, Velocity, **Release Velocity**, Aftertouch, Mod Wheel, Foot, and Pitch Bend each go to 2 targets (for example, Velocity > Loop Length). Pitch bend reaches up to 24 st.
- **Imports:** drag REX, ACID, or Soundtrack files into a Set; they land in User Library/Sampler/Imports.

### Simpler

- **One line:** a single-sample instrument with a basic synth voice and **Live's warping**. It is the default for one-shots, chopping breaks, quick melodic sampling, and loops that must stay in tempo.
- **Loading:** a dragged clip keeps its region and warp markers.
- **Playback modes (the key decision):**
  - **Classic** (default; polyphonic): pitched instruments. It has full ADSR and Loop. Start and Length are percentages of the region between the flags. **Snap** (zero crossings; left channel only) and **Fade** hide loop clicks. Very short loops turn granular or pitched but can be heavy on CPU, especially with Complex warp. **Retrig** cuts repeated notes.
  - **One-Shot** (always mono): drums and phrases. It has no loop. **Trigger** plays the full sample no matter how long you hold the key; **Gate** fades out on release. It has Fade In and Fade Out.
  - **Slicing:** one slice per chromatic note. Slice By:
    - **Transient**: Sensitivity sets the count, up to 64.
    - **Beat**: by a beat division.
    - **Region**: equal parts.
    - **Manual**: double-click to add a slice.
    - Drag a slice to move it; double-click to delete it. Alt/Option-click turns an auto slice into a manual one, which survives Sensitivity changes.
    - Playback is Mono, Poly, or **Thru** (plays on to the end of the region).
- **Warp:** with Warp on, the sample plays at the Set tempo on any note, using the same modes as audio clips. "Warp as X bars" fixes the length; use ÷2 and ×2 when Live guesses wrong. With Warp off, pitch and speed are linked.
- **Synth section:**
  - The shared filter (cutoff modulated by Vel, Key, Env, or LFO).
  - ADSR envelopes for amp, filter, and pitch. The pitch envelope is good for percussive drops. The **amp envelope can loop** (Loop, Trigger, Beat, Sync) for rhythmic gating.
  - A per-voice LFO with depth sliders for Volume, Pitch, Pan, and Filter. Offset does nothing unless Retrigger is on.
- **Global:** C3 plays the original pitch. Pitch bend is fixed at **±5 st**. **Gain** comes before the filter; **Volume** is the final output.
- **Easy-to-miss context menu items:**
  - **Slice to Drum Rack** and **Slice to New MIDI Track**. The second also creates a clip that plays the slices in order.
  - Non-destructive **Crop** and **Reverse**.
  - **Simpler -> Sampler**. Warp and slicing are lost, so the result sounds different.
  - Linear loop fades. Gotcha: **Fade is not available while Warp is on.**
- **CPU:** Complex and Complex Pro warp are expensive. 24 dB costs more than 12 dB. **Stereo costs about twice as much as mono.** Reduce Voices and keep Spread at 0 when unused.

### Tension

- **One line:** a physical-modeling string synth (made with AAS) that uses no samples. Use it for plucked, struck, and bowed strings, pianos, dulcimers, e-pianos with a pickup, and odd hybrids. It supports **MPE**.
- **Chain:** Exciter > String (with Damper, Termination, Vibrato) > Pickup > Filter > Body. Every section except String and Keyboard has its own switch. **Turning a section off saves CPU.**
- **Exciters:**
  - **Bow** (Force for scratchiness), **Hammer** (piano), **Hammer (bouncing)** (dulcimer), and **Plectrum**. All share Velocity, Position, and Damping.
  - **Fix. Pos** on suits guitar, where the pick position is constant. Off suits piano, where hammers strike at about 1/7 of the string length.
- **Damper:** a high damper Velocity makes a loud thump on release. Damping above about 50% makes the damper bounce, which gives *longer* decay.
- **String:** Decay, Ratio (release shorter than onset), **Inharm** (out-of-tune upper partials, for metallic or piano-wire tones), and Damping (high frequencies).
- **Other sections:** Pickup Position (low is bright and thin). Body type and size (bigger = lower resonance). Vibrato with **Error** for random variation.
- **Filter/Global tab:**
  - Filter types LP, BP, Notch, and HP (2nd or 4th order), plus **Formant**, where Res sweeps through vowels. The filter has its own ADSR and LFO; their sliders do nothing until those subsections are on.
  - **MPE**: Pressure and Slide each route to 2 targets. You can set the global and per-note pitch bend ranges.
  - **Keyboard**: **Stretch** tuning gives brighter pianos.
- **Gotchas:** the sections interact like parts of one physical object, so many settings give **silence**. If you hear nothing, check that Exciter or Damper is on. Others get **extremely loud**. Learn the instrument by studying the presets.

### Wavetable

- **One line:** two wavetable oscillators, a sub, two Cytomic filters, and a modulation matrix. It is the modern all-rounder for evolving pads, supersaws, growling basses, and leads, and it is easy to start with.
- **Oscillators:**
  - **Wave Position** is the main control; modulate it for movement.
  - The output is **band-limited, with no aliasing, until you add modulation**.
  - **Drag any WAV or AIFF** onto the display to use it as a wavetable. **Raw** mode skips the cleanup; use it for files made as wavetables, or for glitches.
- **Oscillator effects:**
  - **FM**: Tune ±50% is 1 octave and ±100% is 2 octaves; values in between are inharmonic.
  - **Classic**: PW, which works on any table, and hard Sync.
  - **Modern**: Warp and wave**Fold**.
- **Sub:** Tone at 0% is a pure sine; it can drop 1 or 2 octaves.
- **Filters:** the shared filter types and circuits. Routing:
  - **Serial**: F1 into F2.
  - **Parallel**: both oscillators into both filters.
  - **Split**: Osc 1 into F1, Osc 2 into F2. Use it for layered sounds. If a filter is off, its oscillator still plays.
  - The sub feeds both filters in every routing.
- **Matrix:**
  - Sources are columns and targets are rows. **Click any parameter** to add it; it stays only if you give it modulation.
  - **The Matrix and MIDI tabs share the same rows.**
  - Additive targets sum the sources (0 is neutral). **Multiplicative** targets multiply (1 is neutral, 0 is the minimum). These include Volume, Sustain, Initial, LFO Amount, Unison Amount, and the matrix Amount.
  - Global **Time** scales all modulators (negative is faster). **Amount** scales all modulation.
- **Mod sources:**
  - 3 envelopes with slopes. Loop mode turns one into a custom LFO.
  - **2 LFOs** with a **Shape** control (skew, symmetry, pulse width, or random distribution), plus Sync, Attack, Retrigger, and Offset. Offset cannot be modulated.
- **MIDI tab:** Velocity, **Note** (centered on C3; at 100% to Filter Freq it tracks the key exactly), Pitch Bend, Aftertouch, Mod Wheel, and **Random** (a new value per note).
- **Global:**
  - Poly or Mono. **Glide works only in Mono**, and Mono gives legato envelopes.
  - Unison modes: **Classic** (even detune), **Shimmer** (reverb-like jitter), **Noise** (breathy), **Phase Sync** (phaser sweep), **Position Spread** (spreads the wavetable position), and **Random Note**.
  - Voices sets the thickness and Amount sets the depth.
- **Hi-Quality** (context menu): when off, modulation updates every 32 samples and the filters run in low-power versions, saving up to 25% CPU. **Off by default since Live 11.1**, but older Sets and user presets load with it on. Turn it on for fast, precise modulation, and expect slight differences in sound.
