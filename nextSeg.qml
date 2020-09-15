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
      version:  "1.0"
      description: "show next segment of first segment in selection"
      menuPath: "Plugins.nextInAnyVoice"
      
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
            console.log('current: tick='+cursor.tick);
            var seg = cursor.segment;
            if (seg) {
                while(seg = seg.next) {
                    console.log('next seg: tick='+seg.tick);
                    var t;
                    for (t = 0; t < curScore.ntracks; t++) {
                        var el = seg.elementAt(t);
                        if (el) console.log('track#'+t+' of type '+el.userName());
						if (el && el.type == Element.CHORD)
                            break;
                    }
                    if (t < curScore.ntracks) {
                        cursor.track = t;
                        cursor.next();
                        console.log('next cursor seg: tick='+cursor.segment.tick);
                        break;
                    } else
                        console.log('no chord found on next segment');
                }
                if ( ! seg ) {
                    console.log('no following chord segment found');
                }
            } else {
                console.log('no segment!');
            }
            Qt.quit();
      }
}


