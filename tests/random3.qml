import QtQuick 2.1
import MuseScore 3.0
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.0
import QtQuick.Dialogs 1.0
import Qt.labs.settings 1.0

MuseScore {
      version:  "3.0"
      description: "Create random score."
      menuPath: "Plugins.random2"
      requiresScore: false
    pluginType: "dialog"
    width: 370
    height: 260
    id: chordDialog
    //   pluginType: "dock"
    //   dockArea:   "left"
    //   width:  150
    //   height: 75
    property variant displayChordMode   : 0 //0: Normal chord C  F7  Gm  //1: Roman Chord level   Ⅳ
    property variant displayChordColor  : 0 //0: disable ,1 enable
    property variant inversion_notation : 0 //set to 1: bass note is specified after a / like that: C/E for first inversion C chord.
    property variant display_bass_note  : 1 //set to 1: bass note is specified after a / like that: C/E for first inversion C chord.
    property variant entire_note_duration : 1 //set to 1 to consider full duration of note in chords.

      onRun: { }

      function addNote(key, cursor) {
            var cdur = [ 0, 2, 4, 5, 7, 9, 11 ];
            //           c  g  d  e
            var keyo = [ 0, 7, 2, 4 ];

            var idx    = Math.random() * 6;
            var octave = Math.floor(Math.random() * octaves.value);
            var pitch  = cdur[Math.floor(idx)] + octave * 12 + 60 + keyo[key];
            console.log("Add note pitch "+pitch);
            cursor.addNote(pitch);
            }

      function createScore() {
            var measures    = 18; //in 4/4 default time signature
            var numerator   = 3;
            var denominator = 4;
            var key         = 2; //index in keyo from addNote function above

            var score = newScore("Random2.mscz", "piano", measures);

            score.startCmd();
            score.addText("title", "==Random2==");
            score.addText("subtitle", "Another subtitle");

            var cursor = score.newCursor();
            cursor.track = 0;

            cursor.rewind(0);

            var ts = newElement(Element.TIMESIG);
            ts.timesig = fraction(numerator, denominator);
            cursor.add(ts);

            var realMeasures = Math.ceil(measures * denominator / numerator);
            console.log(realMeasures);
            var notes = realMeasures * 4; //number of 1/4th notes

            for (var staff = 0; staff < 2; ++staff) { //piano has two staves to fill
                  cursor.track = staff * 4; //4 voice tracks per staff
                  cursor.rewind(0); //go to the start of the score
                  //add notes
                  for (var i = 0; i < notes; ++i) {
                        if (Math.random() < 0.4) {
                              console.log("Adding two notes at ", i);
                              cursor.setDuration(1, 8);
                              addNote(key, cursor);
                              addNote(key, cursor);
                              }
                        else {
                              console.log("Adding note at ", i);
                              cursor.setDuration(1, 4);
                              addNote(key, cursor);
                              }
                        } //done adding notes to this staff
                  }
            score.endCmd();
            Qt.quit();
            }

  function showVals () {
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
          displayChordMode=symbolMode.buttonList.length-1-i;
          break;
      }
    }
    
    for (var i=0; i < bassMode.buttonList.length; i++ ) {
      var s = bassMode.buttonList[i];
      if (s.checked) {
          display_bass_note=bassMode.buttonList.length-1-i;
          break;
      }
    }


    for (var i=0; i < chordColorMode.buttonList.length; i++ ) {
      var s = chordColorMode.buttonList[i];
      if (s.checked) {
          displayChordColor=chordColorMode.buttonList.length-1-i;
          break;
      }
    }
    
        for (var i=0; i < inversionMode.buttonList.length; i++ ) {
      var s = inversionMode.buttonList[i];
      if (s.checked) {
          inversion_notation=inversionMode.buttonList.length-1-i;
          break;
      }
    }

        for (var i=0; i < durationMode.buttonList.length; i++ ) {
      var s = durationMode.buttonList[i];
      if (s.checked) {
          entire_note_duration=durationMode.buttonList.length-1-i;
          break;
      }
    }
	console.log('use entire note duration = ' + entire_note_duration);

//    for (var i=0; i < newScoreMode.buttonList.length; i++ ) {
//      var s = newScoreMode.buttonList[i];
//      if (s.checked) {
//          creatNewChordScore=newScoreMode.buttonList.length-1-i;
//          break;
//      }
//    }


  }

      // Settings {
      //       id: settings
      //       // property alias noctaves: octaves.value
      //       property alias checkedBut: bGroup.checkedButton
      // }
      function getButtonIndex(buttons, text) { 
            for (var i = 0; i < buttons.length; i++) {
                  if (buttons[i].text == text) {
                        console.log(i)
                        return i;
                  }
            }
            return -1;
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
          RadioButton { parent: symbolMode;text: "Roman"; exclusiveGroup: rowC ;},
          RadioButton { parent: symbolMode;text: "Normal"; exclusiveGroup: rowC ;checked: true }
        ]
      }

      RowLayout {
        id: bassMode
        spacing: 20
        Text  { text:  "  Bass:"; font.bold: true }
        property list<RadioButton> buttonList: [
          RadioButton { parent: bassMode;text: "Yes"; exclusiveGroup: rowD },
          RadioButton { parent: bassMode;text: "No"; exclusiveGroup: rowD ;checked: true }
        ]
      }

      RowLayout {
        id: chordColorMode
        spacing: 20
        Text  { text:  "  Highlight Chord Notes:"; font.bold: true }
        property list<RadioButton> buttonList: [
          RadioButton { parent: chordColorMode;text: "Yes"; exclusiveGroup: rowE },
          RadioButton { parent: chordColorMode;text: "No"; exclusiveGroup: rowE ;checked: true }

        ]
      }

      RowLayout {
        id: inversionMode
        spacing: 20
        Text  { text:  "  Inversion:"; font.bold: true }
        property list<RadioButton> buttonList: [
          RadioButton { parent: inversionMode;text: "Figured Bass"; exclusiveGroup: rowB },
          RadioButton { parent: inversionMode;text: "Normal"; exclusiveGroup: rowB },
          RadioButton { parent: inversionMode;text: "No"; exclusiveGroup: rowB ;checked: true }
        ]
      }

      RowLayout {
        id: durationMode
        spacing: 20
        Text  { text:  "  Use Entire Note Duration:"; font.bold: true }
        property list<RadioButton> buttonList: [
          RadioButton { parent: durationMode;text: "Yes"; exclusiveGroup: rowF; checked: true },
          RadioButton { parent: durationMode;text: "No"; exclusiveGroup: rowF }
        ]
      }


      ExclusiveGroup { id: rowB; onCurrentChanged: { showVals(); }}
      ExclusiveGroup { id: rowC; onCurrentChanged: { showVals(); }}
      ExclusiveGroup { id: rowD; onCurrentChanged: { showVals(); }}
      ExclusiveGroup { id: rowE; onCurrentChanged: { showVals(); }}
      ExclusiveGroup { id: rowF; onCurrentChanged: { showVals(); }}
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
      Qt.quit();
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
      curScore.startCmd();
      runsheet();
      curScore.endCmd();
      Qt.quit();
    }
  }

    }
