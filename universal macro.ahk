#NoEnv
#SingleInstance Force
#MaxThreadsPerHotkey 2
CoordMode, Mouse, Screen
DetectHiddenWindows, On 

; Enable dragging for GUI windows
OnMessage(0x0201, "DragWindow")

TargetCount = 0
VisualGuiCount = 1
IsRunning = 0
RemapsRunning = 0
IsHidden = 0
IsCollapsed = 0
RunOnceMode = 0 ; 0 = Infinite, 1 = Once
MenuTargetIndex = 0

; Variables to hold the copied target data
CopiedType = 
CopiedDelay = 
CopiedKey = 
CopiedHoldDuration = 
CopiedScrollDir = 
CopiedScrollAmt = 
CopiedRemapFrom = 
CopiedRemapTo = 
CopiedDragSpeed = 

; Define the Right-Click Menu
Menu, TargetMenu, Add, Edit Action, MenuEdit
Menu, TargetMenu, Add, Copy Target, MenuCopy
Menu, TargetMenu, Add, Delete Target, MenuDelete

; Safely define where settings will be saved
if A_ScriptDir =
    IniFile = %A_WorkingDir%\AutoClickerSettings.ini
else
    IniFile = %A_ScriptDir%\AutoClickerSettings.ini

IniRead, ConfigList, %IniFile%, Main, Configs, %A_Space%
if ConfigList = %A_Space%
{
    ConfigList = 
}

; --- Create Toolbar (Default GUI 1) ---
Gui, +AlwaysOnTop +ToolWindow

; Top Section (Always Visible)
Gui, Add, Button, vBtnCollapse gToggleCollapse w140 h25, Collapse UI
Gui, Font, Bold cRed
Gui, Add, Text, vStatusText w140 Center, [ STOPPED ]
Gui, Font

; Bottom Section (Collapsible)
Gui, Add, Button, vBtnAddClick gBtnAdd w140 h30, Add Click Target
Gui, Add, Button, vBtnAddKey gBtnAddKey w140 h30, Add Keystroke Target
Gui, Add, Button, vBtnAddDrag gBtnAddDrag w140 h30, Add Drag Target
Gui, Add, Button, vBtnAddHold gBtnAddHold w140 h30, Add Hold Target

; Split Scroll into Up and Down on the same line
Gui, Add, Button, vBtnAddScrollUp gBtnAddScrollUp w65 h30, Scroll Up
Gui, Add, Button, vBtnAddScrollDown gBtnAddScrollDown x+10 yp w65 h30, Scroll Dn

; Split Remap line into Add and Play
Gui, Add, Button, vBtnAddRemap gBtnAddRemap xm w85 h30, Add Remap
Gui, Add, Button, vBtnToggleRemap gToggleRemap x+5 yp w50 h30, Play

; Independent Status Text for Remaps
Gui, Font, Bold cRed
Gui, Add, Text, vRemapStatusText xm w140 Center, Remaps: [ STOPPED ]
Gui, Font

Gui, Add, Button, vBtnHide gToggleHide xm w140 h30, Hide Targets
Gui, Add, Button, vBtnRunMode gToggleRunMode xm w140 h25, Loop: Infinite

Gui, Add, Button, vBtnClear gBtnClear w65 h30, Clear All
Gui, Add, Button, vBtnUndo gBtnUndo x+10 yp w65 h30, Undo Last

Gui, Add, Text, vTxtConfig xm w140 Center, --- Saved Configs ---
Gui, Add, DropDownList, vSelectedConfig gLoadConfig w140, %ConfigList%
Gui, Add, Button, vBtnSave gBtnSave w140 h25, Save Config
Gui, Add, Button, vBtnDelete gBtnDelete w140 h25, Delete Config

Gui, Show, x20 y20 NoActivate, AutoClicker
return ; End of auto-execute section


; --- RIGHT-CLICK MENU LOGIC ---
TGuiContextMenu:
ClickedIndex = 0
Loop, %TargetCount%
{
    type := TargetType%A_Index%
    if type = Drag
    {
        gA := TargetGuiA%A_Index%
        gB := TargetGuiB%A_Index%
        if A_Gui = %gA%
        {
            ClickedIndex = %A_Index%
            break
        }
        if A_Gui = %gB%
        {
            ClickedIndex = %A_Index%
            break
        }
    }
    else
    {
        gN := TargetGui%A_Index%
        if A_Gui = %gN%
        {
            ClickedIndex = %A_Index%
            break
        }
    }
}

if ClickedIndex > 0
{
    MenuTargetIndex = %ClickedIndex%
    Menu, TargetMenu, Show
}
return

; --- Menu Action: Copy ---
MenuCopy:
idx = %MenuTargetIndex%
CopiedType := TargetType%idx%
CopiedDelay := TargetDelay%idx%

if CopiedType = Key
{
    CopiedKey := TargetKey%idx%
}
else if CopiedType = Hold
{
    CopiedKey := TargetKey%idx%
    CopiedHoldDuration := TargetHoldDuration%idx%
}
else if CopiedType = Scroll
{
    CopiedScrollDir := TargetScrollDir%idx%
    CopiedScrollAmt := TargetScrollAmt%idx%
}
else if CopiedType = Remap
{
    CopiedRemapFrom := TargetRemapFrom%idx%
    CopiedRemapTo := TargetRemapTo%idx%
}
else if CopiedType = Drag
{
    CopiedDragSpeed := TargetDragSpeed%idx%
}

ToolTip, Action Copied! Move mouse and press Ctrl+V to paste.
SetTimer, RemoveToolTip, -3000
return

RemoveToolTip:
ToolTip
return

; --- Menu Action: Edit ---
MenuEdit:
idx = %MenuTargetIndex%
type := TargetType%idx%

if type = Remap
{
    if RemapsRunning = 1
        return
        
    currTo := TargetRemapTo%idx%
    EditPrompt = Enter new destination key or combo to send instead:`n(e.g., ctrl+v, {Enter})
    InputBox, newTo, Edit Remap, %EditPrompt%,, 400, 200,,,,, %currTo%
    if ErrorLevel = 0
    {
        TargetRemapTo%idx% = %newTo%
        fromK := TargetRemapFrom%idx%
        gN := TargetGui%idx%
        GuiControl, %gN%:, TargetText%gN%, %idx%: %fromK% > %newTo%
    }
}
else if type = Hold
{
    if IsRunning = 1
        return
        
    currHold := TargetHoldDuration%idx%
    HoldPrompt = Enter new HOLD duration (in milliseconds):
    InputBox, newHold, Edit Hold, %HoldPrompt%,, 400, 200,,,,, %currHold%
    if ErrorLevel = 0
    {
        TargetHoldDuration%idx% = %newHold%
        
        currDelay := TargetDelay%idx%
        EditPrompt = Enter new wait time AFTER release (in milliseconds):
        InputBox, newDelay, Edit Delay, %EditPrompt%,, 400, 200,,,,, %currDelay%
        if ErrorLevel = 0
        {
            TargetDelay%idx% = %newDelay%
        }
    }
}
else if type = Scroll
{
    if IsRunning = 1
        return
        
    currDir := TargetScrollDir%idx%
    DirPrompt = Enter new scroll direction (U for Up, D for Down):
    InputBox, newDir, Edit Scroll, %DirPrompt%,, 400, 200,,,,, %currDir%
    if ErrorLevel = 0
    {
        if newDir = u
            newDir = U
        if newDir = d
            newDir = D
            
        if (newDir = "U" or newDir = "D")
        {
            TargetScrollDir%idx% = %newDir%
            
            currAmt := TargetScrollAmt%idx%
            AmtPrompt = Enter new scroll amount (number of ticks):
            InputBox, newAmt, Edit Scroll, %AmtPrompt%,, 400, 200,,,,, %currAmt%
            if ErrorLevel = 0
            {
                TargetScrollAmt%idx% = %newAmt%
                
                currDelay := TargetDelay%idx%
                DelayPrompt = Enter new wait time AFTER scrolling (in ms):
                InputBox, newDelay, Edit Delay, %DelayPrompt%,, 400, 200,,,,, %currDelay%
                if ErrorLevel = 0
                {
                    TargetDelay%idx% = %newDelay%
                    gN := TargetGui%idx%
                    GuiControl, %gN%:, TargetText%gN%, %idx%: Scr %newDir% %newAmt%
                }
            }
        }
        else
        {
            MsgBox, 48, Error, Invalid direction! Use U or D.
        }
    }
}
else
{
    if IsRunning = 1
        return
        
    currDelay := TargetDelay%idx%
    EditPrompt = Enter new wait time AFTER this target (in milliseconds):
    InputBox, newDelay, Edit Delay, %EditPrompt%,, 400, 200,,,,, %currDelay%
    if ErrorLevel = 0
    {
        TargetDelay%idx% = %newDelay%
    }
}
return

; --- Menu Action: Delete ---
MenuDelete:
idx = %MenuTargetIndex%
type := TargetType%idx%

if type = Remap
{
    if RemapsRunning = 1
        return
}
else
{
    if IsRunning = 1
        return
}

; Destroy visual box
if type = Drag
{
    gA := TargetGuiA%idx%
    Gui, %gA%: Destroy
    gB := TargetGuiB%idx%
    Gui, %gB%: Destroy
}
else
{
    gN := TargetGui%idx%
    Gui, %gN%: Destroy
}

; Shift subsequent targets to fill the gap
ShiftCount = %TargetCount%
EnvSub, ShiftCount, %idx%

Loop, %ShiftCount%
{
    curr = %idx%
    EnvAdd, curr, %A_Index%
    EnvSub, curr, 1
    
    next = %curr%
    EnvAdd, next, 1
    
    ntype := TargetType%next%
    ndelay := TargetDelay%next%
    
    TargetType%curr% = %ntype%
    TargetDelay%curr% = %ndelay%
    
    if ntype = Drag
    {
        nspeed := TargetDragSpeed%next%
        TargetDragSpeed%curr% = %nspeed%
        gA := TargetGuiA%next%
        TargetGuiA%curr% = %gA%
        GuiControl, %gA%:, TargetText%gA%, %curr%S
        gB := TargetGuiB%next%
        TargetGuiB%curr% = %gB%
        GuiControl, %gB%:, TargetText%gB%, %curr%E
    }
    else if ntype = Key
    {
        nkey := TargetKey%next%
        TargetKey%curr% = %nkey%
        gN := TargetGui%next%
        TargetGui%curr% = %gN%
        GuiControl, %gN%:, TargetText%gN%, %curr%: %nkey%
    }
    else if ntype = Hold
    {
        nkey := TargetKey%next%
        nhold := TargetHoldDuration%next%
        TargetKey%curr% = %nkey%
        TargetHoldDuration%curr% = %nhold%
        gN := TargetGui%next%
        TargetGui%curr% = %gN%
        GuiControl, %gN%:, TargetText%gN%, %curr%: Hld %nkey%
    }
    else if ntype = Scroll
    {
        sDir := TargetScrollDir%next%
        sAmt := TargetScrollAmt%next%
        TargetScrollDir%curr% = %sDir%
        TargetScrollAmt%curr% = %sAmt%
        gN := TargetGui%next%
        TargetGui%curr% = %gN%
        GuiControl, %gN%:, TargetText%gN%, %curr%: Scr %sDir% %sAmt%
    }
    else if ntype = Remap
    {
        fK := TargetRemapFrom%next%
        tK := TargetRemapTo%next%
        TargetRemapFrom%curr% = %fK%
        TargetRemapTo%curr% = %tK%
        gN := TargetGui%next%
        TargetGui%curr% = %gN%
        GuiControl, %gN%:, TargetText%gN%, %curr%: %fK% > %tK%
    }
    else
    {
        gN := TargetGui%next%
        TargetGui%curr% = %gN%
        GuiControl, %gN%:, TargetText%gN%, %curr%
    }
}
EnvSub, TargetCount, 1
return

; --- CTRL+V Paste Target Feature ---
$^v::
if CopiedType = 
{
    Send, ^v ; Let standard Windows paste work normally if nothing is copied
    return
}
if IsRunning = 1
    return
if RemapsRunning = 1
    return

GoSub, ForceUnhide
MouseGetPos, tX, tY

EnvAdd, TargetCount, 1
EnvAdd, VisualGuiCount, 1
gNum = %VisualGuiCount%

TargetType%TargetCount% = %CopiedType%
TargetDelay%TargetCount% = %CopiedDelay%
TargetGui%TargetCount% = %gNum%

if CopiedType = Click
{
    gx = %tX%
    gy = %tY%
    EnvSub, gx, 12
    EnvSub, gy, 12
    Gui, %gNum%: +AlwaysOnTop +ToolWindow -Caption +LastFound -SysMenu +LabelTGui
    Gui, %gNum%: Color, Red
    Gui, %gNum%: Font, s10 cWhite Bold
    Gui, %gNum%: Add, Text, vTargetText%gNum% x0 y0 w24 h24 Center 0x200, %TargetCount%
    WinSet, Transparent, 200
    Gui, %gNum%: Show, x%gx% y%gy% w24 h24 NoActivate
}
else if CopiedType = Key
{
    TargetKey%TargetCount% = %CopiedKey%
    gx = %tX%
    gy = %tY%
    EnvSub, gx, 50
    EnvSub, gy, 12
    Gui, %gNum%: +AlwaysOnTop +ToolWindow -Caption +LastFound -SysMenu +LabelTGui
    Gui, %gNum%: Color, Blue
    Gui, %gNum%: Font, s8 cWhite Bold
    Gui, %gNum%: Add, Text, vTargetText%gNum% x0 y0 w100 h24 Center 0x200, %TargetCount%: %CopiedKey%
    WinSet, Transparent, 200
    Gui, %gNum%: Show, x%gx% y%gy% w100 h24 NoActivate
}
else if CopiedType = Hold
{
    TargetKey%TargetCount% = %CopiedKey%
    TargetHoldDuration%TargetCount% = %CopiedHoldDuration%
    gx = %tX%
    gy = %tY%
    EnvSub, gx, 50
    EnvSub, gy, 12
    Gui, %gNum%: +AlwaysOnTop +ToolWindow -Caption +LastFound -SysMenu +LabelTGui
    Gui, %gNum%: Color, Orange
    Gui, %gNum%: Font, s8 cWhite Bold
    Gui, %gNum%: Add, Text, vTargetText%gNum% x0 y0 w100 h24 Center 0x200, %TargetCount%: Hld %CopiedKey%
    WinSet, Transparent, 200
    Gui, %gNum%: Show, x%gx% y%gy% w100 h24 NoActivate
}
else if CopiedType = Scroll
{
    TargetScrollDir%TargetCount% = %CopiedScrollDir%
    TargetScrollAmt%TargetCount% = %CopiedScrollAmt%
    gx = %tX%
    gy = %tY%
    EnvSub, gx, 50
    EnvSub, gy, 12
    Gui, %gNum%: +AlwaysOnTop +ToolWindow -Caption +LastFound -SysMenu +LabelTGui
    Gui, %gNum%: Color, Teal
    Gui, %gNum%: Font, s8 cWhite Bold
    Gui, %gNum%: Add, Text, vTargetText%gNum% x0 y0 w100 h24 Center 0x200, %TargetCount%: Scr %CopiedScrollDir% %CopiedScrollAmt%
    WinSet, Transparent, 200
    Gui, %gNum%: Show, x%gx% y%gy% w100 h24 NoActivate
}
else if CopiedType = Remap
{
    TargetRemapFrom%TargetCount% = %CopiedRemapFrom%
    TargetRemapTo%TargetCount% = %CopiedRemapTo%
    gx = %tX%
    gy = %tY%
    EnvSub, gx, 50
    EnvSub, gy, 12
    Gui, %gNum%: +AlwaysOnTop +ToolWindow -Caption +LastFound -SysMenu +LabelTGui
    Gui, %gNum%: Color, Purple
    Gui, %gNum%: Font, s8 cWhite Bold
    Gui, %gNum%: Add, Text, vTargetText%gNum% x0 y0 w100 h24 Center 0x200, %TargetCount%: %CopiedRemapFrom% > %CopiedRemapTo%
    WinSet, Transparent, 200
    Gui, %gNum%: Show, x%gx% y%gy% w100 h24 NoActivate
}
else if CopiedType = Drag
{
    TargetDragSpeed%TargetCount% = %CopiedDragSpeed%
    
    gNumA = %gNum%
    EnvAdd, VisualGuiCount, 1
    gNumB = %VisualGuiCount%
    
    TargetGuiA%TargetCount% = %gNumA%
    TargetGuiB%TargetCount% = %gNumB%
    
    gxA = %tX%
    gyA = %tY%
    EnvSub, gxA, 12
    EnvSub, gyA, 12
    
    gxB = %tX%
    gyB = %tY%
    EnvAdd, gxB, 50 ; Shift end point diagonally
    EnvAdd, gyB, 50
    EnvSub, gxB, 12
    EnvSub, gyB, 12
    
    Gui, %gNumA%: +AlwaysOnTop +ToolWindow -Caption +LastFound -SysMenu +LabelTGui
    Gui, %gNumA%: Color, Green
    Gui, %gNumA%: Font, s10 cWhite Bold
    Gui, %gNumA%: Add, Text, vTargetText%gNumA% x0 y0 w24 h24 Center 0x200, %TargetCount%S
    WinSet, Transparent, 200
    Gui, %gNumA%: Show, x%gxA% y%gyA% w24 h24 NoActivate
    
    Gui, %gNumB%: +AlwaysOnTop +ToolWindow -Caption +LastFound -SysMenu +LabelTGui
    Gui, %gNumB%: Color, Green
    Gui, %gNumB%: Font, s10 cWhite Bold
    Gui, %gNumB%: Add, Text, vTargetText%gNumB% x0 y0 w24 h24 Center 0x200, %TargetCount%E
    WinSet, Transparent, 200
    Gui, %gNumB%: Show, x%gxB% y%gyB% w24 h24 NoActivate
}
return


; --- F2 Hotkey: Reset All Remaps ---
F2::
if RemapsRunning = 1
{
    MsgBox, 48, Error, You must STOP the Remap Play Button before resetting remaps!
    return
}
GoSub, ForceUnhide
currIdx = %TargetCount%
Loop
{
    if currIdx <= 0
        break
        
    type := TargetType%currIdx%
    if type = Remap
    {
        MenuTargetIndex = %currIdx%
        GoSub, MenuDelete
    }
    EnvSub, currIdx, 1
}
return

; --- Button: Toggle Run Mode (Infinite vs Once) ---
ToggleRunMode:
if IsRunning = 1
    return

if RunOnceMode = 0
{
    RunOnceMode = 1
    GuiControl,, BtnRunMode, Loop: Once (Test)
}
else
{
    RunOnceMode = 0
    GuiControl,, BtnRunMode, Loop: Infinite
}
return

; --- Toggle Remaps Button ---
ToggleRemap:
if TargetCount = 0
    return

hasRemaps = 0
Loop, %TargetCount%
{
    type := TargetType%A_Index%
    if type = Remap
        hasRemaps = 1
}

if hasRemaps = 0
{
    MsgBox, 48, Error, No Key Remaps defined!
    return
}

if RemapsRunning = 0
{
    RemapsRunning = 1
    GuiControl,, BtnToggleRemap, Stop
    GuiControl,, RemapStatusText, Remaps: [ RUNNING ]
    Gui, Font, cGreen
    GuiControl, Font, RemapStatusText
    Gui, Font
    
    Loop, %TargetCount%
    {
        type := TargetType%A_Index%
        if type = Remap
        {
            rFrom := TargetRemapFrom%A_Index%
            StringReplace, rFrom, rFrom, ctrl%A_Space%+%A_Space%, ^, All
            StringReplace, rFrom, rFrom, ctrl+, ^, All
            StringReplace, rFrom, rFrom, ctrl-, ^, All
            StringReplace, rFrom, rFrom, shift%A_Space%+%A_Space%, +, All
            StringReplace, rFrom, rFrom, shift+, +, All
            StringReplace, rFrom, rFrom, shift-, +, All
            StringReplace, rFrom, rFrom, alt%A_Space%+%A_Space%, !, All
            StringReplace, rFrom, rFrom, alt+, !, All
            StringReplace, rFrom, rFrom, alt-, !, All
            StringReplace, rFrom, rFrom, win%A_Space%+%A_Space%, #, All
            StringReplace, rFrom, rFrom, win+, #, All
            StringReplace, rFrom, rFrom, win-, #, All
            
            TargetRemapFromTrans%A_Index% = %rFrom%
            Hotkey, %rFrom%, DoRemap, On
            
            if IsHidden = 0
            {
                gNum := TargetGui%A_Index%
                Gui, %gNum%: +E0x20
            }
        }
    }
}
else
{
    RemapsRunning = 0
    GuiControl,, BtnToggleRemap, Play
    GuiControl,, RemapStatusText, Remaps: [ STOPPED ]
    Gui, Font, cRed
    GuiControl, Font, RemapStatusText
    Gui, Font
    
    Loop, %TargetCount%
    {
        type := TargetType%A_Index%
        if type = Remap
        {
            rFrom := TargetRemapFromTrans%A_Index%
            Hotkey, %rFrom%, DoRemap, Off
            
            if IsHidden = 0
            {
                gNum := TargetGui%A_Index%
                Gui, %gNum%: -E0x20
            }
        }
    }
}
return


; --- Button: Toggle Collapse/Expand UI ---
ToggleCollapse:
if IsCollapsed = 0
{
    IsCollapsed = 1
    GuiControl,, BtnCollapse, Expand UI
    GuiControl, Hide, BtnAddClick
    GuiControl, Hide, BtnAddKey
    GuiControl, Hide, BtnAddDrag
    GuiControl, Hide, BtnAddHold
    GuiControl, Hide, BtnAddScrollUp
    GuiControl, Hide, BtnAddScrollDown
    GuiControl, Hide, BtnAddRemap
    GuiControl, Hide, BtnToggleRemap
    GuiControl, Hide, RemapStatusText
    GuiControl, Hide, BtnHide
    GuiControl, Hide, BtnRunMode
    GuiControl, Hide, BtnClear
    GuiControl, Hide, BtnUndo
    GuiControl, Hide, TxtConfig
    GuiControl, Hide, SelectedConfig
    GuiControl, Hide, BtnSave
    GuiControl, Hide, BtnDelete
    Gui, Show, AutoSize
}
else
{
    IsCollapsed = 0
    GuiControl,, BtnCollapse, Collapse UI
    GuiControl, Show, BtnAddClick
    GuiControl, Show, BtnAddKey
    GuiControl, Show, BtnAddDrag
    GuiControl, Show, BtnAddHold
    GuiControl, Show, BtnAddScrollUp
    GuiControl, Show, BtnAddScrollDown
    GuiControl, Show, BtnAddRemap
    GuiControl, Show, BtnToggleRemap
    GuiControl, Show, RemapStatusText
    GuiControl, Show, BtnHide
    GuiControl, Show, BtnRunMode
    GuiControl, Show, BtnClear
    GuiControl, Show, BtnUndo
    GuiControl, Show, TxtConfig
    GuiControl, Show, SelectedConfig
    GuiControl, Show, BtnSave
    GuiControl, Show, BtnDelete
    Gui, Show, AutoSize
}
return

; --- Button: Toggle Hide/Show Targets ---
ToggleHide:
if IsRunning = 1
    return
if TargetCount = 0
    return

if IsHidden = 0
{
    IsHidden = 1
    GuiControl,, BtnHide, Show Targets
    GoSub, HideAllGUIs
}
else
{
    IsHidden = 0
    GuiControl,, BtnHide, Hide Targets
    GoSub, ShowAllGUIs
}
return

HideAllGUIs:
Loop, %TargetCount%
{
    type := TargetType%A_Index%
    if type = Drag
    {
        gNumA := TargetGuiA%A_Index%
        Gui, %gNumA%: Hide
        gNumB := TargetGuiB%A_Index%
        Gui, %gNumB%: Hide
    }
    else
    {
        gNum := TargetGui%A_Index%
        Gui, %gNum%: Hide
    }
}
return

ShowAllGUIs:
Loop, %TargetCount%
{
    type := TargetType%A_Index%
    if type = Drag
    {
        gNumA := TargetGuiA%A_Index%
        Gui, %gNumA%: Show, NoActivate
        gNumB := TargetGuiB%A_Index%
        Gui, %gNumB%: Show, NoActivate
    }
    else
    {
        gNum := TargetGui%A_Index%
        Gui, %gNum%: Show, NoActivate
    }
}
return

ForceUnhide:
if IsHidden = 1
{
    IsHidden = 0
    GuiControl,, BtnHide, Hide Targets
    GoSub, ShowAllGUIs
}
if IsCollapsed = 1
{
    GoSub, ToggleCollapse
}
return


; --- Button: Add Mouse Click ---
BtnAdd:
if IsRunning = 1
    return
GoSub, ForceUnhide
ToolTip, Click anywhere on the screen to place the next click target...
Hotkey, LButton, CatchClick, On
return

CatchClick:
Hotkey, LButton, CatchClick, Off
MouseGetPos, tX, tY
ToolTip

DelayPrompt = Enter wait time AFTER this click (in milliseconds):`n`n(e.g. 1000 = 1 second)
InputBox, tDelay, Target Delay, %DelayPrompt%,, 400, 200,,,,, 1000
if ErrorLevel > 0
    return

EnvAdd, TargetCount, 1
EnvAdd, VisualGuiCount, 1
gNum = %VisualGuiCount%

gx = %tX%
gy = %tY%
EnvSub, gx, 12
EnvSub, gy, 12

Gui, %gNum%: +AlwaysOnTop +ToolWindow -Caption +LastFound -SysMenu +LabelTGui
Gui, %gNum%: Color, Red
Gui, %gNum%: Font, s10 cWhite Bold
Gui, %gNum%: Add, Text, vTargetText%gNum% x0 y0 w24 h24 Center 0x200, %TargetCount%
WinSet, Transparent, 200
Gui, %gNum%: Show, x%gx% y%gy% w24 h24 NoActivate

TargetType%TargetCount% = Click
TargetDelay%TargetCount% = %tDelay%
TargetGui%TargetCount% = %gNum%
return

; --- Button: Add Keystroke ---
BtnAddKey:
if IsRunning = 1
    return
GoSub, ForceUnhide

KeyPrompt = Type the text, key, or combination to send.`n`nExamples: hello, {Enter}, {Space}, ctrl+c
InputBox, tKey, Add Keystroke, %KeyPrompt%,, 400, 240
if ErrorLevel > 0
    return
if tKey =
    return

KeyDelayPrompt = Enter wait time AFTER this keystroke (in milliseconds):
InputBox, tDelay, Target Delay, %KeyDelayPrompt%,, 400, 200,,,,, 1000
if ErrorLevel > 0
    return

EnvAdd, TargetCount, 1
EnvAdd, VisualGuiCount, 1
gNum = %VisualGuiCount%

gx = 50
gy = 50
offset = %TargetCount%
EnvMult, offset, 30
EnvAdd, gy, %offset%

Gui, %gNum%: +AlwaysOnTop +ToolWindow -Caption +LastFound -SysMenu +LabelTGui
Gui, %gNum%: Color, Blue
Gui, %gNum%: Font, s8 cWhite Bold
Gui, %gNum%: Add, Text, vTargetText%gNum% x0 y0 w100 h24 Center 0x200, %TargetCount%: %tKey%
WinSet, Transparent, 200
Gui, %gNum%: Show, x%gx% y%gy% w100 h24 NoActivate

TargetType%TargetCount% = Key
TargetKey%TargetCount% = %tKey%
TargetDelay%TargetCount% = %tDelay%
TargetGui%TargetCount% = %gNum%
return

; --- Button: Add Drag Target ---
BtnAddDrag:
if IsRunning = 1
    return
GoSub, ForceUnhide
ToolTip, Click the START point for the Drag...
DragStep = 1
Hotkey, LButton, CatchDrag, On
return

CatchDrag:
if DragStep = 1
{
    MouseGetPos, dStartX, dStartY
    ToolTip, Click the END point for the Drag...
    DragStep = 2
    return
}
if DragStep = 2
{
    Hotkey, LButton, CatchDrag, Off
    MouseGetPos, dEndX, dEndY
    ToolTip
    
    DragPrompt = Enter how slow the mouse should move while dragging:`n`n(0 = instant jump, 50 = normal human speed, 100 = very slow)
    InputBox, dSpeed, Drag Speed, %DragPrompt%,, 400, 220,,,,, 20
    if ErrorLevel > 0
        return
    
    DelayPrompt = Enter wait time AFTER the drag completes (in ms):
    InputBox, tDelay, Target Delay, %DelayPrompt%,, 400, 200,,,,, 1000
    if ErrorLevel > 0
        return

    EnvAdd, TargetCount, 1
    
    EnvAdd, VisualGuiCount, 1
    gNumA = %VisualGuiCount%
    gxA = %dStartX%
    gyA = %dStartY%
    EnvSub, gxA, 12
    EnvSub, gyA, 12
    
    Gui, %gNumA%: +AlwaysOnTop +ToolWindow -Caption +LastFound -SysMenu +LabelTGui
    Gui, %gNumA%: Color, Green
    Gui, %gNumA%: Font, s10 cWhite Bold
    Gui, %gNumA%: Add, Text, vTargetText%gNumA% x0 y0 w24 h24 Center 0x200, %TargetCount%S
    WinSet, Transparent, 200
    Gui, %gNumA%: Show, x%gxA% y%gyA% w24 h24 NoActivate
    
    EnvAdd, VisualGuiCount, 1
    gNumB = %VisualGuiCount%
    gxB = %dEndX%
    gyB = %dEndY%
    EnvSub, gxB, 12
    EnvSub, gyB, 12
    
    Gui, %gNumB%: +AlwaysOnTop +ToolWindow -Caption +LastFound -SysMenu +LabelTGui
    Gui, %gNumB%: Color, Green
    Gui, %gNumB%: Font, s10 cWhite Bold
    Gui, %gNumB%: Add, Text, vTargetText%gNumB% x0 y0 w24 h24 Center 0x200, %TargetCount%E
    WinSet, Transparent, 200
    Gui, %gNumB%: Show, x%gxB% y%gyB% w24 h24 NoActivate

    TargetType%TargetCount% = Drag
    TargetDelay%TargetCount% = %tDelay%
    TargetDragSpeed%TargetCount% = %dSpeed%
    TargetGuiA%TargetCount% = %gNumA%
    TargetGuiB%TargetCount% = %gNumB%
}
return

; --- Button: Add Hold Target ---
BtnAddHold:
if IsRunning = 1
    return
GoSub, ForceUnhide

HoldKeyPrompt = Enter the key or mouse button to HOLD down:`n(Single buttons only! Do not use combinations)`n`nExamples: LButton, RButton, Space, a
InputBox, tKey, Hold Target, %HoldKeyPrompt%,, 400, 240
if ErrorLevel > 0
    return
if tKey =
    return

ToolTip, Click anywhere on the screen to place the Hold target...
Hotkey, LButton, CatchHoldClick, On
return

CatchHoldClick:
Hotkey, LButton, CatchHoldClick, Off
MouseGetPos, tX, tY
ToolTip

HoldTimePrompt = Enter how long to HOLD the button down (in ms):`n`n(e.g., 2000 = 2 seconds)
InputBox, tHold, Hold Duration, %HoldTimePrompt%,, 400, 200,,,,, 2000
if ErrorLevel > 0
    return

DelayPrompt = Enter wait time AFTER releasing the button (in ms):
InputBox, tDelay, Target Delay, %DelayPrompt%,, 400, 200,,,,, 1000
if ErrorLevel > 0
    return

EnvAdd, TargetCount, 1
EnvAdd, VisualGuiCount, 1
gNum = %VisualGuiCount%

gx = %tX%
gy = %tY%
EnvSub, gx, 50 ; Center width 100
EnvSub, gy, 12 ; Center height 24

Gui, %gNum%: +AlwaysOnTop +ToolWindow -Caption +LastFound -SysMenu +LabelTGui
Gui, %gNum%: Color, Orange
Gui, %gNum%: Font, s8 cWhite Bold
Gui, %gNum%: Add, Text, vTargetText%gNum% x0 y0 w100 h24 Center 0x200, %TargetCount%: Hld %tKey%
WinSet, Transparent, 200
Gui, %gNum%: Show, x%gx% y%gy% w100 h24 NoActivate

TargetType%TargetCount% = Hold
TargetKey%TargetCount% = %tKey%
TargetHoldDuration%TargetCount% = %tHold%
TargetDelay%TargetCount% = %tDelay%
TargetGui%TargetCount% = %gNum%
return

; --- Button: Add Scroll UP Target ---
BtnAddScrollUp:
if IsRunning = 1
    return
GoSub, ForceUnhide

ScrollPendingDir = U

AmtPrompt = Enter scroll amount (number of ticks to scroll UP):
InputBox, ScrollPendingAmt, Scroll Amount, %AmtPrompt%,, 400, 200,,,,, 5
if ErrorLevel > 0
    return

ToolTip, Click anywhere on the screen to place the Scroll UP target...
Hotkey, LButton, CatchScrollClick, On
return

; --- Button: Add Scroll DOWN Target ---
BtnAddScrollDown:
if IsRunning = 1
    return
GoSub, ForceUnhide

ScrollPendingDir = D

AmtPrompt = Enter scroll amount (number of ticks to scroll DOWN):
InputBox, ScrollPendingAmt, Scroll Amount, %AmtPrompt%,, 400, 200,,,,, 5
if ErrorLevel > 0
    return

ToolTip, Click anywhere on the screen to place the Scroll DOWN target...
Hotkey, LButton, CatchScrollClick, On
return

CatchScrollClick:
Hotkey, LButton, CatchScrollClick, Off
MouseGetPos, tX, tY
ToolTip

DelayPrompt = Enter wait time AFTER scrolling (in ms):
InputBox, tDelay, Target Delay, %DelayPrompt%,, 400, 200,,,,, 1000
if ErrorLevel > 0
    return

EnvAdd, TargetCount, 1
EnvAdd, VisualGuiCount, 1
gNum = %VisualGuiCount%

gx = %tX%
gy = %tY%
EnvSub, gx, 50
EnvSub, gy, 12

tDir = %ScrollPendingDir%
tAmt = %ScrollPendingAmt%

Gui, %gNum%: +AlwaysOnTop +ToolWindow -Caption +LastFound -SysMenu +LabelTGui
Gui, %gNum%: Color, Teal
Gui, %gNum%: Font, s8 cWhite Bold
Gui, %gNum%: Add, Text, vTargetText%gNum% x0 y0 w100 h24 Center 0x200, %TargetCount%: Scr %tDir% %tAmt%
WinSet, Transparent, 200
Gui, %gNum%: Show, x%gx% y%gy% w100 h24 NoActivate

TargetType%TargetCount% = Scroll
TargetScrollDir%TargetCount% = %tDir%
TargetScrollAmt%TargetCount% = %tAmt%
TargetDelay%TargetCount% = %tDelay%
TargetGui%TargetCount% = %gNum%
return

; --- Button: Add Remap Target ---
BtnAddRemap:
if RemapsRunning = 1
    return
GoSub, ForceUnhide

FromPrompt = Enter the key or combo to INTERCEPT.`n`nExamples: a, Space, LButton, ctrl+c, shift+a
InputBox, tFrom, Key Remap, %FromPrompt%,, 400, 220
if ErrorLevel > 0
    return
if tFrom =
    return

ToPrompt = Enter the key or combo to SEND instead.`n`nExamples: b, {Space}, {Enter}, ctrl+v
InputBox, tTo, Key Remap, %ToPrompt%,, 400, 220
if ErrorLevel > 0
    return

EnvAdd, TargetCount, 1
EnvAdd, VisualGuiCount, 1
gNum = %VisualGuiCount%

gx = 50
gy = 50
offset = %TargetCount%
EnvMult, offset, 30
EnvAdd, gy, %offset%

Gui, %gNum%: +AlwaysOnTop +ToolWindow -Caption +LastFound -SysMenu +LabelTGui
Gui, %gNum%: Color, Purple
Gui, %gNum%: Font, s8 cWhite Bold
Gui, %gNum%: Add, Text, vTargetText%gNum% x0 y0 w100 h24 Center 0x200, %TargetCount%: %tFrom% > %tTo%
WinSet, Transparent, 200
Gui, %gNum%: Show, x%gx% y%gy% w100 h24 NoActivate

TargetType%TargetCount% = Remap
TargetRemapFrom%TargetCount% = %tFrom%
TargetRemapTo%TargetCount% = %tTo%
TargetDelay%TargetCount% = 0
TargetGui%TargetCount% = %gNum%
return

; --- Button: Clear All Targets ---
BtnClear:
if IsRunning = 1
    return
if RemapsRunning = 1
    return
GoSub, ForceUnhide

CopiedType = ; Clear clipboard cache just in case

Loop, %TargetCount%
{
    type := TargetType%A_Index%
    if type = Drag
    {
        gNumA := TargetGuiA%A_Index%
        Gui, %gNumA%: Destroy
        gNumB := TargetGuiB%A_Index%
        Gui, %gNumB%: Destroy
    }
    else
    {
        gNum := TargetGui%A_Index%
        Gui, %gNum%: Destroy
    }
}
TargetCount = 0
VisualGuiCount = 1
return

; --- Button: Undo Last Target ---
BtnUndo:
if IsRunning = 1
    return
if RemapsRunning = 1
    return
if TargetCount = 0
    return
GoSub, ForceUnhide
type := TargetType%TargetCount%

if type = Drag
{
    gNumA := TargetGuiA%TargetCount%
    Gui, %gNumA%: Destroy
    gNumB := TargetGuiB%TargetCount%
    Gui, %gNumB%: Destroy
    EnvSub, VisualGuiCount, 2
}
else
{
    gNum := TargetGui%TargetCount%
    Gui, %gNum%: Destroy
    EnvSub, VisualGuiCount, 1
}

EnvSub, TargetCount, 1
return

; --- Button: Save Config (FIXED) ---
BtnSave:
if IsRunning = 1
    return
if RemapsRunning = 1
    return
if TargetCount = 0
{
    MsgBox, 48, Error, No targets to save!
    return
}

InputBox, newName, Save Config, Enter a name for this config`n(No spaces or special characters):,, 400, 200
if ErrorLevel > 0
    return
if newName =
    return

GoSub, ForceUnhide 

IniWrite, %TargetCount%, %IniFile%, %newName%, Count

Loop, %TargetCount%
{
    type := TargetType%A_Index%
    IniWrite, %type%, %IniFile%, %newName%, Type%A_Index%
    del := TargetDelay%A_Index%
    IniWrite, %del%, %IniFile%, %newName%, Delay%A_Index%
    
    if type = Drag
    {
        gNumA := TargetGuiA%A_Index%
        Gui, %gNumA%: +LastFound
        WinGetPos, winXA, winYA
        cxA = %winXA%
        cyA = %winYA%
        EnvAdd, cxA, 12
        EnvAdd, cyA, 12
        IniWrite, %cxA%, %IniFile%, %newName%, XA%A_Index%
        IniWrite, %cyA%, %IniFile%, %newName%, YA%A_Index%
        
        gNumB := TargetGuiB%A_Index%
        Gui, %gNumB%: +LastFound
        WinGetPos, winXB, winYB
        cxB = %winXB%
        cyB = %winYB%
        EnvAdd, cxB, 12
        EnvAdd, cyB, 12
        IniWrite, %cxB%, %IniFile%, %newName%, XB%A_Index%
        IniWrite, %cyB%, %IniFile%, %newName%, YB%A_Index%
        
        ds := TargetDragSpeed%A_Index%
        IniWrite, %ds%, %IniFile%, %newName%, DragSpeed%A_Index%
    }
    else if type = Key
    {
        gNum := TargetGui%A_Index%
        Gui, %gNum%: +LastFound
        WinGetPos, winX, winY
        cx = %winX%
        cy = %winY%
        EnvAdd, cx, 50
        EnvAdd, cy, 12
        IniWrite, %cx%, %IniFile%, %newName%, X%A_Index%
        IniWrite, %cy%, %IniFile%, %newName%, Y%A_Index%
        
        tk := TargetKey%A_Index%
        IniWrite, %tk%, %IniFile%, %newName%, Key%A_Index%
    }
    else if type = Hold
    {
        gNum := TargetGui%A_Index%
        Gui, %gNum%: +LastFound
        WinGetPos, winX, winY
        cx = %winX%
        cy = %winY%
        EnvAdd, cx, 50
        EnvAdd, cy, 12
        IniWrite, %cx%, %IniFile%, %newName%, X%A_Index%
        IniWrite, %cy%, %IniFile%, %newName%, Y%A_Index%
        
        tk := TargetKey%A_Index%
        th := TargetHoldDuration%A_Index%
        IniWrite, %tk%, %IniFile%, %newName%, Key%A_Index%
        IniWrite, %th%, %IniFile%, %newName%, HoldDur%A_Index%
    }
    else if type = Scroll
    {
        gNum := TargetGui%A_Index%
        Gui, %gNum%: +LastFound
        WinGetPos, winX, winY
        cx = %winX%
        cy = %winY%
        EnvAdd, cx, 50
        EnvAdd, cy, 12
        IniWrite, %cx%, %IniFile%, %newName%, X%A_Index%
        IniWrite, %cy%, %IniFile%, %newName%, Y%A_Index%
        
        sD := TargetScrollDir%A_Index%
        sA := TargetScrollAmt%A_Index%
        IniWrite, %sD%, %IniFile%, %newName%, ScrollDir%A_Index%
        IniWrite, %sA%, %IniFile%, %newName%, ScrollAmt%A_Index%
    }
    else if type = Remap
    {
        gNum := TargetGui%A_Index%
        Gui, %gNum%: +LastFound
        WinGetPos, winX, winY
        cx = %winX%
        cy = %winY%
        EnvAdd, cx, 50
        EnvAdd, cy, 12
        IniWrite, %cx%, %IniFile%, %newName%, X%A_Index%
        IniWrite, %cy%, %IniFile%, %newName%, Y%A_Index%
        
        fK := TargetRemapFrom%A_Index%
        tK := TargetRemapTo%A_Index%
        IniWrite, %fK%, %IniFile%, %newName%, RemapFrom%A_Index%
        IniWrite, %tK%, %IniFile%, %newName%, RemapTo%A_Index%
    }
    else
    {
        gNum := TargetGui%A_Index%
        Gui, %gNum%: +LastFound
        WinGetPos, winX, winY
        cx = %winX%
        cy = %winY%
        EnvAdd, cx, 12
        EnvAdd, cy, 12
        IniWrite, %cx%, %IniFile%, %newName%, X%A_Index%
        IniWrite, %cy%, %IniFile%, %newName%, Y%A_Index%
    }
}

IniRead, curList, %IniFile%, Main, Configs, %A_Space%
foundExact = 0
Loop, Parse, curList, |
{
    if A_LoopField = %newName%
    {
        foundExact = 1
        break
    }
}

if foundExact = 1
{
    GuiControl, ChooseString, SelectedConfig, %newName%
    MsgBox, 64, Success, Configuration '%newName%' updated!
}
else
{
    if curList = %A_Space%
        newList = %newName%
    else
        newList = %curList%|%newName%
        
    IniWrite, %newList%, %IniFile%, Main, Configs
    GuiControl,, SelectedConfig, |%newList%
    GuiControl, ChooseString, SelectedConfig, %newName%
    MsgBox, 64, Success, Configuration '%newName%' saved!
}
return

; --- Dropdown: Load Config ---
LoadConfig:
if IsRunning = 1
    return
if RemapsRunning = 1
    return
Gui, Submit, NoHide
if SelectedConfig =
    return

GoSub, BtnClear
IniRead, loadCount, %IniFile%, %SelectedConfig%, Count, 0

Loop, %loadCount%
{
    IniRead, ltype, %IniFile%, %SelectedConfig%, Type%A_Index%, Click
    IniRead, ldelay, %IniFile%, %SelectedConfig%, Delay%A_Index%, 1000
    
    EnvAdd, TargetCount, 1
    
    if ltype = Drag
    {
        IniRead, lxA, %IniFile%, %SelectedConfig%, XA%A_Index%, 0
        IniRead, lyA, %IniFile%, %SelectedConfig%, YA%A_Index%, 0
        IniRead, lxB, %IniFile%, %SelectedConfig%, XB%A_Index%, 0
        IniRead, lyB, %IniFile%, %SelectedConfig%, YB%A_Index%, 0
        IniRead, lspeed, %IniFile%, %SelectedConfig%, DragSpeed%A_Index%, 20
        
        EnvAdd, VisualGuiCount, 1
        gNumA = %VisualGuiCount%
        gxA = %lxA%
        gyA = %lyA%
        EnvSub, gxA, 12
        EnvSub, gyA, 12
        
        Gui, %gNumA%: +AlwaysOnTop +ToolWindow -Caption +LastFound -SysMenu +LabelTGui
        Gui, %gNumA%: Color, Green
        Gui, %gNumA%: Font, s10 cWhite Bold
        Gui, %gNumA%: Add, Text, vTargetText%gNumA% x0 y0 w24 h24 Center 0x200, %TargetCount%S
        WinSet, Transparent, 200
        Gui, %gNumA%: Show, x%gxA% y%gyA% w24 h24 NoActivate
        
        EnvAdd, VisualGuiCount, 1
        gNumB = %VisualGuiCount%
        gxB = %lxB%
        gyB = %lyB%
        EnvSub, gxB, 12
        EnvSub, gyB, 12
        
        Gui, %gNumB%: +AlwaysOnTop +ToolWindow -Caption +LastFound -SysMenu +LabelTGui
        Gui, %gNumB%: Color, Green
        Gui, %gNumB%: Font, s10 cWhite Bold
        Gui, %gNumB%: Add, Text, vTargetText%gNumB% x0 y0 w24 h24 Center 0x200, %TargetCount%E
        WinSet, Transparent, 200
        Gui, %gNumB%: Show, x%gxB% y%gyB% w24 h24 NoActivate
        
        TargetType%TargetCount% = Drag
        TargetDelay%TargetCount% = %ldelay%
        TargetDragSpeed%TargetCount% = %lspeed%
        TargetGuiA%TargetCount% = %gNumA%
        TargetGuiB%TargetCount% = %gNumB%
    }
    else if ltype = Hold
    {
        IniRead, lx, %IniFile%, %SelectedConfig%, X%A_Index%, 0
        IniRead, ly, %IniFile%, %SelectedConfig%, Y%A_Index%, 0
        IniRead, lkey, %IniFile%, %SelectedConfig%, Key%A_Index%, LButton
        IniRead, ldur, %IniFile%, %SelectedConfig%, HoldDur%A_Index%, 2000
        
        EnvAdd, VisualGuiCount, 1
        gNum = %VisualGuiCount%
        
        gx = %lx%
        gy = %ly%
        EnvSub, gx, 50
        EnvSub, gy, 12
        
        Gui, %gNum%: +AlwaysOnTop +ToolWindow -Caption +LastFound -SysMenu +LabelTGui
        Gui, %gNum%: Color, Orange
        Gui, %gNum%: Font, s8 cWhite Bold
        Gui, %gNum%: Add, Text, vTargetText%gNum% x0 y0 w100 h24 Center 0x200, %TargetCount%: Hld %lkey%
        WinSet, Transparent, 200
        Gui, %gNum%: Show, x%gx% y%gy% w100 h24 NoActivate
        
        TargetType%TargetCount% = Hold
        TargetKey%TargetCount% = %lkey%
        TargetHoldDuration%TargetCount% = %ldur%
        TargetDelay%TargetCount% = %ldelay%
        TargetGui%TargetCount% = %gNum%
    }
    else if ltype = Scroll
    {
        IniRead, lx, %IniFile%, %SelectedConfig%, X%A_Index%, 0
        IniRead, ly, %IniFile%, %SelectedConfig%, Y%A_Index%, 0
        IniRead, lSD, %IniFile%, %SelectedConfig%, ScrollDir%A_Index%, U
        IniRead, lSA, %IniFile%, %SelectedConfig%, ScrollAmt%A_Index%, 5
        
        EnvAdd, VisualGuiCount, 1
        gNum = %VisualGuiCount%
        
        gx = %lx%
        gy = %ly%
        EnvSub, gx, 50
        EnvSub, gy, 12
        
        Gui, %gNum%: +AlwaysOnTop +ToolWindow -Caption +LastFound -SysMenu +LabelTGui
        Gui, %gNum%: Color, Teal
        Gui, %gNum%: Font, s8 cWhite Bold
        Gui, %gNum%: Add, Text, vTargetText%gNum% x0 y0 w100 h24 Center 0x200, %TargetCount%: Scr %lSD% %lSA%
        WinSet, Transparent, 200
        Gui, %gNum%: Show, x%gx% y%gy% w100 h24 NoActivate
        
        TargetType%TargetCount% = Scroll
        TargetScrollDir%TargetCount% = %lSD%
        TargetScrollAmt%TargetCount% = %lSA%
        TargetDelay%TargetCount% = %ldelay%
        TargetGui%TargetCount% = %gNum%
    }
    else if ltype = Remap
    {
        IniRead, lx, %IniFile%, %SelectedConfig%, X%A_Index%, 0
        IniRead, ly, %IniFile%, %SelectedConfig%, Y%A_Index%, 0
        IniRead, lfK, %IniFile%, %SelectedConfig%, RemapFrom%A_Index%, a
        IniRead, ltK, %IniFile%, %SelectedConfig%, RemapTo%A_Index%, b
        
        EnvAdd, VisualGuiCount, 1
        gNum = %VisualGuiCount%
        
        gx = %lx%
        gy = %ly%
        EnvSub, gx, 50
        EnvSub, gy, 12
        
        Gui, %gNum%: +AlwaysOnTop +ToolWindow -Caption +LastFound -SysMenu +LabelTGui
        Gui, %gNum%: Color, Purple
        Gui, %gNum%: Font, s8 cWhite Bold
        Gui, %gNum%: Add, Text, vTargetText%gNum% x0 y0 w100 h24 Center 0x200, %TargetCount%: %lfK% > %ltK%
        WinSet, Transparent, 200
        Gui, %gNum%: Show, x%gx% y%gy% w100 h24 NoActivate
        
        TargetType%TargetCount% = Remap
        TargetRemapFrom%TargetCount% = %lfK%
        TargetRemapTo%TargetCount% = %ltK%
        TargetDelay%TargetCount% = 0
        TargetGui%TargetCount% = %gNum%
    }
    else
    {
        IniRead, lx, %IniFile%, %SelectedConfig%, X%A_Index%, 0
        IniRead, ly, %IniFile%, %SelectedConfig%, Y%A_Index%, 0
        EnvAdd, VisualGuiCount, 1
        gNum = %VisualGuiCount%
        
        gx = %lx%
        gy = %ly%
        
        if ltype = Key
        {
            IniRead, lkey, %IniFile%, %SelectedConfig%, Key%A_Index%, Space
            EnvSub, gx, 50
            EnvSub, gy, 12
            
            Gui, %gNum%: +AlwaysOnTop +ToolWindow -Caption +LastFound -SysMenu +LabelTGui
            Gui, %gNum%: Color, Blue
            Gui, %gNum%: Font, s8 cWhite Bold
            Gui, %gNum%: Add, Text, vTargetText%gNum% x0 y0 w100 h24 Center 0x200, %TargetCount%: %lkey%
            WinSet, Transparent, 200
            Gui, %gNum%: Show, x%gx% y%gy% w100 h24 NoActivate
            
            TargetType%TargetCount% = Key
            TargetKey%TargetCount% = %lkey%
        }
        else
        {
            EnvSub, gx, 12
            EnvSub, gy, 12
            
            Gui, %gNum%: +AlwaysOnTop +ToolWindow -Caption +LastFound -SysMenu +LabelTGui
            Gui, %gNum%: Color, Red
            Gui, %gNum%: Font, s10 cWhite Bold
            Gui, %gNum%: Add, Text, vTargetText%gNum% x0 y0 w24 h24 Center 0x200, %TargetCount%
            WinSet, Transparent, 200
            Gui, %gNum%: Show, x%gx% y%gy% w24 h24 NoActivate
            
            TargetType%TargetCount% = Click
        }
        
        TargetDelay%TargetCount% = %ldelay%
        TargetGui%TargetCount% = %gNum%
    }
}
return

; --- Button: Delete Config ---
BtnDelete:
if IsRunning = 1
    return
if RemapsRunning = 1
    return
Gui, Submit, NoHide
if SelectedConfig =
    return

MsgBox, 36, Confirm, Are you sure you want to delete '%SelectedConfig%'?
IfMsgBox, No
    return

IniDelete, %IniFile%, %SelectedConfig%

IniRead, curList, %IniFile%, Main, Configs, %A_Space%
newList = 
Loop, Parse, curList, |
{
    if A_LoopField = %SelectedConfig%
        continue
    if newList = 
        newList = %A_LoopField%
    else
        newList = %newList%|%A_LoopField%
}

IniWrite, %newList%, %IniFile%, Main, Configs
GuiControl,, SelectedConfig, |%newList%
GoSub, BtnClear
return

; --- F7 Hotkey: Toggle Start/Stop Main Loop ---
F7::
if TargetCount = 0
{
    MsgBox, 48, Error, No targets defined! Add targets first.
    return
}

if IsRunning = 0
{
    IsRunning = 1
    GuiControl,, StatusText, [ RUNNING ]
    Gui, Font, cGreen
    GuiControl, Font, StatusText
    
    Loop, %TargetCount%
    {
        type := TargetType%A_Index%
        
        if type = Remap
            continue ; Skipped, handled independently by Play button
        
        if IsHidden = 0
        {
            if type = Drag
            {
                gNumA := TargetGuiA%A_Index%
                Gui, %gNumA%: +E0x20
                gNumB := TargetGuiB%A_Index%
                Gui, %gNumB%: +E0x20
            }
            else
            {
                gNum := TargetGui%A_Index%
                Gui, %gNum%: +E0x20
            }
        }
    }
    
    SetTimer, ClickerLoop, -1
}
else
{
    IsRunning = 0
    GuiControl,, StatusText, [ STOPPED ]
    Gui, Font, cRed
    GuiControl, Font, StatusText
    
    Loop, %TargetCount%
    {
        type := TargetType%A_Index%
        
        if type = Remap
            continue ; Skipped, handled independently by Play button
        
        if IsHidden = 0
        {
            if type = Drag
            {
                gNumA := TargetGuiA%A_Index%
                Gui, %gNumA%: -E0x20
                gNumB := TargetGuiB%A_Index%
                Gui, %gNumB%: -E0x20
            }
            else
            {
                gNum := TargetGui%A_Index%
                Gui, %gNum%: -E0x20
            }
        }
    }
}
return

; --- Intercept Remap Logic ---
DoRemap:
pressedKey = %A_ThisHotkey%
Loop, %TargetCount%
{
    type := TargetType%A_Index%
    if type = Remap
    {
        rFromTrans := TargetRemapFromTrans%A_Index%
        if rFromTrans = %pressedKey%
        {
            rTo := TargetRemapTo%A_Index%
            
            StringReplace, rTo, rTo, ctrl%A_Space%+%A_Space%, ^, All
            StringReplace, rTo, rTo, ctrl+, ^, All
            StringReplace, rTo, rTo, ctrl-, ^, All
            StringReplace, rTo, rTo, shift%A_Space%+%A_Space%, +, All
            StringReplace, rTo, rTo, shift+, +, All
            StringReplace, rTo, rTo, shift-, +, All
            StringReplace, rTo, rTo, alt%A_Space%+%A_Space%, !, All
            StringReplace, rTo, rTo, alt+, !, All
            StringReplace, rTo, rTo, alt-, !, All
            StringReplace, rTo, rTo, win%A_Space%+%A_Space%, #, All
            StringReplace, rTo, rTo, win+, #, All
            StringReplace, rTo, rTo, win-, #, All
            
            Send, %rTo%
            break
        }
    }
}
return

; --- Main Clicking & Typing Loop ---
ClickerLoop:
Loop
{
    Loop, %TargetCount%
    {
        if IsRunning = 0
            return
        
        type := TargetType%A_Index%
        
        if type = Remap
        {
            continue
        }
        else if type = Hold
        {
            gNum := TargetGui%A_Index%
            Gui, %gNum%: +LastFound
            WinGetPos, winX, winY
            cx = %winX%
            cy = %winY%
            EnvAdd, cx, 50
            EnvAdd, cy, 12
            
            MouseMove, %cx%, %cy%, 0
            Sleep, 50
            
            hk := TargetKey%A_Index%
            Send, {%hk% down}
            
            ; Hold mini-loop allows instant F7 interrupts!
            hLeft := TargetHoldDuration%A_Index%
            Loop
            {
                if hLeft <= 0
                    break
                if IsRunning = 0
                {
                    Send, {%hk% up}
                    return
                }
                
                if hLeft > 50
                    hAmount = 50
                else
                    hAmount = %hLeft%
                    
                Sleep, %hAmount%
                EnvSub, hLeft, %hAmount%
            }
            
            Send, {%hk% up}
        }
        else if type = Scroll
        {
            gNum := TargetGui%A_Index%
            Gui, %gNum%: +LastFound
            WinGetPos, winX, winY
            cx = %winX%
            cy = %winY%
            EnvAdd, cx, 50
            EnvAdd, cy, 12
            
            MouseMove, %cx%, %cy%, 0
            Sleep, 50
            
            sDir := TargetScrollDir%A_Index%
            sAmt := TargetScrollAmt%A_Index%
            
            if sDir = U
            {
                MouseClick, WheelUp, , , %sAmt%
            }
            else
            {
                MouseClick, WheelDown, , , %sAmt%
            }
        }
        else if type = Key
        {
            tk := TargetKey%A_Index%
            StringReplace, tk, tk, ctrl%A_Space%+%A_Space%, ^, All
            StringReplace, tk, tk, ctrl+, ^, All
            StringReplace, tk, tk, ctrl-, ^, All
            StringReplace, tk, tk, shift%A_Space%+%A_Space%, +, All
            StringReplace, tk, tk, shift+, +, All
            StringReplace, tk, tk, shift-, +, All
            StringReplace, tk, tk, alt%A_Space%+%A_Space%, !, All
            StringReplace, tk, tk, alt+, !, All
            StringReplace, tk, tk, alt-, !, All
            StringReplace, tk, tk, win%A_Space%+%A_Space%, #, All
            StringReplace, tk, tk, win+, #, All
            StringReplace, tk, tk, win-, #, All
            Send, %tk%
        }
        else if type = Drag
        {
            gNumA := TargetGuiA%A_Index%
            Gui, %gNumA%: +LastFound
            WinGetPos, winXA, winYA
            cxA = %winXA%
            cyA = %winYA%
            EnvAdd, cxA, 12
            EnvAdd, cyA, 12
            
            gNumB := TargetGuiB%A_Index%
            Gui, %gNumB%: +LastFound
            WinGetPos, winXB, winYB
            cxB = %winXB%
            cyB = %winYB%
            EnvAdd, cxB, 12
            EnvAdd, cyB, 12
            
            dSpeed := TargetDragSpeed%A_Index%
            
            MouseMove, %cxA%, %cyA%, 0
            Sleep, 50
            Click, Down
            Sleep, 50
            MouseMove, %cxB%, %cyB%, %dSpeed%
            Sleep, 50
            Click, Up
        }
        else
        {
            gNum := TargetGui%A_Index%
            Gui, %gNum%: +LastFound
            WinGetPos, winX, winY
            cx = %winX%
            cy = %winY%
            EnvAdd, cx, 12
            EnvAdd, cy, 12
            Click, %cx%, %cy%
        }
        
        timeLeft := TargetDelay%A_Index%
        
        Loop
        {
            if timeLeft <= 0
                break
            if IsRunning = 0
                break
            
            if timeLeft > 50
                sleepAmount = 50
            else
                sleepAmount = %timeLeft%
                
            Sleep, %sleepAmount%
            EnvSub, timeLeft, %sleepAmount%
        }
    }
    
    if RunOnceMode = 1
    {
        if IsRunning = 1
        {
            GoSub, F7
        }
        break
    }
}
return

; --- Allow Window Dragging ---
DragWindow()
{
    if A_Gui = 1 
        return
    PostMessage, 0xA1, 2,,, A
}

GuiClose:
ExitApp