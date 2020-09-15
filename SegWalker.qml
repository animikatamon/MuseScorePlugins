//=============================================================================
//  MuseScore
//  Music Composition & Notation
//
//  Copyright (C) 2020 Mendy Mendelsohn
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License version 2
//  as published by the Free Software Foundation and appearing in
//  the file LICENCE.GPL
//
//  WHAT ABOUT selected PROPERTY?
//=============================================================================

import QtQuick 2.0
import MuseScore 3.0	// for curScore.selection

MuseScore {
      version:  "1.1"
      description: "This test plugin walks through all elements in a selection or by default in entire score"
      menuPath: "Plugins.SegWalk"

	  function getSelectionElements() {
		  console.log('selection');
		  return curScore.selection.elements;
	  }
			
	  function getAllElements() {
            var cursor = curScore.newCursor();
            var seg;
			var segList = [];
/*			cursor.filter = -1;
            cursor.voice    = 0;
            cursor.staffIdx = 0;
            cursor.rewind(Cursor.SELECTION_START);

            var startStaff = 0; // start with 1st staff
			var endTick = 10000000;
            var endStaff = curScore.nstaves - 1; // and end with last
		
            if (seg = cursor.segment) {
				startStaff = cursor.staffIdx;
				cursor.rewind(Cursor.SELECTION_END);
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
				cursor.rewind(Cursor.SELECTION_START);
			} else */
				cursor.rewind(Cursor.SCORE_START);



//            cursor.voice    = 0;
//            cursor.staffIdx = 0;
			seg = cursor.segment;
            while (seg /*&& seg.tick < endTick*/) {
//				console.log(seg.userName());
				segList.push(seg);
				seg = seg.next;
			}
			return segList;
	  }
	  
	  function visBool(bul, txt) {
		  return txt + (bul ? ':yes' : ':no');
	  }

      onRun: {
            console.log("Segment Walker");

            if (!curScore)
                  Qt.quit();
			
			var elems;
			var onlySelection = (curScore.selection.elements.length > 0);
			console.log('>>> print ' + onlySelection ? 'selection' : 'entire score');
			
/*			if (curScore.selection.elements.length > 0)
				elems = getSelectionElements();
			else*/
				elems = getAllElements();
			console.log('#elems=' + elems.length); 
			
			for (var e = 0; e < elems.length; e++) {
				var topEl = elems[e];
//				if (curScore.selection.elements.length > 0)
//					console.log('      elem#' + e + ' is ' + topEl.userName());
				if (topEl.type == Element.SEGMENT) {
					var seg = topEl;
					console.log('tick ' + seg.tick /*+ visBool(seg.selected, ' - selected')*/);
					for (var tr = 15; tr >= 0; tr--) {
						var el = seg.elementAt(tr);
						if ( !el ) continue;
						console.log('   element type = ' + el.userName() /*+ visBool(el.selected, ' - selected')*/);
						if (el.type == Element.CHORD) {
							var notes = el.notes;
							var s = '';
							for (var i = notes.length - 1; i >= 0; i--) {
								if ( !onlySelection || notes[i].selected )
									s += notes[i].pitch + '/' + notes[i].parent.duration.ticks + /*visBool(notes[i].selected, '/s') +*/ ' ';
							}
							if (s)
								console.log('>>> track#' + tr + '  chord: ' + s);
						} else if (el.type == Element.KEYSIG) {
							var defs = 0, ks = Object.keys(el);
							for (var k = 0; k < ks.length; k++) {
								if (el[ks[k]] != undefined) {
									defs++;
									console.log('   ' + ks[k] + ':' + el[ks[k]]);
								}
							}
							console.log('>>> KeySig #defs = ' + defs + ' / #keys = ' + ks.length);
						}
					}
				} else if (topEl.type == Element.NOTE) {
					var note = topEl;
					console.log('tick#' + note.parent.parent.tick + ':  ' + note.pitch + "/" + note.parent.duration.ticks);
				}
			}
            Qt.quit();
	  }
}
