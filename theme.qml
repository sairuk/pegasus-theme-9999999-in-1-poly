import QtQuick 2.0
import QtMultimedia 5.8


FocusScope {
    readonly property real scale: Math.min(width / 1280.0, height / 720.0)
    function scaled(value) {
        return scale * value;
    }
	
    SoundEffect {
    id: selectSound
    source: "assets/audio/Select.wav"
    volume: 2.5
  }
  
     SoundEffect {
    id: navSound
    source: "assets/audio/Nav.wav"
    volume: 2.5
  }
  
     SoundEffect {
    id: changeSound
    source: "assets/audio/Change.wav"
    volume: 2.5
  }

    function zeroPad(number, width) {
        var str = number.toString();
        var strlen = str.length;
        if (strlen >= width)
            return str;

        return new Array(width - strlen + 1).join('0') + number;
    }

    function modulo(a, n) {
        return (a % n + n) % n;
    }

    function nextCollection() {
	changeSound.play();
        collectionIdx = modulo(collectionIdx + 1, api.collections.count);
    }
    function prevCollection() {
	changeSound.play();
        collectionIdx = modulo(collectionIdx - 1, api.collections.count);
    }

    function launchGame(game) {
		selectSound.play();
        api.memory.set('collectionIndex', collectionIdx);
        api.memory.set('gameIndex', gamelist.currentIndex);
        game.launch();
    }

    property int collectionIdx: api.memory.get('collectionIndex') || 0
    readonly property var collection: api.collections.get(collectionIdx) || api.collections.get(0)

    Keys.onLeftPressed: prevCollection()
    Keys.onRightPressed: nextCollection()

    Component.onCompleted: {
        gamelist.currentIndex = api.memory.get('gameIndex') || 0;
    }

    FontLoader { source: "assets/arcade-classic.ttf" }

    Image {
        id: background

        readonly property int bgCount: 14

        source: "bg/0.png"
        anchors.fill: parent
        fillMode: Image.PreserveAspectFit
        smooth: false
    }

    Item {
        width: scaled(1280)
        height: scaled(720)
        anchors.centerIn: parent

        readonly property int textHeight: collName.height

        RetroText {
            id: collName
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            text: collection.name
        }
		
		RetroText {
            id: startText
			anchors.topMargin: scaled(50)
			color: "red"
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            text: "PUSH START KEY"
        }

        ListView {
            id: gamelist

            readonly property int maxVisibleLines: 24
            readonly property int leftPadding: scaled(34)
            readonly property int digitCount: collection.games.count.toString().length

            height: parent.textHeight * maxVisibleLines
            anchors.top: collName.bottom
            anchors.left: parent.left
            anchors.leftMargin: scaled(180) - leftPadding
            anchors.right: parent.right
            anchors.rightMargin: scaled(160)
			anchors.topMargin: scaled(90)
            clip: true

            focus: true
            keyNavigationWraps: true

            Keys.onPressed: {

                if (api.keys.isPageDown(event)) {
                    event.accepted = true;
                    navSound.play();

                    if ( currentIndex >= collection.games.count - maxVisibleLines )
                        currentIndex = collection.games.count - 1;
                    else
                        currentIndex = currentIndex + maxVisibleLines;
                    return;
                }
                
                if (api.keys.isPageUp(event)) {
                    event.accepted = true;
					navSound.play();

                    if ( currentIndex <= maxVisibleLines )
                        currentIndex = 0;
                    else
                        currentIndex = currentIndex - maxVisibleLines;

                    return;
                }
            }

            model: collection.games
            delegate: RetroText {
                id: gametitle

                readonly property int myIndex: index

                text: zeroPad(index + 1, gamelist.digitCount) + "." + modelData.title
                leftPadding: gamelist.leftPadding
                width: ListView.view.width
                elide: Text.ElideRight
			
				
                Keys.onPressed: {
                    if (event.isAutoRepeat)
                        return;

                    if (api.keys.isAccept(event)) {
                        event.accepted = true;
                        launchGame(modelData);
                        return;
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (gamelist.currentIndex !== parent.myIndex) {
                            gamelist.currentIndex = parent.myIndex;
                            return;
                        }
                        launchGame(modelData);
                    }
                }
            }

            highlight: Item {
                AnimatedSprite {
                    source: "assets/birdA.png"
                    frameWidth: 41
                    frameHeight: 44
                    frameCount: 1
                    frameDuration: 0

                    interpolate: false
                    smooth: false

                    height: scaled(20)
                    width: height / frameHeight * frameWidth
                }
            }
            highlightMoveDuration: 0

            onCurrentIndexChanged: {
                const page = Math.floor(currentIndex / maxVisibleLines);
                contentY = page * maxVisibleLines * parent.textHeight;
                const bg_idx = page % background.bgCount;
                background.source = "bg/%1.png".arg(bg_idx);
				navSound.play();
                bgFire.visible = bg_idx == 9;
            }
        }

        MouseArea {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: gamelist.left
            anchors.bottom: parent.bottom
            onClicked: prevCollection()
        }
        MouseArea {
            anchors.top: parent.top
            anchors.left: gamelist.right
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            onClicked: nextCollection()
        }

        Birds {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: scaled(440)
        }

        Fire {
            id: bgFire
            visible: false

            anchors.left: parent.left
            anchors.top: parent.top
            anchors.leftMargin: scaled(520)
            anchors.topMargin: scaled(597)
        }

    }
}
