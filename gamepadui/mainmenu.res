"GameMenu"
{
	"ResumeGame"
	{
		"text"			"#GameUI_GameMenu_ResumeGame"
		"command"		"cmd gamemenucommand resumegame"
		"priority"		"7"
		"family"		"ingame"
	}
	"Disconnect"
	{
		"text" "#GameUI_GameMenu_Disconnect"
		"command" "cmd disconnect"
		"priority" "6"
		"family" "ingame"
	}
	"Mute"
	{
		"text" "#GameUI_GameMenu_PlayerList"
		"command" "cmd gamemenucommand openplayerlistdialog"
		"priority" "5"
		"family" "ingame"
	}
	"FindServers"
	{
		"text" "#GameUI_GameMenu_FindServers"
		"command" "cmd gamemenucommand openserverbrowser"                 
		"priority" "4"
		"family" "all"
	}
	"CreateServer"
	{
		"text" "#GameUI_GameMenu_CreateServer"
		"command" "cmd gamemenucommand OpenCreateMultiplayerGameDialog"               
        "priority" "3"
		"family" "all"
	}
	"Options"
	{
		"text" "#GameUI_GameMenu_Options"
		"command" "cmd gamepadui_openoptionsdialog"                 
        "priority" "2"
		"family" "all"
	}
	"Quit"
	{
		"text" "#GameUI_GameMenu_Quit"
		"command" "cmd gamepadui_openquitgamedialog"                 
        "priority" "1"
		"family" "all"
	}
}

