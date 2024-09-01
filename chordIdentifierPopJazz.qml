//==============================================
//  Chord Identifier (Pop & Jazz) v5.0
//
//  https://github.com/animikatamon/MuseScorePlugins
//  Copyright (C)2024 Joshua Boniface (joshuaboniface) - Reworking
//  Copyright (C)2019-2024 animikatamon - Maintainer
//  Copyright (C)2016 Emmanuel Roussel (rousselmanu) - Original Author
//  and Other Contributors as listed there
//
//  This is a major cleanup and functional improvement to the original
//  "Chord Identifier" plugin v4.4, enough so that I believe this new
//  header and a major version bump is prudent.
//  The following are the major differences from v4.4:
//
//  * The menu/dialog is completely rewritten for MuseScore 4, based on the
//    official "Note Names" and "Courtesy Accidentals" plugins as of MS4.4.
//  * Incomplete chord suggestion is now handled with either a red (flag)
//    or just placing the best guess (default) rather than "??" and red,
//    respectively, due to both some bugs in the colour picker and the idea
//    that most people would just want to take the match as-is and edit as
//    needed later.
//  * The plugin now works on explicitly selected staves. i.e. if you select
//    only one instrument in a score of many instruments, this plugin will
//    act ONLY on that instrument's notes, and place the chord symbol above
//    that instrument. This is a personal choice as I find a "whole-score"
//    chord identifier to be pretty useless in practice, and I'd much rather
//    have dedicated chord symbols for specific instruments (e.g. guitar).
//    One CAVEAT here is that you must select a whole grand staff to work
//    on the whole grand staff.
//  * The code has been completely cleaned of cruft: old commented out code
//    blocks, disabled debug print statements, etc. have all been removed.
//  * Comments have been improved as much as possible to be clear and aid
//    in understanding the code. Several "attribution" comments and ancient
//    "TODO" comments have been removed as well (that's what version control
//    and Issues are for).
//  * Several variable names have been renamed to make them make more sense.
//    This includes all the configurable options which now have standardized
//    names based on the scheme <x><X>Mode.
//  * Functions have been named in a consistent format (camelCase) and have
//    been given header blocks with details about what they do (as much as
//    I could gather, at least).
//  * A consistent code spacing style has been applied throughout: spaces
//    between operators (e.g. "1 + 1" instead of "1+1"), variable assignment
//    ("var x = 1" instead of "var x=1"), and consistent braces and spaces.
//    As I'm not really a JS developer I didn't go any further on style,
//    but this should provide a cleaner base to do so in the future.
//
//  Original plugin based on configCourtesyAccidentals
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 2 of the License.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//==============================================

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import MuseScore 3.0
import Muse.UiComponents 1.0

MuseScore {
    version: "2.0"
    description: "This plugin identifies adds chord symbols automatically"
    title: "Chord Identifier (Pop & Jazz)"
    categoryCode: "composing-arranging-tools"
    pluginType: "dialog"
    thumbnailName: "note_names.png"

    requiresScore: true

    width: 464
    height: 298

    // Settings
    Settings {
        id: settings
        property int chordMode:                 0  // 0: Normal chord (C, F7, etc.); 1: Roman chord level (IV, etc.)
        property int bassMode:                  0  // 0: Disabled; 1: Enabled
        property int inversionMode:             0  // 0: None; 1: Note with Superscript; 2: Figured Bass notation
        property int partialChordMode:          0  // 0: Flag; 1: Suggest
        property int entireDurationMode:        0  // 0: Disabled; 1: Enabled
        property int chordColorMode:            0  // 0: Disabled; 1: Enabled
    }

    // Error dialog

    MessageDialog {
        id: errorDialog
        visible: false
        //icon: StandardIcon.Warning
    }


    Item {
        id: rect1
        anchors.fill: parent
        anchors.margins: 8

        // Selector rows

        ColumnLayout {
            id: col1
            anchors.left: parent.left
            anchors.right: parent.right

            ButtonGroup { id: symbolModeGroup }
            ButtonGroup { id: bassModeGroup }
            ButtonGroup { id: inversionModeGroup }
            ButtonGroup { id: partialChordModeGroup }
            ButtonGroup { id: durationModeGroup }
            ButtonGroup { id: colorChordModeGroup }

            Label {
                text: "Identify Chords and add Chord Symbols"
            }

            RowLayout {
                Rectangle { // for indentation
                    width: 10
                }

                id: symbolModeR

                Label {
                    text: "Chord symbol type:"
                }

                RadioButton {
                    parent: symbolModeR
                    text: "Normal"
                    checked: true
                    ButtonGroup.group: symbolModeGroup
                    onClicked: {
                        console.log("Selected Normal chord symbol mode");
                        settings.symbolMode = 0; 
                    }
                }

                RadioButton {
                    parent: symbolModeR
                    text: "Roman"
                    checked: false
                    ButtonGroup.group: symbolModeGroup
                    onClicked: {
                        console.log("Selected Roman chord symbol mode");
                        settings.symbolMode = 1; 
                    }
                }
            }

            RowLayout {
                Rectangle { // for indentation
                    width: 10
                }

                id: bassModeR

                Label {
                    text: "Bass note slash notation:"
                }

                RadioButton {
                    parent: bassModeR
                    text: "Yes"
                    checked: true
                    ButtonGroup.group: bassModeGroup
                    onClicked: {
                        console.log("Selected bass slash notation mode");
                        settings.bassMode = 1; 
                    }
                }

                RadioButton {
                    parent: bassModeR
                    text: "No"
                    checked: false
                    ButtonGroup.group: bassModeGroup
                    onClicked: {
                        console.log("Selected no bass slash notation mode");
                        settings.bassMode = 0; 
                    }
                }
            }

            RowLayout {
                Rectangle { // for indentation
                    width: 10
                }

                id: inversionModeR

                Label {
                    text: "Add inversion numbers:"
                }

                RadioButton {
                    parent: inversionModeR
                    text: "No"
                    checked: true
                    ButtonGroup.group: inversionModeGroup
                    onClicked: {
                        console.log("Selected no inversion numbers mode");
                        settings.inversionMode = 0; 
                    }
                }

                RadioButton {
                    parent: inversionModeR
                    text: "Normal"
                    checked: false
                    ButtonGroup.group: inversionModeGroup
                    onClicked: {
                        console.log("Selected normal inversion numbers mode");
                        settings.inversionMode = 1; 
                    }
                }

                RadioButton {
                    parent: inversionModeR
                    text: "Figured Bass"
                    checked: false
                    ButtonGroup.group: inversionModeGroup
                    onClicked: {
                        console.log("Selected figured bass inversion numbers mode");
                        settings.inversionMode = 2;
                    }
                }
            }

            RowLayout {
                Rectangle { // for indentation
                    width: 10
                }

                id: partialChordModeR

                Label {
                    text: "Partial chord handling:"
                }

                RadioButton {
                    parent: partialChordModeR
                    text: "Accept"
                    checked: true
                    ButtonGroup.group: partialChordModeGroup
                    onClicked: {
                        console.log("Selected partial chord suggest mode");
                        settings.partialChordMode = 1; 
                    }
                }

                RadioButton {
                    parent: partialChordModeR
                    text: "Flag (red)"
                    checked: false
                    ButtonGroup.group: partialChordModeGroup
                    onClicked: {
                        console.log("Selected partial chord flag mode");
                        settings.partialChordMode = 0; 
                    }
                }
            }

            RowLayout {
                Rectangle { // for indentation
                    width: 10
                }

                id: durationModeR

                Label {
                    text: "Duration handling:"
                }

                RadioButton {
                    parent: durationModeR
                    text: "Entire note"
                    checked: true
                    ButtonGroup.group: durationModeGroup
                    onClicked: {
                        console.log("Selected entire note duration mode");
                        settings.durationMode = 1; 
                    }
                }

                RadioButton {
                    parent: durationModeR
                    text: "Every note"
                    checked: false
                    ButtonGroup.group: durationModeGroup
                    onClicked: {
                        console.log("Selected every note duration mode");
                        settings.durationMode = 0; 
                    }
                }
            }

            RowLayout {
                Rectangle { // for indentation
                    width: 10
                }

                id: chordColorModeR

                Label {
                    text: "Colorize chord notes:"
                }

                RadioButton {
                    parent: chordColorModeR
                    text: "No"
                    checked: true
                    ButtonGroup.group: chordColorModeGroup
                    onClicked: {
                        console.log("Selected no colorize chord notes mode");
                        settings.chordColorMode = 0; 
                    }
                }

                RadioButton {
                    parent: chordColorModeR
                    text: "Yes"
                    checked: false
                    ButtonGroup.group: chordColorModeGroup
                    onClicked: {
                        console.log("Selected colorize chord notes mode");
                        settings.chordColorMode = 1; 
                    }
                }
            }
        }

        // Control buttons

        FlatButton {
            text:"Run"
            anchors {
                top: col1.bottom
                topMargin: 15
                left: rect1.left
                leftMargin: 10
            }
            onClicked: {
                curScore.startCmd();
                run();
                curScore.endCmd();
                quit();
            }
        }

        FlatButton {
            text: "Cancel"
            anchors {
                top: col1.bottom
                topMargin: 15
                right: rect1.right
                rightMargin: 10
            }
            onClicked: {
                quit();
            }
        }
    }

    // if nothing is selected process whole score
    property bool processAll: false

    property var black     : "#000000"
    property var red       : "#ff0000"
    property var green     : "#00ff00"
    property var blue      : "#0000ff"
    property var colorOth3 : "#C080C0"    //color: ext.:(9/11/13)
    property var colorOth2 : "#80C0C0"    //color: ext.:(9/11/13)
    property var colorOth1 : "#4080C0"    //color: ext.:(9/11/13)
    property var color7th  : "#804080"    //color: 7th
    property var color5th  : "#808000"    //color: 5th
    property var color3rd  : "#008000"    //color: 3rd (4th for suss4)
    property var colorroot : "#800000"    //color: Root

    // Function: getNoteName
    //
    // Gets the note name from the TPC (Tonal Pitch Class) of a note object
    function getNoteName(note_tpc) {
        var notename = "";
        var tpc_str = [
            "Cbb","Gbb","Dbb","Abb","Ebb","Bbb",
            "Fb","Cb","Gb","Db","Ab","Eb","Bb",
            "F","C","G","D","A","E","B",
            "F#","C#","G#","D#","A#","E#","B#",
            "F##","C##","G##","D##","A##","E##","B##",
            "Fbb" // tpc -1 is at number 34 (last item)
        ];

        if (note_tpc != 'undefined' && note_tpc<=33) {
            if (note_tpc == -1)
                notename = tpc_str[34];
            else
                notename = tpc_str[note_tpc];
        }
        return notename;
    }

    // Function: getNoteRomanSeq
    //
    // Gets the Roman sequence value for a given note and key signature
    function getNoteRomanSeq(note,keysig) {
        var notename = "";
        var num = 0;
        var keysigNote = [
            11, 6, 1, 8, 3, 10, 5, 0, 7, 2, 9, 4, 11, 6, 1
        ];
        var Roman_str_flat_mode1 = ["Ⅰ","Ⅱ♭","Ⅱ","Ⅲ♭","Ⅲ","Ⅳ","Ⅴ♭","Ⅴ","Ⅵ♭","Ⅵ","Ⅶ♭","Ⅶ"];
        var Roman_str_flat_mode2 =  ["①","②♭","②","③♭","③","④","⑤♭","⑤","⑥♭","⑥","⑦♭","⑦"];

        if (keysig != 'undefined') {
            num = (note + 12 - keysigNote[keysig+7]) % 12;
            notename = Roman_str_flat_mode1[num];

        }
        return notename;
    }

    // Function: doRemoveDuplicateNotes
    //
    // Removes any duplicate (higher) notes from a chord, operating on mod modulus
    // Called by the wrapper functions removeDuplicateNotes and removeDuplicateNotes12
    function doRemoveDuplicateNotes(chord, mod) {
        var chord_notes = new Array();

        // Confine the notes to mod values (octave or "infinite")
        for (var i = 0; i < chord.length; i++)
            chord_notes[i] = chord[i].pitch % mod;

        // Sort the notes
        chord_notes.sort(function(a, b) { return a - b; });

        // Filter the notes of duplicates
        var sorted_notes = chord_notes.filter(
            function(elem, index, self) {
                return index == self.indexOf(elem);
            }
        );

        return sorted_notes;
    }

    // Function: removeDuplicateNotes12
    //
    // Removes any duplicate (higher) notes from a chord, within a single octave
    // (Wrapper for doRemoveDuplicateNotes)
    function removeDuplicateNotes12(chord) {
        return doRemoveDuplicateNotes(chord, 12);
    }

    // Function: removeDuplicateNotes
    //
    // Removes any duplicate (higher) notes from a chord, at the original pitch
    // (Wrapper for doRemoveDuplicateNotes)
    function removeDuplicateNotes(chord) {
        // 132 = 12 chromatic notes * 10 octaves from 20Hz-20kHz (C0-C10), plus another octave for good measure (C11)
        return doRemoveDuplicateNotes(chord, 132);
    }
    
    // Function: areNotesEqual
    //
    // Checks if the notes in two chords are identical
    function areNotesEqual(chord1, chord2) {
        var a1 = removeDuplicateNotes(chord1);
        var a2 = removeDuplicateNotes(chord2);
        return a1.length == a2.length && a1.every(function(value, i) { return value === a2[i]});
    }

    // ---------- find intervals for all possible positions of the root note ---------- 
    // Function: findIntervals
    //
    // Finds intervals for all possible positions of the root note in the given chord (unique notes)
    function findIntervals(sorted_notes) {
        var n = sorted_notes.length;
        var intervals = new Array(n);

        for (var i = 0; i < n; i++)
            intervals[i] = new Array();

        // For each position of root note in the chord
        for (var root_pos = 0; root_pos < n; root_pos++) {
            var idx = -1;
            // Get intervals from current "root"
            for (var i = 0; i < (n - 1); i++) {
                var cur_inter = (sorted_notes[(root_pos + i + 1) % n] - sorted_notes[(root_pos + i) % n]) % 12;  
                // If we're negative, increase the interval by an octave until we're not
                while(cur_inter < 0)
                    cur_inter+=12;

                // Skip unison intervals (if that somehow happens)
                if (cur_inter != 0) {
                    idx++;
                    intervals[root_pos][idx] = cur_inter;
                    if (idx > 0)
                        intervals[root_pos][idx] += intervals[root_pos][idx-1];
                }
            }
            console.log('\t intervals: ' + intervals[root_pos]);
        }

        return intervals;
    }
    
    // Function: compareArray
    //
    // Returns an array of size ref_arr.length with boolean values representing the comparison
    function compareArray(ref_arr, search_elt) {
        if (ref_arr == null || search_elt == null) return [];
        var cmp_arr = [];
        var nb_found = 0;
        for (var i = 0; i < ref_arr.length; i++) {
            if (search_elt.indexOf(ref_arr[i]) >= 0) {
                cmp_arr[i] = 1;
                nb_found++;
            } else {
                cmp_arr[i] = 0;
            }
        }
        return {
            cmp_arr: cmp_arr,
            nb_found: nb_found
        };
    }
        
    // Function: getChordName
    //
    // Gets the actual chord name of a given chord in the given key signature
    function getChordName(chord,keysig) {
        // Standard notation for inversions
        if (settings.inversionMode === 1) {
            // Unicode values for superscript "1", "2", "3" (e.g. to represent C Major first, or second inversion)
            var inversions = [
                "", " \u00B9", " \u00B2"," \u00B3"," \u2074"," \u2075"," \u2076"," \u2077"," \u2078"," \u2079"
            ];
            var inversions_7th = inversions;
			var inversions_9th  = inversions;
			var inversions_11th = inversions;
			var inversions_13th = inversions;
        // Figured bass notation for inversions
        } else if (settings.inversionMode === 2) {
            var inversions = [
                '', ' \u2076', ' \u2076\u2084', '', '', '', '', '', '', ''
            ];
            var inversions_7th = [
                ' \u2077', ' \u2076\u2085', ' \u2074\u2083', ' \u2074\u2082', ' \u2077-\u2074', ' \u2077-\u2075', ' \u2077-\u2076', ' \u2077-\u2077', ' \u2077-\u2078', ' \u2077-\u2079'
            ];
			var inversions_9th = [
                ' \u2079', ' inv\u00B9', ' inv\u00B2', ' inv\u00B3',' inv\u2074',' inv\u2075',' inv\u2076',' inv\u2077',' inv\u2078',' inv\u2079'
            ];
			var inversions_11th = [
                ' \u00B9\u00B9', ' inv\u00B9', ' inv\u00B2', ' inv\u00B3',' inv\u2074',' inv\u2075',' inv\u2076',' inv\u2077',' inv\u2078',' inv\u2079'
            ];
            var	inversions_13th = [
                ' \u00B9\u00B3', ' inv\u00B9', ' inv\u00B2', ' inv\u00B3',' inv\u2074',' inv\u2075',' inv\u2076',' inv\u2077',' inv\u2078',' inv\u2079'
            ];
        // No notation for inversions (just numericals for the chord type)
        } else {
            var inversions      = [
                "","","","","","","","","",""
            ]; 
			var inversions_7th  = [
                " \u2077","","","","","","","","",""
            ];
			var inversions_9th  = [
                " \u2079","","","","","","","","",""
            ];
			var inversions_11th = [
                " \u00B9\u00B9","","","","","","","","",""
            ];
			var inversions_13th = [
                " \u00B9\u00B3","","","","","","","","",""
            ];
        }
            
        var root_note = null;
        var inversion = null;
        var partial_chord = 0;
           
        // intervals (number of semitones from root note) for main chords types...
        //          0    1   2    3        4   5          6      7    8         9     10    11
        // numeric: R,  b9,  9,  m3(#9),  M3, 11(sus4), #11(b5), 5,  #5(b13),  13(6),  7,   M7  //Ziya
        const STR = 0;
        const INTERVALS = 1;

        // List of all (supported) chord types based on their intervals
        const all_chords = [
            [ "",           [4,7] ],            //00: M (0)*
            [ "m",          [3,7] ],            //01: m*
            [ "dim",        [3,6] ],            //02: dim*
            [ "sus4",       [5,7] ],            //03: sus4 = Suspended Fourth*
            [ "7sus4",      [5,7,10] ],         //04: 7sus4 = Dominant7, Suspended Fourth*
            [ "Maj7",       [4,7,11] ],         //05: M7 = Major Seventh*
            [ "m(Maj7)",    [3,7,11] ],         //06: mMa7 = minor Major Seventh*
            [ "m7",         [3,7,10] ],         //07: m7 = minor Seventh*
            [ "7",          [4,7,10] ],         //08: 7 = Dominant Seventh*
            [ "o7",         [3,6,9] ],          //09: dim7 = Diminished Seventh*
            [ "Maj7(#5)",   [4,8,11] ],         //10: #5Maj7 = Major Seventh, Raised Fifth*
            [ "7(#5)",      [4,8,10] ],         //11: #57 = Dominant Seventh, Raised Fifth*
            [ "aug",        [4,8] ],            //12: #5 = Majör Raised Fifth*
            [ "0",          [3,6,10] ],         //13: m7b5 = minor 7th, Flat Fifth*
            [ "7(b5)",      [4,6,10] ],         //14: M7b5 = Major 7th, Flat Fifth*                     
            [ "(add9)",     [4,7,2] ],          //15: add9 = Major additional Ninth*
            [ "Maj9",       [4,7,11,2] ],       //16: Maj7(9) = Major Seventh, plus Ninth*    
            [ "9",          [4,7,10,2] ],       //17: 7(9) = Dominant Seventh, plus Ninth*    
            [ "m(add9)",    [3,7,2] ],          //18: add9 = minor additional Ninth*
            [ "m9(Maj7)",   [3,7,11,2] ],       //19: m9(Maj7) = minor Major Seventh, plus Ninth*
            [ "m9",         [3,7,10,2] ],       //20: m7(9) = minor Seventh, plus Ninth*
            [ "Maj7(#11)",  [4,7,11,6] ],       //21: Maj7(#11) = Major Seventh, Sharp Eleventh*
            [ "Maj9(#11)",  [4,7,11,2,6] ],     //22: Maj9(#11) = Major Seventh, Sharp Eleventh, plus Ninth* 
            [ "7(#11)",     [4,7,10,6] ],       //23: 7(#11) =  Dom. Seventh, Sharp Eleventh*
            [ "9(#11)",     [4,7,10,2,6] ],     //24: 9(#11) =  Dom. Seventh, Sharp Eleventh, plus Ninth* 
            [ "7(13)",      [4,7,10,9] ],       //25: 7(13) =  Dom. Seventh, Thirteenth*
            [ "9(13)",      [4,7,10,2,9] ],     //26: 9(13) =  Dom. Seventh, Thirteenth, plus Ninth* 
            [ "7(b9)",      [4,7,10,1] ],       //27: 7(b9) = Dominant Seventh, plus Flattened Ninth*
            [ "7(b13)",     [4,7,10,8] ],       //28: 7(b13) =  Dom. Seventh, Flattened Thirteenth*
            [ "7(b9/b13)",  [4,7,10,1,8] ],     //29: 7(b13b9) =  Dom. Seventh, Flattened Thirteenth, plus Flattened Ninth* 
            [ "11(b9/b13)", [4,7,10,1,5,8] ],   //30: 7(b13b911) =  Dom. Seventh, Flattened Thirteenth plus Flattenet Ninth, plus Eleventh* 
            [ "7(#9)",      [4,7,10,3] ],       //31: 7(#9) = Dominant Seventh, plus Sharp Ninth*
            [ "m7(11)",     [3,7,10,5] ],       //32: m7(11) = minor Seventh, plus Eleventh*
            [ "m11",        [3,7,10,2,5] ],     //33: m9(11) = minor Seventh, plus Eleventh, plus Ninth* 
            [ "x", [0,0,0] ]                    //34: Dummy
        ];                                               

        // NOTE: The following possible chord types are disabled:
        //   [2,7],     //sus2  = Suspended Two // Not recognized; Recognized as 5sus/1 eg. c,d,g = Gsus4/C
        //   [4,7,9],   //6  = Sixth // Not recognized; Recognized as vim7/1 eg. c,e,g,a = Am7/C
        //   [3,7,9],   //m6 = Minor Sixth // Not recognized; Recognized as vim7b5/1 eg. c,e,g,a = Am7b5/C
        //   [4,7,9,2], //6(9) = Nine Sixth //Removed; clashed with m7(11)
        //   [7],       //1+5 //Removed; has some problems

        // Sort chord from low to high notes
        chord.sort(function(a, b) { return (a.pitch) - (b.pitch); });
        
        var sorted_notes = removeDuplicateNotes12(chord);
        var intervals = findIntervals(sorted_notes);
        
        // Compare intervals with chord types for identification
        var idx_chtype = -1;
        var idx_rootpos = -1;
        var nb_found = 0;
        var all_found = false;
        var idx_chtype_arr = [];
        var idx_rootpos_arr = [];
        var cmp_result_arr = [];
        var nb_found_arr = [];
        // For each chord type
        for (var idx_chtype_ = 0; idx_chtype_ < all_chords.length; idx_chtype_++) {
            // For each interval (possible root position)
            for (var idx_rootpos_ = 0; idx_rootpos_ < intervals.length; idx_rootpos_++) {
                // Check if our arrays match
                var cmp_result = compareArray(all_chords[idx_chtype_][INTERVALS], intervals[idx_rootpos_]);
                // We found some intervals
                if (cmp_result.nb_found > 0) {
                    // A full chord match was found
                    if (cmp_result.nb_found == all_chords[idx_chtype_][INTERVALS].length) {
                        // Ensure chord is the "best" found
                        if (cmp_result.nb_found > nb_found) {
                            nb_found = cmp_result.nb_found;
                            idx_rootpos = idx_rootpos_;
                            idx_chtype = idx_chtype_;
                            if (nb_found == intervals[idx_rootpos_].length)
                                all_found = true;
                        }
                    }
                    // Save partial result
                    idx_chtype_arr.push(idx_chtype_);
                    idx_rootpos_arr.push(idx_rootpos_);
                    cmp_result_arr.push(cmp_result.cmp_arr);
                    nb_found_arr.push(cmp_result.nb_found);
                }
            }
        }
        
        // No full chord was found, so check for partial chords
        if (idx_chtype < 0 && idx_chtype_arr.length > 0) {
            nb_found = nb_found_arr.reduce(
                function(a,c){
                    return Math.max(a,c)
                }
            );

            // Look for a 7th shell voicing (no 5th)
            for (var i = 0; i < cmp_result_arr.length; i++) {
                // 3rd and 7th found (missing 5th)
                if (cmp_result_arr[i][0] === 1 && cmp_result_arr[i][2] === 1) {
                    idx_chtype = idx_chtype_arr[i];
                    idx_rootpos = idx_rootpos_arr[i];
                    break;
                }
            }

            // Look for a 3rd only
            if (idx_chtype < 0) {
                for (var i = 0; i < cmp_result_arr.length; i++) {
                    // 3rd found
                    if (cmp_result_arr[i][0] === 1) {
                        idx_chtype = idx_chtype_arr[i];
                        idx_rootpos = idx_rootpos_arr[i];
                        break;
                    }
                }
            }
        }

        var upper_extension_type = 0;
        
        // If we found at least one chord type
		if (idx_chtype >= 0) {
            console.log('Found chord number ' + idx_chtype);
            console.log('  root position: ' + idx_rootpos);
            console.log('  interval: ' + intervals[idx_rootpos]);

            // Check what type of chord we have
            if (idx_chtype == 1 || idx_chtype == 2 || idx_chtype == 3 || idx_chtype == 12 ) {
                // No upper extension
				upper_extension_type = 0;
			} else if ((idx_chtype >= 4 && idx_chtype <=11) || idx_chtype == 13 || idx_chtype == 14 ) {
                // 7th
			    upper_extension_type = 1;
			} else if ((idx_chtype >= 15 && idx_chtype <=20) || idx_chtype == 27 || idx_chtype == 31 ) {
                // 9th
			    upper_extension_type = 2;
			} else if ((idx_chtype >= 21 && idx_chtype <=24) || idx_chtype == 32 || idx_chtype == 33) {
                // 11th
			    upper_extension_type = 3;
			} else if (idx_chtype == 25 || idx_chtype ==26 || idx_chtype == 28 || idx_chtype == 29 || idx_chtype == 30 ) {
                // 13th
			    upper_extension_type = 4;
			}
			console.log('  upper extension: ' + upper_extension_type);

			root_note = sorted_notes[idx_rootpos];
            console.log('  root: ' + root_note);
        } else {
            console.log('No chord found');
        }

        var colorize = settings.chordColorMode;
        var regular_chord = [
            -1,-1,-1,-1,-1,-1,-1,-1,-1,-1
        ];
        var bass = null;

        var chordName = '';
        var chordNameRoman = '';

        // Chord was identified
        if (root_note !== null) {
            // Color notes and find root note
            for (i = 0; i < chord.length; i++) {
                // Color root note
                if ((chord[i].pitch % 12) === (root_note % 12)) {
                    regular_chord[0] = chord[i];

                    if (colorize)
                        chord[i].color = colorroot;
                    else
                        chord[i].color = black; 

                    if (bass == null)
                        bass = chord[i];
                // Color 3rd
                } else if ((chord[i].pitch % 12) === ((root_note + all_chords[idx_chtype][INTERVALS][0]) % 12)) {
                    regular_chord[1] = chord[i];

                    if (colorize)
                        chord[i].color = color3rd;
                    else
                        chord[i].color = black;

                    if (bass == null)
                        bass = chord[i];
                // Color 5th
                } else if (all_chords[idx_chtype][INTERVALS].length >= 2 && (chord[i].pitch % 12) === ((root_note + all_chords[idx_chtype][INTERVALS][1]) % 12)) {
                    regular_chord[2] = chord[i];

                    if (colorize)
                        chord[i].color = color5th;
                    else
                        chord[i].color = black;

                    if (bass == null)
                        bass = chord[i];
                // Color 13th (other)
                } else if (all_chords[idx_chtype][INTERVALS].length >= 6 && (chord[i].pitch % 12) === ((root_note + all_chords[idx_chtype][INTERVALS][5]) % 12)) {
                    regular_chord[6] = chord[i];

                    if (colorize)
                        chord[i].color = colorOth3;
                    else
                        chord[i].color = black;

                    if (bass == null)
                        bass = chord[i];
                // Color 11th (other)
                } else if (all_chords[idx_chtype][INTERVALS].length >= 5 && (chord[i].pitch % 12) === ((root_note + all_chords[idx_chtype][INTERVALS][4]) % 12)) {
                    regular_chord[5] = chord[i];

                    if (colorize)
                        chord[i].color = colorOth2;
                    else
                        chord[i].color = black;

                    if (bass == null)
                        bass = chord[i];
                // Color 9th (other)
                } else if (all_chords[idx_chtype][INTERVALS].length >= 4 && (chord[i].pitch % 12) === ((root_note + all_chords[idx_chtype][INTERVALS][3]) % 12)) {
                    regular_chord[4] = chord[i];

                    if (colorize)
                        chord[i].color = colorOth1;
                    else
                        chord[i].color = black;

                    if (bass == null)
                        bass = chord[i];
                // Color 7th
                } else if (all_chords[idx_chtype][INTERVALS].length >= 3 && (chord[i].pitch % 12) === ((root_note + all_chords[idx_chtype][INTERVALS][2]) % 12)) {
                    regular_chord[3] = chord[i];

                    if (colorize)
                        chord[i].color = color7th;
                    else
                        chord[i].color = black;

                    if (bass == null)
                        bass = chord[i];
                // Reset other note color
                } else {
                    chord[i].color = black; 
                }
            }
        
            // Find the chord's root note
            var chordRootNote;
            for (var i = 0; i < chord.length; i++) {
                if (chord[i].pitch % 12 == root_note)
                    chordRootNote = chord[i];
            }
            
            // Find the chord's name
            var notename = getNoteName(regular_chord[0].tpc);
            chordName = notename + all_chords[idx_chtype][STR];
            chordNameRoman = getNoteRomanSeq(regular_chord[0].pitch,keysig);
            chordNameRoman += all_chords[idx_chtype][STR];
        } else {
            for (i = 0; i < chord.length; i++) {
                chord[i].color = black; 
            }
        }

        // Find the chord's inversion
        inversion = -1;
        if (chordName !== '') {
            var bass_pitch = bass.pitch % 12;

            // Is the chord in root position?
            if (bass_pitch == root_note) {
                inversion = 0;
            } else {
                // This is incrementing inversion but will stop when we find the right inversion
                for (inversion = 1; inversion < all_chords[idx_chtype][INTERVALS].length + 1; inversion++) {
                   if (bass_pitch == ((root_note + all_chords[idx_chtype][INTERVALS][inversion - 1]) % 12))
                       break;
                }
            }
            console.log('  inversion: ' + inversion);
            
            // Set our inversions in those modes
            if (settings.inversionMode === 1 || settings.inversionMode === 2 ) {
                // Chord is a triad
                if (upper_extension_type == 0) {
                    chordName += inversions[inversion];
                    chordNameRoman += inversions[inversion];
                // Chord has upper extensions
                } else { 
                    if (upper_extension_type === 4) {
    				    chordName += inversions_13th[inversion]; 
                        chordNameRoman += inversions_13th[inversion];
    				} else if (upper_extension_type === 3) {
    				    chordName += inversions_11th[inversion]; 
                        chordNameRoman += inversions_11th[inversion];
    				} else if (upper_extension_type === 2) {
    				    chordName += inversions_9th[inversion]; 
                        chordNameRoman += inversions_9th[inversion];
    				} else if (upper_extension_type === 1) {
    				    chordName += inversions_7th[inversion]; 
                        chordNameRoman += inversions_7th[inversion];
    				}
                } 
            }
            
            if (settings.bassMode == 1 && inversion > 0) {
                chordName += "/" + getNoteName(bass.tpc);
            }
            
            if (settings.chordMode === 1 ) {
                chordName = chordNameRoman;
            } else if (settings.chordMode === 2 ) {
                chordName += " " + chordNameRoman
            }
        }

        if (!all_found)
            console.log('NOTE: Not all notes matched');

        return {
            chordName:      chordName,
            matchAllNotes:  all_found
        };
    }
    
    // Function: getSegmentHarmony
    //
    // Get a HARMONY element (Chord symbol) at the given segment if it exists
    function getSegmentHarmony(segment) {
        var aCount = 0;
        if (!segment.annotations)
            return null;
        var annotation = segment.annotations[aCount];
        while (annotation) {
            if (annotation.type == Element.HARMONY)
                return annotation;
            annotation = segment.annotations[++aCount];     
        }
        return null;
    } 
    
    // Function: chordDuration
    //
    // Get the number of ticks the chord represents
    function chordDuration(chord) {
        var duration = chord.globalDuration;
        if (!duration)
            duration = chord.duration;
        return duration.ticks;
    }

    // Function: getAllCurrentNotes
    //
    // Gets all notes on the selected stave(s) at the current cursor position
    function getAllCurrentNotes(cursor, startStaff, endStaff, onlySelected, prev_chord) {
        var full_chord = [];
        var tickLogged = false;

        // Loop through the staves in inverse order (lowest to highest)
        for (var staff = endStaff; staff >= startStaff; staff--) {
            // Loop through the voices in inverse order (lowest to highest, theoretically)
            for (var voice = 3; voice >= 0; voice--) {
                var trackLogged = false;
                cursor.voice = voice;
                cursor.staffIdx = staff;
                if (cursor.element && cursor.element.type == Element.CHORD) {
                    var notes = cursor.element.notes;
                    for (var i = 0; i < notes.length; i++) {
                        if (onlySelected && !notes[i].selected)
                            continue;
                        if ( !tickLogged ) {
                            tickLogged = true;
                        }
                        if ( !trackLogged ) {
                            trackLogged = true;
                        }
                        full_chord.push(notes[i]);
                    }
                }
            }
        }

		if (prev_chord) {
			for (var i = 0; i < prev_chord.length; i++) {
				var note = prev_chord[i];
				var excl = (note.parent.parent.tick + chordDuration(note.parent) > cursor.tick ? "!!!" : "");
				if (excl && settings.entireDurationMode)
					full_chord.push(note);
			}
		}
		
        return full_chord;
    }
    
    // Function: setToClosestNextElement
    //
    // Move cursor to closest next segment with Element elemType, whatever the track
    function setToClosestNextElement(cursor, elemType) {
        var seg = cursor.segment;
        if ( !seg )
            return false;

        while (seg = seg.next) {
            var tr;
            for (tr = 0; tr < curScore.ntracks; tr++) {
                var el = seg.elementAt(tr);
                if (el && el.type == elemType)
                    break;
            }

            if (tr < curScore.ntracks) {
                cursor.track = tr;
                while (cursor.tick < seg.tick)
                    cursor.next();
                return true;
            }
        }

        if (!seg) {
            // Reached end without finding Element Type
            return false;
        }
    }

    // Function: run
    //
    // Main entry point
    function run() {
        // Check that we are actually on a score
        if (typeof curScore === 'undefined') {
            quit();
        }

        // Check the MuseScore version
        // This plugin version is explicitly not targeting MuseScore 3.x or 2.x
        if (mscoreMajorVersion < 4) {
            console.log('This plugin requires MuseScore 4.0 and above');
            return;
        }

        var cursor = curScore.newCursor();
        var startStaff;
        var endStaff;
        var endTick;
        var fullScore = false;

        cursor.rewind(1);
                
        // No selection, so process the whole score
        if (!cursor.segment) {
            fullScore = true;
            startStaff = 0;
            endStaff = curScore.nstaves - 1;
        // Selection, process only those staves
        } else {
            console.log("HERE")
            startStaff = cursor.staffIdx;
            cursor.rewind(2);
            if (cursor.tick === 0) {
                // this happens when the selection includes
                // the last measure of the score.
                // rewind(2) goes behind the last segment (where
                // there's none) and sets tick=0
                endTick = curScore.lastSegment.tick + 1;
            } else {
                endTick = cursor.tick;
            }
            endStaff = cursor.staffIdx;
        }

        console.log('Processing chords:');
        console.log('  start staff: ' + startStaff);
        console.log('  end staff: ' + endStaff);
        console.log('  num staves: ' + (endStaff - startStaff));
        console.log('  cursor tick: ' + cursor.tick);
        console.log('  end tick: ' + endTick);

        // Move to the beginning of the selection
        cursor.rewind(1);
        // ...or to the beginning of the score if needed
        if (fullScore) {
            cursor.rewind(0);
        }
        
        // Select voice 0
        cursor.voice = 0;
        // Select the starting staff
        cursor.staffIdx = startStaff;

        // Get the current key signature
        var keySig = cursor.keySignature;
        var keysig_name_major = getNoteName(keySig+7+7);
        var keysig_name_minor = getNoteName(keySig+7+10);
        console.log('  key signature: ' + keySig);
        console.log('  key: ' + keysig_name_major + ' major/' + keysig_name_minor + ' minor');
        
        var segment;
        var chordName = '';
        var curr_matched_all = false;
        var full_chord = [];

        // Loop through the segments
        while (segment = cursor.segment && (fullScore || cursor.tick < endTick)) {
            // Set the previous chord value
            var prev_full_chord = full_chord;

            // Get all notes in the selected staves at the current position
            full_chord = getAllCurrentNotes(cursor, startStaff, endStaff, !fullScore, full_chord);
            
            // If 1 or more notes are found...
            if (full_chord.length > 0) {
                console.log('Found ' + full_chord.length + ' notes at tick ' + cursor.tick);

                var prev_chordName = chordName;
                var prev_matched_all = curr_matched_all;

                // Get the chord name
                var gcnRes = getChordName(full_chord, cursor.keySignature);
                chordName = gcnRes.chordName;
                curr_matched_all = gcnRes.matchAllNotes;

                console.log('  chord name: ' + chordName);

                var harmonyText = chordName;
                var harmonyColor = black;

                if (harmonyText && !gcnRes.matchAllNotes) {
                    if (settings.partialChordMode)
                        harmonyColor = red;
                }

                // Get a chord symbol if it exists and replace it
                var harmony = getSegmentHarmony(segment);
                if (harmony) {
                    harmony.text = harmonyText;
                    harmony.color = harmonyColor;
                // Otherwise create a new one
                } else {
                    harmony = newElement(Element.HARMONY);
                    harmony.text = harmonyText;
                    harmony.color = harmonyColor;
                    cursor.add(harmony);
                }

                // Skip displaying a duplicate chord if:
                //  * current and previous fully matched
                //  * previous chord notes are fully identical to current
                if ((prev_chordName == chordName && prev_matched_all && curr_matched_all) || areNotesEqual(prev_full_chord, full_chord)) {
                    harmony.text = '';
                }
            }
            
            // Check if we're at the next element and break (?)
            if (!setToClosestNextElement(cursor, Element.CHORD))
                break;
        } // end while segment
    } // end run
}
