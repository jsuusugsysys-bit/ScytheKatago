; Scythe-Katago Helper Script (Compatible Version)
; Requires AutoHotkey (https://www.autohotkey.com/)

#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%

; F1 Key: Trigger Scythe Mode (Using kata-set-param Hack)
F1::
    SetTitleMatchMode, 2
    IfWinActive, Lizzie
    {
        Send, g
        Sleep, 50
        Send, kata-set-param scythe_trigger true{Enter}
        Sleep, 50
        Send, {Esc}
        SoundBeep, 750, 100
    }
return

; F2 Key: Set Black Scythes to 3
F2::
    SetTitleMatchMode, 2
    IfWinActive, Lizzie
    {
        Send, g
        Sleep, 50
        Send, kata-set-param scythe_count_black 3{Enter}
        Sleep, 50
        Send, {Esc}
        SoundBeep, 500, 200
    }
return

; F3 Key: Set White Scythes to 3
F3::
    SetTitleMatchMode, 2
    IfWinActive, Lizzie
    {
        Send, g
        Sleep, 50
        Send, kata-set-param scythe_count_white 3{Enter}
        Sleep, 50
        Send, {Esc}
        SoundBeep, 500, 200
    }
return
