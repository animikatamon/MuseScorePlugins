//=============================================================================
//  MuseScore - Chord Identifier Plugin 
//  Chgd. debugged fixed and new-code added by: Ziya Mete Demircan 2019/04/09 23:02
//  Add option to use entire note duration for identification: Mendy Mendelsohn, Aug-Sep 2020
//  Suggestions: - Mark incomplete triads (with 3 voices and above?)
//               - Better recognize minor key (add sub-option for Minor?)
//               - Find if it is possible to colorize chord symbols according to score defaults? MS preferences?
//                    If so, colorize chords (and notes?) according to prevailing defaults
//  TODO: unify chords, strings etc. into single object array
//        (must order chord_type from short to long?)
//
//  Code Repository & Documentation: https://github.com/AniMikatamon/MuseScorePlugins
//  Code Issues: https://github.com/AniMikatamon/MuseScorePlugins/issues
//  
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License version 2
//  as published by the Free Software Foundation and appearing in
//  the file "LICENSE - GPLv2"
//
//  Prior contributors:
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
import QtQuick 2.0

import QtQuick.Layouts 1.0
import QtQuick.Controls 1.0
import QtQuick.Dialogs 1.0
import Qt.labs.settings 1.0

MuseScore {
    menuPath: "Plugins.Chords.Chord Identifier (Pop & Jazz)"
    description: 'Identify and add Chord Symbols to score ("Automatic Ctrl-K")'
    version: "3.4"

    
//    pluginType: "dock"
//    dockArea:   "left"
//
    pluginType: "dialog"
    width: 370
    height: 260
    id: chordDialog
    
    Component.onCompleted : {
        if (mscoreMajorVersion >= 4) {
            chordDialog.title = "Chord Identifier (Pop & Jazz)";
        }
    }

    Settings {
        id: settings
        category: "t2"
        property int displayChordMode     : 0 //0: Normal chord C  F7  Gm  //1: Roman Chord level   Ⅳ
        property int displayChordColor    : 0 //0: disable ,1 enable
        property int inversion_notation   : 0 //0: none //1: note with superscript (1, 2 or 3) //2: figured bass notation
        property int display_bass_note    : 1 //1: bass note is specified after a / like that: C/E for first inversion C chord.
        property int entire_note_duration : 1 //1: consider full duration of note in chords.
        property int hidePartialChords    : 1 //1: display ?? for incomplete chords //0: allow suggestion (with red chord)
    }

    property variant partialCodeStr: "??"

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
        rowB.current = objFromIndex(inversionMode.buttonList, settings.inversion_notation) 
        rowC.current = objFromIndex(symbolMode.buttonList, settings.displayChordMode) 
        rowD.current = objFromIndex(bassMode.buttonList, settings.display_bass_note) 
        rowE.current = objFromIndex(chordColorMode.buttonList, settings.displayChordColor) 
        rowF.current = objFromIndex(durationMode.buttonList, settings.entire_note_duration)
        rowG.current = objFromIndex(partialChordMode.buttonList, settings.hidePartialChords)
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
            chord_notes[i] = chord[i].pitch%mod; // remove octaves - or not

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
        
    function getChordName(chord,keysig) {
//        var INVERSION_NOTATION = 0; //set to 0: inversions are not shown
                                    //set to 1: inversions are noted with superscript 1, 2 or 3
                                    //set to 2: figured bass notation is used instead
                                
//        var DISPLAY_BASS_NOTE = 0; //set to 1: bass note is specified after a / like that: C/E for first inversion C chord.
 
        //Standard notation for inversions:
        if(settings.inversion_notation===1){
            var inversions = ["", " \u00B9", " \u00B2"," \u00B3"," \u2074"," \u2075"," \u2076"," \u2077"," \u2078"," \u2079"]; // unicode for superscript "1", "2", "3" (e.g. to represent C Major first, or second inversion)
            var inversions_7th = inversions;
			var inversions_9th  = inversions;
			var inversions_11th = inversions;
			var inversions_13th = inversions;

        }else if(settings.inversion_notation===2){//Figured bass of inversions:
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
        const STR = 0;
        const INTERVALS = 1;
        const all_chords = [
            // semi-automatically generated from previous chord_type & chord_str
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
            [ "11(b9/b13)", [4,7,10,1,5,8] ],      //30: 7(b13b911) =  Dom. Seventh, Flattened Thirteenth plus Flattenet Ninth, plus Eleventh* 
            [ "7(#9)",      [4,7,10,3] ],       //31: 7(#9) = Dominant Seventh, plus Sharp Ninth*
            [ "m7(11)",     [3,7,10,5] ],       //32: m7(11) = minor Seventh, plus Eleventh*
            [ "m11",        [3,7,10,2,5] ],     //33: m9(11) = minor Seventh, plus Eleventh, plus Ninth* 
            [ "x", [0,0,0] ]                    //34: Dummy
        ];                                               
        //Notice: [2,7],     //sus2  = Suspended Two // Not recognized; Recognized as 5sus/1 eg. c,d,g = Gsus4/C
        //Notice: [4,7,9],   //6  = Sixth // Not recognized; Recognized as vim7/1 eg. c,e,g,a = Am7/C
        //Notice: [3,7,9],   //m6 = Minor Sixth // Not recognized; Recognized as vim7b5/1 eg. c,e,g,a = Am7b5/C
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

        // ---------- SORT CHORD from bass to soprano --------
        chord.sort(function(a, b) { return (a.pitch) - (b.pitch); }); //bass note is now chord[0]
        
        //debug:
//        for(var i=0; i<chord.length; i++){
//            console.log('pitch note ' + i + ': ' + chord[i].pitch + ' -> ' + chord[i].pitch%12);
//        }   
        
        var sorted_chord_uniq = remove_dup_mod12(chord); //remove multiple occurence of octave notes in chord
        var intervals = find_intervals(sorted_chord_uniq);
        
        //debug:
        //for(var i=0; i<chord_uniq.length; i++) console.log('pitch note ' + i + ': ' + chord_uniq[i]);
        // console.log('compare: ' + compare_arr([0,1,2,3,4,5],[1,3,4,2])); //returns [0,1,1,1,1,0}
        
        
        // ---------- Compare intervals with chord types for identification ---------- 
        var idx_chtype=-1, idx_rootpos=-1, nb_found=0, all_found = false;
        var idx_chtype_arr=[], idx_rootpos_arr=[], cmp_result_arr=[], nb_found_arr=[];
        for(var idx_chtype_=0; idx_chtype_<all_chords.length; idx_chtype_++){ //chord types. 
            for(var idx_rootpos_=0; idx_rootpos_<intervals.length; idx_rootpos_++){ //loop through the intervals = possible root positions
                var cmp_result = compare_arr(all_chords[idx_chtype_][INTERVALS], intervals[idx_rootpos_]);
                if(cmp_result.nb_found>0){ //found some intervals
                    if(cmp_result.nb_found == all_chords[idx_chtype_][INTERVALS].length){ //full chord found!
                        if(cmp_result.nb_found>nb_found){ //keep chord with maximum number of similar interval
                            nb_found=cmp_result.nb_found;
                            idx_rootpos=idx_rootpos_;
                            idx_chtype=idx_chtype_;
                            if (nb_found == intervals[idx_rootpos_].length)
                                all_found = true;
                        } //else
                            // console.log('!! Something wrong with "chord_type" list');
                    }
                    idx_chtype_arr.push(idx_chtype_); //save partial results
                    idx_rootpos_arr.push(idx_rootpos_);
                    cmp_result_arr.push(cmp_result.cmp_arr);
                    nb_found_arr.push(cmp_result.nb_found);
                }
            }
        }
        
        if(idx_chtype<0 && idx_chtype_arr.length>0){ //no full chord found, but found partial chords
            // console.log('other partial chords: '+ idx_chtype_arr);
            // console.log('root_pos: '+ idx_rootpos_arr);
            // console.log('cmp_result_arr: '+ cmp_result_arr);
            nb_found = nb_found_arr.reduce(function(a,c){return Math.max(a,c)});
            console.log('nb_found',nb_found,'\n   root / chord / result:');
            for(var i=0; i<cmp_result_arr.length; i++) {
                if ( nb_found_arr[i]==nb_found )
                    console.log('    '+idx_rootpos_arr[i]+'/'+all_chords[idx_chtype_arr[i]][INTERVALS]+'/'+cmp_result_arr[i]);
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
            console.log('FOUND CHORD number '+ idx_chtype +'! root_pos: '+idx_rootpos);
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

        var colorize = settings.displayChordColor;
        var regular_chord=[-1,-1,-1,-1,-1,-1,-1,-1,-1,-1]; //without NCTs
        var bass=null; 
        
        var chordName='';
        var chordNameRoman='';
        if (rootNote !== null) { // ----- the chord was identified
            for(i=0; i<chord.length; i++){  // ---- color notes and find root note
                if((chord[i].pitch%12) === (rootNote%12)){  //color root note
                    regular_chord[0] = chord[i];
                    if (colorize) chord[i].color = colorroot; else chord[i].color = black; 
                    if(bass==null) bass=chord[i];
                }else if((chord[i].pitch%12) === ((rootNote+all_chords[idx_chtype][INTERVALS][0])%12)){ //third note
                    regular_chord[1] = chord[i];
                    if (colorize) chord[i].color = color3rd; else chord[i].color = black;
                    if(bass==null) bass=chord[i];
                }else if(all_chords[idx_chtype][INTERVALS].length>=2 && (chord[i].pitch%12) === ((rootNote+all_chords[idx_chtype][INTERVALS][1])%12)){ //5th
                    regular_chord[2] = chord[i];
                    if (colorize) chord[i].color = color5th; else chord[i].color = black;
                    if(bass==null) bass=chord[i];
                }else if(all_chords[idx_chtype][INTERVALS].length>=6 && (chord[i].pitch%12) === ((rootNote+all_chords[idx_chtype][INTERVALS][5])%12)){ //13Other
                    regular_chord[6] = chord[i];
                    if (colorize) chord[i].color = colorOth3; else chord[i].color = black;
                    if(bass==null) bass=chord[i];
                    //seventhchord=4;
                }else if(all_chords[idx_chtype][INTERVALS].length>=5 && (chord[i].pitch%12) === ((rootNote+all_chords[idx_chtype][INTERVALS][4])%12)){ //11Other
                    regular_chord[5] = chord[i];
                    if (colorize) chord[i].color = colorOth2; else chord[i].color = black;
                    if(bass==null) bass=chord[i];
                    //seventhchord=3;
                }else if(all_chords[idx_chtype][INTERVALS].length>=4 && (chord[i].pitch%12) === ((rootNote+all_chords[idx_chtype][INTERVALS][3])%12)){ //9Other
                    regular_chord[4] = chord[i];
                    if (colorize) chord[i].color = colorOth1; else chord[i].color = black;
                    if(bass==null) bass=chord[i];
                    //seventhchord=2;
                }else if(all_chords[idx_chtype][INTERVALS].length>=3 && (chord[i].pitch%12) === ((rootNote+all_chords[idx_chtype][INTERVALS][2])%12)){ //7th
                    regular_chord[3] = chord[i];
                    if (colorize) chord[i].color = color7th; else chord[i].color = black;
                    if(bass==null) bass=chord[i];
                    //seventhchord=1;
                }else{      //reset other note color 
				    //seventhchord='';
                    chord[i].color = black; 
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

        }else{
            for(i=0; i<chord.length; i++){
                chord[i].color = black; 
            }
        }

        // ----- find inversion
        inv=-1;
        if (chordName !== ''){ // && inversion !== null) {
            var bass_pitch=bass.pitch%12;
            //console.log('bass_pitch: ' + bass_pitch);
            if(bass_pitch == rootNote){ //Is chord in root position ?
                inv=0;
            }else{
                for(var inv=1; inv<all_chords[idx_chtype][INTERVALS].length+1; inv++){
                   if(bass_pitch == ((rootNote+all_chords[idx_chtype][INTERVALS][inv-1])%12)) break;
                   //console.log('note n: ' + ((chord[idx_rootpos].pitch+intervals[idx_rootpos][inv-1])%12));
                }
            }
            console.log('\t inv: ' + inv);
            
            
            // Commented: Both are fixed now -Ziya.
            
            if (settings.inversion_notation===1 || settings.inversion_notation===2 ) {
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
             if(settings.display_bass_note==1 && inv>0){
                chordName+="/"+getNoteName(bass.tpc);
            }
            
            if(settings.displayChordMode === 1 ) {
                chordName = chordNameRoman;
            } else if(settings.displayChordMode === 2 ) {
                chordName += " "+chordNameRoman
            }
        }

        if ( ! all_found)
            console.log(' >> not all notes matched');

        return {
            chordName:      chordName,
            matchAllNotes:  all_found
        };
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
				if (excl && settings.entire_note_duration)
					full_chord.push(note);
//				console.log(excl+'     >> tick:'+note.parent.parent.tick+' len'+note.parent.duration.ticks+' p'+note.pitch);
			}
		}
		
        return full_chord;
    }
    
/*  Unneeded functions - replaced by function closestNextElement
    function setCursorToTime(cursor, time){
        var cur_staff=cursor.staffIdx;
        cursor.rewind(0);
        cursor.staffIdx=cur_staff;
        while (cursor.segment && cursor.tick < curScore.lastSegment.tick + 1) { 
            var current_time = cursor.tick;
            if(current_time>=time){
                return true;
            }
            cursor.next();
        }
        cursor.rewind(0);
        cursor.staffIdx=cur_staff;
        return false;
    }
    
    function next_note(cursor, startStaff, endStaff){
        var cur_time=cursor.tick;
        console.log('cur_time: ' + cur_time);
        var next_time=10000000;
        var cur_staff=startStaff;
        for (var staff = startStaff; staff <= endStaff; staff++) {
            //for (var voice = 0; voice < 4; voice++) {
                //cursor.voice=0;
            cursor.staffIdx = staff;
            setCursorToTime(cursor, cur_time);
            cursor.next();
            console.log('tick: ' + cursor.tick);
            if((next_time<0 || cursor.tick<next_time) && cursor.tick !=0) {
                next_time=cursor.tick;
                cur_staff=staff;
            }
            //}
        }
        console.log('next_time: ' + next_time);
        cursor.staffIdx = cur_staff;
        //cursor.next();
        if(next_time>0 && cursor.tick != next_time){
            setCursorToTime(cursor, next_time);
        }
    }
  */
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

    function runsheet() {

        if (typeof curScore === 'undefined') {
            quit();
        }
        if (mscoreMajorVersion < 3 
            || (mscoreMajorVersion == 3 && mscoreMinorVersion < 3)) {
            // MM: Is there a way to check MS version before dialog is displayed?
            console.log('This plugin requires MuseScore 3.3 and above');
            return;
        }

        var cursor = curScore.newCursor(),
            startStaff = 0,
            endStaff = curScore.nstaves - 1,
//          endTick,
            fullScore = (curScore.selection.elements.length <= 1); // ignore accidental note or element
                
/*        cursor.rewind(1);
        
        if (!cursor.segment) { // no selection
            fullScore = true;
            startStaff = 0; // start with 1st staff
            endStaff = curScore.nstaves - 1; // and end with last
        } else {
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
        console.log(startStaff + " - " + endStaff + " - " + endTick);*/
        console.log('startStaff: ' + startStaff);
        console.log('endStaff: ' + endStaff);
        console.log('curScore.nstaves: ' + curScore.nstaves);
/*        console.log('endTick: ' + endTick);
        console.log('cursor.tick: ' + cursor.tick);
        console.log('curScore.lastSegment.tick: ' + curScore.lastSegment.tick);

        cursor.rewind(1); // beginning of selection
        if (fullScore) { // no selection
            cursor.rewind(0); // beginning of score
        }
        cursor.voice = 0;
        cursor.staffIdx = startStaff; //staff;*/
        cursor.rewind(Cursor.SCORE_START);  // start from beginning of score
        var keySig = cursor.keySignature;
        var keysig_name_major = getNoteName(keySig+7+7);
        var keysig_name_minor = getNoteName(keySig+7+10);
        console.log('559: keysig: ' + keySig + ' -> '+keysig_name_major+' major or '+keysig_name_minor+' minor.');
        
        var segment;
        var chordName = '';
        var curr_matched_all = false;
        var full_chord = [];
        while (segment=cursor.segment) { //loop through entire score
            // FIRST we get all notes on current position of the cursor, for all voices and all staves.
            var prev_full_chord = full_chord;
            full_chord = getAllCurrentNotes(cursor, startStaff, endStaff, !fullScore, full_chord);
            
            if(full_chord.length>0){ //More than 0 notes found!
                console.log('------');
                console.log('nb of notes found: ' + full_chord.length);
                var prev_chordName = chordName, prev_matched_all = curr_matched_all;
                var gcnRes = getChordName(full_chord,cursor.keySignature);
                chordName = gcnRes.chordName;
                curr_matched_all = gcnRes.matchAllNotes;
                console.log('\tchordName: ' + chordName + (gcnRes.matchAllNotes?'':partialCodeStr));

                // if (chordName !== '') { //chord has been identified
                var harmonyText = chordName, harmonyColor = black;
                if (harmonyText && !gcnRes.matchAllNotes) {
                    if (settings.hidePartialChords)
                        harmonyText = partialCodeStr;
                    else
                        harmonyColor = red;
                }
                var harmony = getSegmentHarmony(segment);
                if (harmony) { //if chord symbol exists, replace it
                    //console.log("got harmony " + staffText + " with root: " + harmony.rootTpc + " bass: " + harmony.baseTpc);
                    harmony.text = harmonyText;
                    harmony.color = harmonyColor;
                }else{ //chord symbol does not exist, create it
                    harmony = newElement(Element.HARMONY);
                    harmony.text = harmonyText;
                    harmony.color = harmonyColor;
                    //console.log("text type:  " + staffText.type);
                    cursor.add(harmony);
                }

                /* when to skip displaying duplicate chord:
                    - if current and previous fully matched
                    OR
                    - if previous chord notes identical to current (NOT mod 12. Really identical)
                */
                if((prev_chordName == chordName && prev_matched_all && curr_matched_all)
                    || areNotesEqual(prev_full_chord, full_chord)){
                    harmony.text = '';
                }
                //console.log("xpos: "+harmony.pos.x+" ypos: "+harmony.pos.y);
                /*staffText = newElement(Element.STAFF_TEXT);
                staffText.text = chordName;
                staffText.pos.x = 0;
                cursor.add(staffText);*/
                // }
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
                console.log('612: FOUND KEY: '+key_str);
								
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


    function showVals () {   // MM: calcVals or findVals may be a better name for this func
//    for (var i=0; i < chrodMeasure.buttonList.length; i++ ) {
//      var s = chrodMeasure.buttonList[i];
//      if (s.checked) {
//          chordPerMeasure=chrodMeasure.buttonList.length-i;
//          break;
//      }
//    }

//    for (var i=0; i < chordStaff.buttonList.length; i++ ) {
//      var s = chordStaff.buttonList[i];
//      if (s.checked) {
//          chordIdentifyMode=chordStaff.buttonList.length-1-i;
//          break;
//      }
//    }
    
    for (var i=0; i < symbolMode.buttonList.length; i++ ) {
      var s = symbolMode.buttonList[i];
      if (s.checked) {
          settings.displayChordMode=symbolMode.buttonList.length-1-i;
          break;
      }
    }
    
    for (var i=0; i < bassMode.buttonList.length; i++ ) {
      var s = bassMode.buttonList[i];
      if (s.checked) {
          settings.display_bass_note=bassMode.buttonList.length-1-i;
          break;
      }
    }


    for (var i=0; i < chordColorMode.buttonList.length; i++ ) {
      var s = chordColorMode.buttonList[i];
      if (s.checked) {
          settings.displayChordColor=chordColorMode.buttonList.length-1-i;
          break;
      }
    }
    
    for (var i=0; i < inversionMode.buttonList.length; i++ ) {
      var s = inversionMode.buttonList[i];
      if (s.checked) {
          settings.inversion_notation=inversionMode.buttonList.length-1-i;
          break;
      }
    }

    for (var i=0; i < durationMode.buttonList.length; i++ ) {
      var s = durationMode.buttonList[i];
      if (s.checked) {
          settings.entire_note_duration=durationMode.buttonList.length-1-i;
          break;
      }
    }

    for (var i=0; i < partialChordMode.buttonList.length; i++ ) {
      var s = partialChordMode.buttonList[i];
      if (s.checked) {
          settings.hidePartialChords=partialChordMode.buttonList.length-1-i;
          break;
      }
    }
	console.log('hidePartialChords =', settings.hidePartialChords);

//    for (var i=0; i < newScoreMode.buttonList.length; i++ ) {
//      var s = newScoreMode.buttonList[i];
//      if (s.checked) {
//          creatNewChordScore=newScoreMode.buttonList.length-1-i;
//          break;
//      }
//    }


    }

/*      function getButtonIndex(buttons, text) { 
            for (var i = 0; i < buttons.length; i++) {
                  if (buttons[i].text == text) {
                        console.log(i)
                        return i;
                  }
            }
            return -1;
      }*/

    function objFromIndex(list, index) {
        return list[list.length-1-index]
    }

  ColumnLayout {
      // Left: column of note names
      // Right: radio buttons in flat/nat/sharp positions
      id: radioVals
      anchors.left: Button.right

      RowLayout {
        id: flatRow1
        spacing: 20
        Text  { text:  "  "; font.bold: true }
      }

      RowLayout {
        id: symbolMode
        spacing: 20
        Text  { text:  "  Symbol:"; font.bold: true }
        property list<RadioButton> buttonList: [
          RadioButton { parent: symbolMode;text: "Roman"; exclusiveGroup: rowC },
          RadioButton { parent: symbolMode;text: "Normal(A-G)"; exclusiveGroup: rowC }
        ]
      }

      RowLayout {
        id: bassMode
        spacing: 20
        Text  { text:  "  Bass:"; font.bold: true }
        property list<RadioButton> buttonList: [
          RadioButton { parent: bassMode;text: "Yes"; exclusiveGroup: rowD },
          RadioButton { parent: bassMode;text: "No"; exclusiveGroup: rowD }
        ]
      }

      RowLayout {
        id: inversionMode
        spacing: 20
        Text  { text:  "  Inversion:"; font.bold: true }
        property list<RadioButton> buttonList: [
          RadioButton { parent: inversionMode;text: "Figured Bass"; exclusiveGroup: rowB },
          RadioButton { parent: inversionMode;text: "Normal"; exclusiveGroup: rowB },
          RadioButton { parent: inversionMode;text: "No"; exclusiveGroup: rowB }
        ]
      }

      RowLayout {
        id: chordColorMode
        spacing: 20
        Text  { text:  "  Highlight Chord Notes:"; font.bold: true }
        property list<RadioButton> buttonList: [
          RadioButton { parent: chordColorMode;text: "Yes"; exclusiveGroup: rowE },
          RadioButton { parent: chordColorMode;text: "No"; exclusiveGroup: rowE }
        ]
      }

      RowLayout {
        id: partialChordMode
        spacing: 20
        Text  { text:  "  On Incomplete Chords:"; font.bold: true }
        property list<RadioButton> buttonList: [
          RadioButton { parent: partialChordMode;text: "Show '??'"; exclusiveGroup: rowG },
          RadioButton { parent: partialChordMode;text: "Suggest"; exclusiveGroup: rowG }
        ]
      }

      RowLayout {
        id: durationMode
        spacing: 20
        Text  { text:  "  Use Entire Note Duration:"; font.bold: true }
        property list<RadioButton> buttonList: [
          RadioButton { parent: durationMode;text: "Yes"; exclusiveGroup: rowF },
          RadioButton { parent: durationMode;text: "No"; exclusiveGroup: rowF }
        ]
      }

      ExclusiveGroup { id: rowB }
      ExclusiveGroup { id: rowC }
      ExclusiveGroup { id: rowD }
      ExclusiveGroup { id: rowE }
      ExclusiveGroup { id: rowF }
      ExclusiveGroup { id: rowG }
  }

  Button {
    id: buttonCancel
    text: qsTr("Cancel")
    anchors.bottom: chordDialog.bottom
    anchors.right: chordDialog.right
    anchors.bottomMargin: 10
    anchors.rightMargin: 10
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
    onClicked: {
      showVals();
      curScore.startCmd();
      runsheet();
      curScore.endCmd();
      quit();
    }
  }

}

