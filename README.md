# POE-Whisper-Notification
Path of Exile Whisper Notification

Currently supports Telegram only

- [Require AutoHotKey to Run .ahk or Compile](https://autohotkey.com/download/)
#### ICON @ Grinding Gear Games Ltd. Rights reserved.




## Config
```
[PathOfExile]
; Set your Path of Exile Client Log File Path
GAME_CLIENT_LOG_PATH			=	

; Set Path of Exile Client Log Max File Size (Bytes)
; Default: 5120000 (5 MB)
; Min: 3072000 (3 MB)
; Max: 30720000 (30 MB)
GAME_CLIENT_LOG_LIMIT_SIZE		=	

; Set Path of Exile Client Log File Backup
; 1 = Enable (Rename and Backup the log file when limit size reached)
; 0 = Disable (Wipe the log file when limit size reached)
; To Reduce Memory Use of Program
GAME_CLIENT_LOG_BACKUP			=	

[Telegram]
; Set your Telegram Bot Token
TELEGRAM_BOT_TOKEN				=	

; Set your Telegram Chat Room ID
TELEGRAM_CHAT_ROOM_ID			=	

[Config]
; Set notification when you recived whispers
; 1 = All (Send notification all whispers)
; 0 = Trade Only (Send notification only trading whispers)
NOTIFICATION_ALL_WHISPERS		=	

; Set notification when you recived whispers while AFK Mode is ON
; 1 = Enable
; 0 = Disable
NOTIFICATION_AFK_ONLY			=	
```
