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
import MuseScore 3.3	// for curScore.selection

MuseScore {
      version:  "1.0"
      description: "This test plugin walks through all elements in a selection or by default in entire score"
      menuPath: "Plugins.SegWalk"
/*
      function next_cursor_seg(cursor, startStaff, endStaff){
		  // nice try, doesn't work...
			var cur_time = cursor.tick;
			console.log('cur_time: ' + cur_time);
			var next_time = 10000000;
			var closest_next_track = -1;
			for (var staff = startStaff; staff <= endStaff; staff++) {
				cursor.staffIdx = staff;
				for (var voice = 0; voice < 4; voice++) {
					cursor.voice = voice;
//				setCursorToTime(cursor, cur_time);
					cursor.next();
					if (cursor.tick != 0) {
						console.log('tick on '+staff+'v'+voice+': ' + cursor.tick);
						if (cursor.tick < next_time) {
							next_time = cursor.tick;
							closest_next_track = cursor.track;
						}
					}
					cursor.prev();
					if (cur_time != cursor.tick)
						console.log('AAAHHHH!!!  cursor time '+cursor.tick+' != cur_time '+cur_time)
				}
			}
			cursor.track = closest_next_track;
			console.log('   set cursor track to '+closest_next_track+' -> staff='+cursor.staffIdx+' voice='+cursor.voice);
			return cursor.segment;
      }
*/
      function next_segment_seg(seg){
		  return seg.next;
	  }
	  
      onRun: {
            console.log("Segment Walker");

            if (!curScore)
                  Qt.quit();

            var cursor = curScore.newCursor();
            var seg;
			cursor.filter = -1;
            cursor.voice    = 0;
            cursor.staffIdx = 0;
            cursor.rewind(Cursor.SELECTION_START);

            var startStaff = 0; // start with 1st staff
            var endStaff = curScore.nstaves - 1; // and end with last
			var endTick = 10000000;
		
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
			} else
				cursor.rewind(Cursor.SCORE_START);

            cursor.voice    = 0;
            cursor.staffIdx = 0;
			seg = cursor.segment;
            while (seg && seg.tick < endTick) {
				console.log('tick ' + seg.tick);
				for (var staff = endStaff; staff >= startStaff; staff--)
					for (var voice = 3; voice >= 0; voice--) {
						var tr = staff*4 + voice;
						var el;
						if ((el = seg.elementAt(tr)) && el.type == Element.CHORD) {
							var notes = el.notes;
							for (var s = '  chord: ', i = notes.length - 1; i >= 0; i--)
								s += notes[i].pitch + '/' + notes[i].parent.duration.ticks + ' ';
							console.log('   track#'+tr+s);
						}
					}
/*                var e = cursor.element;
                if (e) {
                    console.log("type:", e.name, "at  tick:", e.tick, "color", e.color);
                    if (e.type == Element.REST) {
                        var d = e.duration;
                        console.log("   duration " + d.numerator + "/" + d.denominator);
                        }
                    }
                cursor.next();*/
				seg = next_cursor_seg(cursor, startStaff, endStaff);
//				seg = seg.next;next_cursor_seg
				}
            Qt.quit();
            }
      }
