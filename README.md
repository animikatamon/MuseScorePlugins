# Chord Identifier (Pop & Jazz) 
## This plugin automatically identifies chords in a score
This is a new version of the "Chord Identifier Special V3" plugin. See long list of credits below.

### Functionality

- Automatically identify chords and write chord symbols above top staff (Like Ctrl+K in MuseScore).
- Recognize advanced Jazz chords as well as classic chords. E.g. C11(b9/b13), Bb7#5, F7(b9), as well as C, G7, Am etc.
- Works on entire score, or only on selected notes (if selection includes more than one chord).   

### Parameters:
 [inline:ChordIdentifierOptions.png=Options Dialog] 

- Symbol:
    - Normal chord, e.g. C, F7, Gm79.  
    - Roman numeral quality level, e.g. Ⅳ.
- Bass: Add Bass note, when different from root note. E.g. Bb/F.
- Inversion: Type of inversion notation, if any.  
- Highlight Chord Notes: color chord notes according to their role in the chord.
    - red: root note
    - green: 3th
    - olive(dark-yellow): 5th
    - purple: 7th
    - blue/lightblue/pink: 9/11/13th
    - black: N/A
- On Incomplete Chords: How to handle cases where not all notes were identified in chord - either color in red or mark as ??
- Use Entire Note Duration: Whether to consider entire duration in identification, or only when each note begins.
                         

### Example
 [inline:ChordIdentifierExample2.png] 

### Installation Guide:
https://musescore.org/en/handbook/3/plugins#installation

### Usage Tips  
- Ctrl-Z will undo all changes at once. So go ahead, try different parameters, see what works best for you!
- The plugin should  work on any selection you require. For example: only the piano part; everything except the solo, etc.

### What's new in v3.4
-  Added “On Incomplete Chords” option
-  Improve handling of tuplets (in MS 3.5 and above)
### What's new in v3.3
-  Added “Use Entire Note Duration” option
-  Overhauled note/chord traversal so that all notes are traversed from left to right, regardless of staff/voice they are on (this bug existed in several prior versions)
-  Remember selected options between plugin invocations


### Acknowledgments:  
I started this plugin as an improvement of https://musescore.org/en/project/chord-identifier-special-v3 by Ziya Mete Demircan, who was also very helpful in commenting and checking on my progress.

Prior contributions include:
- https://github.com/rousselmanu/msc_plugins  plugin by rousselmanu and its ports to MuseScore 2.3 by Ke Xu and to MS 3 by Dmitri Ovodok
- https://github.com/andresn/standard-notation-experiments/tree/master/MuseScore/plugins/findharmonies  
- http://musescore.org/en/project/findharmony  by Merte  
- https://github.com/berteh/musescore-chordsToNotes/  - Jon Ensminger (AddNoteNameNoteHeads v. 1.2 plugin)  

Thank you all!