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
			console.log(cursor);
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
				console.log(seg.userName());
				segList.push(seg);
				seg = seg.next;
			}
			return segList;
	  }

      onRun: {
            console.log("Segment Walker");

            if (!curScore)
                  Qt.quit();
			
			var elems;
			
			if (curScore.selection.elements.length > 0)
				elems = getSelectionElements();
			else
				elems = getAllElements();
			
			for (var i = 0; i < elems.length; i++) {
				var el = elems[i];
				console.log('elem#' + i + ' is ' + el.userName());
/*				console.log('tick ' + seg.tick);
				for (var tr = 15; tr >= 0; tr--) {
					var el;
					if ((el = seg.elementAt(tr)) && el.type == Element.CHORD) {
						var notes = el.notes;
						for (var s = '  chord: ', i = notes.length - 1; i >= 0; i--)
							s += notes[i].pitch + '/' + notes[i].parent.duration.ticks + ' ';
						console.log('   track#'+tr+s);
					}
				}
/ *                var e = cursor.element;
                if (e) {
                    console.log("type:", e.name, "at  tick:", e.tick, "color", e.color);
                    if (e.type == Element.REST) {
                        var d = e.duration;
                        console.log("   duration " + d.numerator + "/" + d.denominator);
                        }
                    }
                cursor.next();
				seg = seg.next;*/
			}
            Qt.quit();
	  }
}
