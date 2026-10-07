# Accessibility, Keyboard Navigation and Shortcuts

Distilled from the Ableton Live 12 Reference Manual. Keys are macOS (CMD, ALT/OPTION, SHIFT, CTRL).

## Chapters 41-42: Accessibility and Keyboard Navigation; Live Keyboard Shortcuts

Key notation (macOS): CMD = Command, ALT = Option, SHIFT, CTRL = Control. "+" joins keys pressed together.

### Keyboard navigation model and accessibility (Ch. 41)

- **Focus jumps:** ALT+0 Control Bar, ALT+1 Session, ALT+2 Arrangement, ALT+3 Clip View editor, ALT+4 Device View, ALT+5 Browser, ALT+6 Groove Pool, ALT+7 Learn View, ALT+8 selected clip panel, ALT+SHIFT+P clip panels. These *move focus*. CMD+ALT+3/4/6/7 *show/hide* the same views.
- **Tab is overloaded.** By default Tab toggles Session/Arrangement. Turn on **Use Tab Key to Move Focus** (Navigate menu or Settings > Display & Input) and Tab/SHIFT+Tab then step through controls. ALT+Tab / ALT+SHIFT+Tab moves to the "neighbor" control: the same control on the next track in the mixers. If a user says "Tab doesn't switch views anymore", this option is on.
- **Wrap Tab Navigation** makes Tab cycle back to the first control in an area instead of stopping.
- **Move Clips with Arrow Keys** is on by default: left/right arrows *move* selected clips or time selections in Arrangement. Turn it off in Display & Input if clips keep moving by accident. With it off, the arrows collapse the selection to its start or end.
- **Esc** moves focus from a track element back to its title bar, cancels value entry, and closes Settings and dialogs.
- **Settings** (CMD+,): Tab moves between options whether or not the focus option is on. Up/down arrows or Enter change values. ALT+Tab switches settings pages. A UI language change needs a restart.
- **Screen readers:** VoiceOver works with most views. Not supported: browser tagging and filters, MPE editing, Max for Live, Wavetable's Mod Matrix, some Operator parameters, audio fade editing, and some plug-ins. Options > Accessibility toggles announcements (Speak Menu Commands, Min/Max Slider Values, Time in Seconds). Info View help text is spoken if VoiceOver verbosity has help text on, or on demand with VO+SHIFT+H.
- **Keyboard envelope editing** (Arrangement automation lanes and the clip Envelope Editor): arrows move the insert marker, Enter creates or selects a breakpoint, ALT+left/right jumps between breakpoints, and Tab/SHIFT+Tab selects next/previous. Type a number or use up/down to set the value, then Enter confirms, Esc cancels, and Delete removes it. ALT+up/down cycles through a track's automated parameters. SHIFT+ALT+up/down cycles through all parameters.
- **Menu search on Mac:** CMD+? opens a search for any menu command. CTRL-click opens the context menu (VO+SHIFT+M with VoiceOver). Some commands exist only in context menus: Auto-Warp grid marker commands, grid line width options, and Operator envelope copy/paste.
- **Computer MIDI Keyboard gotcha:** with it on (M), letter keys play notes. Add SHIFT to single-letter shortcuts, for example SHIFT+S to solo.
- **Momentary latching:** hold A, B, S, Z, F1-F8 or Tab for more than about 500 ms and the toggle reverts on release. To disable it, add `-DisableHotKeyLatching` to Options.txt.

### Live keyboard shortcuts (Ch. 42, macOS)

#### Showing and Hiding Views

| Action | Shortcut |
|---|---|
| Toggle Full Screen | CTRL+CMD+F |
| Toggle Second Window | CMD+SHIFT+W |
| Toggle Session/Arrangement View | Tab (when Tab focus mode is off) |
| Toggle Device/Clip View | SHIFT+Tab or F12 |
| Toggle Hot-Swap Mode | Q |
| Toggle Drum Rack/Last Selected Pad | D |
| Hide/Show Info View | SHIFT+? |
| Hide/Show Browser | CMD+ALT+B or CMD+ALT+5 |
| Hide/Show Overview | CMD+ALT+O |
| Hide/Show In/Out | CMD+ALT+I |
| Hide/Show Sends | CMD+ALT+S |
| Hide/Show Mixer | CMD+ALT+M |
| Hide/Show Clip View | CMD+ALT+3 |
| Hide/Show Device View | CMD+ALT+4 |
| Hide/Show Groove Pool | CMD+ALT+6 |
| Open Settings | CMD+, |
| Close Window/Dialog | Esc |

#### Keyboard Focus and Navigation

| Action | Shortcut |
|---|---|
| Focus Control Bar / Session / Arrangement | ALT+0 / ALT+1 / ALT+2 |
| Focus Clip View / Device View / Browser | ALT+3 / ALT+4 / ALT+5 |
| Focus Groove Pool / Learn View | ALT+6 / ALT+7 |
| Focus Selected Clip Panel | ALT+8 |
| Focus Clip Panels | ALT+SHIFT+P |
| Next / Previous control (Tab focus mode on) | Tab / SHIFT+Tab |
| Next / Previous neighbor control | ALT+Tab / ALT+SHIFT+Tab |

#### Working with Sets and the Program

| Action | Shortcut |
|---|---|
| New / Open Live Set | CMD+N / CMD+O |
| Save / Save As | CMD+S / CMD+SHIFT+S |
| Export Audio/Video | CMD+SHIFT+R |
| Export MIDI File | CMD+SHIFT+E |
| Hide / Quit Live | CMD+H / CMD+Q |

#### Working with Devices and Plug-Ins

| Action | Shortcut |
|---|---|
| Group Devices (into Rack) | CMD+G |
| Ungroup Devices | CMD+SHIFT+G |
| Activate/Deactivate all devices in group | ALT-click device activator |
| Add device to selection | SHIFT-click |
| Reset parameter to default | Delete or double-click |
| Load selected device from browser | Enter |
| Hot-Swap selected device | Q |
| Hide/Show open plug-in windows | CMD+ALT+P |
| Open multiple plug-in windows | CMD-click Show/Hide Plug-In Window button |
| Compare A/B: switch device state | P |

#### Editing

| Action | Shortcut |
|---|---|
| Cut / Copy / Paste | CMD+X / CMD+C / CMD+V |
| Duplicate | CMD+D |
| Delete | Delete |
| Undo / Redo | CMD+Z / CMD+SHIFT+Z |
| Rename | CMD+R |
| Select All | CMD+A |
| Select multiple items | CMD-click |
| Select range (first to last) | SHIFT-click |
| Next track/scene while renaming | Tab |
| Ignore grid while dragging | CMD (hold) |
| Apply edit to clips/slots or time across all tracks | add SHIFT |
| Apply edit to selected part of envelope | add ALT |

#### Adjusting Values

| Action | Shortcut |
|---|---|
| Decrement/Increment | Up/Down arrows |
| Octave or fine steps | SHIFT+Up/Down |
| Finer resolution when dragging | SHIFT (hold) |
| Return to default | Delete |
| Type value | 0-9, then Enter (Esc cancels) |
| Next field (bar/beat/16th) | . or , |

#### Commands for Breakpoint Envelopes

| Action | Shortcut |
|---|---|
| Toggle Automation Mode | A |
| Finer resolution when dragging | SHIFT (hold) |
| Create curved segment | ALT-drag |
| Momentarily toggle fade controls | F |
| Delete selected envelope | CMD+Delete |
| Ignore grid while dragging | CMD (hold) |

#### Loop Brace and Start/End Markers

| Action | Shortcut |
|---|---|
| Set Start Marker / Loop Start / Loop End / End Marker | CMD+F9 / CMD+F10 / CMD+F11 / CMD+F12 |
| Move start marker to position | CMD-click |
| Move end marker to position | CMD+SHIFT-click |
| Nudge loop brace left/right (brace selected) | Left/Right arrows |
| Move loop by its length | Up/Down arrows |
| Halve/Double loop length | CMD+Up/Down |
| Shorten/Lengthen loop | CMD+Left/Right |
| Select material in loop | CMD+SHIFT+L |

#### Zooming, Display and Selections

| Action | Shortcut |
|---|---|
| Zoom window in/out | CMD++ / CMD+- |
| Zoom time ruler in/out | + / - |
| Follow playback (scroll display) | ALT+SHIFT+F |
| Scroll left/right | SHIFT+scroll |
| Add to selection | SHIFT-click or drag |
| Add nonadjacent clips/tracks/scenes | CMD-click |

#### Clip View Editor View Modes

| Action | Shortcut |
|---|---|
| Cycle Sample/Notes, Envelopes, MPE tabs | ALT+Tab |
| Sample/Notes tab | ALT+SHIFT+1 |
| Envelopes tab | ALT+SHIFT+2 |
| MPE tab | ALT+SHIFT+3 |

#### Clip View Sample Editor

| Action | Shortcut |
|---|---|
| Quantize / Quantize Settings | CMD+U / CMD+SHIFT+U |
| Insert / Delete Warp Marker | CMD+I / Delete |
| Move selected Warp Marker | Left/Right arrows |
| Select Warp Marker | CMD+Left/Right |
| Insert / Delete Transient | CMD+SHIFT+I / CMD+SHIFT+Delete |
| Move clip region with start marker | SHIFT+Left/Right |
| Zoom to / back from clip selection | Z / X |
| Fit to view width / height | W / H |
| Follow playback | ALT+SHIFT+F |

#### Clip View MIDI Note Editor

| Action | Shortcut |
|---|---|
| Select all notes | CMD+A |
| Invert note selection | CMD+SHIFT+A |
| Copy notes | ALT-drag |
| Chop notes on grid / split at time selection | CMD+E |
| Chop in increments of 1 / 2 | CMD+E drag up/down / CMD+SHIFT+E drag up/down |
| Split at exact spot | Hold E, click (drag to move) |
| Join notes | CMD+J |
| Fit notes to time range | CMD+ALT+J |
| Quantize / Quantize Settings | CMD+U / CMD+SHIFT+U |
| Set velocity | Type 0-127, Enter |
| Adjust velocity | CMD+Up/Down |
| Adjust velocity deviation | CMD+SHIFT+Up/Down |
| Adjust chance (probability) | CMD+ALT+Up/Down |
| Change velocity by dragging | CMD-drag |
| Next/previous note | ALT+Up/Down |
| Next/previous note on same key | ALT+Left/Right |
| Move / transpose notes | Arrows (SHIFT+Up/Down = octave) |
| Shorten/lengthen notes | SHIFT+Left/Right |
| Group notes (play all) / Ungroup | CMD+G / CMD+SHIFT+G |
| Apply current MIDI Tool settings | CMD+Enter |
| Highlight Scale | K |
| Show/Hide MIDI Note Filters | CMD+SHIFT+F |
| Toggle full-size Clip View | CMD+ALT+E |
| Split Arrangement clip at time selection | CMD+SHIFT+E |
| Scroll vertically / fine / horizontally | Page Up/Down / SHIFT+Page Up/Down / CMD+Page Up/Down |
| Insert marker to start / end | Home or Fn+Left / End or Fn+Right |
| Zoom horizontally | + / - |
| Zoom to / back from selection | Z / X |
| Fit to view width / height | W / H |
| Follow playback | ALT+SHIFT+F |

#### Grid Snapping and Drawing

| Action | Shortcut |
|---|---|
| Toggle Draw Mode (pitch lock off) | B |
| Narrow / Widen grid | CMD+1 / CMD+2 |
| Triplet grid | CMD+3 |
| Snap to grid | CMD+4 |
| Fixed / zoom-adaptive grid | CMD+5 |
| Bypass snapping while dragging | CMD (hold) |

#### Global Quantization

| Action | Shortcut |
|---|---|
| 1/16 / 1/8 / 1/4 note | CMD+6 / CMD+7 / CMD+8 |
| 1 Bar | CMD+9 |
| Off | CMD+0 |

#### Session View

| Action | Shortcut |
|---|---|
| Launch selected clip/slot (or scene) | Enter |
| Select neighboring clip/slot | Arrow keys |
| Copy clips | ALT-drag |
| Add/Remove Stop Button | CMD+E |
| Stop clips in track of selected slot | CMD+Enter |
| Insert MIDI clip | CMD+SHIFT+M |
| Insert Scene / Captured Scene | CMD+I / CMD+SHIFT+I |
| Move between scenes, 1 / 8 at a time | Up/Down / Page Up/Down |
| Record to Session View | CMD+SHIFT+F9 |
| Toggle Follow Actions on selected clips | SHIFT+Enter |
| Create Follow Action chain | CMD+SHIFT+Enter |
| Move selected track left/right | CMD+Left/Right |
| Move nonadjacent scenes without collapsing | CMD+Up/Down |
| Drop browser clips as a scene | hold CMD while dropping |
| Deactivate selected clip | 0 |
| Jump to track title bar | Esc |
| First / last track of scene | Home or Fn+Left / End or Fn+Right |
| Solo selected chain | S |

#### Arrangement View

| Action | Shortcut |
|---|---|
| Split clip at selection | CMD+E |
| Consolidate selection into clip | CMD+J |
| Crop selected clips | CMD+SHIFT+J |
| Resize clip with insert marker at edge | Enter, then Left/Right |
| Slide waveform | SHIFT+ALT-drag |
| Stretch warped clip | SHIFT-drag in clip title bar |
| Create fade/crossfade | CMD+ALT+F |
| Delete fades in selected clips | CMD+ALT+Delete |
| Momentarily toggle fade handles | F |
| Toggle loop brace | CMD+L |
| Adjust loop length | CMD+Left/Right |
| Select loop contents | CMD+SHIFT+L |
| Insert silence | CMD+I |
| Cut / Copy / Paste time | CMD+SHIFT+X / CMD+SHIFT+C / CMD+SHIFT+V |
| Duplicate / Delete time | CMD+SHIFT+D / CMD+SHIFT+Delete |
| Fold/Unfold selected tracks | U or Left/Right |
| Unfold all tracks | ALT+U |
| Adjust height of selected tracks/clips | ALT++ / ALT+- |
| Optimize height / width | H / W |
| Nudge selection | Left/Right arrows |
| Reverse audio clip selection | R |
| Deactivate selection | 0 |
| Zoom to / back from time selection | Z / X |
| Follow playback | ALT+SHIFT+F |
| Play from insert marker in selected clip | ALT+Space |
| Move insert marker to playhead | CMD+SHIFT+Space |
| Move focus to mixer | ALT+SHIFT+M |

#### Comping

| Action | Shortcut |
|---|---|
| Show take lanes | CMD+ALT+U |
| Add selected take area to main lane | Enter |
| Audition selected take lane | T |
| Add take lane | SHIFT+ALT+T |
| Duplicate take lane | CMD+D |
| Swap main clip to next/previous take | CMD+Up/Down |

#### Bounce to Audio

| Action | Shortcut |
|---|---|
| Bounce to new track | CMD+B |
| Paste bounced audio | CMD+ALT+V |

#### Commands for Tracks

| Action | Shortcut |
|---|---|
| Insert Audio / MIDI / Return track | CMD+T / CMD+SHIFT+T / CMD+ALT+T |
| Rename selected track | CMD+R |
| Group / Ungroup tracks | CMD+G / CMD+SHIFT+G |
| Show / Hide grouped tracks | + / - |
| Collapse/Expand group | U |
| Hide/Show return tracks | CMD+ALT+R |
| Move nonadjacent tracks without collapsing | CMD+arrows |
| Arm selected tracks | C |
| Solo selected tracks | S |
| Deactivate selected track | 0 |
| Freeze/Unfreeze | CMD+ALT+SHIFT+F |
| Delete track (title bar focused) | Delete |

#### Transport

| Action | Shortcut |
|---|---|
| Play from start marker / Stop | Space |
| Continue from stop point | SHIFT+Space |
| Stop at end of selection | ALT+Space |
| Play Arrangement selection | Space |
| Insert marker to beginning | Home or Fn+Left |
| Record | F9 |
| Arm recording in Arrangement | SHIFT+F9 |
| Record to Session View | CMD+SHIFT+F9 |
| Back to Arrangement | F10 |
| Activate/deactivate tracks 1-8 | F1-F8 |
| Toggle metronome | O |

#### Audio Engine

| Action | Shortcut |
|---|---|
| Audio engine on/off | CMD+ALT+SHIFT+E |

#### Browser

| Action | Shortcut |
|---|---|
| Search | CMD+F |
| Jump to search results | Down arrow or Enter |
| Scroll / open-close folders | Up/Down / Right/Left arrows |
| Load selected item | Enter |
| Preview selected file | SHIFT+Enter or Right arrow |
| Assign / reset color | 1-7 / 0 |
| Similarity search (similar files) | CMD+SHIFT+F |
| History back / forward | CMD+[ / CMD+] |
| Hide/Show Filter View | CMD+ALT+G |
| Hide/Show Tag Editor | CMD+SHIFT+E |

#### Similar Sample Swapping

Works in Drum Racks, Drum Rack pads and Simpler.

| Action | Shortcut |
|---|---|
| Swap to next / previous similar sample | CMD+Right / CMD+Left |
| Save as similarity reference | CMD+Up |
| Return to reference | CMD+Down |
| Temporarily show swap controls in Drum Racks | ALT (hold) |

#### Key/MIDI Map Mode and the Computer MIDI Keyboard

| Action | Shortcut |
|---|---|
| MIDI Map Mode | CMD+M |
| Key Map Mode | CMD+K |
| Computer MIDI Keyboard on/off | M |
| Octave down / up | Z / X |
| Velocity down / up | C / V |

#### Context-dependent keys

Some keys do different things in different places. CMD+E splits clips in Arrangement, chops notes in the MIDI editor and adds or removes a Stop Button in Session. CMD+I inserts a scene, silence or a Warp Marker. CMD+SHIFT+E exports MIDI from the File menu, opens the Tag Editor in the browser, or splits an Arrangement clip from the note editor. CMD+SHIFT+F runs similarity search in the browser and shows MIDI Note Filters in the note editor. Tell the user where the focus must be.
