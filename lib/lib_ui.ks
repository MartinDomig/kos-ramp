// clearscreen.
global ui_announce is 0.
global ui_announceMsg is "".

global logconsole   is false. //Save console to log.txt / 0:/<CRAFT NAME>.txt

function uiConsole {
  parameter prefix.
  parameter msg.

  local logtext is "T+" + round(time:seconds) + " " + prefix + ": " + msg.
  print logtext.

  if logconsole {
    LOG logtext to "log.txt".
    IF HOMECONNECTION:ISCONNECTED {
      COPYPATH("log.txt","0:/logs/"+SHIP:NAME+".txt").
    }
  }
}

function uiBanner {
  parameter prefix.
  parameter msg.
  parameter sound is 1. // Sound to play when show the message: 1 = Beep, 2 = Chime, 3 = Alert

  if (time:seconds - ui_announce > 60) or (ui_announceMsg <> msg) {
    uiConsole(prefix, msg).
    hudtext(msg, 10, 2, 24, GREEN, false).
    set ui_announce to time:seconds.
    set ui_announceMsg to msg.
    // Select a sound.
    if      sound = 1 uiBeep().
    else if sound = 2 uiChime().
    else if sound = 3 uiAlarm().
  }
}

function uiWarning {
  parameter prefix.
  parameter msg.

  uiConsole(prefix, msg).
  hudtext(msg, 10, 4, 36, YELLOW, false).
  uiAlarm().
}

function uiError {
  parameter prefix.
  parameter msg.

  uiConsole(prefix, msg).
  hudtext(msg, 10, 4, 36, RED, false).
  uiAlarm().
}

function uiShowPorts {
  parameter myPort.
  parameter hisPort.
  parameter dist.
  parameter ready.

  if myPort <> 0 {
    set ui_myPort:start to myPort:position.
    local facing is 0.
    if myPort:typename = "DockingPort" set facing to myPort:portfacing.
    else set facing to myPort:facing.
    set ui_myPort:vec to facing:vector*dist.
    if ready {
      set ui_myPort:color to GREEN.
    } else {
      set ui_myPort:color to RED.
    }
    set ui_myPort:show to true.
  } else {
    set ui_myPort:show to false.
  }

  if hisPort <> 0 {
    set ui_hisPort:start to hisPort:position.
    local facing is 0.
    if hisPort:typename = "DockingPort" set facing to hisPort:portfacing.
    else set facing to hisPort:facing.
    set ui_hisPort:vec to facing:vector*dist.
    set ui_hisPort:show to true.
  } else {
    set ui_hisPort:show to false.
  }
}

function uiFatal {
  parameter prefix.
  parameter message.

  uiError(prefix, message + " - RESUME CONTROL").
  wait 3.
  reboot.
}

function uiAssertAccel {
  parameter prefix.

  local uiAccel is ship:availablethrust / ship:mass. // kN over tonnes; 1000s cancel

  if uiAccel <= 0 {
    uiFatal("Maneuver", "ENGINE FAULT").
  } else {
    return uiAccel.
  }
}

FUNCTION uiAlarm {
    local vAlarm TO GetVoice(0).
    set vAlarm:wave to "TRIANGLE".
    set vAlarm:volume to 0.5.
      vAlarm:PLAY(
          LIST(
              NOTE("A#4", 0.2,  0.25), 
              NOTE("A4",  0.2,  0.25), 
              NOTE("A#4", 0.2,  0.25), 
              NOTE("A4",  0.2,  0.25),
              NOTE("R",   0.2,  0.25),
              NOTE("A#4", 0.2,  0.25), 
              NOTE("A4",  0.2,  0.25), 
              NOTE("A#4", 0.2,  0.25), 
              NOTE("A4",  0.2,  0.25)
          )
      ).
}

FUNCTION uiBeep {
  local vBeep to GetVoice(0).
  set vBeep:volume to 0.35.
  set vBeep:wave to "SQUARE".
  vBeep:PLAY(NOTE("A4",0.1, 0.1)).
}

FUNCTION uiChime {
  local vChimes to GetVoice(0).
  set vChimes:volume to 0.25.
  set vChimes:wave to "SINE". 
  vChimes:PLAY(
      LIST(
        NOTE("E5",0.8, 1),
        NOTE("C5",1,1.2)
        )).
}


function uiTerminalMenu {
  // Shows a menu in the terminal window and waits for user input.
  // The parameter is a lexicon of a key to be pressed and a text to be show.
  // ie.: 
  // LOCAL MyOptions IS LEXICON("Y","Yes","N","No").
  // LOCAL myVal is uiTerminalMenu(MyOptions).
  //
  // That code will produce a menu with two options, Stay or Go, and will return 1 or 2 depending which key user press.

	parameter Options.
	local Choice is 0.
	local Term is Terminal:Input().
	local ValidSelection is false.
	Until ValidSelection {
    uiBanner("Terminal","Please choose an option in Terminal.",2).
		print " ".
		print "=================".
		Print "Choose an option:".
		Print "=================".
		print " ".
		for Opt in Options:keys {
			print Opt + ") - " + Options[Opt].
		}
		print "?>".

		Term:CLEAR().
		set Choice to Term:GETCHAR().
		if Options:HASKEY(Choice) {
			set ValidSelection to true.
      print "===> " + Options[Choice].
		}
		else print "Invalid selection".
	}
	return Choice.
}

function uiTerminalList {
  // Shows a menu in the terminal window and waits for user input.
  
	parameter Options.

	local Choice is 0.
  local page is 0.
  local KeyPressed is 0.
	local Term is Terminal:Input().
	local ValidSelection is false.

  uiBanner("Terminal","Please make a choice in the Terminal.",2).
	Until ValidSelection {
    clearscreen.
		print " ".
		print "=================".
		Print "Choose an option:".
		Print "=================".
		print " ".
		from { local i is 10*page. } until i = min(10+(10*page),Options:length) step { set i to i+1. } do {
			print (i-(10*page)) + ") - " + Options[i].
		}
		print "Showing " + min(Options:Length,10+(10*Page)) + " of " + Options:Length() + " options.".
    print "Use arrows < and > to change pages".

		Term:CLEAR().
		set KeyPressed to Term:GETCHAR().
    if KeyPressed = Term:RightCursorOne {
      if Options:Length > 10+(10*Page) set Page to Page + 1.
    }
    else if KeyPressed = Term:LeftCursorOne {
      if Page > 0 set Page to Page - 1.
    }
    else if "0123456789":Contains(KeyPressed) {
      set choice to KeyPressed:ToNumber()+(10*Page).
      if choice < Options:Length {
        set ValidSelection to true.
        print "===> " + Options[Choice].
      }
    }
		else print "Invalid selection".
	}
	return Choice.
}

FUNCTION uiMSTOKMH { 
    // Return m/s in km/h. 
    PARAMETER MS.
    RETURN MS * 3.6.
}
