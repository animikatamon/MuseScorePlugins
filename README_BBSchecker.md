# Barbershop Checker
## This plugin checks adherence to Barbershop Harmony rules

### Functionality

- Automatically identify chords and write chord symbols above top staff (Like Ctrl+K in MuseScore).
- Recognize advanced Jazz chords as well as classic chords. E.g. C11(b9/b13), Bb7#5, F7(b9), as well as C, G7, Am etc.
- Works on entire score, or only on selected notes (if selection includes more than one chord).   

- Mark places where Tenor isn't highest voice or Bass isn't lowest. (Works only for standard BBS scores - written either in 2 staves X 2 voices each, or in 4 separate staves)

It does not check adherence to homophanic/homorhythmic equirements of barbershop
Not to be used to determine whether a song is contestable! Refer to official judge for professional verdict

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

(If there is a chord issue and no notes can be marked, then the message must be displayed)

### Reported Issues
The plugin reports the following issues:


### Example
 [inline:ChordIdentifierExample2.png] 

### Installation Guide:
https://musescore.org/en/handbook/3/plugins#installation

### Usage Tips  
- Ctrl-Z will undo all changes at once. So go ahead, try different parameters, see what works best for you!
- If no notes are selected, the plugin will work on the entire score. Otherwise, it will work only on the selected notes (Also if partial staves are selected, please beware).

### Acknowledgments:  
Harmony checker is based on the "Chord Identifier (Pop & Jazz)" plugin, which I started in turn as an improvement of https://musescore.org/en/project/chord-identifier-special-v3 by Ziya Mete Demircan.

Prior contributions include:
- https://github.com/rousselmanu/msc_plugins  plugin by rousselmanu and its ports to MuseScore 2.3 by Ke Xu and to MS 3 by Dmitri Ovodok
- https://github.com/andresn/standard-notation-experiments/tree/master/MuseScore/plugins/findharmonies  
- http://musescore.org/en/project/findharmony  by Merte  
- https://github.com/berteh/musescore-chordsToNotes/  - Jon Ensminger (AddNoteNameNoteHeads v. 1.2 plugin)  

Thank you all!