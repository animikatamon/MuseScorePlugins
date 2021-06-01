# Barbershop Checker
### Checking adherence of score to Barbershop Harmony rules

## Functionality
- Mark points in score that do not adhere to the rules of Barbershop Harmony. For full list of reported issues see [below](#Reported-Issues).
- Automatically identify chords and write chord symbols above top staff (Like Ctrl+K in MuseScore).
- Mark chords that are not in the Barbershop vocabulary.
- Works on entire score, or only on selected notes (if selection includes at least one chord).

## Notes
- This plugin does not check adherence to homophonic/homorhythmic requirements of Barbershop. It only checks the harmonies, i.e. the note combinations of the four voices. 
- Issues reported by this plugin should be taken with a grain of salt. The purpose of this plugin is to help Barbershop arrangers quickly point out potential inconsistencies with the Barbershop style. It is up to the arranger to determine which issues to fix and which ones to ignore.
- _Moreover, this plugin should certainly **NOT** be used for determining whether a song is contestable!!_ Check with a certified music judge before taking an arrangement to contest.

## Parameters:
 [inline:BarbershopCheckerOptions.png=Options Dialog] 

- **How to display Barbershop incompatibilities**:
    - **Red noteheads**: Whether to mark issues using red noteheads
    - **Textual remarks**: Whether to mark issues using staff text 
    - **Red chord symbols**: Display unrecognized or non-Barbershop chords in red (this option is always checked)
- **Show info also for "legal" chords**: Whether to display chord analysis results also for chords without issues
    - **Add chord text**: Whether to add chord symbol text
        - If checked, select style of chord symbols to display:
            - **Regular (A-G)**: "Normal" pitch-based chord, e.g. F7, C/G, G79(no5)
            - **Roman (I-VII)**: Roman numeral quality level, e.g. III, iv
    - **Color notes according to role in chord**: (this option was copied as is from [prior plugin varaints](#Acknowledgments), _and not sufficiently tested_. Use at own risk)
        - red: root note
        - green: 3th
        - olive(dark-yellow): 5th
        - purple: 7th
        - blue/lightblue/pink: 9/11/13th
        - black: unknown

## Reported Issues
The plugin provides the following reports to the following issues:
- **Minor second interval**: staff text "Semitone!" + red pitch-name noteheads
- **Doubling of same pitch**: staff text "Doubled note" + red pitch-name noteheads
- **Bass not singing lowest note**: staff text "Low Bari"(etc.) + red pitch-name noteheads
- **Tenor not singing highest note**: staff text "High Lead"(etc.) + red pitch-name noteheads
- **Weak Voicing ("Wrong Bass")**: staff text "Voicing" + red circle notehead on Bass
- **9 too close to root**: staff text "Low 9" + red circle notehead on 9 and Bass
- **Unidentified chord**: "XX" as chord symbol, in red
- **Identified non-Barbershop chord**: red chord symbol

Note: High Bass or Low Tenor are marked only in standard BBS scores - written either in 2 staves X 2 voices each, or in 4 separate staves

## Barbershop Chord Vocabulary and Possible Voicings
- Major (Bass on Root or 5th)
- Barbershop 7th (Bass on Root or 5th)
- Major 7th (Bass on Root)
- Major with added 9th (Bass on Root)
- Major 6th - with or without 5th (Bass on Root)
- Dominant 9th - without 5th (Bass on Root)
- Minor (Bass on Root or 5th)
- Minor 6th - not distinguished from Dominant 9th without root (Bass on Root)
- Minor 7th (Bass on Root or 5th)
- Diminished (Bass on Root)
- Diminished 7th (Bass on Root)
- Augmented (Bass on Root)
- Augmented dominant 7th (Bass on Root)
- Half diminished 7th (Bass on Root or 5th)
- Barbershop 7th with flatted 5th (Bass on Root)

## Example
 [inline:CarolineBBScheckerExample.png] 

## Installation Guide:
https://musescore.org/en/handbook/3/plugins#installation

## Usage Tips  
- Ctrl-Z will undo all changes at once. So go ahead, try different parameters, see what works best for you!
- If no notes are selected, the plugin will work on the entire score. Otherwise, it will work only on the selected notes (Also if partial staves are selected, please beware)

## Known problems
- The Roman chord symbols option assumes the major scale - as this is Barbershop, after all... (e.g. Dm in the A minor / C major scale will appear as ii, rather than iv) 

## Resources
- [Contest and Judging Handbook (2018)](https://www.barbershop.org/files/documents/contestandjudging/C&J%20Handbook.pdf)
- [Barbershop Arrangers Manual (1980)](https://shop.barbershop.org/barbershop-arrangers-manual/)
- [The 11 Chords of Barbershop](https://www.sunshinetracks.com/chords.pdf)

## Acknowledgments:  
Harmony checker is based on the [Chord Identifier (Pop & Jazz) plugin](https://musescore.org/en/project/chord-identifier-pop-jazz), which I developed in turn as an improvement of [Chord Identifier Special V3](https://musescore.org/en/project/chord-identifier-special-v3) by Ziya Mete Demircan.

### Prior contributions include:
- https://github.com/rousselmanu/msc_plugins  plugin by rousselmanu and its ports to MuseScore 2.3 by Ke Xu and to MS 3 by Dmitri Ovodok
- https://github.com/andresn/standard-notation-experiments/tree/master/MuseScore/plugins/findharmonies  
- http://musescore.org/en/project/findharmony  by Merte  
- https://github.com/berteh/musescore-chordsToNotes/  - Jon Ensminger (AddNoteNameNoteHeads v. 1.2 plugin)  

Thank you all!