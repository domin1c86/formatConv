#define MyAppName "FormatConv"
#define MyAppVersion GetEnv("APP_VERSION")
#define MyAppPublisher "domin1c86"
#define MyAppExeName "format_conv.exe"
#define SourceDir GetEnv("FORMATCONV_RELEASE_DIR")
#define DistDir GetEnv("FORMATCONV_DIST_DIR")

[Setup]
AppId={{8A1AF5B1-75D2-4C35-9BA0-FD4A2F7C7D01}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
OutputDir={#DistDir}
OutputBaseFilename=FormatConv_Setup_{#MyAppVersion}_x64
SetupIconFile=D:\Coding\formatConv\apps\windows\runner\resources\app_icon.ico
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
UninstallDisplayIcon={app}\{#MyAppExeName}
PrivilegesRequired=admin

[Languages]
Name: "chinesesimp"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "创建桌面快捷方式"; GroupDescription: "附加任务："; Flags: unchecked

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "启动 {#MyAppName}"; Flags: nowait postinstall skipifsilent