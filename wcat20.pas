type
  More_Prompt_Type = (Erase_Prompt, Next_Line);
  Expertise_Level = (xpNovice, xpRegular, xpExpert);
  Transfer_Type  = (All, Xmodem, XmodemCRC, Ymodem, YmodemG, Xmodem1K,
                    Xmodem1KG, ASCii, ExtBatch, Ext1, Ext2, Ext3, Ext4, Ext5, Ext6, Ext7, Ext8,
                    Ext9, Ext10);
  Time = LongInt; { Numbers of Seconds since midnight }
  Date = LongInt; { Number of days since 1/1/1600 }
  wDateTimeRec = Record  { Record which holds a date/time value }
                  D : Date;
                  T : Time;
                end;
  Password_Type  = (NotReq, YesReq, Protect);


  wcat_userrec =
  record
    Status         : LongInt;               { Btree Status }
    UserName       : String[37];              { Users name }
    CallingFrom    : String[30];                { location }
    Password       : String[14];                { Password }
    PhoneNumber    : String[12];       { User phone number }
    ComputerType   : String[15];     { Users Computer Type }
    ConfJoined     : String[26];            { Open Folders }
    MorePrompt     : More_Prompt_Type;      { Erase -MORE- }
    Xpert          : Expertise_Level;        { Xpert level }
    TransferMethod : Transfer_Type;             { Protocol }
    HighMsg        : array['A'..'Z'] of Word; { Last read each folder }
    LinesPerPage   : Byte;               { Lines Per Page  }
    LastNew,                       { Last New Files Search }
    TimeDate       : wDateTimeRec;       { Last time called }
    MemoDate,                           { Extra Date Field }
    UserSince,                         { Date First Called }
    BirthDate      : Date;               { Users Birth Day }
    SecurityLevel,                        { Security level }
    Uploads,                            { Number of ULoads }
    Downloads,                          { Number of DLoads }
    TimesOn,                             { Number times on }
    TimeLeft       : Word;               { Time left today }
    DailyDL,       { temp counter for daily download count }
    DailyDK,              { temp counter for daily K-bytes }
    TotalUK,                            { Total K uploaded }
    TotalDK        : LongInt;           { Total K downlded }
    ChatPage,                                 { Ok to Page }
    HotKey,                                 { Use Hot Keys }
    LockedOut,                             { allowed user? }
    ColorMenus     : Boolean;           { type of graphics }
  end;

  wcat_ulfrec =
  record                                    { FILESPEC.DAT }
    Status         : LongInt;              { B-Tree Status }
    FileName       : String[12];        { Name of the file }
    Password       : String[14];        { 12 Byte password }
    FileDate,                           { Date of the file }
    LastAccessed   : wDateTimeRec;    { Date of last access }
    Desc           : array[1..2] of String[40]; { Description }
    UploadedBy     : String[37];         { Who uploaded by }
    Area           : Char;   { file Area it is assigned to }
    NumOfAccess,                     { Number of downloads }
    Size           : LongInt;           { Size of the File }
    PasswordReq    : Password_Type; { Is a password required }
  end;                                    { Size 178 Bytes }

