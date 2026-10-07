# Audio Effect Reference

Distilled from the Ableton Live 12 Reference Manual. Keys are macOS (CMD, ALT/OPTION, SHIFT, CTRL).

## Contents

- Live 12 Audio Effects: Amp to Delay (Manual 29.1-29.11)
- Live 12 Audio Effects, Part 2: Drum Buss to Reverb (operating reference)
- Live 12 Audio Effects: Roar to Vocoder (29.33-29.42)

## Live 12 Audio Effects: Amp to Delay (Manual 29.1-29.11)


### Amp

- **What:** Softube model of seven guitar amps. Use it for guitar and bass tone, or for analog grit on synths and drums.
- **Models:** Clean, Boost (edgy rock), Blues (bright), Rock (classic), Lead (modern high gain), Heavy (vintage high gain, grunge), Bass (fuzzy, deep low end). All models share one set of controls, so you can swap models fast.
- **Gain** is the main distortion control. **Volume** sets the output level, but on Blues, Heavy, and Bass, high Volume also distorts.
- **Bass/Middle/Treble/Presence** affect each other in a non-linear way. A boost can add distortion, and more Treble can take away lows and mids. Expect to adjust several knobs together.
- **Dual** (stereo) output uses twice the CPU.
- Put Cabinet after Amp for a realistic sound.

### Auto Filter

- **What:** analog-modeled multimode filter with an LFO, an envelope follower, and an external sidechain. Use it for sweeps, auto-wah, rhythmic filtering, DJ transitions, lo-fi, and vowel sounds.
- **Types:** LP, HP, BP, and Notch (12 or 24 dB). **Morph** (6-48 dB) sweeps LP to BP to HP. **DJ** puts LP and HP on one bipolar knob, and resonance grows toward the extremes. **Comb** gives a flanger effect when modulated. **Resampling** adds aliasing (it has no Res). **Notch+LP**. **Vowel** has Pitch and Formant (a-e-i-o-u) controls.
- **Circuits** (they apply to LP, HP, BP, Notch, and Morph only): SVF is clean. DFM has feedback drive. MS2 is a Sallen-Key design with soft-clipped resonance. PRD is a ladder filter with no resonance limit, so it gets wild.
- **Drive** saturates before the filter. **Clip** soft-clips resonance peaks. Use **Output** to compensate for level.
- **LFO:** separate L/R LFOs. Phase sets an offset in degrees, and Spin detunes the two rates. Steps and S&H quantization give stepped motion. Phase Offset works only in synced modes.
- **Envelope follower:** Attack, Release, Hold, and optional beat-quantized S&H. The bipolar Envelope knob sets depth and direction.
- **Sidechain** (toggle at top left): External source, with the tap point Pre FX, Post FX, or Post Mixer. Mix blends the external and internal triggers. SC Gain changes the trigger level only. Listen lets you hear the trigger. The SC filter makes it react to one band, for example a kick-keyed filter duck.
- **Gotcha:** the sidechain is mono by default. To get separate L/R envelopes, turn off "Mono Sidechain" in the context menu.

### Auto Pan-Tremolo

- **What:** LFO-driven panning, tremolo, gating, and ducking. You can fake sidechain pumping with no trigger.
- **Panning** (two LFOs) or **Tremolo** (one LFO). The two modes **share Amount and Rate**.
- **Time modes:** Rate, Time (100 ms-200 s), Synced, Dotted, Triplet, 16th. Phase or Spin sets the stereo offset (random waves use Phase only). In beat modes, Phase Offset moves the LFO against the grid.
- **Shape** at its extremes makes ramps. Invert off gives a **gate**, and Invert on gives a **pump or duck**.
- **Harmonic** (Tremolo) alternates the lows and highs around a fixed 600 Hz split. **Vintage** gives non-linear warmth.
- **Attack Time** leaves the transients alone, so they stay centered or punchy. **Dynamic Frequency Modulation** makes the input level change the LFO rate.

### Auto Shift

- **What:** real-time pitch correction for monophonic sources, mainly vocals. It also does formant shift, vibrato, an LFO, and MIDI-driven harmonies.
- **Pitch Range** (High, Mid, or Bass) must match the source for good detection, and the latency changes with each range. **Live Mode** gives lower latency for performance, but it can glitch on onsets.
- **Quantizer:** high Correction Strength with no Smooth gives the hard-tuned effect. Smoothing (0-200 ms) keeps the natural vibrato. Root/Scale or **Use Current Scale** follows the clip's scale. Pitch Shift here works in scale degrees after the correction.
- **MIDI mode:** a source track sets the target notes. Mono (with Glide) or Poly (up to 8 voices, for harmonies). Gotchas: it makes **sound only while notes play**, and it ignores scale awareness. To limit notes to a scale, put the Scale MIDI effect on the source track and tap Post FX. MPE and mod sources can route to Pitch, Formant, Volume, and Pan.
- **Formant Shift** changes the timbre without changing pitch. **Formant Follow** makes transposition sound natural.
- **LFO** (pitch, formant, volume, pan) and **Vibrato** (0-200 cents, 2-15 Hz, Natural option) work even with no correction. **Dry/Wet 50%** gives a doubler.

### Beat Repeat

- **What:** a tempo-synced slice repeater for stutters, glitch fills, and buildups.
- **Interval** and **Offset** set when it captures. **Chance** sets the probability. **Gate** sets the repeat length. **Repeat** captures right away (map it for performance).
- **Grid:** large slices give loops, and tiny slices give buzzy artifacts. **Variation** randomizes the grid (Auto is the most chaotic).
- **Pitch** works by resampling, so it smears the rhythm. **Decay** fades the repeats. There is a built-in band filter.
- **Mix modes:** Mix adds the repeats to the original. Insert mutes the original during repeats (classic stutter). Gate sends the repeats only (use it on a return).

### Cabinet

- **What:** Softube model of five guitar cabinets. Put it after Amp, or use it alone as a speaker-color filter.
- **Speaker** sets the size and count. **Mic:** Near On-Axis is bright, Near Off-Axis is resonant, and Far adds room. A dynamic mic is grittier, and a condenser is more accurate.
- **Dual** output uses twice the CPU.
- **Multi-mic trick:** put Cabinet in an Audio Effect Rack, duplicate the chain, give each chain a different mic, and balance them in the Rack mixer.

### Channel EQ

- **What:** a three-band EQ in the style of a mixing desk, for fast, musical tone shaping.
- **HP 80 Hz** switch. **Low:** 100 Hz shelf, ±15 dB. **Mid:** sweep from 120 Hz to 7.5 kHz, ±12 dB.
- **High** boosts as a shelf, but a cut also brings a low-pass down to 8 kHz, so the cut darkens the sound.
- Put Saturator after it to emulate a channel strip.

### Chorus-Ensemble

- **What:** a modulated-delay effect for thickening, flanging, and vibrato.
- **Chorus** uses two delay lines. **Ensemble** uses three lines for a richer, string-machine sound. **Vibrato** is pitch-only, and Feedback and Dry/Wet are disabled in it.
- In Chorus mode, a **fixed Delay Time** gives a stable chorus with no pitch wobble (good on bass and guitar). One tap gives a simpler pedal sound.
- The **HP filter** keeps the lows unmodulated. **Width** above 100% pushes the effect to the sides.
- **Feedback** adds flanging, and it keeps ringing after playback stops. **Warmth** adds crunch.
- **Recipe:** Ensemble at 1-1.8 Hz with 100% Amount gives surf guitar.

### Compressor

- **What:** a general-purpose compressor, expander, and sidechain ducker.
- **Threshold, Ratio, Knee:** Knee is a soft knee (the Transfer Curve view shows it). **Makeup** is **not available with an external sidechain**.
- **Warning:** more than about 6 dB of gain reduction changes the sound a lot. Be careful on the Main bus.
- **Attack** of 10-50 ms keeps the punch. A very short attack sounds lifeless or buzzy. A short release pumps. **Auto Release** adapts to the material.
- **Lookahead** of 0, 1, or 10 ms. Each setting sounds different.
- **Modes:** Peak (precise, for limiting), RMS (musical), Expand. **Lin/Log:** Log releases hard peaks faster and sounds smoother. The switch is **hidden in the collapsed view**.
- **Sidechain** (title-bar toggle): the trigger signal is never heard. The SC EQ makes it react to one band, and Listen lets you hear the trigger.
- **Recipes:** duck music under a voiceover. Duck the bass from the kick. With a full drum mix only, use a low-pass SC EQ to isolate the kick.

### Corpus

- **What:** an AAS physical-model resonator that makes the input ring like a struck object, for tuned percussion and metallic or wooden tones.
- **Types:** Beam, Marimba, String, Membrane, Plate, Pipe, Tube. Quality from Eco to High trades CPU for detail.
- **Timbre:** **Decay** sets the damping. **Material** goes from wood (highs die fast) to metal (highs ring). **Inharm** stretches the partials for a bell sound. **Hit** and **Pos L/R** set the strike and listening points. Pipe and Tube use Radius in place of Material, and they ignore several other controls.
- **Width** and **Spread** set the stereo image. **Bleed** brings back the dry highs. **Gain** has a built-in limiter.
- **MIDI sidechain:** Frequency lets a MIDI track play the pitch. **Off Decay** lets note-off damp the ring.
- **Gotcha:** lowering Dry/Wet only stops new input. Notes that are already ringing do not stop.

### Delay

- **What:** a stereo delay with a band-pass filter and an LFO, for echoes, ping-pong, tape warble, chorus, and glitch effects.
- **Sync** uses 16th-note buttons, with per-side **Offset** for swing. **Time** mode covers 1 ms-5 s. **Stereo Link** copies the time to both sides.
- **Feedback** has no cross-feed (use **Ping Pong** for that). **Freeze** loops the buffer and ignores new input.
- **LFO** (expand it with its toggle) modulates the delay time and the filter.
- **Smoothing:** **Repitch** (tape-style, default), **Fade** (granular), **Jump** (can click).
- **Hidden context menu:** **Hi-Quality** and **Equal-Loudness Dry/Wet**.
- **Recipes:** for glitch, use the S&H LFO with Fade. For chorus, unlink the sides at 12 and 30 ms, set feedback to 0, and use a Triangle LFO with Repitch and Ping Pong.

## Live 12 Audio Effects, Part 2: Drum Buss to Reverb (operating reference)

### Drum Buss
- All-in-one analog-style drum group processor: compression, distortion, transient shaping, and tuned low end.
- Order: Trim -> **Comp** (fixed, with auto makeup) -> Drive -> Soft, Medium, or Hard (clipping plus bass boost) distortion.
- **Crunch** distorts only the mid-highs (snare and hat bite). **Damp** is a low-pass that removes fizz after distortion.
- **Transients** (above 100 Hz): + gives punch with more sustain. - gives attack with less sustain (tighter, less room).
- **Boom** is a resonant low-end enhancer. **Force To Note** tunes it to the key. **Decay** sets the low-end length. Use the headphone button to solo it.

### Dynamic Tube
- Tube saturation with an envelope follower on Bias. Good for warmth or level-dependent dirt.
- Tubes: **A** is clean until a threshold, then bright. **C** always distorts. **B** sits between.
- **Bias** sets the intensity (high values break the sound up). **Tone** moves the distortion between highs and lows.
- **Envelope**: + makes loud parts dirtier, - cleans them up. Attack and Release do nothing at Envelope 0.
- Hi-Quality mode (title bar context menu) reduces aliasing for a little CPU.

### Echo
- Live's main creative delay: two lines plus filter, modulation, tape character, built-in reverb, and ducking.
- Modes: **Stereo**, **Ping Pong**, and **Mid/Side**. Times are synced (Notes, Triplet, Dotted, or 16th) or in ms. **Delay Offset** adds swing per side, even with Stereo Link on.
- **Modulation tab**: an LFO (6 waves) on delay time and filter. **x4** with short times gives deep flanging. **Env Mix** blends in an envelope follower.
- **Character tab**: input **Gate**, **Ducking** (the repeats drop while input plays, great on vocals), **Noise**/**Wobble** (vintage and tape), and **Repitch** (time changes bend pitch; with it off, they crossfade).
- The **Reverb** goes pre, post, or inside the feedback loop. **Stereo** goes above 100% for width. Dry/Wet has an **Equal-Loudness** option in its context menu.
- Gotcha: Echo turns itself off about 8 s or more after the input goes silent, unless both Noise and Gate are on.

### EQ Eight
- The main 8-band parametric EQ. Modes: **Stereo**, **L/R**, and **M/S** (the **Edit** switch picks the curve; use M/S to clean the sides' lows).
- Option-drag sets Q. Cuts are 12 or 48 dB/oct. Stack two identical bands for steeper slopes.
- **Adaptive Q** (analog-style). **Audition** solos a band. **Scale** scales all gains at once.
- Turn off unused bands to save CPU. **Oversampling** (context menu) smooths high-frequency filtering.

### EQ Three
- A DJ-mixer EQ with full kills (-inf to +6 dB). Use it for performance cuts. Map the band on/off buttons to keys.
- **FreqLo** and **FreqHi** set the crossovers. 48 dB is sharper and uses more CPU.
- Gotcha: it colors the sound by design, even at 0 dB in 48 dB mode. For linear behavior, use 24 dB or EQ Eight.

### Erosion
- Degradation from a short delay modulated by a sine and/or filtered noise (**Noise Blend**, 0-100%).
- X-Y pad: frequency on X, Amount on Y. **Filter Width** applies to noise only.
- Live 12.4: the device was updated. Older Sets load **Erosion Legacy**.

### External Audio Effect
- Inserts a hardware processor through the interface I/O (**Audio To** and **Audio From**). Watch the Gain and peak meters on both sides.
- Set **Hardware Latency** by hand: samples for digital connections, ms for analog. You can fine-tune in samples, but switch back to ms before you change the sample rate. It is disabled if Delay Compensation is off. **Invert** flips the return polarity.

### Filter Delay
- Three delays (L, L+R, R), each with its own X-Y band filter, which the feedback also passes through. Use it to echo only part of the spectrum.
- Feedback can run away. Set Dry to minimum on returns.

### Gate
- Mutes the signal below the threshold. Use it for noise, cutting tails, or rhythmic gating.
- **Return** (hysteresis) stops chatter. **Flip** passes only the quiet parts. **Lookahead** (0, 1, or 10 ms) fixes late opening, and each setting sounds different.
- A very short **Attack** clicks. **Floor** above -inf gives gentle expansion instead of a full mute.
- **Sidechain** (unfold): another track triggers the gate (a pad gated by a drum loop). It has a band-limited sidechain EQ and a listen button. The trigger audio is never heard.

### Glue Compressor
- Cytomic's model of an 80s console bus compressor. Its main use is glue on groups and the Main track.
- There is no knee control. The knee hardens as Ratio rises. **Auto release** uses a dual time constant. It is gentle, but slow on sudden changes.
- **Range** caps the gain reduction. -40 to -15 dB works as a parallel-style alternative to Dry/Wet.
- **Soft clip** is a colored waveshaper (-0.5 dB max), not a transparent limiter. The Clip LED turns red above 0 dB.
- **Oversampling** reduces harshness, but peaks can then pass 0 dB even with soft clip on.

### Grain Delay
- Granular delay and pitch for textures and glitches.
- **Frequency** sets the grain size and shapes how everything else sounds. **Spray** randomizes time (low smears, high gives rhythmic chaos). **Pitch** is a crude shifter. **Random Pitch**: low values give mutant chorus, high values make the pitch unintelligible.
- Any parameter can be put on the X-Y pad axes for performance. Feedback can run away.

### Hybrid Reverb
- Convolution plus algorithmic reverb, for real spaces, custom IRs, drones, and freezes.
- **Routing**: Serial (convolution feeds algorithm), Parallel (Blend balances the engines), or a single engine (Blend does nothing).
- **Convolution**: IR categories include Halls, Plates, Springs, Made for Drums, Textures, and more. Drag audio files or folders onto the display to add User IRs. Gotcha: User IRs are lost when you remove the device and add it again. Attack, Decay, and Size shape the IR.
- Every algorithm has Decay, Size, Delay, and **Freeze** / **Freeze In** (keeps adding input to the freeze). The algorithms:
  - **Dark Hall**: smooth classic halls (Damping, Mod, Shape, Bass X/Mult). Long Decay with tiny Size gives gongs.
  - **Quartz**: clear early reflections with echoes, for vocals and drums.
  - **Shimmer**: a pitch shifter in the feedback (Pitch, Shimmer amount). Diffusion below 10% gives dub delays on drums.
  - **Tides**: a modulated multiband filter on the tail (Wave, Tide, Phase, synced Rate).
  - **Prism**: bright velvet-noise "ghost" reverb. Small Decay and Size give an 80s gated snare.
- EQ tab: 4 bands. **Pre Algo** places the EQ before the algorithmic engine.
- Output: **Vintage** (lo-fi digital: Subtle to Extreme), **Bass Mono** (below 180 Hz), and Stereo above 100%.

### Limiter
- Mastering peak limiter. Put it last on Main, and keep the Main fader at or below 0 dB, because anything after it can add gain.
- **Ceiling** is the maximum output. **Maximize** turns it into **Threshold** (lowering it raises loudness), and Input becomes the Output target.
- **Release**: fast is punchier and louder, slow is smoother. **Auto** adapts it.
- **Lookahead** (1.5, 3, or 6 ms): shorter allows more limiting but distorts bass more. Longer catches fast peaks. More lookahead means more latency.
- **Ceiling Mode**: Standard, **Soft Clip** (color and punch), or **True Peak** (inter-sample safe; use it for release masters).
- **Routing**: L/R (more limiting, but the image shifts) or M/S (stable image, more latency). **Link** at 100% keeps the image stable. At 0% the channels limit independently (a creative wobble).

### Looper
- A looper pedal in a device: synced overdubs, tempo detection, and clip import/export.
- With the song running, Record, Overdub, Play, and Stop follow Quantization. With the song stopped, they act at once. **Undo** removes everything since Overdub was last enabled. **Clear** during a running overdub keeps the tempo and length. Clear anywhere else resets them.
- **Multi-purpose button** (map it to a footswitch): click to record, play, or overdub. Double-click stops. Hold for 2 s to undo, or to clear when stopped.
- **Tempo Control**: None, Follow, or **Set & Follow** (the first loop sets Live's tempo). With the song stopped, pick a bar count in **Record Length** first, or the tempo guess can come out half or double.
- **x2** duplicates the buffer, **÷2** halves it. **Song Control** can start or stop Live's transport.
- **Feedback** sets how fast old layers fade per overdub pass. It has no effect in Play.
- **Input -> Output**: Always (insert), Never (return), Rec/OVR (several pedal-controlled loopers), or Rec/OVR/Stop.
- Use "Drag me!" to export the buffer as a clip (set to Re-Pitch) or to import a bed.
- Feedback-routing trick: on a second track, set the top I/O to the Looper track and the bottom I/O to "Insert-Looper", set Monitoring to In, and add effects. Each overdub pass then gets reprocessed.

### Multiband Dynamics
- A 3-band compressor and expander, both upward and downward, with Above and Below thresholds per band (6 processes). Use it for mastering, de-essing, or reviving a mix.
- Above block down is downward compression. Above block up is upward expansion. Below block down is downward expansion. Below block up is upward compression.
- Drag a block edge to set the threshold and its body to set the ratio. Cmd applies to all bands.
- **Time** scales all envelopes. **Amount** scales all ratios (0% means no effect). RMS mode ignores very short peaks. Turn the Low and High bands off to make it single-band. Sidechain has no EQ.
- **De-ess**: use only the high band at about 5 kHz, with gentle ratio and fast times.
- **Uncompress**: lower Input, set the Above thresholds below the peaks, add a little upward expansion, and use fast attack for more transient impact. Don't put a limiter after it.

### Overdrive
- A pedal-style overdrive that keeps its dynamics when pushed. An X-Y band-pass before the distortion picks which band gets driven.
- Drive at 0% still distorts. **Tone** is post-distortion brightness. **Dynamics**: low values compress more as Drive rises, high values keep more dynamics.

### Pedal
- Guitar distortion types: **Overdrive** (warm), **Distortion** (tight and aggressive), and **Fuzz** (broken amp). It works on synths, drums, and vocals too.
- Gain at 0% still distorts. Start low, and put Utility before Pedal to lower the input further. Hi-Quality mode (context menu) reduces aliasing.
- Post-distortion adaptive EQ: Bass (100 Hz), Mid (500 Hz, 1 kHz, or 2 kHz), Treble (3.3 kHz shelf), and **Sub** (+ below 250 Hz). For precision, leave the EQ neutral and use EQ Eight.
- A compressor before Pedal evens it out. A resonant EQ before it gives screaming tones.
- **Techno kick**: Distortion with Sub on, Mid at 2 kHz for whack. **Drum fizz**: Fuzz with Bass and Mid at -100%, Treble at 100%, Output at -20 dB, then raise Dry/Wet slowly. **Sub warmer**: Overdrive with Sub and Bass up, then raise Gain.

### Phaser-Flanger
- Modes: **Phaser** (all-pass notches with Notches, Center, Spread, and Blend), **Flanger** (short modulated delay as a comb filter), and **Doubler** (bipolar modulated delay that thickens like a double-tracked take).
- Unfold it for the full LFO (includes stepped waves and S&H). **Spin** detunes the L/R rates. LFO2 and an envelope follower are also available.
- High **Feedback** can jump in volume quickly. **Ø** gives a hollow sound.
- **Safe Bass** is a high-pass (5 Hz-3 kHz) that keeps the lows clean. **Warmth** adds light grit.

### Redux
- Bitcrusher and downsampler.
- **Rate** sets the sample rate (lower means more aliasing). **Jitter** adds noise and width. The **Post filter** cuts imaging.
- **Bits** sets the bit depth. **Shape**: high values spare quiet detail. **DC Shift** adds volume and crunch at low bit counts.

### Resonators
- Five tuned parallel resonators that add pitch to drums, noise, or any input, from plucked strings to vocoder-like tones.
- An input filter (LP, BP, HP, or Notch) comes first. **Mode A** is realistic. **Mode B** suits a low Resonator I note.
- **Decay**: low notes ring longer. **Const** gives the same decay at every pitch. **Color** sets brightness. **Width** at 0% folds II-V to mono (II and IV get L, III and V get R).
- Resonator I sets the root. II-V are ±24 semitones relative to it. Live 12: **scale awareness** makes them scale degrees, and **tuning systems** are supported.
- A resonator that is turned off uses no CPU.

### Reverb
- Classic algorithmic reverb. It uses little CPU and is very adjustable.
- The **Input filter** (X-Y low and high cut) keeps mud out of the tail. **Early reflections Spin**: high rates give Doppler effects. **Shape**: high values give clarity, low values a smoother blend.
- **Diffusion network** shelves set the frequency-dependent decay. **Chorus** adds movement to the tail.
- **Predelay**: 1-25 ms sounds natural. **Size**: huge is a delay-like smear, tiny is metallic. Set **Smooth** to Slow or Fast before you automate Size, or it glitches.
- **Freeze** holds the tail. **Flat** stops the shelves from draining a frozen tail. **Cut** blocks new input from adding to it. **Stereo** goes up to 120°.
- **Density** (Sparse to High) trades CPU for richness.

## Live 12 Audio Effects: Roar to Vocoder (29.33-29.42)

### Roar
- Multi-stage saturator with routing, a mod matrix, a feedback loop and a compressor. Use it for anything from subtle warmth and drum crunch to mix-bus saturation, wavefolded synths, distorted delays, and pitched feedback.
- **Input:** Drive sets the level into all stages at once. Tone tilts the spectrum before the shapers (positive = fewer lows, so less mud on distorted bass). **Color Compensation** undoes the Tone tilt after the shaper. Negative Tone with it on saturates drums without losing low-end punch.
- **Routing:** Single, Serial (Blend: stage 1 to 1+2), Parallel (Blend crossfades two shapers; modulate it between contrasting curves), Multi Band (3 bands; drum buses and mixes), Mid Side (widen the sides, keep the center clean), Feedback (degrading delays, e.g. small Bias offsets), Delay (one distorted slapback from stage 1, long tails from stage 2's self-feedback).
- **Per stage:** Shaper Amount, Bias (asymmetry, "broken circuit"; extreme values go silent), Level (makeup gain), and a filter. **Pre** puts the filter before the shaper.
- **Shapers:** Soft Sine (warm even when pushed), Digital Clip (harsh), Bit Crusher (strong on quiet signals; likes Bias modulation), Diode Clipper (warm, darker), Tube Preamp (keeps transients), Half Wave Rectifier (drum crunch), Full Wave Rectifier (adds an octave up), Polynomial (metallic), Fractal/Tri Fold (bright to very harsh), Noise Injection (grit), Shards (rhythmically breaks up the signal).
- **Filters:** LP/BP/HP/Notch/Peak, Morph (LP to BP to HP), Comb (modulate it to flange), Resampling (Redux-style, no Resonance), Dispersion (spring-like smear).
- **Modulation** (open the panel with its toggle): 2 LFOs (synced or free, Morph, Smooth), an envelope follower (band-limited, Hold, Listen), Noise (Simplex/Wander = organic drift, S&H = stepped, Brown = hiss/crackle). In the Matrix, click a parameter to add it as a target and drag a cell to set depth. Global Amount scales all modulation; X clears it. The header toggle expands the view. Tip: have the envelope follow the snare and drive Shaper Amount or Dry/Wet.
- **Feedback:** Time/Synced/Triplet/Dotted (delay) or Note (rings at a pitch). Feedback runs through a band-pass. Invert flips its phase. **Gate** fades the feedback once input stops (off = it rings forever). The loop compressor ducks the feedback when the input is loud.
- **Global:** Compression (inside the feedback loop; the SC HP toggle stops lows from pumping it). Output Gain feeds a **hard clipper** before Dry/Wet.
- **Sidechain** (top-left toggle): external audio can trigger the envelope (Mix sets the external/internal blend; SC Gain only changes the trigger level). **MIDI > FB Note** sets the feedback pitch from MIDI. Gotcha: Feedback Mode and Amount are disabled while MIDI sidechain is on.

### Saturator
- Classic waveshaper for dirt, punch and warmth; simpler and lighter than Roar.
- **Curves:** Analog Clip (soft knee) and Digital Clip (hard) stay linear below the clip point. Soft Sine, Medium, and Hard shape the tone differently. Sinoid Fold is a wavefolder. **Bass Shaper** gives smooth harmonics on heavily driven 808s and basslines; its Threshold (0 to -50 dB) goes from soft clipping (low values, best with high Drive) to hard. **Waveshaper** adds 6 controls in the expanded view: Drive, Curve (3rd harmonics), Depth/Period (sine ripples), Linear, Damp (an ultra-fast gate).
- **Post Clip** Soft/Hard keeps the output under the Output level. Use it to catch boosts from negative Color settings.
- **Color:** an EQ applied before the shaper and inverted after it, which changes *what* saturates. Negative Amt Lo keeps the bass clean but full; Amt Hi/Freq/Width target a band.
- Context menu: **Hi-Quality** (less aliasing, slightly more CPU) and **Pre-DC Filter**. Set Dry/Wet to 100% on returns.

### Shifter
- Pitch shifter, frequency shifter and ring modulator with delay, LFO, envelope follower and MIDI control.
- **Modes:** Pitch (st/cents; long Window for lows, short for highs), Freq (Hz; small values phase, large ones sound metallic), Ring (adds and subtracts Hz; **Drive** only here).
- **Wide** shifts L and R in opposite directions by the Spread amount (no effect at Spread 0). Optional Delay with Feedback; Tone darkens the feedback path.
- **LFO:** 10 shapes; Phase, Spin (detunes L/R rates) or Width (random shapes). **Envelope follower** Amount is in st (Pitch) or Hz (Freq/Ring).
- **MIDI mode** (unfold via the title-bar triangle): pitch or frequency follows a MIDI track, with Glide and PB.
- **Recipes:** a duplicated drum track with Pitch mode, Delay on and automated Coarse gives metallic echoes; Freq mode with Fine under ~2 Hz at 50% mix gives phasing; Ring mode under ~20 Hz gives tremolo (Wide plus small Spread for stereo).

### Spectral Resonator
- Applies tuned resonant partials to the input. Use it for pitched drums, MIDI-played vocoder-like effects, and reverb-ish washes. Scale-aware, supports tuning systems and MPE.
- **Internal** (fixed Freq in Hz or as a note) or **MIDI** (from any MIDI track; route a hardware controller via a MIDI track). Poly gives 2-16 voices with MIDI Gate forced on. MIDI Gate on = rings only while notes are held. Glide works in Mono only.
- **Use Current Scale** turns Freq/Transp into SD Shift (scale degrees).
- Stretch spaces the partials (100% = odd only, square-like). **Shift transposes the input**, not the resonator. Decay goes from percussive to drone. HF/LF Damp track pitch.
- **Mod modes:** Chorus (triangle; at Rate 0 it modulates amplitude only), Wander (random saw), Granular (random decaying grains; Rate = density). Pch. Mod sets the depth.
- **Harmonics** (in the display): more = brighter and **more CPU**, and they are split across voices in poly. **Quantize** snaps partials to the scale.
- Input Send has a limiter (LED). Unison/Uni. Amt thicken (very dense with Wander/Granular). Set Dry/Wet to 100% on returns.
- **Tips:** MIDI-drive a drum loop to make it tonal; Convert Melody/Harmony to MIDI to follow audio pitch; for reverb, use a low Freq, high Unison, slow Wander, and Decay as the tail; chain two with different MIDI.

### Spectral Time
- Spectral freezer plus spectral delay. Use it for infinite sustain, stutter-freezes, smeared and spiralling metallic echoes.
- **Freezer** (the Freeze button must be on): Manual (click, Fade In/Out), or Retrigger by **Onsets** (Sensitivity) or **Sync** (Interval in ms or beats). Fades: Crossfade (X-Fade = % of the interval) or Envelope (stacks up to **8 freezes**).
- **Delay:** Time in ms, notes, or 16th counts. Feedback. **Shift** frequency-shifts each repeat. **Tilt** delays highs (+) or lows (-) more. **Spray** randomizes delay per frequency. **Mask** limits Tilt/Spray to the highs or lows. Stereo widens them. The delay's own Dry/Wet affects only the delay.
- Order: Frz > Dly (default) or Dly > Frz.
- **Latency:** high **Resolution** = better fidelity but more latency, so lower it while tracking. Context menu **Zero Dry Signal Latency** gives live players a latency-free dry path, at the cost of dry/wet alignment.

### Spectrum
- Analyzer only; does not change the audio. Block and Refresh trade accuracy for CPU. Avg 1 catches transients; higher values are smoother (closer to how we hear).
- Scale X: linear (best for detail in the highs), log, or semitone (log scale labeled with notes). Max holds the peak (click to reset). Range/Auto sets the dB view. Double-click to move it into the main window.

### Tuner
- Mono pitch meter for hardware synths and instruments; does not change the audio. Needs a clean, single-pitch source; chords, noise and harmonically rich sounds read poorly.
- Classic view (Target: sharp = right of the circle; Strobe: the band spins right when sharp, faster the further off) or Histogram (pitch over time). Hz/Cents switch. Right-click for note spellings. Reference 410-480 Hz.

### Utility
- Gain, phase, width, mono and mute anywhere in a chain.
- Per-channel phase invert. Channel Mode Left/Right puts one side on both outputs (this disables Width).
- **Width:** 0% = mono, >100% = wider. The context menu **Mid/Side Mode** gives a knob from 100M (mono sum) to 100S (sides only).
- **Bass Mono** (50-500 Hz) plus **Audition** keeps the low end mono-safe.
- **Gain** (-inf to +35 dB): automate fades here and keep the fader for mixing.
- **Mute** before a reverb or delay cuts its input while the tail rings (the track mute always acts at the end of the chain).
- **DC** filter: audible only if nonlinear devices come after it.

### Vinyl Distortion
- Lo-fi record emulation: groove distortion plus crackle.
- **Tracing Model** = even harmonics. **Pinch** = odd harmonics, out of phase between L and R (wider). Each has an X-Y pad (vertical = drive, horizontal = frequency, Option-drag = Q).
- Drive scales both. Soft = dub plate, Hard = standard vinyl. Set Pinch to stereo for realism. Crackle: Density plus Volume.

### Vocoder
- Not in Intro/Lite. Puts the modulator's envelope (voice, drums) onto the carrier's spectrum. Use it for talking synths, robot voices, and formant shifting.
- **Insert it on the modulator track.** Carrier: **External** (another track; classic robot voice), **Noise** (X-Y pad: downsampling and density), **Modulator** (self-resynthesis), or **Pitch Tracking** (a mono oscillator follows the voice. Set the High/Low range. It holds the last clear pitch, so it is erratic on chords and drums, and resets such as grouping the track cause jumps).
- **Clarity:** use saw-rich carriers, **Enhance** (fixes dull external carriers), and **Unvoiced** noise for sibilants (Sens. 100% = always on).
- **Filterbank:** Bands (more = more accurate, more CPU), Range (trim if piercing or boomy), BW (100% = most accurate), Precise or Retro (narrower and louder up high), Gate. Click the band display to attenuate bands.
- Depth: 100% = classic, 200% = only peaks pass. Very fast Attack/Release keeps transients but can distort. **Formant** shifts the carrier bands (changes apparent gender).
- **Robot voice:** Carrier External, Audio From = the synth track **Post FX**, arm both tracks if live, solo the vocal track. **Formant shifter:** Carrier Modulator, Depth 100%, Enhance on, then sweep Formant.
