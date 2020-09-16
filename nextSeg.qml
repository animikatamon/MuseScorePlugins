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
import MuseScore 3.0

MuseScore {
      version:  "1.1"
      description: "Show all consequtive chord segments in selection, regardless of staff/voice\n"
                    + "  (using only start and end of selection, i.e. ignoring partial staff selection)"
                    + "  ==> test plugin for closestNextElement(cursor, CHORD)"
      menuPath: "Plugins.printSegmentsOrderLeft2RightInAnyTrack"
      
    function closestNextElement(cursor, elemType) {
        // move cursor to closest next segment with Element elemType, whatever the track
        var seg = cursor.segment;
        if ( !seg )
            return false;
        while(seg = seg.next) {
            console.log('   next seg: tick='+seg.tick);
            var tr;
            for (tr = 0; tr < curScore.ntracks; tr++) {
                var el = seg.elementAt(tr);
                if (el) console.log('      track#'+tr+' of type '+el.userName());
                if (el && el.type == elemType)
                    break;
            }
            if (tr < curScore.ntracks) {
                cursor.track = tr;
                while (cursor.tick < seg.tick)
                    cursor.next();
                if (cursor.tick > seg.tick)
                    console.log('BUG cursor('+cursor.tick+') went beyond seg('+seg.tick+') !!');
                console.log('   next cursor seg: tick='+cursor.segment.tick+' of type '+cursor.segment.userName());
                return true;
            } else
                console.log('      required element not found');
        }
        if ( !seg ) {
            // reached end without finding Element Type
            return false;
        }
    }

      onRun: {
            console.log("Next Segment Demo");

            if (!curScore)
                  Qt.quit();
            
            var cursor = curScore.newCursor();
            cursor.rewind(Cursor.SELECTION_START);
            if (!cursor.segment) { 
                console.log('no selection');
                Qt.quit();
            }
            cursor.rewind(Cursor.SELECTION_END);
            var endTick = cursor.tick;
            if (cursor.tick === 0) {
                // this happens when the selection includes
                // the last measure of the score.
                // rewind(2) goes behind the last segment (where
                // there's none) and sets tick=0
                endTick = curScore.lastSegment.tick + 1;
            }

            cursor.rewind(Cursor.SELECTION_START);
            console.log('start from cursor tick '+cursor.tick);
            console.log('endTick = '+endTick);
            var seg;
            while ((seg = cursor.segment) && seg.tick < endTick) {
                console.log('>>tick ' + seg.tick);
                for (var tr = curScore.ntracks - 1; tr >= 0; tr--) {
                    var el = seg.elementAt(tr);
                    if ( !el ) continue;
                    //console.log('   element type = ' + el.userName() /*+ visBool(el.selected, ' - selected')*/);
                    if (el.type == Element.CHORD) {
                        var notes = el.notes;
                        var s = '';
                        for (var i = notes.length - 1; i >= 0; i--) {
//                            if ( !onlySelection || notes[i].selected )
                                s += notes[i].pitch + '/' + notes[i].parent.duration.ticks + /*visBool(notes[i].selected, '/s') +*/ ' ';
                        }
                        if (s)
                            console.log('>>  track#' + tr + '  chord: ' + s);
                    }
                }
                if ( !closestNextElement(cursor, Element.CHORD) )
                    break;
            }
            Qt.quit();
      }
}


