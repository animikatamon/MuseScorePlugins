//=============================================================================
//  MuseScore - Check adherence to Barbershop Harmony rules
//              Copyright (C) 2020 Mendy Mendelsohn
//
//  Suggestions: - Mark incomplete triads (with 3 voices and above?)
//               - Better recognize minor key (add sub-option for Minor?)
//                   (less important becasue BBS is mostly in Major key?)
//  TODO: don't test/output chords with less than 3 notes
//        add test cases for aug7 + dom7b5
//        test on 4 staves
//        test different flag combos
//        put err text on correct staff/s?
//        try suggesting BBS chords instead of XX chords 
//        use all staves, regardless of selection
//        spell 79(noRoot) chord alongside m6 equivalent?
//  possibly older issues:
//        make sure to colorize only notes of fully recognized chords (regardless of whether Bass is OK)
//        stop traversing notes where only older notes are included in selection (what if one of chord notes stops and the other continue?)
//
//  Code Repository, Documentation, Issues & Requests: https://github.com/AniMikatamon/MuseScorePlugins
//  
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License version 2
//  as published by the Free Software Foundation and appearing in
//  the file "LICENSE - GPLv2"
//
//  Prior contributors:
//  Based on https://musescore.org/en/project/chord-identifier-pop-jazz
//      and on work by: 
//  Chgd. debugged fixed and new-code added by: Ziya Mete Demircan 2019/04/09 23:02
//  Copyright (C) 2016 Emmanuel Roussel - https://github.com/rousselmanu/msc_plugins
//  I started this plugin as an improvement of the "Find Harmonies" plugin by Andresn 
//      (https://github.com/andresn/standard-notation-experiments/tree/master/MuseScore/plugins/findharmonies)
//      itself being an enhanced version of "findharmony" by Merte (http://musescore.org/en/project/findharmony)
//  I took some lines of code or got inspiration from:
//  - Berteh (https://github.com/berteh/musescore-chordsToNotes/)
//  - Jon Ensminger (AddNoteNameNoteHeads v. 1.2 plugin)
//  Thank you :-)
// 
//=============================================================================

import MuseScore 3.0

import QtQuick.Window 2.2

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts

MuseScore {
	requiresScore: true
    description: 'Check adherence of arrangement to Barbershop Harmony rules'
    version: "4.6.1"
    title: "Barbershop Checker + Chord Analyzer"
    categoryCode: "composing-arranging-tools"
    
//    pluginType: "dock"
//    dockArea:   "left"
//
    pluginType: "dialog"
    width: 480
    height: 320
    id: chordDialog
    
    Component.onCompleted : {
        if (mscoreVersion.major >= 4) {
            chordDialog.title = "Chord Identifier (Pop & Jazz)";
        }
    }

    Settings {
        id: settings
        category: "BBScheckerS2"
        property int duplicateScore       : 0 //whether to work on copy of score 
        property int modifyNoteheads      : 1 //whether to show BBS issues with colored noteheads
        property int showTextRemarks      : 0 //whether to show BBS issues on Staff text
        property int displayChordAnalysis : 0 //whether to output chord analysis for all chords
        property int displayChordText     : 1 //whether to add chord symbol to all chords
        property int displayChordMode     : 0 //0: Normal chord C  F7  Gm  //1: Roman Chord level   Ⅳ
        property int displayChordColor    : 0 //0: disable, 1 enable
        // property int dontDisplayBBSissues : 0 //0: display, 1 don't - replaced by modifyNoteheads & showTextRemarks
    }
    // original settings of Pop&Jazz Chord Identifier
    property int inversion_notation   : 0 //0: none //1: note with superscript (1, 2 or 3) //2: figured bass notation
    property int display_bass_note    : 1 //1: bass note is specified after a / like that: C/E for first inversion C chord.
    property int entire_note_duration : 1 //1: consider full duration of note in chords.
    // property int hidePartialChords    : 0 //1: display ?? for incomplete chords //0: allow suggestion (with red chord)

    property variant fCheckBBSrules
    property variant fAlwaysAddChords
    property variant fDisplayRomanChords
    property variant fColorChordNotes

    property variant partialCodeStr: "XX"
    property variant partsBBS: [ 'Tenor', 'Lead', 'Bari', 'Bass' ]

    property variant black     : "#000000"
    property variant colorOth3 : "#C080C0"    //color: ext.:(9/11/13)
    property variant colorOth2 : "#80C0C0"    //color: ext.:(9/11/13)
    property variant colorOth1 : "#4080C0"    //color: ext.:(9/11/13)
    property variant color7th  : "#804080"    //color: 7th
    property variant color5th  : "#808000"    //color: 5th
    property variant color3rd  : "#008000"    //color: 3rd (4th for suss4)
    property variant colorroot : "#800000"    //color: Root
//--------------------------------------------------------------------------------
    property variant red       : "#ff0000"
    property variant green     : "#00ff00"
    property variant blue      : "#0000ff"

    onRun: {
        //  MM: Is this the right place to do initializations?
        dupScore.checked = settings.duplicateScore;
        redNoteheads.checked = settings.modifyNoteheads;
        textRemarks.checked = settings.showTextRemarks;
        chordAnalysis.checked = settings.displayChordAnalysis;
        setupChordGroup();
        addChordSymbols.checked = settings.displayChordText;
        chordMode.currentIndex = settings.displayChordMode;
        colorizeNotes.checked = settings.displayChordColor;
        // ignoreBBS.checked = settings.dontDisplayBBSissues;
/*        if (!String.format) {
            String.format = function(format) {
                var args = Array.prototype.slice.call(arguments, 1);
                return format.replace(/{(\d+)}/g, function(match, number) { 
                return typeof args[number] != 'undefined'
                    ? args[number] 
                    : match
                ;
                });
            };
        }*/
    }

    // ---------- get note name from TPC (Tonal Pitch Class):
    function getNoteName(note_tpc){ 
        var notename = "";
        var tpc_str = ["Cbb","Gbb","Dbb","Abb","Ebb","Bbb",
            "Fb","Cb","Gb","Db","Ab","Eb","Bb","F","C","G","D","A","E","B","F#","C#","G#","D#","A#","E#","B#",
            "F##","C##","G##","D##","A##","E##","B##","Fbb"]; //tpc -1 is at number 34 (last item).
        if(note_tpc != 'undefined' && note_tpc<=33){
            if(note_tpc==-1) 
                notename=tpc_str[34];
            else
                notename=tpc_str[note_tpc];
        }
        return notename;
    }
// Roman numeral sequence for chords ①②③④⑤⑥⑦  Ⅰ  Ⅱ Ⅲ  Ⅳ  Ⅴ Ⅵ   Ⅶ Ⅷ Ⅸ Ⅹ Ⅺ Ⅻ
    function getNoteRomanSeq(note,keysig){
        var notename = "";
        var num=0;
        var keysigNote = [11,6,1,8,3,10,5,0,7,2,9,4,11,6,1];
        var Roman_str_flat_mode1 = ["Ⅰ","Ⅱ♭","Ⅱ","Ⅲ♭","Ⅲ","Ⅳ","Ⅴ♭","Ⅴ","Ⅵ♭","Ⅵ","Ⅶ♭","Ⅶ"];
        var Roman_str_flat_mode2 =  ["①","②♭","②","③♭","③","④","⑤♭","⑤","⑥♭","⑥","⑦♭","⑦"];

        if(keysig != 'undefined' ){
            num=(note+12-keysigNote[keysig+7])%12;
            notename=Roman_str_flat_mode1[num];

        }
        //console.log("keysigNote num:"+note + " "+ keysig + " "+notename);
        return notename;
    }

    function string2Roman(str){
        var strtmp="";
        strtmp=str[0];
        if(str.length>1 && str[1]=="♭")
            strtmp+=str[1];
        var Roman_str_flat_mode1 = ["Ⅰ","Ⅱ♭","Ⅱ","Ⅲ♭","Ⅲ","Ⅳ","Ⅴ♭","Ⅴ","Ⅵ♭","Ⅵ","Ⅶ♭","Ⅶ"];
        var Roman_str_flat_mode2 =  ["①","②♭","②","③♭","③","④","⑤♭","⑤","⑥♭","⑥","⑦♭","⑦"];
        var i=0;
        for(;i<Roman_str_flat_mode1.length;i++)
            if(strtmp==Roman_str_flat_mode1[i])
                return i;

        return -1;
    }    
    function remove_dup_mod(chord, mod){
        var chord_notes=new Array();

        for(var i=0; i<chord.length; i++)
            chord_notes[i] = chord[i].pitch%mod; // remove octaves (if mod=12)

        chord_notes.sort(function(a, b) { return a - b; }); //sort notes

        var sorted_chord_uniq = chord_notes.filter(function(elem, index, self) {
            return index == self.indexOf(elem);
        }); //remove duplicates

        return sorted_chord_uniq;
    }
    // ---------- remove duplicate from chord notes (original pitch) --------
    function remove_dup_mod12(chord){
        return remove_dup_mod(chord, 12);
    }
    // ---------- remove duplicate from chord notes (in single octave) --------
    function remove_dup(chord){
        return remove_dup_mod(chord, 10000);
    }
    
    function areNotesEqual(chord1, chord2){
        // currently does not check for voice-by-voice equality 
        var a1 = remove_dup(chord1);
        var a2 = remove_dup(chord2);
        return a1.length == a2.length && a1.every(function(value, i) { return value === a2[i]})
    }

    // ---------- find intervals for all possible positions of the root note ---------- 
    function find_intervals(sorted_chord_uniq){
        var n=sorted_chord_uniq.length;
        var intervals = new Array(n); for(var i=0; i<n; i++) intervals[i]=new Array();

        for(var root_pos=0; root_pos<n; root_pos++){ //for each position of root note in the chord
            var idx=-1;
            for(var i=0; i<n-1; i++){ //get intervals from current "root"
                var cur_inter = (sorted_chord_uniq[(root_pos+i+1)%n] - sorted_chord_uniq[(root_pos+i)%n])%12;  
                while(cur_inter<0)
                    cur_inter+=12;
                if(cur_inter != 0){// && (idx==-1 || intervals[root_pos][idx] != cur_inter)){   //avoid duplicates and 0 intervals
                    idx++;
                    intervals[root_pos][idx]=cur_inter;
                    if(idx>0)
                        intervals[root_pos][idx]+=intervals[root_pos][idx-1];
                }
            }
            //debug:
            console.log('\t intervals: ' + intervals[root_pos]);
        }

        return intervals;
    }
    
    function compare_arr(ref_arr, search_elt) { //returns an array of size ref_tab.length
        if (ref_arr == null || search_elt == null) return [];
        var cmp_arr=[], nb_found=0;
        for(var i=0; i<ref_arr.length; i++){
            if( search_elt.indexOf(ref_arr[i]) >=0 ){
                cmp_arr[i]=1;
                nb_found++;
            }else{
                cmp_arr[i]=0;
            }
        }
        return {
            cmp_arr: cmp_arr,
            nb_found: nb_found
        };
    }
        
    function checkWholeChord(chord,keysig) {
//        var INVERSION_NOTATION = 0; //set to 0: inversions are not shown
                                    //set to 1: inversions are noted with superscript 1, 2 or 3
                                    //set to 2: figured bass notation is used instead
                                
//        var DISPLAY_BASS_NOTE = 0; //set to 1: bass note is specified after a / like that: C/E for first inversion C chord.

        //Standard notation for inversions:
        if(inversion_notation===1){
            var inversions = ["", " \u00B9", " \u00B2"," \u00B3"," \u2074"," \u2075"," \u2076"," \u2077"," \u2078"," \u2079"]; // unicode for superscript "1", "2", "3" (e.g. to represent C Major first, or second inversion)
            var inversions_7th = inversions;
            var inversions_9th  = inversions;
            var inversions_11th = inversions;
            var inversions_13th = inversions;

        }else if(inversion_notation===2){//Figured bass of inversions:
            var inversions = ['', ' \u2076', ' \u2076\u2084','','','','','','',''];
            var inversions_7th = [' \u2077', ' \u2076\u2085', ' \u2074\u2083', ' \u2074\u2082', ' \u2077-\u2074', ' \u2077-\u2075', ' \u2077-\u2076', ' \u2077-\u2077', ' \u2077-\u2078', ' \u2077-\u2079'];
            var inversions_9th = [' \u2079', ' inv\u00B9', ' inv\u00B2', ' inv\u00B3',' inv\u2074',' inv\u2075',' inv\u2076',' inv\u2077',' inv\u2078',' inv\u2079'];
            var inversions_11th = [' \u00B9\u00B9', ' inv\u00B9', ' inv\u00B2', ' inv\u00B3',' inv\u2074',' inv\u2075',' inv\u2076',' inv\u2077',' inv\u2078',' inv\u2079'];
            var	inversions_13th = [' \u00B9\u00B3', ' inv\u00B9', ' inv\u00B2', ' inv\u00B3',' inv\u2074',' inv\u2075',' inv\u2076',' inv\u2077',' inv\u2078',' inv\u2079'];
        }else{
            var inversions      = ["","","","","","","","","",""]; 
            var inversions_7th  = [" \u2077","","","","","","","","",""]; 
            var inversions_9th  = [" \u2079","","","","","","","","",""]; 
            var inversions_11th = [" \u00B9\u00B9","","","","","","","","",""]; 
            var inversions_13th = [" \u00B9\u00B3","","","","","","","","",""]; 
        }
            
        var rootNote = null,
            inversion = null,
            partial_chord=0;
        
        // intervals (number of semitones from root note) for main chords types...          //TODO : revoir fonctionnement et identifier d'abord triad, puis seventh ?
        //          0    1   2    3        4   5          6      7    8         9     10    11
        // numeric: R,  b9,  9,  m3(#9),  M3, 11(sus4), #11(b5), 5,  #5(b13),  13(6),  7,   M7  //Ziya
        const ENDBBS = "END BBS";
        const STR = 0;
        const INTERVALS = 1;
        const BASS5thALLOWED = 2, OK5 = true, NOT5 = false, SYM = false/*i.e. meaningless*/;
        const MINOCTAVEINTERVAL = 3;
        const all_chords = [
            // BBS chords - (2.#) numbering per https://www.sunshinetracks.com/chords.pdf
            //              (p#) numbering for page no. in 1980 "Bible"
            [ "",           [4,7],    OK5 ],    //(2.1) M (0)*
            [ "7",          [4,7,10], OK5 ],    //(2.2) 7 = Dominant/BBS Seventh*
            [ "Maj7",       [4,7,11], NOT5 ],   //(2.3) M7 = Major Seventh*
            [ "(add9)",     [4,7,2],  NOT5, 2 ],//(2.4) add9 = Major additional Ninth*
            [ "6(no5)",     [4,9],    NOT5 ],   //(p13) Major Sixth without 5* (not to be confused with m)
            [ "6",          [4,7,9],  NOT5 ],   //(2.5) add6 = Major Sixth* (not to be confused with m7)
            [ "79(no5)",    [4,10,2], NOT5, 2 ],//(2.6) 7(9) = Dominant Seventh, plus Ninth, no Fifth*    
            [ "m",          [3,7],    OK5 ],    //(2.7) m* (not to be confused with 6no5)
            [ "m6",         [3,7,9],  NOT5 ],   //(2.8) m / 79(no root)* (not to be confused with Half Dimished)
            [ "m7",         [3,7,10], OK5 ],    //(2.9) m7 = minor Seventh* (not to be confused with Major 6)
            [ "o7",         [3,6,9],  SYM ],    //(2.10) dim7 = Diminished Seventh*
            [ "dim",        [3,6],    NOT5 ],   //(p260) dim triad* 
            [ "aug",        [4,8],    SYM ],    //(2.11) #5 = Augmented / Majör Raised Fifth*
            [ "0",          [3,6,10], OK5 ],    //(p255) m7b5 = ø = minor 7th, Flat Fifth* / Half Diminished
            [ "aug7",       [4,8,10], NOT5 ],   //11: #57 = Dominant Seventh, Raised Fifth*
            [ "7(b5)",      [4,6,10], SYM ],    //14: M7b5 = Dom 7th, Flat Fifth*                     
            [ ENDBBS, [0,0,0] ],
            // non-BBS chords (numberings meaningless, carried over from from original list)
            [ "sus4",       [5,7] ],            //03: sus4 = Suspended Fourth*
            [ "7sus4",      [5,7,10] ],         //04: 7sus4 = Dominant7, Suspended Fourth*
            [ "m(Maj7)",    [3,7,11] ],         //06: mMa7 = minor Major Seventh*
            [ "Maj7(#5)",   [4,8,11] ],         //10: #5Maj7 = Major Seventh, Raised Fifth*
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
        //Notice: [2,7],     //sus2  = Suspended Two // Not recognized; Recognized as 5sus/1 eg. c,d,g = Gsus4/C
        //(distinguishable using Bass)Notice: [4,7,9],   //6  = Sixth // Not recognized; Recognized as vim7/1 eg. c,e,g,a = Am7/C
        //(distinguishable using Bass)Notice: [3,7,9],   //m6 = Minor Sixth // Not recognized; Recognized as vim7b5/1 eg. c,e,g,a = Am7b5/C
        //Notice: [4,7,9,2], //6(9) = Nine Sixth //Removed; clashed with m7(11)
        //Notive: [7],       //1+5 //Removed; has some problems
                            
                            //... and associated notation:
        //var chord_str = ["", "m", "\u00B0", "MM7", "m7", "Mm7", "\u00B07"];
        // var chord_str = ["", "m", "dim", "sus4",  "7sus4", "Maj7", "m(Maj7)", "m7", "7", "o7", "Maj7(#5)", "7(#5)", "aug", "0", "7(b5)", "(add9)", "Maj9", "9", "m(add9)", "m9(Maj7)", "m9", "Maj7(#11)", "Maj9(#11)", "7(#11)", "9(#11)", "7(13)", "9(13)", "7(b9)","7(b13)", "7(b9/b13)", "11(b9/b13)", "7(#9)", "m7(11)", "m11", "x"];
        /*var chord_type_reduced = [ [4],  //M
                                    [3],  //m
                                    [4,11],   //MM7
                                    [3,10],   //m7
                                    [4,10]];  //Mm7
        var chord_str_reduced = ["", "m", "MM", "m", "Mm"];*/
        /*var major_scale_chord_type = [[0,3], [1,4], [1,4], [0,3], [0,5], [1,4], [2,6]]; //first index is for triads, second for seventh chords.
        var minor_scale_chord_type = [[0,4], [2,6], [0,3], [1,4], [0,5], [0,3], [2,6]];*/

        // ---------- SORT CHORD from lowest to highest --------
        chord.sort(function(a, b) { return (a.pitch) - (b.pitch); }); //lowest note is now chord[0]
        
        var sorted_chord_uniq = remove_dup_mod12(chord); //remove multiple occurence of octave notes in chord
        console.log('sorted chord: ' + sorted_chord_uniq);
        if (sorted_chord_uniq.length < 3) // minimal notes for triad or more
            return { chordName: "" };
        var intervals = find_intervals(sorted_chord_uniq);

        //debug:
        //for(var i=0; i<chord_uniq.length; i++) console.log('pitch note ' + i + ': ' + chord_uniq[i]);
        // console.log('compare: ' + compare_arr([0,1,2,3,4,5],[1,3,4,2])); //returns [0,1,1,1,1,0}
        
        // ---------- Compare intervals with chord types for identification ---------- 
        var idx_chtype=-1, idx_rootpos=-1, bestNbFound=0, all_found = false;
        var idx_chtype_arr=[], idx_rootpos_arr=[], cmp_result_arr=[], nb_found_arr=[];
        var isBBS = true, foundBBS = false, foundGoodBass = false, issues = [];
        for(var i_chType=0; i_chType<all_chords.length; i_chType++){ //chord types. 
            var currChord = all_chords[i_chType];
            if (currChord[STR] == ENDBBS)
                { isBBS = false; continue; }
            for(var i_rPos=0; i_rPos<intervals.length; i_rPos++){ //loop through the intervals = possible root positions
                var cmp_result = compare_arr(currChord[INTERVALS], intervals[i_rPos]);
                if(cmp_result.nb_found>0){ //found some intervals
                    if(cmp_result.nb_found == currChord[INTERVALS].length){ //full chord found!
                        var currBassGood = false;
                        var df = cmp_result.nb_found - bestNbFound;
                        if(df > 0                              //keep chord with maximum number of matching intervals
                           || (df == 0 && !foundGoodBass)) {  //OR with a better Bass note
                            if (isBBS) {
                                // check if new Bass is good
                                var bassInterval = (chord[0].pitch+12-sorted_chord_uniq[i_rPos])%12;
                                currBassGood = (bassInterval == 0
                                                || (currChord[BASS5thALLOWED] && (bassInterval == 7
                                                                                || bassInterval == 6)));
                                console.log('bassInterval='+bassInterval+'  currBassGood='+currBassGood
                                            +'  '+currChord[STR]+'/inv'+i_rPos+'  found',cmp_result.nb_found);
                            }
                            if (df > 0 || currBassGood) {
                                // found something better
                                issues = [];
                                if ( isBBS && !currBassGood )
                                    issues.push({ notes:[chord[0]], msg:"Voicing" });
                                if (typeof(currChord[MINOCTAVEINTERVAL]) !== 'undefined') {
                                    var idx4octave = currChord[MINOCTAVEINTERVAL];
                                    var rtNote = chord.find(function(nt){return nt.pitch%12 == sorted_chord_uniq[i_rPos]%12});
                                    var octNote = chord.find(function(nt){return nt.pitch%12 == (sorted_chord_uniq[i_rPos] +
                                                                                                 currChord[INTERVALS][idx4octave])%12});
                                    console.log('  check octave:'+idx4octave,'root='+rtNote.pitch,'oct=',octNote.pitch);
                                    if (octNote.pitch - rtNote.pitch < 12)
                                        issues.push({ notes:[rtNote, octNote], msg:"Low 9" });
                                }
                                foundBBS = isBBS;
                                foundGoodBass = currBassGood;
                                bestNbFound = cmp_result.nb_found;
                                idx_rootpos = i_rPos;
                                idx_chtype = i_chType;
                                if (bestNbFound == intervals[i_rPos].length)
                                    all_found = true;
                            }
                        } //else
                            // console.log('!! Something wrong with "chord_type" list');
                    }
                    idx_chtype_arr.push(i_chType); //save partial results
                    idx_rootpos_arr.push(i_rPos);
                    cmp_result_arr.push(cmp_result.cmp_arr);
                    nb_found_arr.push(cmp_result.nb_found);
                }
            }
        }
        
        if(idx_chtype<0 && idx_chtype_arr.length>0){ //no full chord found, but found partial chords
            // console.log('other partial chords: '+ idx_chtype_arr);
            // console.log('root_pos: '+ idx_rootpos_arr);
            // console.log('cmp_result_arr: '+ cmp_result_arr);
            bestNbFound = nb_found_arr.reduce(function(a,c){return Math.max(a,c)});
            console.log('bestNbFound',bestNbFound,'\n    chord / result:');
            for(var i=0; i<cmp_result_arr.length; i++) {
                if ( nb_found_arr[i]==bestNbFound ) {
                    var rtNote = chord.find(function(nt){return nt.pitch%12 == sorted_chord_uniq[idx_rootpos_arr[i]]%12});
                    console.log('    '+getNoteName(rtNote.tpc)
                                    +all_chords[idx_chtype_arr[i]][STR]
                                    +'('+all_chords[idx_chtype_arr[i]][INTERVALS]+') /'+cmp_result_arr[i]);
                    // 			rootNote=sorted_chord_uniq[idx_rootpos];
                    //  getNoteName(regular_chord[0].tpc);
                }
            }

            for(var i=0; i<cmp_result_arr.length; i++){
                if(cmp_result_arr[i][0]===1 && cmp_result_arr[i][2]===1){ //third and 7th ok (missing 5th)
                    idx_chtype=idx_chtype_arr[i];
                    idx_rootpos=idx_rootpos_arr[i];
                    console.log('3rd + 7th OK!');
                    break;
                }
            }
            if(idx_chtype<0){ //still no chord found. Check for third interval only (missing 5th and 7th)
                for(var i=0; i<cmp_result_arr.length; i++){
                    if(cmp_result_arr[i][0]===1){ //third ok 
                        idx_chtype=idx_chtype_arr[i];
                        idx_rootpos=idx_rootpos_arr[i];
                        console.log('3rd OK!');
                        break;
                    }
                }
            }
        }
        var seventhchord=0;    
        
        if(idx_chtype>=0){
            console.log('FOUND CHORD ['+ all_chords[idx_chtype][STR] +']! root_pos: '+idx_rootpos);
            console.log('\t interval: ' + intervals[idx_rootpos]);
            if (idx_chtype == 1 || idx_chtype == 2 || idx_chtype == 3 || idx_chtype == 12 ) {
                seventhchord=0;
            } else if ((idx_chtype >= 4 && idx_chtype <=11) || idx_chtype == 13 || idx_chtype == 14 ) {
                seventhchord=1;  //7th
            } else if ((idx_chtype >= 15 && idx_chtype <=20) || idx_chtype == 27 || idx_chtype == 31 ) {
                seventhchord=2; //9th
            } else if ((idx_chtype >= 21 && idx_chtype <=24) || idx_chtype == 32 || idx_chtype == 33) {
                seventhchord=3; //11th
            } else if (idx_chtype == 25 || idx_chtype ==26 || idx_chtype == 28 || idx_chtype == 29 || idx_chtype == 30 ) {
                seventhchord=4; //13th
            }
            console.log('\t SEVENTHCHORD: ' + seventhchord + '\t idx_chtype: '+idx_chtype);
            rootNote=sorted_chord_uniq[idx_rootpos];
            console.log('\t rootNote: '+rootNote); //Ziya
        }else{
            console.log('No chord found');
        }

        // var colorize = settings.displayChordColor;
        var regular_chord=[-1,-1,-1,-1,-1,-1,-1,-1,-1,-1]; //without NCTs
        var bass=null; 
        
        var chordName='';
        var chordNameRoman='';
        if (rootNote !== null) { // ----- a chord was identified
            for(i=0; i<chord.length; i++){  // ---- color notes and find root note
                if((chord[i].pitch%12) === (rootNote%12)){  //color root note
                    regular_chord[0] = chord[i];
                    if (fColorChordNotes) chord[i].color = colorroot; //else chord[i].color = black; 
                    if(bass==null) bass=chord[i];
                }else if((chord[i].pitch%12) === ((rootNote+all_chords[idx_chtype][INTERVALS][0])%12)){ //third note
                    regular_chord[1] = chord[i];
                    if (fColorChordNotes) chord[i].color = color3rd; //else chord[i].color = black;
                    if(bass==null) bass=chord[i];
                }else if(all_chords[idx_chtype][INTERVALS].length>=2 && (chord[i].pitch%12) === ((rootNote+all_chords[idx_chtype][INTERVALS][1])%12)){ //5th
                    regular_chord[2] = chord[i];
                    if (fColorChordNotes) chord[i].color = color5th; //else chord[i].color = black;
                    if(bass==null) bass=chord[i];
                }else if(all_chords[idx_chtype][INTERVALS].length>=6 && (chord[i].pitch%12) === ((rootNote+all_chords[idx_chtype][INTERVALS][5])%12)){ //13Other
                    regular_chord[6] = chord[i];
                    if (fColorChordNotes) chord[i].color = colorOth3; //else chord[i].color = black;
                    if(bass==null) bass=chord[i];
                    //seventhchord=4;
                }else if(all_chords[idx_chtype][INTERVALS].length>=5 && (chord[i].pitch%12) === ((rootNote+all_chords[idx_chtype][INTERVALS][4])%12)){ //11Other
                    regular_chord[5] = chord[i];
                    if (fColorChordNotes) chord[i].color = colorOth2; //else chord[i].color = black;
                    if(bass==null) bass=chord[i];
                    //seventhchord=3;
                }else if(all_chords[idx_chtype][INTERVALS].length>=4 && (chord[i].pitch%12) === ((rootNote+all_chords[idx_chtype][INTERVALS][3])%12)){ //9Other
                    regular_chord[4] = chord[i];
                    if (fColorChordNotes) chord[i].color = colorOth1; //else chord[i].color = black;
                    if(bass==null) bass=chord[i];
                    //seventhchord=2;
                }else if(all_chords[idx_chtype][INTERVALS].length>=3 && (chord[i].pitch%12) === ((rootNote+all_chords[idx_chtype][INTERVALS][2])%12)){ //7th
                    regular_chord[3] = chord[i];
                    if (fColorChordNotes) chord[i].color = color7th; //else chord[i].color = black;
                    if(bass==null) bass=chord[i];
                    //seventhchord=1;
                }else{      //reset other note color 
                    //seventhchord='';
                    // chord[i].color = black; 
                }
            }
        
            // ----- find root note //commentted before: Ziya
            var chordRootNote;
            for(var i=0; i<chord.length; i++){
                if(chord[i].pitch%12 == rootNote)
                    chordRootNote = chord[i];
            }
            
            // ----- find chord name:
            var notename = getNoteName(regular_chord[0].tpc);
            chordName = notename + all_chords[idx_chtype][STR];
            chordNameRoman = getNoteRomanSeq(regular_chord[0].pitch,keysig);
            console.log(' 382: chordNameRoman1: '+chordNameRoman); 
            chordNameRoman += all_chords[idx_chtype][STR];
            console.log(' 384: chordNameRoman2: '+chordNameRoman); 

        }/*else{
            for(i=0; i<chord.length; i++){
                chord[i].color = black; 
            }
        }*/

        // ----- find inversion
        var inv=-1;
        if (chordName !== ''){ // && inversion !== null) {
            var bass_pitch=bass.pitch%12;
            //console.log('bass_pitch: ' + bass_pitch);
            if(bass_pitch == rootNote){ //Is chord in root position ?
                inv=0;
            }else{
                for(inv=1; inv<all_chords[idx_chtype][INTERVALS].length+1; inv++){
                if(bass_pitch == ((rootNote+all_chords[idx_chtype][INTERVALS][inv-1])%12)) break;
                //console.log('note n: ' + ((chord[idx_rootpos].pitch+intervals[idx_rootpos][inv-1])%12));
                }
            }
            console.log('\t inv: ' + inv);
            
            
            // Commented: Both are fixed now -Ziya.
            
            if (inversion_notation===1 || inversion_notation===2 ) {
                if(seventhchord == 0){ //we have a triad:
                    chordName += inversions[inv]; //no inversions for this version.
                    chordNameRoman += inversions[inv]; //no inversions for this version.
                }else{  //we have a 7th chord 
                    if (seventhchord===4) {
                        chordName += inversions_13th[inv]; 
                        chordNameRoman += inversions_13th[inv];
                    } else if (seventhchord===3) {
                        chordName += inversions_11th[inv]; 
                        chordNameRoman += inversions_11th[inv];
                    } else if (seventhchord===2) {
                        chordName += inversions_9th[inv]; 
                        chordNameRoman += inversions_9th[inv];
                    } else if (seventhchord===1) {
                        chordName += inversions_7th[inv]; 
                        chordNameRoman += inversions_7th[inv];
                    }
                } 
            }
            
        // if(bassMode===1 && inv>0){
            if(display_bass_note==1 && inv>0){
                chordName+="/"+getNoteName(bass.tpc);
            }
            
            if(fDisplayRomanChords) {
                chordName = chordNameRoman;
            // } else if(settings.displayChordMode === 2 ) {
            //     chordName += " "+chordNameRoman
            }
        }

        if ( ! all_found)
            console.log(' >> not all notes matched');

        return {
            chordName:      chordName,
            matchAllNotes:  all_found,
            isBBSchord:     foundBBS,
            goodBass:       foundGoodBass,
            BBSissues:      issues
        };
    }

    function findStaffLayout(notes) {
        // recognize distribution of staves. return values:
        // 2 = 2 staves x 2 voices
        // 4 = 4 staves x 1 voice
        // 0 = other
        const staffLayouts = [
            { id:2, tracks:[0, 1, 4, 5] },
            { id:4, tracks:[0, 4, 8, 12] }
        ];
        if (notes.length < 3 || notes.length > 4)
            return null;

        var tracks = [];
        notes.forEach(function (v) {
            if (tracks.indexOf(v.track) < 0)
                tracks.push(v.track);
        });
        // console.log('tracks:'+tracks,'len:'+tracks.length,'notes.len:'+notes.length);
        // console.log(staffLayouts.length,'layouts');
        if (tracks.length != notes.length)
            return null;
        for (var i = 0; i < staffLayouts.length; i++)
            if (tracks.every(function(v) { return staffLayouts[i].tracks.indexOf(v) >= 0; }))
                return staffLayouts[i];
        return null;
    }
    function partName(stLayout, trk) {
        if ( ! stLayout )
            return null;
        var i = stLayout.tracks.indexOf(trk);
        if (i < 0 || i >= partsBBS.length)
            return null;
        return partsBBS[i];
    }
    function checkChordElements(notes) {
        var res = [];
        notes.sort(function(a, b) { return (a.pitch) - (b.pitch); });
        var staffLayout = findStaffLayout(notes), part2, nt, msg;

        nt = notes.reduce(function(a, b){return (a.track>b.track ? a : b)}); 
        if (notes[0].pitch < nt.pitch && partName(staffLayout, nt.track) == 'Bass') {
            if (part2 = partName(staffLayout, notes[0].track))
                msg = 'Low ' + part2;
            else
                msg = 'Bass not lowest?';
            console.log(msg+': t'+notes[0].track+'p'+notes[0].pitch+' / p'+nt.pitch);
            res.push({ msg:msg, notes:[notes[0], nt]});
        }

        nt = notes.reduce(function(a, b){return (a.track<b.track ? a : b)});
        if (notes[notes.length-1].pitch > nt.pitch && partName(staffLayout, nt.track) == 'Tenor') {
            if (part2 = partName(staffLayout, notes[notes.length-1].track))
                msg = 'High ' + part2;
            else
                msg = 'Tenor not highest?';
            console.log(msg+': p'+nt.pitch+' / t'+notes[notes.length-1].track+'p'+notes[notes.length-1].pitch);
            res.push({ msg:msg, notes:[notes[notes.length-1], nt]});
        }

        for (var i = 1; i < notes.length; i++) {
            // check intervals
            var diff = notes[i].pitch - notes[i-1].pitch;
            if (diff <= 1) {
                if (diff == 1)
                    msg = 'Semitone!';
                else 
                    msg = 'Doubled note';
                console.log(msg+': t'+notes[i].track+'p'+notes[i].pitch+
                                ' / t'+notes[i-1].track+'p'+notes[i-1].pitch);
                res.push({ msg:msg, notes:[notes[i-1], notes[i]]});
            }
        }
        return res;
    }
    
    function getSegmentHarmony(segment) {
        //if (segment.segmentType != Segment.ChordRest) 
        //    return null;
        var aCount = 0;
        var annotation = segment.annotations[aCount];
        while (annotation) {
            if (annotation.type == Element.HARMONY)
                return annotation;
            annotation = segment.annotations[++aCount];     
        }
        return null;
    } 
    
    function chordDuration(chord){
        var duration = chord.globalDuration;    // only from MS 3.5 onwards
        if ( !duration )
            duration = chord.duration;
        return duration.ticks;
    }
    function getAllCurrentNotes(cursor, startStaff, endStaff, onlySelected, prev_chord){
        var full_chord = [];
        var tickLogged = false;
        // console.log('>>>>> tick ' + cursor.tick);
        for (var staff = endStaff; staff >= startStaff; staff--) {
            for (var voice = 3; voice >=0; voice--) { //Ziya var voice = 3 New! var voice = 6
                var trackLogged = false;
                cursor.voice = voice;
                cursor.staffIdx = staff;
//                if (cursor.element && cursor.element.type != Element.CHORD)
//					console.log('     IGNORE '+cursor.element.userName()+' s'+staff+' v'+voice+'   duration:'+cursor.element.duration.ticks);
                if (cursor.element && cursor.element.type == Element.CHORD) {
                    // console.log('     >> s'+staff+' v'+voice+'   duration:'+cursor.element.duration.ticks);
                    var notes = cursor.element.notes;
                    for (var i = 0; i < notes.length; i++) {
                        if (onlySelected && !notes[i].selected)
                            continue;
                        if ( !tickLogged ) {
                            console.log('>>>>> tick ' + cursor.tick);
                            tickLogged = true;
                        }
                        if ( !trackLogged ) {
                            console.log('     >> s'+staff+' v'+voice+'   duration:'+chordDuration(cursor.element));
                            // var act = cursor.element.stam, glo = cursor.element.globalDuration;
                            // console.log('        (stam?',(act?'def':'undef'),act==undefined, //defined(act),
                            //                     ') (global?',glo==undefined,glo.numerator,'/'+glo.denominator, glo.ticks);
                            trackLogged = true;
                        }
                        full_chord.push(notes[i]);
                        console.log('       >> pitch:' + notes[i].pitch);
                    }
                }
            }
        }
        if (prev_chord) {
//			console.log('   >> prev');
            for (var i = 0; i < prev_chord.length; i++) {
                var note = prev_chord[i];
                var excl = (note.parent.parent.tick + chordDuration(note.parent) > cursor.tick ? "!!!" : "");
                if (excl && entire_note_duration)
                    full_chord.push(note);
				console.log(excl+'     >> tick:'+note.parent.parent.tick+' len'+note.parent.duration.ticks+' p'+note.pitch);
            }
        }

        return full_chord;
    }
    
    function setToClosestNextElement(cursor, elemType) {
        // move cursor to closest next segment with Element elemType, whatever the track
        var seg = cursor.segment;
        if ( !seg )
            return false;
        while(seg = seg.next) {
            // console.log('   next seg: tick='+seg.tick);
            var tr;
            for (tr = 0; tr < curScore.ntracks; tr++) {
                var el = seg.elementAt(tr);
                // if (el) console.log('      track#'+tr+' of type '+el.userName());
                if (el && el.type == elemType)
                    break;
            }
            if (tr < curScore.ntracks) {
                cursor.track = tr;
                while (cursor.tick < seg.tick)
                    cursor.next();
                if (cursor.tick > seg.tick)
                    console.log('BUG!!! cursor('+cursor.tick+') went beyond seg('+seg.tick+') !!');
                // console.log('   next cursor seg: tick='+cursor.segment.tick+' of type '+cursor.segment.userName());
                return true;
            } else {
                // console.log('      required element not found');
            }
        }
        if ( !seg ) {
            // reached end without finding Element Type
            return false;
        }
    }

    function displayErr(errLine, prevErrs, cursor, isChordText, noteHeadFunc) {
        var anyCurrentNotes = false; 
        // Mark Noteheads:
        for (var n = 0; n < errLine.notes.length; n++) {
            var nt = errLine.notes[n];
            if (nt.parent.parent.tick == cursor.tick) {
                anyCurrentNotes = true;
                if (settings.modifyNoteheads) {
                    noteHeadFunc(nt);
                    nt.color = 'red';
                }
            }
        }
        // Mark text:
        if ((settings.showTextRemarks && (anyCurrentNotes || isChordText))
            || ( !anyCurrentNotes && isChordText))
        {
            // Avoid clutter of same text with same notes
            var isDup = prevErrs && prevErrs.some(function(pErr){ return errLine.msg == pErr.msg &&
                                                                          areNotesEqual (errLine.notes, pErr.notes); });
            if (isDup)
                return;
            var newText = newElement(Element.STAFF_TEXT);
            cursor.add(newText);
            newText.text = errLine.msg;
            newText.color = 'red';

        }
    }

    function runsheet() {

        if (typeof curScore === 'undefined') {
            quit();
        }
        if (mscoreVersion.major < 3 
            || (mscoreVersion.major == 3 && mscoreVersion.minor < 3)) {
            // MM: Is there a way to check MS version before dialog is displayed?
            console.log('This plugin requires MuseScore 3.3 and above');
            return;
        }

        var cursor = curScore.newCursor(),
            startStaff = 0,
            endStaff = curScore.nstaves - 1,
            fullScore = (curScore.selection.elements.length <= 1); // ignore accidental note or element
                
        console.log('startStaff: ' + startStaff);
        console.log('endStaff: ' + endStaff);
        console.log('curScore.nstaves: ' + curScore.nstaves);

        cursor.rewind(Cursor.SCORE_START);  // start from beginning of score, even for limited selection
        var keySig = cursor.keySignature;
        var keysig_name_major = getNoteName(keySig+7+7);
        var keysig_name_minor = getNoteName(keySig+7+10);
        console.log('559: keysig: ' + keySig + ' -> '+keysig_name_major+' major (or '+keysig_name_minor+' minor)');
        
        var segment;
        var chordName = '';
        var curr_matched_all = false;
        var full_chord = [];
        var cceRes = [];
        var prev_cwcRes_issues = [];
        while (segment=cursor.segment) { //loop through entire score
            // FIRST we get all notes on current position of the cursor, for all voices and all staves.
            var prev_full_chord = full_chord;
            full_chord = getAllCurrentNotes(cursor, startStaff, endStaff, !fullScore, full_chord);
            
            if (full_chord.length>1) { //At least 2 notes found!
                console.log('------');
                console.log('nb of notes found: ' + full_chord.length);
                if (fCheckBBSrules) {
                    var prev_cceRes = cceRes;
                    cceRes = checkChordElements(full_chord);
                    for (var i = 0; i < cceRes.length; i++) {
                        displayErr(cceRes[i], prev_cceRes, cursor, false,
                                   function(nt){ nt.headScheme = NoteHeadScheme.HEAD_PITCHNAME; });
                    }
                }
                var prev_chordName = chordName, prev_matched_all = curr_matched_all;
                var cwcRes = checkWholeChord(full_chord,cursor.keySignature);
                chordName = cwcRes.chordName;
                curr_matched_all = cwcRes.matchAllNotes;
                console.log('\tchordName: ' + chordName + (cwcRes.matchAllNotes?'':partialCodeStr)
                            + ' - ' + (cwcRes.isBBSchord?'':'non-') + 'BBS chord ('
                            + (cwcRes.goodBass?'strong':'weak') + ' voicing)');

                if (fAlwaysAddChords || !curr_matched_all || !cwcRes.isBBSchord) { // output chord text
                    var harmonyText = chordName, harmonyColor = black;
                    if (harmonyText) {
                        if ( !curr_matched_all )
                            harmonyText = partialCodeStr;
                        if ( !curr_matched_all || !cwcRes.isBBSchord )
                            harmonyColor = red;
                    }
                    var harmony = getSegmentHarmony(segment);
                    if (harmony) { //if chord symbol exists, replace it
                        //console.log("got harmony " + staffText + " with root: " + harmony.rootTpc + " bass: " + harmony.baseTpc);
                        harmony.text = harmonyText;
                        harmony.color = harmonyColor;
                    }else{ //chord symbol does not exist, create it
                        harmony = newElement(Element.HARMONY);
                        cursor.add(harmony);
                        harmony.text = harmonyText;
                        harmony.color = harmonyColor;
                        //console.log("text type:  " + staffText.type);
                    }

                    /* when to skip displaying duplicate chord:
                        // - NOT HERE!!! if current and previous fully matched
						OR
                        - if previous chord notes identical to current (NOT mod 12. Really identical)
                    */
                    if(/*(prev_chordName == chordName && prev_matched_all && curr_matched_all)
                            ||*/ areNotesEqual(prev_full_chord, full_chord))
                        harmony.text = '';
                    //console.log("xpos: "+harmony.pos.x+" ypos: "+harmony.pos.y);
                    /*staffText = newElement(Element.STAFF_TEXT);
                    staffText.text = chordName;
                    staffText.pos.x = 0;
                    cursor.add(staffText);*/
                    // }
                }
                if (curr_matched_all)
                    for (var i = 0; i < cwcRes.BBSissues.length; i++)
                        displayErr(cwcRes.BBSissues[i], prev_cwcRes_issues, cursor, 
                                   !areNotesEqual(prev_full_chord, full_chord),
                                   function(nt){ nt.headGroup = NoteHeadGroup.HEAD_CIRCLED_LARGE; });
                prev_cwcRes_issues = cwcRes.BBSissues;
            }
            
            if ( !setToClosestNextElement(cursor, Element.CHORD) )
                break;
            //cursor.next();
            //next_note(cursor, startStaff, endStaff);
        } // end while segment
        
        if (fullScore) {
            var key_str='';
            if(chordName==keysig_name_major){   //if last chord of score is a I chord => we most probably found the key :-)
                key_str=keysig_name_major+' major';
            }else if(chordName==keysig_name_minor){
                key_str=keysig_name_minor+' minor';
            }else{
                console.log('Key not found :-(');
            }
            if(key_str!=''){
                console.log('771: FOUND KEY: '+key_str);
                                
                /*var staffText = newElement(Element.STAFF_TEXT);
                staffText.text = key_str+':';
                staffText.pos.x = -13;
                staffText.pos.y = -1.5;
                cursor.rewind(0);
                cursor.add(staffText);*/
            }
        }
//        quit();
    } // end onRun

    function setupChordGroup() {
        chordGroup.enabled = chordAnalysis.checked;
        chordGroup.opacity = chordAnalysis.checked ? 1 : 0.5;
    }

    ColumnLayout {
        //   id: radioVals
        anchors.left: Button.right

        RowLayout {
            id: flatRow1
            spacing: 20
            Text  { text:  "  "; font.bold: true }
        }

        RowLayout {
            // enabled: false;
            // opacity: 0.5;
            visible: false
            id: rowDup
            spacing: 20
            Layout.leftMargin: 30
            CheckBox { id: dupScore; text:  "Work on new copy" }
        }
        Label { Layout.leftMargin: 30; text: "How to display Barbershop incompatibilities:" }
        CheckBox { id: redNoteheads; Layout.leftMargin: 50; text: "Red noteheads" }
        CheckBox { id: textRemarks; Layout.leftMargin: 50; text: "Textual remarks" }
        CheckBox { opacity:0.5; checked:true; enabled:false; Layout.leftMargin:50; text: "Red chord symbols"
                     /*; id:doChord - always disabled - added just for clarity */ }
        RowLayout {
            spacing: 20
            Layout.leftMargin: 30
            CheckBox { 
                id: chordAnalysis
                text: 'Show info also for "legal" chords' + (checked?':':'');
                onClicked: {
                    setupChordGroup();
                }
            }
        }
        ColumnLayout {
            id: chordGroup
            Layout.leftMargin: 50
            RowLayout {
                CheckBox { 
                    id: addChordSymbols; 
                    text: "Add chord text";
                    onClicked: {
                        chordMode.enabled = checked;
                        chordMode.opacity = checked ? 1 : 0.5;
                    } 
                }
                ComboBox {
                    id: chordMode; 
                    model: [ "Regular (A-G)", "Roman (I-VII)" ];
                    Layout.preferredWidth: 150
                }
            }
            CheckBox { id: colorizeNotes; text: "Color notes according to role in chord" }
            // CheckBox { id: ignoreBBS; text: "Ignore other Barbershop issues" }
        }
    }

    Button {
        id: buttonCancel
        text: qsTr("Cancel")
        anchors.bottom: chordDialog.bottom
        anchors.right: chordDialog.right
        anchors.bottomMargin: 10
        anchors.rightMargin: 20
        width: 100
        height: 40
        onClicked: {
            quit();
        }
    }

    Button {
        id: buttonOK
        text: qsTr("OK")
        width: 100
        height: 40
        anchors.bottom: chordDialog.bottom
        anchors.right:  buttonCancel.left
        anchors.topMargin: 10
        anchors.bottomMargin: 10
        anchors.rightMargin: 10
        onClicked: {
        //   showVals();
            {
                // save settings for next time
                settings.duplicateScore = dupScore.checked;
                settings.modifyNoteheads = redNoteheads.checked;
                settings.showTextRemarks = textRemarks.checked;
                settings.displayChordAnalysis = chordAnalysis.checked;
                settings.displayChordText = addChordSymbols.checked;
                settings.displayChordMode = chordMode.currentIndex;
                settings.displayChordColor = colorizeNotes.checked;
                // settings.dontDisplayBBSissues = ignoreBBS.checked;
            }
            {
                // set combination flags
                fCheckBBSrules = settings.modifyNoteheads || settings.showTextRemarks;
                fAlwaysAddChords = settings.displayChordAnalysis && settings.displayChordText;
                fDisplayRomanChords = (settings.displayChordMode == 1) && fAlwaysAddChords;
                fColorChordNotes = settings.displayChordAnalysis && settings.displayChordColor;
            }
            curScore.startCmd();
            runsheet();
            curScore.endCmd();
            quit();
        }
    }
    // Keys.onEscapePressed: { // doesn't work
    //         dialog.parent.Window.window.close();
    //         // quit();
    // }

}
