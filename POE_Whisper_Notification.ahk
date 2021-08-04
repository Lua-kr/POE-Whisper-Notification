#Persistent
#NoEnv
#SingleInstance, Force

SetBatchLines -1
DetectHiddenWindows, Off
FileEncoding, UTF-8
OnExit("CloseApp")

global NAME := "Path Of Exile Whisper Notification"
global VERSION := "v1.0"

Menu, Tray, NoStandard
if ( !A_IsCompiled && FileExist(A_ScriptDir "/icon.ico") )
	Menu, Tray, Icon, %A_ScriptDir%/icon.ico
Menu,Tray,Tip,POE Whisper Notification
Menu,Tray,Icon
Menu, Tray, Add, About
Menu, Tray, Add, Exit, CloseApp
Menu, Tray, Default, About


if (!FileExist(A_ScriptDir "/config.ini"))
{
	IniWrite, -1, %A_ScriptDir%/config.ini, PathOfExile, GAME_CLIENT_LOG_PATH
	IniWrite, -1, %A_ScriptDir%/config.ini, PathOfExile, GAME_CLIENT_LOG_LIMIT_SIZE
	IniWrite, -1, %A_ScriptDir%/config.ini, PathOfExile, GAME_CLIENT_LOG_BACKUP
	IniWrite, -1, %A_ScriptDir%/config.ini, Telegram, TELEGRAM_BOT_TOKEN
	IniWrite, -1, %A_ScriptDir%/config.ini, Telegram, TELEGRAM_CHAT_ROOM_ID
	IniWrite, -1, %A_ScriptDir%/config.ini, Config, NOTIFICATION_ALL_WHISPERS
}

global SendTelegramMessage_CHECK := false
global GAME_CLIENT_LOG_PATH
global GAME_CLIENT_LOG_LIMIT_SIZE
global GAME_CLIENT_LOG_BACKUP
global TELEGRAM_BOT_TOKEN
global TELEGRAM_CHAT_ROOM_ID
global NOTIFICATION_ALL_WHISPERS
IniRead, GAME_CLIENT_LOG_PATH, %A_ScriptDir%/config.ini, PathOfExile, GAME_CLIENT_LOG_PATH
IniRead, GAME_CLIENT_LOG_LIMIT_SIZE, %A_ScriptDir%/config.ini, PathOfExile, GAME_CLIENT_LOG_LIMIT_SIZE
IniRead, GAME_CLIENT_LOG_BACKUP, %A_ScriptDir%/config.ini, PathOfExile, GAME_CLIENT_LOG_BACKUP
IniRead, TELEGRAM_BOT_TOKEN, %A_ScriptDir%/config.ini, Telegram, TELEGRAM_BOT_TOKEN
IniRead, TELEGRAM_CHAT_ROOM_ID, %A_ScriptDir%/config.ini, Telegram, TELEGRAM_CHAT_ROOM_ID
IniRead, NOTIFICATION_ALL_WHISPERS, %A_ScriptDir%/config.ini, Config, NOTIFICATION_ALL_WHISPERS

CheckConfig()
Main()

Main()
{
	if (!FileExist(GAME_CLIENT_LOG_PATH))
	{
		MsgBox, 4144, % NAME, Couldn't find Path of Exile Client Log File:`n%GAME_CLIENT_LOG_PATH%
		ExitApp
	}
	SendTelegramMessage(NAME . " - Started")
	TrayTip, % NAME, Started, 3, 1
	SetTimer, LogWatcher, 100
	Return
}

LogWatcher()
{
	static fileOldCheckSize := 3
	FileGetSize, logFileSize, % GAME_CLIENT_LOG_PATH
	if (ErrorLevel == 0 && logFileSize > 3)
	{
		if (fileOldCheckSize == 3)
			fileOldCheckSize := logFileSize, Return

		If (fileOldCheckSize == logFileSize)
			Return

		fileOldCheckSize := logFileSize

		FileRead, logFileText, % GAME_CLIENT_LOG_PATH
		RegExReplace(logFileText, "(\R)",, logFileLastLine)
		if (logFileLastLine > 0)
		{
			FileReadLine, logFileLine, % GAME_CLIENT_LOG_PATH, logFileLastLine+1
			textPos := InStr(logFileLine, "@")
			if (textPos > 0)
			{
				whisperText := SubStr(logFileLine, textPos+6)
				if (NOTIFICATION_ALL_WHISPERS || IsTradingWhisper(whisperText))
					SendTelegramMessage(whisperText)
			}
		}
		logFileText := "" ;Free memory

		if (logFileSize >= GAME_CLIENT_LOG_LIMIT_SIZE)
		{
			if (GAME_CLIENT_LOG_BACKUP)
			{
				FileGetTime, fileTime, % GAME_CLIENT_LOG_PATH
				newFileName := StrReplace(GAME_CLIENT_LOG_PATH, ".txt", "." . fileTime . ".txt")
				FileCopy, % GAME_CLIENT_LOG_PATH, % newFileName
			}
			SetTimer, LogFileNuke, 1000 ;Give a second for other POE programs
			Return
		}
	}
}

LogFileNuke()
{
	logFile := FileOpen(GAME_CLIENT_LOG_PATH, "w")
	if (ErrorLevel == 0)
	{
		logFile.write()
		logFile.close()
	}
}

SendTelegramMessage(msg)
{
	uriMsg := UriEncode(msg)
	UrlDownloadToFile https://api.telegram.org/bot%TELEGRAM_BOT_TOKEN%/sendmessage?chat_id=%TELEGRAM_CHAT_ROOM_ID%&text=%uriMsg%, _telegram_resp.txt

	FileRead, logFile, %A_ScriptDir%/_telegram_resp.txt
	if (ErrorLevel == 1)
	{
		MsgBox, 4144, % NAME, AHK doesn't work properly...
		ExitApp
	}

	FileDelete, %A_ScriptDir%/_telegram_resp.txt
	if (InStr(logFile, """ok"":false") > 0)
	{
		MsgBox, 4144, % NAME, Failed to send telegram message, Check telegram configs`n`nBOT TOKEN: %TELEGRAM_BOT_TOKEN%`nCHAT ID: %TELEGRAM_CHAT_ROOM_ID%
		TELEGRAM_BOT_TOKEN := -1
		TELEGRAM_CHAT_ROOM_ID := -1
		CheckConfig()
		SendTelegramMessage(msg)
		Return
	}
	logFile := ""
	SendTelegramMessage_CHECK := true
}

CheckConfig()
{
	if (GAME_CLIENT_LOG_PATH == -1)
	{
		InputBox, input, % NAME, Set your Path of Exile Client Log File Path, , 460, 160
		if (ErrorLevel > 0)
			ExitApp
		else
		{
			if !FileExist(input)
			{
				MsgBox, 4144, % NAME, Couldn't find Path of Exile Client Log File:`n%input%
				ExitApp
			}
		}
		IniWrite, %input%, %A_ScriptDir%/config.ini, PathOfExile, GAME_CLIENT_LOG_PATH
		GAME_CLIENT_LOG_PATH := input
	}

	if (GAME_CLIENT_LOG_LIMIT_SIZE == -1 || GAME_CLIENT_LOG_LIMIT_SIZE < 3072000 || GAME_CLIENT_LOG_LIMIT_SIZE > 3072000000)
	{
		InputBox, input, % NAME, Set Path of Exile Client Log File Max Size (Kilobyte)`n`nDefault: 5120 (5 MB)`nMin: 3072 (3 MB)`nMax: 30720 (30 MB), , 460, 200
		if (ErrorLevel > 0)
			ExitApp
		else
		{
			if (input < 3072 || input > 30720)
			{
				MsgBox, 4144, % NAME, You have to set value between 3072 ~ 30720 (3 MB ~ 30 MB)
				CheckConfig()
				Return
			}
		}
		IniWrite, % input*1000, %A_ScriptDir%/config.ini, PathOfExile, GAME_CLIENT_LOG_LIMIT_SIZE
		GAME_CLIENT_LOG_LIMIT_SIZE := input
	}

	if (GAME_CLIENT_LOG_BACKUP == -1)
	{
		InputBox, input, % NAME, Set Path of Exile Client Log File Backup`n`n1 = ENABLE (Rename and Backup the log file when limit size reached)`n0 = DISABLE (Wipe the log file when limit size reached), , 460, 200
		if (ErrorLevel > 0)
			ExitApp
		else
		{
			if (input != 0 && input != 1)
			{
				MsgBox, 4144, % NAME, You have to set 0 or 1 for this config
				CheckConfig()
				Return
			}
		}
		IniWrite, %input%, %A_ScriptDir%/config.ini, PathOfExile, GAME_CLIENT_LOG_BACKUP
		GAME_CLIENT_LOG_BACKUP := input
	}

	if (TELEGRAM_BOT_TOKEN == -1)
	{
		InputBox, input, % NAME, Set your Telegram Bot Token, , 460, 160
		if (ErrorLevel > 0)
			ExitApp
		IniWrite, %input%, %A_ScriptDir%/config.ini, Telegram, TELEGRAM_BOT_TOKEN
		TELEGRAM_BOT_TOKEN := input
	}

	if (TELEGRAM_CHAT_ROOM_ID == -1)
	{
		InputBox, input, % NAME, Set your Telegram Chat Room ID, , 460, 160
		if (ErrorLevel > 0)
			ExitApp
		IniWrite, %input%, %A_ScriptDir%/config.ini, Telegram, TELEGRAM_CHAT_ROOM_ID
		TELEGRAM_CHAT_ROOM_ID := input
	}

	if (NOTIFICATION_ALL_WHISPERS == -1)
	{
		InputBox, input, % NAME, Set notification when you recived whispers`n`n1 = All (Send notification all whispers)`n0 = Trade Only (Send notification only trading whispers), , 460, 200
		if (ErrorLevel > 0)
			ExitApp
		else
		{
			if (input != 0 && input != 1)
			{
				MsgBox, 4144, % NAME, You have to set 0 or 1 for this config
				CheckConfig()
				Return
			}
		}
		IniWrite, %input%, %A_ScriptDir%/config.ini, Config, NOTIFICATION_ALL_WHISPERS
		NOTIFICATION_ALL_WHISPERS := input
	}
}

About()
{
	MsgBox, 4160, % NAME, %VERSION%`n`nby. Lua`nhttps://github.com/Lua-kr/POE-Whisper-Notification
}

CloseApp(ExitReason, ExitCode)
{
	if (SendTelegramMessage_CHECK)
		SendTelegramMessage(NAME . " - Stopped")

	ExitApp
}

; URI encode Function
; https://autohotkey.com/board/topic/75390-ahk-l-unicode-uri-encode-url-encode-function/
UriEncode(Uri, Enc = "UTF-8")
{
	StrPutVar(Uri, Var, Enc)
	f := A_FormatInteger
	SetFormat, IntegerFast, H
	Loop
	{
		Code := NumGet(Var, A_Index - 1, "UChar")
		If (!Code)
			Break
		If (Code >= 0x30 && Code <= 0x39 ; 0-9
			|| Code >= 0x41 && Code <= 0x5A ; A-Z
			|| Code >= 0x61 && Code <= 0x7A) ; a-z
			Res .= Chr(Code)
		Else
			Res .= "%" . SubStr(Code + 0x100, -1)
	}
	SetFormat, IntegerFast, %f%
	Return, Res
}

StrPutVar(Str, ByRef Var, Enc = "")
{
	Len := StrPut(Str, Enc) * (Enc = "UTF-16" || Enc = "CP1200" ? 2 : 1)
	VarSetCapacity(Var, Len, 0)
	Return, StrPut(Str, &Var, Enc)
}

; Function by POE-Trades-Companion
; https://github.com/lemasato/POE-Trades-Companion/blob/dev/lib/Game.ahk
IsTradingWhisper(str) {
	; Make sure it doesnt contain line break
	if (InStr(str, "`n") > 0)
		Return False

	allTradingRegEx := { "currencyPoeTrade": "(.*)Hi, I'd like to buy your (.*) for my (.*) in (.*)"
		, "ggg_FRE": "(.*)Bonjour, je souhaiterais t'acheter (.*) pour (.*) dans la ligue (.*)"
		, "ggg_FRE_currency": "(.*)Bonjour, je voudrais t'acheter (.*) contre (.*) dans la ligue (.*)"
		, "ggg_FRE_unpriced": "(.*)Bonjour, je souhaiterais t'acheter (.*) dans la ligue (.*)"
		, "ggg_GER": "(.*)Hi, ich möchte '(.*)' zum angebotenen Preis von (.*) in der '(.*)'-Liga kaufen(.*)"
		, "ggg_GER_currency": "(.*)Hi, ich möchte '(.*)' zum angebotenen Preis von '(.*)' in der '(.*)'-Liga kaufen(.*)"
		, "ggg_GER_unpriced": "(.*)Hi, ich möchte '(.*)' in der '(.*)'-Liga kaufen(.*)"
		, "ggg_KOR": "(.*)안녕하세요, (.*)에 (.*)\(으\)로 올려놓은 (.*)\(을\)를 구매하고 싶습니다(.*)"
		, "ggg_KOR_currency": "(.*)안녕하세요, (.*)에 올려놓은(.*)\(을\)를 제 (.*)\(으\)로 구매하고 싶습니다(.*)"
		, "ggg_KOR_unpriced": "(.*)안녕하세요, (.*)에 올려놓은 (.*)\(을\)를 구매하고 싶습니다(.*)"
		, "ggg_POR": "(.*)Olá, eu gostaria de comprar o seu item (.*) listado por (.*) na (.*)"
		, "ggg_POR_currency": "(.*)Olá, eu gostaria de comprar seu\(s\) (.*) pelo\(s\) meu\(s\) (.*) na (.*)"
		, "ggg_POR_unpriced": "(.*)Olá, eu gostaria de comprar o seu item (.*) na (.*)"
		, "ggg_RUS": "(.*)Здравствуйте, хочу купить у вас (.*) за (.*) в лиге (.*)"
		, "ggg_RUS_currency": "(.*)Здравствуйте, хочу купить у вас (.*) за (.*) в лиге (.*)"
		, "ggg_RUS_unpriced": "(.*)Здравствуйте, хочу купить у вас (.*) в лиге (.*)"
		, "ggg_SPA": "(.*)Hola, quisiera comprar tu (.*) listado por (.*) en (.*)"
		, "ggg_SPA_currency": "(.*)Hola, me gustaría comprar tu\(s\) (.*) por mi (.*) en (.*)"
		, "ggg_SPA_unpriced": "(.*)Hola, quisiera comprar tu (.*) en (.*)"
		, "ggg_THA": "(.*)สวัสดี, เราต้องการจะชื้อของคุณ (.*) ใน ราคา (.*) ใน (.*)"
		, "ggg_THA_currency": "(.*)สวัสดี เรามีความต้องการจะชื้อ (.*) ของคุณ ฉันมี (.*) ใน (.*)"
		, "ggg_THA_unpriced": "(.*)สวัสดี, เราต้องการจะชื้อของคุณ (.*) ใน (.*)"
		, "ggg_TWN": "(.*)你好，我想購買 (.*) 標價 (.*) 在 (.*)"
		, "ggg_TWN_currency": "(.*)你好，我想用 (.*) 購買 (.*) in (.*)"
		, "ggg_TWN_unpriced": "(.*)你好，我想購買 (.*) 在 (.*)"
		, "poeApp": "(.*)wtb (.*) listed for (.*) in (.*)"
		, "poeApp_Currency": "(.*)I'd like to buy your (.*) for my (.*) in (.*)"
		, "poeApp_Unpriced": "(.*)wtb (.*) in (.*)"
		, "poeDb_TWN": "(.*)您好，我想買在 (.*) 的 (.*) 價格 (.*)"
		, "poeDb_TWN_currency": "(.*)您好，我想買在 (.*) 的 (.*) 個 (.*) 直購價 (.*)"
		, "poeDb_TWN_unpriced": "(.*)您好，我想買在 (.*) 的 (.*)"
		, "poeTrade": "(.*)Hi, I would like to buy your (.*) listed for (.*) in (.*)"
		, "poeTrade_Unpriced": "(.*)Hi, I would like to buy your (.*) in (.*)" }	

	; Check if trading whisper
	for regexName in allTradingRegEx { ; compare whisper with regex
		if (allTradingRegEx[regexName]) && RegExMatch(str, "iS)" allTradingRegEx[regexName]) { ; Trading whisper detected
			Return True
		}
	}

	Return False
}