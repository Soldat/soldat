unit Steam;


interface
uses
  cmem, sysutils, ctypes, SteamTypes, GameNetworkingSockets;

const
  {$IFDEF WINDOWS}
  STEAMLIB = 'steam_api.dll';
  {$ENDIF}
  {$IFDEF DARWIN}
  STEAMLIB = 'libsteam_api.dylib';
  {$ENDIF}
  {$IFDEF LINUX}
  STEAMLIB = 'libsteam_api.so';
  {$ENDIF}

  STEAM_APPID = 638490;

function SteamAPI_Init(): Boolean; cdecl; external STEAMLIB;
procedure SteamAPI_Shutdown(); cdecl; external STEAMLIB;
function SteamAPI_GetHSteamPipe(): HSteamPipe; cdecl; external STEAMLIB;
function SteamGameServer_GetHSteamPipe(): HSteamPipe; cdecl; external STEAMLIB;

procedure SteamAPI_RegisterCallback(pCallback: Pointer; iCallback: Integer); cdecl; external STEAMLIB;
procedure SteamAPI_RegisterCallResult(pCallback: Pointer; hAPICall: uint64); cdecl; external STEAMLIB;

procedure SteamAPI_UnregisterCallback(pCallback: Pointer); cdecl; external STEAMLIB;
procedure SteamAPI_UnregisterCallResult(pCallback: Pointer; hAPICall: uint64); cdecl; external STEAMLIB;

procedure SteamAPI_RunCallbacks(); cdecl; external STEAMLIB;
procedure SteamGameServer_Shutdown(instancePtr: Pointer); cdecl; external STEAMLIB;
procedure SteamGameServer_RunCallbacks(instancePtr: Pointer); cdecl; external STEAMLIB;

procedure SteamAPI_ManualDispatch_Init(); cdecl; external STEAMLIB;

/// Perform certain periodic actions that need to be performed.
procedure SteamAPI_ManualDispatch_RunFrame(hSteamPipe: HSteamPipe); cdecl; external STEAMLIB;

/// Fetch the next pending callback on the given pipe, if any.  If a callback is available, true is returned
/// and the structure is populated.  In this case, you MUST call SteamAPI_ManualDispatch_FreeLastCallback
/// (after dispatching the callback) before calling SteamAPI_ManualDispatch_GetNextCallback again.
function SteamAPI_ManualDispatch_GetNextCallback(hSteamPipe: HSteamPipe; pCallbackMsg: PCallbackMsg_t): Boolean; cdecl; external STEAMLIB;

/// You must call this after dispatching the callback, if SteamAPI_ManualDispatch_GetNextCallback returns true.
procedure SteamAPI_ManualDispatch_FreeLastCallback(hSteamPipe: HSteamPipe); cdecl; external STEAMLIB;

/// Return the call result for the specified call on the specified pipe.  You really should
/// only call this in a handler for SteamAPICallCompleted_t callback.
function SteamAPI_ManualDispatch_GetAPICallResult(hSteamPipe: HSteamPipe; hSteamAPICall: SteamAPICall_t; pCallback: Pointer; cubCallback: Integer; iCallbackExpected: Integer; pbFailed: PBoolean): Boolean; cdecl; external STEAMLIB;



function SteamInternal_CreateInterface(ver: PChar): Pointer; cdecl; external STEAMLIB;
//function SteamAPI_ISteamClient_ConnectToGlobalUser(instancePtr: Pointer; hSteamPipe: HSteamPipe): longint; cdecl; external STEAMLIB;
//function SteamAPI_ISteamClient_GetISteamGameServer(instancePtr: Pointer; hSteamUser: HSteamUser; hSteamPipe: HSteamPipe; pchVersion: PChar): ISteamFriends; cdecl; external STEAMLIB;
//function SteamAPI_ISteamClient_GetISteamUser(instancePtr: Pointer; hSteamUser: HSteamUser; hSteamPipe: HSteamPipe; pchVersion: PChar): ISteamFriends; cdecl; external STEAMLIB;
function SteamInternal_FindOrCreateGameServerInterface(hSteamUser: HSteamUser; ver: PChar): Pointer; cdecl; external STEAMLIB;
function SteamInternal_FindOrCreateUserInterface(user: HSteamUser; pszVersion: PChar): Pointer; cdecl; external STEAMLIB;

function SteamInternal_GameServer_Init(unIP: uint32; usSteamPort: uint16; usGamePort: uint16; usQueryPort: uint16; ServerMode: EServerMode; pchVersionString: PChar): Boolean; cdecl; external STEAMLIB;


function SteamAPI_ISteamClient_CreateSteamPipe(SteamInterface: ISteamClient): HSteamPipe; cdecl; external STEAMLIB;
function SteamAPI_ISteamClient_BReleaseSteamPipe(SteamInterface: ISteamClient; hSteamPipe: HSteamPipe): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamClient_ConnectToGlobalUser(SteamInterface: ISteamClient; hSteamPipe: HSteamPipe): HSteamUser; cdecl; external STEAMLIB;
function SteamAPI_ISteamClient_CreateLocalUser(SteamInterface: ISteamClient; phSteamPipe: pint32; eAccountType: EAccountType): HSteamUser; cdecl; external STEAMLIB;
procedure SteamAPI_ISteamClient_ReleaseUser(SteamInterface: ISteamClient; hSteamPipe: HSteamPipe; hUser: HSteamUser); cdecl; external STEAMLIB;
function SteamAPI_ISteamClient_GetISteamUser(SteamInterface: ISteamClient; hSteamUser: HSteamUser; hSteamPipe: HSteamPipe; pchVersion: PChar): ISteamUser; cdecl; external STEAMLIB;
function SteamAPI_ISteamClient_GetISteamGameServer(SteamInterface: ISteamClient; hSteamUser: HSteamUser; hSteamPipe: HSteamPipe; pchVersion: PChar): ISteamGameServer; cdecl; external STEAMLIB;
procedure SteamAPI_ISteamClient_SetLocalIPBinding(SteamInterface: ISteamClient; unIP: PSteamIPAddress_t; usPort: uint16); cdecl; external STEAMLIB;
function SteamAPI_ISteamClient_GetISteamFriends(SteamInterface: ISteamClient; hSteamUser: HSteamUser; hSteamPipe: HSteamPipe; pchVersion: PChar): ISteamFriends; cdecl; external STEAMLIB;
function SteamAPI_ISteamClient_GetISteamUtils(SteamInterface: ISteamClient; hSteamPipe: HSteamPipe; pchVersion: PChar): ISteamUtils; cdecl; external STEAMLIB;
function SteamAPI_ISteamClient_GetISteamMatchmaking(SteamInterface: ISteamClient; hSteamUser: HSteamUser; hSteamPipe: HSteamPipe; pchVersion: PChar): ISteamMatchmaking; cdecl; external STEAMLIB;
function SteamAPI_ISteamClient_GetISteamMatchmakingServers(SteamInterface: ISteamClient; hSteamUser: HSteamUser; hSteamPipe: HSteamPipe; pchVersion: PChar): ISteamMatchmakingServers; cdecl; external STEAMLIB;
function SteamAPI_ISteamClient_GetISteamGenericInterface(SteamInterface: ISteamClient; hSteamUser: HSteamUser; hSteamPipe: HSteamPipe; pchVersion: PChar): Pointer; cdecl; external STEAMLIB;
function SteamAPI_ISteamClient_GetISteamUserStats(SteamInterface: ISteamClient; hSteamUser: HSteamUser; hSteamPipe: HSteamPipe; pchVersion: PChar): ISteamUserStats; cdecl; external STEAMLIB;
function SteamAPI_ISteamClient_GetISteamGameServerStats(SteamInterface: ISteamClient; hSteamuser: HSteamUser; hSteamPipe: HSteamPipe; pchVersion: PChar): ISteamGameServerStats; cdecl; external STEAMLIB;
function SteamAPI_ISteamClient_GetISteamApps(SteamInterface: ISteamClient; hSteamUser: HSteamUser; hSteamPipe: HSteamPipe; pchVersion: PChar): ISteamApps; cdecl; external STEAMLIB;
function SteamAPI_ISteamClient_GetISteamNetworking(SteamInterface: ISteamClient; hSteamUser: HSteamUser; hSteamPipe: HSteamPipe; pchVersion: PChar): ISteamNetworking; cdecl; external STEAMLIB;
function SteamAPI_ISteamClient_GetISteamRemoteStorage(SteamInterface: ISteamClient; hSteamuser: HSteamUser; hSteamPipe: HSteamPipe; pchVersion: PChar): ISteamRemoteStorage; cdecl; external STEAMLIB;
function SteamAPI_ISteamClient_GetISteamScreenshots(SteamInterface: ISteamClient; hSteamuser: HSteamUser; hSteamPipe: HSteamPipe; pchVersion: PChar): ISteamScreenshots; cdecl; external STEAMLIB;
function SteamAPI_ISteamClient_GetISteamGameSearch(SteamInterface: ISteamClient; hSteamuser: HSteamUser; hSteamPipe: HSteamPipe; pchVersion: PChar): ISteamGameSearch; cdecl; external STEAMLIB;
function SteamAPI_ISteamClient_GetIPCCallCount(SteamInterface: ISteamClient): uint32; cdecl; external STEAMLIB;
procedure SteamAPI_ISteamClient_SetWarningMessageHook(SteamInterface: ISteamClient; pFunction: Pointer); cdecl; external STEAMLIB;
function SteamAPI_ISteamClient_BShutdownIfAllPipesClosed(SteamInterface: ISteamClient): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamClient_GetISteamHTTP(SteamInterface: ISteamClient; hSteamuser: HSteamUser; hSteamPipe: HSteamPipe; pchVersion: PChar): ISteamHTTP; cdecl; external STEAMLIB;
function SteamAPI_ISteamClient_GetISteamController(SteamInterface: ISteamClient; hSteamUser: HSteamUser; hSteamPipe: HSteamPipe; pchVersion: PChar): ISteamController; cdecl; external STEAMLIB;
function SteamAPI_ISteamClient_GetISteamUGC(SteamInterface: ISteamClient; hSteamUser: HSteamUser; hSteamPipe: HSteamPipe; pchVersion: PChar): ISteamUGC; cdecl; external STEAMLIB;
function SteamAPI_ISteamClient_GetISteamAppList(SteamInterface: ISteamClient; hSteamUser: HSteamUser; hSteamPipe: HSteamPipe; pchVersion: PChar): ISteamAppList; cdecl; external STEAMLIB;
function SteamAPI_ISteamClient_GetISteamMusic(SteamInterface: ISteamClient; hSteamuser: HSteamUser; hSteamPipe: HSteamPipe; pchVersion: PChar): ISteamMusic; cdecl; external STEAMLIB;
function SteamAPI_ISteamClient_GetISteamMusicRemote(SteamInterface: ISteamClient; hSteamuser: HSteamUser; hSteamPipe: HSteamPipe; pchVersion: PChar): ISteamMusicRemote; cdecl; external STEAMLIB;
function SteamAPI_ISteamClient_GetISteamHTMLSurface(SteamInterface: ISteamClient; hSteamuser: HSteamUser; hSteamPipe: HSteamPipe; pchVersion: PChar): ISteamHTMLSurface; cdecl; external STEAMLIB;
function SteamAPI_ISteamClient_GetISteamInventory(SteamInterface: ISteamClient; hSteamuser: HSteamUser; hSteamPipe: HSteamPipe; pchVersion: PChar): ISteamInventory; cdecl; external STEAMLIB;
function SteamAPI_ISteamClient_GetISteamVideo(SteamInterface: ISteamClient; hSteamuser: HSteamUser; hSteamPipe: HSteamPipe; pchVersion: PChar): ISteamVideo; cdecl; external STEAMLIB;
function SteamAPI_ISteamClient_GetISteamParentalSettings(SteamInterface: ISteamClient; hSteamuser: HSteamUser; hSteamPipe: HSteamPipe; pchVersion: PChar): ISteamParentalSettings; cdecl; external STEAMLIB;
function SteamAPI_ISteamClient_GetISteamInput(SteamInterface: ISteamClient; hSteamUser: HSteamUser; hSteamPipe: HSteamPipe; pchVersion: PChar): ISteamInput; cdecl; external STEAMLIB;
function SteamAPI_ISteamClient_GetISteamParties(SteamInterface: ISteamClient; hSteamUser: HSteamUser; hSteamPipe: HSteamPipe; pchVersion: PChar): ISteamParties; cdecl; external STEAMLIB;
function SteamAPI_ISteamClient_GetISteamRemotePlay(SteamInterface: ISteamClient; hSteamUser: HSteamUser; hSteamPipe: HSteamPipe; pchVersion: PChar): ISteamRemotePlay; cdecl; external STEAMLIB;


function SteamAPI_SteamUser_v021(): ISteamUser; cdecl; external STEAMLIB;

function SteamAPI_ISteamUser_GetHSteamUser(SteamInterface: ISteamUser): HSteamUser; cdecl; external STEAMLIB;
function SteamAPI_ISteamUser_BLoggedOn(SteamInterface: ISteamUser): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUser_GetSteamID(SteamInterface: ISteamUser): TSteamID; cdecl; external STEAMLIB;
function SteamAPI_ISteamUser_InitiateGameConnection(SteamInterface: ISteamUser; pAuthBlob: Pointer; cbMaxAuthBlob: Longint; steamIDGameServer: TSteamID; unIPServer: uint32; usPortServer: uint16; bSecure: Boolean): Longint; cdecl; external STEAMLIB;
procedure SteamAPI_ISteamUser_TerminateGameConnection(SteamInterface: ISteamUser; unIPServer: uint32; usPortServer: uint16); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamUser_TrackAppUsageEvent(SteamInterface: ISteamUser; gameID: uint64_gameid; eAppUsageEvent: Longint; pchExtraInfo: PChar); cdecl; external STEAMLIB;
function SteamAPI_ISteamUser_GetUserDataFolder(SteamInterface: ISteamUser; pchBuffer: PChar; cubBuffer: Longint): Boolean; cdecl; external STEAMLIB;
procedure SteamAPI_ISteamUser_StartVoiceRecording(SteamInterface: ISteamUser); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamUser_StopVoiceRecording(SteamInterface: ISteamUser); cdecl; external STEAMLIB;
function SteamAPI_ISteamUser_GetAvailableVoice(SteamInterface: ISteamUser; pcbCompressed: puint32; pcbUncompressed_Deprecated: puint32; nUncompressedVoiceDesiredSampleRate_Deprecated: uint32): EVoiceResult; cdecl; external STEAMLIB;
function SteamAPI_ISteamUser_GetVoice(SteamInterface: ISteamUser; bWantCompressed: Boolean; pDestBuffer: Pointer; cbDestBufferSize: uint32; nBytesWritten: puint32; bWantUncompressed_Deprecated: Boolean; pUncompressedDestBuffer_Deprecated: Pointer; cbUncompressedDestBufferSize_Deprecated: uint32; nUncompressBytesWritten_Deprecated: puint32; nUncompressedVoiceDesiredSampleRate_Deprecated: uint32): EVoiceResult; cdecl; external STEAMLIB;
function SteamAPI_ISteamUser_DecompressVoice(SteamInterface: ISteamUser; pCompressed: Pointer; cbCompressed: uint32; pDestBuffer: Pointer; cbDestBufferSize: uint32; nBytesWritten: puint32; nDesiredSampleRate: uint32): EVoiceResult; cdecl; external STEAMLIB;
function SteamAPI_ISteamUser_GetVoiceOptimalSampleRate(SteamInterface: ISteamUser): uint32; cdecl; external STEAMLIB;
function SteamAPI_ISteamUser_GetAuthSessionTicket(SteamInterface: ISteamUser; pTicket: Pointer; cbMaxTicket: Longint; pcbTicket: puint32): HAuthTicket; cdecl; external STEAMLIB;
function SteamAPI_ISteamUser_BeginAuthSession(SteamInterface: ISteamUser; pAuthTicket: Pointer; cbAuthTicket: Longint; steamID: TSteamID): EBeginAuthSessionResult; cdecl; external STEAMLIB;
procedure SteamAPI_ISteamUser_EndAuthSession(SteamInterface: ISteamUser; steamID: TSteamID); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamUser_CancelAuthTicket(SteamInterface: ISteamUser; hAuthTicket: HAuthTicket); cdecl; external STEAMLIB;
function SteamAPI_ISteamUser_UserHasLicenseForApp(SteamInterface: ISteamUser; steamID: TSteamID; appID: AppId_t): EUserHasLicenseForAppResult; cdecl; external STEAMLIB;
function SteamAPI_ISteamUser_BIsBehindNAT(SteamInterface: ISteamUser): Boolean; cdecl; external STEAMLIB;
procedure SteamAPI_ISteamUser_AdvertiseGame(SteamInterface: ISteamUser; steamIDGameServer: TSteamID; unIPServer: uint32; usPortServer: uint16); cdecl; external STEAMLIB;
function SteamAPI_ISteamUser_RequestEncryptedAppTicket(SteamInterface: ISteamUser; pDataToInclude: Pointer; cbDataToInclude: Longint): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamUser_GetEncryptedAppTicket(SteamInterface: ISteamUser; pTicket: Pointer; cbMaxTicket: Longint; pcbTicket: puint32): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUser_GetGameBadgeLevel(SteamInterface: ISteamUser; nSeries: Longint; bFoil: Boolean): Longint; cdecl; external STEAMLIB;
function SteamAPI_ISteamUser_GetPlayerSteamLevel(SteamInterface: ISteamUser): Longint; cdecl; external STEAMLIB;
function SteamAPI_ISteamUser_RequestStoreAuthURL(SteamInterface: ISteamUser; pchRedirectURL: PChar): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamUser_BIsPhoneVerified(SteamInterface: ISteamUser): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUser_BIsTwoFactorEnabled(SteamInterface: ISteamUser): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUser_BIsPhoneIdentifying(SteamInterface: ISteamUser): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUser_BIsPhoneRequiringVerification(SteamInterface: ISteamUser): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUser_GetMarketEligibility(SteamInterface: ISteamUser): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamUser_GetDurationControl(SteamInterface: ISteamUser): SteamAPICall_t; cdecl; external STEAMLIB;


function SteamAPI_SteamFriends_v017(): ISteamFriends; cdecl; external STEAMLIB;

function SteamAPI_ISteamFriends_GetPersonaName(SteamInterface: ISteamFriends): PChar; cdecl; external STEAMLIB;
function SteamAPI_ISteamFriends_SetPersonaName(SteamInterface: ISteamFriends; pchPersonaName: PChar): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamFriends_GetPersonaState(SteamInterface: ISteamFriends): EPersonaState; cdecl; external STEAMLIB;
function SteamAPI_ISteamFriends_GetFriendCount(SteamInterface: ISteamFriends; iFriendFlags: Longint): Longint; cdecl; external STEAMLIB;
function SteamAPI_ISteamFriends_GetFriendByIndex(SteamInterface: ISteamFriends; iFriend: Longint; iFriendFlags: Longint): TSteamID; cdecl; external STEAMLIB;
function SteamAPI_ISteamFriends_GetFriendRelationship(SteamInterface: ISteamFriends; steamIDFriend: TSteamID): EFriendRelationship; cdecl; external STEAMLIB;
function SteamAPI_ISteamFriends_GetFriendPersonaState(SteamInterface: ISteamFriends; steamIDFriend: TSteamID): EPersonaState; cdecl; external STEAMLIB;
function SteamAPI_ISteamFriends_GetFriendPersonaName(SteamInterface: ISteamFriends; steamIDFriend: TSteamID): PChar; cdecl; external STEAMLIB;
function SteamAPI_ISteamFriends_GetFriendGamePlayed(SteamInterface: ISteamFriends; steamIDFriend: TSteamID; pFriendGameInfo: pFriendGameInfo_t): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamFriends_GetFriendPersonaNameHistory(SteamInterface: ISteamFriends; steamIDFriend: TSteamID; iPersonaName: Longint): PChar; cdecl; external STEAMLIB;
function SteamAPI_ISteamFriends_GetFriendSteamLevel(SteamInterface: ISteamFriends; steamIDFriend: TSteamID): Longint; cdecl; external STEAMLIB;
function SteamAPI_ISteamFriends_GetPlayerNickname(SteamInterface: ISteamFriends; steamIDPlayer: TSteamID): PChar; cdecl; external STEAMLIB;
function SteamAPI_ISteamFriends_GetFriendsGroupCount(SteamInterface: ISteamFriends): Longint; cdecl; external STEAMLIB;
function SteamAPI_ISteamFriends_GetFriendsGroupIDByIndex(SteamInterface: ISteamFriends; iFG: Longint): FriendsGroupID_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamFriends_GetFriendsGroupName(SteamInterface: ISteamFriends; friendsGroupID: FriendsGroupID_t): PChar; cdecl; external STEAMLIB;
function SteamAPI_ISteamFriends_GetFriendsGroupMembersCount(SteamInterface: ISteamFriends; friendsGroupID: FriendsGroupID_t): Longint; cdecl; external STEAMLIB;
procedure SteamAPI_ISteamFriends_GetFriendsGroupMembersList(SteamInterface: ISteamFriends; friendsGroupID: FriendsGroupID_t; pOutSteamIDMembers: PSteamID; nMembersCount: Longint); cdecl; external STEAMLIB;
function SteamAPI_ISteamFriends_HasFriend(SteamInterface: ISteamFriends; steamIDFriend: TSteamID; iFriendFlags: Longint): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamFriends_GetClanCount(SteamInterface: ISteamFriends): Longint; cdecl; external STEAMLIB;
function SteamAPI_ISteamFriends_GetClanByIndex(SteamInterface: ISteamFriends; iClan: Longint): TSteamID; cdecl; external STEAMLIB;
function SteamAPI_ISteamFriends_GetClanName(SteamInterface: ISteamFriends; steamIDClan: TSteamID): PChar; cdecl; external STEAMLIB;
function SteamAPI_ISteamFriends_GetClanTag(SteamInterface: ISteamFriends; steamIDClan: TSteamID): PChar; cdecl; external STEAMLIB;
function SteamAPI_ISteamFriends_GetClanActivityCounts(SteamInterface: ISteamFriends; steamIDClan: TSteamID; pnOnline: PInteger; pnInGame: PInteger; pnChatting: PInteger): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamFriends_DownloadClanActivityCounts(SteamInterface: ISteamFriends; psteamIDClans: PSteamID; cClansToRequest: Longint): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamFriends_GetFriendCountFromSource(SteamInterface: ISteamFriends; steamIDSource: TSteamID): Longint; cdecl; external STEAMLIB;
function SteamAPI_ISteamFriends_GetFriendFromSourceByIndex(SteamInterface: ISteamFriends; steamIDSource: TSteamID; iFriend: Longint): TSteamID; cdecl; external STEAMLIB;
function SteamAPI_ISteamFriends_IsUserInSource(SteamInterface: ISteamFriends; steamIDUser: TSteamID; steamIDSource: TSteamID): Boolean; cdecl; external STEAMLIB;
procedure SteamAPI_ISteamFriends_SetInGameVoiceSpeaking(SteamInterface: ISteamFriends; steamIDUser: TSteamID; bSpeaking: Boolean); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamFriends_ActivateGameOverlay(SteamInterface: ISteamFriends; pchDialog: PChar); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamFriends_ActivateGameOverlayToUser(SteamInterface: ISteamFriends; pchDialog: PChar; steamID: TSteamID); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamFriends_ActivateGameOverlayToWebPage(SteamInterface: ISteamFriends; pchURL: PChar; eMode: EActivateGameOverlayToWebPageMode); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamFriends_ActivateGameOverlayToStore(SteamInterface: ISteamFriends; nAppID: AppId_t; eFlag: EOverlayToStoreFlag); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamFriends_SetPlayedWith(SteamInterface: ISteamFriends; steamIDUserPlayedWith: TSteamID); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamFriends_ActivateGameOverlayInviteDialog(SteamInterface: ISteamFriends; steamIDLobby: TSteamID); cdecl; external STEAMLIB;
function SteamAPI_ISteamFriends_GetSmallFriendAvatar(SteamInterface: ISteamFriends; steamIDFriend: TSteamID): Longint; cdecl; external STEAMLIB;
function SteamAPI_ISteamFriends_GetMediumFriendAvatar(SteamInterface: ISteamFriends; steamIDFriend: TSteamID): Longint; cdecl; external STEAMLIB;
function SteamAPI_ISteamFriends_GetLargeFriendAvatar(SteamInterface: ISteamFriends; steamIDFriend: TSteamID): Longint; cdecl; external STEAMLIB;
function SteamAPI_ISteamFriends_RequestUserInformation(SteamInterface: ISteamFriends; steamIDUser: TSteamID; bRequireNameOnly: Boolean): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamFriends_RequestClanOfficerList(SteamInterface: ISteamFriends; steamIDClan: TSteamID): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamFriends_GetClanOwner(SteamInterface: ISteamFriends; steamIDClan: TSteamID): TSteamID; cdecl; external STEAMLIB;
function SteamAPI_ISteamFriends_GetClanOfficerCount(SteamInterface: ISteamFriends; steamIDClan: TSteamID): Longint; cdecl; external STEAMLIB;
function SteamAPI_ISteamFriends_GetClanOfficerByIndex(SteamInterface: ISteamFriends; steamIDClan: TSteamID; iOfficer: Longint): TSteamID; cdecl; external STEAMLIB;
function SteamAPI_ISteamFriends_GetUserRestrictions(SteamInterface: ISteamFriends): uint32; cdecl; external STEAMLIB;
function SteamAPI_ISteamFriends_SetRichPresence(SteamInterface: ISteamFriends; pchKey: PChar; pchValue: PChar): Boolean; cdecl; external STEAMLIB;
procedure SteamAPI_ISteamFriends_ClearRichPresence(SteamInterface: ISteamFriends); cdecl; external STEAMLIB;
function SteamAPI_ISteamFriends_GetFriendRichPresence(SteamInterface: ISteamFriends; steamIDFriend: TSteamID; pchKey: PChar): PChar; cdecl; external STEAMLIB;
function SteamAPI_ISteamFriends_GetFriendRichPresenceKeyCount(SteamInterface: ISteamFriends; steamIDFriend: TSteamID): Longint; cdecl; external STEAMLIB;
function SteamAPI_ISteamFriends_GetFriendRichPresenceKeyByIndex(SteamInterface: ISteamFriends; steamIDFriend: TSteamID; iKey: Longint): PChar; cdecl; external STEAMLIB;
procedure SteamAPI_ISteamFriends_RequestFriendRichPresence(SteamInterface: ISteamFriends; steamIDFriend: TSteamID); cdecl; external STEAMLIB;
function SteamAPI_ISteamFriends_InviteUserToGame(SteamInterface: ISteamFriends; steamIDFriend: TSteamID; pchConnectString: PChar): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamFriends_GetCoplayFriendCount(SteamInterface: ISteamFriends): Longint; cdecl; external STEAMLIB;
function SteamAPI_ISteamFriends_GetCoplayFriend(SteamInterface: ISteamFriends; iCoplayFriend: Longint): TSteamID; cdecl; external STEAMLIB;
function SteamAPI_ISteamFriends_GetFriendCoplayTime(SteamInterface: ISteamFriends; steamIDFriend: TSteamID): Longint; cdecl; external STEAMLIB;
function SteamAPI_ISteamFriends_GetFriendCoplayGame(SteamInterface: ISteamFriends; steamIDFriend: TSteamID): AppId_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamFriends_JoinClanChatRoom(SteamInterface: ISteamFriends; steamIDClan: TSteamID): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamFriends_LeaveClanChatRoom(SteamInterface: ISteamFriends; steamIDClan: TSteamID): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamFriends_GetClanChatMemberCount(SteamInterface: ISteamFriends; steamIDClan: TSteamID): Longint; cdecl; external STEAMLIB;
function SteamAPI_ISteamFriends_GetChatMemberByIndex(SteamInterface: ISteamFriends; steamIDClan: TSteamID; iUser: Longint): TSteamID; cdecl; external STEAMLIB;
function SteamAPI_ISteamFriends_SendClanChatMessage(SteamInterface: ISteamFriends; steamIDClanChat: TSteamID; pchText: PChar): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamFriends_GetClanChatMessage(SteamInterface: ISteamFriends; steamIDClanChat: TSteamID; iMessage: Longint; prgchText: Pointer; cchTextMax: Longint; peChatEntryType: EChatEntryType; psteamidChatter: PSteamID): Longint; cdecl; external STEAMLIB;
function SteamAPI_ISteamFriends_IsClanChatAdmin(SteamInterface: ISteamFriends; steamIDClanChat: TSteamID; steamIDUser: TSteamID): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamFriends_IsClanChatWindowOpenInSteam(SteamInterface: ISteamFriends; steamIDClanChat: TSteamID): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamFriends_OpenClanChatWindowInSteam(SteamInterface: ISteamFriends; steamIDClanChat: TSteamID): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamFriends_CloseClanChatWindowInSteam(SteamInterface: ISteamFriends; steamIDClanChat: TSteamID): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamFriends_SetListenForFriendsMessages(SteamInterface: ISteamFriends; bInterceptEnabled: Boolean): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamFriends_ReplyToFriendMessage(SteamInterface: ISteamFriends; steamIDFriend: TSteamID; pchMsgToSend: PChar): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamFriends_GetFriendMessage(SteamInterface: ISteamFriends; steamIDFriend: TSteamID; iMessageID: Longint; pvData: Pointer; cubData: Longint; peChatEntryType: EChatEntryType): Longint; cdecl; external STEAMLIB;
function SteamAPI_ISteamFriends_GetFollowerCount(SteamInterface: ISteamFriends; steamID: TSteamID): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamFriends_IsFollowing(SteamInterface: ISteamFriends; steamID: TSteamID): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamFriends_EnumerateFollowingList(SteamInterface: ISteamFriends; unStartIndex: uint32): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamFriends_IsClanPublic(SteamInterface: ISteamFriends; steamIDClan: TSteamID): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamFriends_IsClanOfficialGameGroup(SteamInterface: ISteamFriends; steamIDClan: TSteamID): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamFriends_GetNumChatsWithUnreadPriorityMessages(SteamInterface: ISteamFriends): Longint; cdecl; external STEAMLIB;
procedure SteamAPI_ISteamFriends_ActivateGameOverlayRemotePlayTogetherInviteDialog(SteamInterface: ISteamFriends; steamIDLobby: TSteamID); cdecl; external STEAMLIB;


function SteamAPI_SteamUtils_v009(): ISteamUtils; cdecl; external STEAMLIB;
function SteamAPI_SteamGameServerUtils_v009(): ISteamUtils; cdecl; external STEAMLIB;

function SteamAPI_ISteamUtils_GetSecondsSinceAppActive(SteamInterface: ISteamUtils): uint32; cdecl; external STEAMLIB;
function SteamAPI_ISteamUtils_GetSecondsSinceComputerActive(SteamInterface: ISteamUtils): uint32; cdecl; external STEAMLIB;
function SteamAPI_ISteamUtils_GetConnectedUniverse(SteamInterface: ISteamUtils): EUniverse; cdecl; external STEAMLIB;
function SteamAPI_ISteamUtils_GetServerRealTime(SteamInterface: ISteamUtils): uint32; cdecl; external STEAMLIB;
function SteamAPI_ISteamUtils_GetIPCountry(SteamInterface: ISteamUtils): PChar; cdecl; external STEAMLIB;
function SteamAPI_ISteamUtils_GetImageSize(SteamInterface: ISteamUtils; iImage: Longint; pnWidth: puint32; pnHeight: puint32): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUtils_GetImageRGBA(SteamInterface: ISteamUtils; iImage: Longint; pubDest: puint8; nDestBufferSize: Longint): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUtils_GetCSERIPPort(SteamInterface: ISteamUtils; unIP: puint32; usPort: puint16): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUtils_GetCurrentBatteryPower(SteamInterface: ISteamUtils): uint8; cdecl; external STEAMLIB;
function SteamAPI_ISteamUtils_GetAppID(SteamInterface: ISteamUtils): uint32; cdecl; external STEAMLIB;
procedure SteamAPI_ISteamUtils_SetOverlayNotificationPosition(SteamInterface: ISteamUtils; eNotificationPosition: ENotificationPosition); cdecl; external STEAMLIB;
function SteamAPI_ISteamUtils_IsAPICallCompleted(SteamInterface: ISteamUtils; hSteamAPICall: SteamAPICall_t; pbFailed: pboolean): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUtils_GetAPICallFailureReason(SteamInterface: ISteamUtils; hSteamAPICall: SteamAPICall_t): ESteamAPICallFailure; cdecl; external STEAMLIB;
function SteamAPI_ISteamUtils_GetAPICallResult(SteamInterface: ISteamUtils; hSteamAPICall: SteamAPICall_t; pCallback: Pointer; cubCallback: Longint; iCallbackExpected: Longint; pbFailed: pboolean): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUtils_GetIPCCallCount(SteamInterface: ISteamUtils): uint32; cdecl; external STEAMLIB;
procedure SteamAPI_ISteamUtils_SetWarningMessageHook(SteamInterface: ISteamUtils; pFunction: Pointer); cdecl; external STEAMLIB;
function SteamAPI_ISteamUtils_IsOverlayEnabled(SteamInterface: ISteamUtils): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUtils_BOverlayNeedsPresent(SteamInterface: ISteamUtils): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUtils_CheckFileSignature(SteamInterface: ISteamUtils; szFileName: PChar): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamUtils_ShowGamepadTextInput(SteamInterface: ISteamUtils; eInputMode: EGamepadTextInputMode; eLineInputMode: EGamepadTextInputLineMode; pchDescription: PChar; unCharMax: uint32; pchExistingText: PChar): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUtils_GetEnteredGamepadTextLength(SteamInterface: ISteamUtils): uint32; cdecl; external STEAMLIB;
function SteamAPI_ISteamUtils_GetEnteredGamepadTextInput(SteamInterface: ISteamUtils; pchText: PChar; cchText: uint32): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUtils_GetSteamUILanguage(SteamInterface: ISteamUtils): PChar; cdecl; external STEAMLIB;
function SteamAPI_ISteamUtils_IsSteamRunningInVR(SteamInterface: ISteamUtils): Boolean; cdecl; external STEAMLIB;
procedure SteamAPI_ISteamUtils_SetOverlayNotificationInset(SteamInterface: ISteamUtils; nHorizontalInset: Longint; nVerticalInset: Longint); cdecl; external STEAMLIB;
function SteamAPI_ISteamUtils_IsSteamInBigPictureMode(SteamInterface: ISteamUtils): Boolean; cdecl; external STEAMLIB;
procedure SteamAPI_ISteamUtils_StartVRDashboard(SteamInterface: ISteamUtils); cdecl; external STEAMLIB;
function SteamAPI_ISteamUtils_IsVRHeadsetStreamingEnabled(SteamInterface: ISteamUtils): Boolean; cdecl; external STEAMLIB;
procedure SteamAPI_ISteamUtils_SetVRHeadsetStreamingEnabled(SteamInterface: ISteamUtils; bEnabled: Boolean); cdecl; external STEAMLIB;
function SteamAPI_ISteamUtils_IsSteamChinaLauncher(SteamInterface: ISteamUtils): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUtils_InitFilterText(SteamInterface: ISteamUtils): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUtils_FilterText(SteamInterface: ISteamUtils; pchOutFilteredText: PChar; nByteSizeOutFilteredText: uint32; pchInputMessage: PChar; bLegalOnly: Boolean): Longint; cdecl; external STEAMLIB;
function SteamAPI_ISteamUtils_GetIPv6ConnectivityState(SteamInterface: ISteamUtils; eProtocol: ESteamIPv6ConnectivityProtocol): ESteamIPv6ConnectivityState; cdecl; external STEAMLIB;


function SteamAPI_SteamMatchmaking_v009(): ISteamMatchmaking; cdecl; external STEAMLIB;

function SteamAPI_ISteamMatchmaking_GetFavoriteGameCount(SteamInterface: ISteamMatchmaking): Longint; cdecl; external STEAMLIB;
function SteamAPI_ISteamMatchmaking_GetFavoriteGame(SteamInterface: ISteamMatchmaking; iGame: Longint; pnAppID: pAppId_t; pnIP: puint32; pnConnPort: puint16; pnQueryPort: puint16; punFlags: puint32; pRTime32LastPlayedOnServer: puint32): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamMatchmaking_AddFavoriteGame(SteamInterface: ISteamMatchmaking; nAppID: AppId_t; nIP: uint32; nConnPort: uint16; nQueryPort: uint16; unFlags: uint32; rTime32LastPlayedOnServer: uint32): Longint; cdecl; external STEAMLIB;
function SteamAPI_ISteamMatchmaking_RemoveFavoriteGame(SteamInterface: ISteamMatchmaking; nAppID: AppId_t; nIP: uint32; nConnPort: uint16; nQueryPort: uint16; unFlags: uint32): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamMatchmaking_RequestLobbyList(SteamInterface: ISteamMatchmaking): SteamAPICall_t; cdecl; external STEAMLIB;
procedure SteamAPI_ISteamMatchmaking_AddRequestLobbyListStringFilter(SteamInterface: ISteamMatchmaking; pchKeyToMatch: PChar; pchValueToMatch: PChar; eComparisonType: ELobbyComparison); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamMatchmaking_AddRequestLobbyListNumericalFilter(SteamInterface: ISteamMatchmaking; pchKeyToMatch: PChar; nValueToMatch: Longint; eComparisonType: ELobbyComparison); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamMatchmaking_AddRequestLobbyListNearValueFilter(SteamInterface: ISteamMatchmaking; pchKeyToMatch: PChar; nValueToBeCloseTo: Longint); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamMatchmaking_AddRequestLobbyListFilterSlotsAvailable(SteamInterface: ISteamMatchmaking; nSlotsAvailable: Longint); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamMatchmaking_AddRequestLobbyListDistanceFilter(SteamInterface: ISteamMatchmaking; eLobbyDistanceFilter: ELobbyDistanceFilter); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamMatchmaking_AddRequestLobbyListResultCountFilter(SteamInterface: ISteamMatchmaking; cMaxResults: Longint); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamMatchmaking_AddRequestLobbyListCompatibleMembersFilter(SteamInterface: ISteamMatchmaking; steamIDLobby: TSteamID); cdecl; external STEAMLIB;
function SteamAPI_ISteamMatchmaking_GetLobbyByIndex(SteamInterface: ISteamMatchmaking; iLobby: Longint): TSteamID; cdecl; external STEAMLIB;
function SteamAPI_ISteamMatchmaking_CreateLobby(SteamInterface: ISteamMatchmaking; eLobbyType: ELobbyType; cMaxMembers: Longint): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamMatchmaking_JoinLobby(SteamInterface: ISteamMatchmaking; steamIDLobby: TSteamID): SteamAPICall_t; cdecl; external STEAMLIB;
procedure SteamAPI_ISteamMatchmaking_LeaveLobby(SteamInterface: ISteamMatchmaking; steamIDLobby: TSteamID); cdecl; external STEAMLIB;
function SteamAPI_ISteamMatchmaking_InviteUserToLobby(SteamInterface: ISteamMatchmaking; steamIDLobby: TSteamID; steamIDInvitee: TSteamID): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamMatchmaking_GetNumLobbyMembers(SteamInterface: ISteamMatchmaking; steamIDLobby: TSteamID): Longint; cdecl; external STEAMLIB;
function SteamAPI_ISteamMatchmaking_GetLobbyMemberByIndex(SteamInterface: ISteamMatchmaking; steamIDLobby: TSteamID; iMember: Longint): TSteamID; cdecl; external STEAMLIB;
function SteamAPI_ISteamMatchmaking_GetLobbyData(SteamInterface: ISteamMatchmaking; steamIDLobby: TSteamID; pchKey: PChar): PChar; cdecl; external STEAMLIB;
function SteamAPI_ISteamMatchmaking_SetLobbyData(SteamInterface: ISteamMatchmaking; steamIDLobby: TSteamID; pchKey: PChar; pchValue: PChar): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamMatchmaking_GetLobbyDataCount(SteamInterface: ISteamMatchmaking; steamIDLobby: TSteamID): Longint; cdecl; external STEAMLIB;
function SteamAPI_ISteamMatchmaking_GetLobbyDataByIndex(SteamInterface: ISteamMatchmaking; steamIDLobby: TSteamID; iLobbyData: Longint; pchKey: PChar; cchKeyBufferSize: Longint; pchValue: PChar; cchValueBufferSize: Longint): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamMatchmaking_DeleteLobbyData(SteamInterface: ISteamMatchmaking; steamIDLobby: TSteamID; pchKey: PChar): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamMatchmaking_GetLobbyMemberData(SteamInterface: ISteamMatchmaking; steamIDLobby: TSteamID; steamIDUser: TSteamID; pchKey: PChar): PChar; cdecl; external STEAMLIB;
procedure SteamAPI_ISteamMatchmaking_SetLobbyMemberData(SteamInterface: ISteamMatchmaking; steamIDLobby: TSteamID; pchKey: PChar; pchValue: PChar); cdecl; external STEAMLIB;
function SteamAPI_ISteamMatchmaking_SendLobbyChatMsg(SteamInterface: ISteamMatchmaking; steamIDLobby: TSteamID; pvMsgBody: Pointer; cubMsgBody: Longint): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamMatchmaking_GetLobbyChatEntry(SteamInterface: ISteamMatchmaking; steamIDLobby: TSteamID; iChatID: Longint; pSteamIDUser: PSteamID; pvData: Pointer; cubData: Longint; peChatEntryType: EChatEntryType): Longint; cdecl; external STEAMLIB;
function SteamAPI_ISteamMatchmaking_RequestLobbyData(SteamInterface: ISteamMatchmaking; steamIDLobby: TSteamID): Boolean; cdecl; external STEAMLIB;
procedure SteamAPI_ISteamMatchmaking_SetLobbyGameServer(SteamInterface: ISteamMatchmaking; steamIDLobby: TSteamID; unGameServerIP: uint32; unGameServerPort: uint16; steamIDGameServer: TSteamID); cdecl; external STEAMLIB;
function SteamAPI_ISteamMatchmaking_GetLobbyGameServer(SteamInterface: ISteamMatchmaking; steamIDLobby: TSteamID; punGameServerIP: puint32; punGameServerPort: puint16; psteamIDGameServer: PSteamID): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamMatchmaking_SetLobbyMemberLimit(SteamInterface: ISteamMatchmaking; steamIDLobby: TSteamID; cMaxMembers: Longint): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamMatchmaking_GetLobbyMemberLimit(SteamInterface: ISteamMatchmaking; steamIDLobby: TSteamID): Longint; cdecl; external STEAMLIB;
function SteamAPI_ISteamMatchmaking_SetLobbyType(SteamInterface: ISteamMatchmaking; steamIDLobby: TSteamID; eLobbyType: ELobbyType): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamMatchmaking_SetLobbyJoinable(SteamInterface: ISteamMatchmaking; steamIDLobby: TSteamID; bLobbyJoinable: Boolean): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamMatchmaking_GetLobbyOwner(SteamInterface: ISteamMatchmaking; steamIDLobby: TSteamID): TSteamID; cdecl; external STEAMLIB;
function SteamAPI_ISteamMatchmaking_SetLobbyOwner(SteamInterface: ISteamMatchmaking; steamIDLobby: TSteamID; steamIDNewOwner: TSteamID): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamMatchmaking_SetLinkedLobby(SteamInterface: ISteamMatchmaking; steamIDLobby: TSteamID; steamIDLobbyDependent: TSteamID): Boolean; cdecl; external STEAMLIB;



procedure SteamAPI_ISteamMatchmakingServerListResponse_ServerResponded(SteamInterface: ISteamMatchmakingServerListResponse; hRequest: HServerListRequest; iServer: Longint); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamMatchmakingServerListResponse_ServerFailedToRespond(SteamInterface: ISteamMatchmakingServerListResponse; hRequest: HServerListRequest; iServer: Longint); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamMatchmakingServerListResponse_RefreshComplete(SteamInterface: ISteamMatchmakingServerListResponse; hRequest: HServerListRequest; response: EMatchMakingServerResponse); cdecl; external STEAMLIB;



procedure SteamAPI_ISteamMatchmakingPingResponse_ServerResponded(SteamInterface: ISteamMatchmakingPingResponse; server: Pgameserveritem_t); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamMatchmakingPingResponse_ServerFailedToRespond(SteamInterface: ISteamMatchmakingPingResponse); cdecl; external STEAMLIB;



procedure SteamAPI_ISteamMatchmakingPlayersResponse_AddPlayerToList(SteamInterface: ISteamMatchmakingPlayersResponse; pchName: PChar; nScore: Longint; flTimePlayed: Single); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamMatchmakingPlayersResponse_PlayersFailedToRespond(SteamInterface: ISteamMatchmakingPlayersResponse); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamMatchmakingPlayersResponse_PlayersRefreshComplete(SteamInterface: ISteamMatchmakingPlayersResponse); cdecl; external STEAMLIB;



procedure SteamAPI_ISteamMatchmakingRulesResponse_RulesResponded(SteamInterface: ISteamMatchmakingRulesResponse; pchRule: PChar; pchValue: PChar); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamMatchmakingRulesResponse_RulesFailedToRespond(SteamInterface: ISteamMatchmakingRulesResponse); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamMatchmakingRulesResponse_RulesRefreshComplete(SteamInterface: ISteamMatchmakingRulesResponse); cdecl; external STEAMLIB;


function SteamAPI_SteamMatchmakingServers_v002(): ISteamMatchmakingServers; cdecl; external STEAMLIB;

function SteamAPI_ISteamMatchmakingServers_RequestInternetServerList(SteamInterface: ISteamMatchmakingServers; iApp: AppId_t; ppchFilters: pMatchMakingKeyValuePair_t; nFilters: uint32; pRequestServersResponse: ISteamMatchmakingServerListResponse): HServerListRequest; cdecl; external STEAMLIB;
function SteamAPI_ISteamMatchmakingServers_RequestLANServerList(SteamInterface: ISteamMatchmakingServers; iApp: AppId_t; pRequestServersResponse: ISteamMatchmakingServerListResponse): HServerListRequest; cdecl; external STEAMLIB;
function SteamAPI_ISteamMatchmakingServers_RequestFriendsServerList(SteamInterface: ISteamMatchmakingServers; iApp: AppId_t; ppchFilters: pMatchMakingKeyValuePair_t; nFilters: uint32; pRequestServersResponse: ISteamMatchmakingServerListResponse): HServerListRequest; cdecl; external STEAMLIB;
function SteamAPI_ISteamMatchmakingServers_RequestFavoritesServerList(SteamInterface: ISteamMatchmakingServers; iApp: AppId_t; ppchFilters: pMatchMakingKeyValuePair_t; nFilters: uint32; pRequestServersResponse: ISteamMatchmakingServerListResponse): HServerListRequest; cdecl; external STEAMLIB;
function SteamAPI_ISteamMatchmakingServers_RequestHistoryServerList(SteamInterface: ISteamMatchmakingServers; iApp: AppId_t; ppchFilters: pMatchMakingKeyValuePair_t; nFilters: uint32; pRequestServersResponse: ISteamMatchmakingServerListResponse): HServerListRequest; cdecl; external STEAMLIB;
function SteamAPI_ISteamMatchmakingServers_RequestSpectatorServerList(SteamInterface: ISteamMatchmakingServers; iApp: AppId_t; ppchFilters: pMatchMakingKeyValuePair_t; nFilters: uint32; pRequestServersResponse: ISteamMatchmakingServerListResponse): HServerListRequest; cdecl; external STEAMLIB;
procedure SteamAPI_ISteamMatchmakingServers_ReleaseRequest(SteamInterface: ISteamMatchmakingServers; hServerListRequest: HServerListRequest); cdecl; external STEAMLIB;
function SteamAPI_ISteamMatchmakingServers_GetServerDetails(SteamInterface: ISteamMatchmakingServers; hRequest: HServerListRequest; iServer: Longint): pgameserveritem_t; cdecl; external STEAMLIB;
procedure SteamAPI_ISteamMatchmakingServers_CancelQuery(SteamInterface: ISteamMatchmakingServers; hRequest: HServerListRequest); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamMatchmakingServers_RefreshQuery(SteamInterface: ISteamMatchmakingServers; hRequest: HServerListRequest); cdecl; external STEAMLIB;
function SteamAPI_ISteamMatchmakingServers_IsRefreshing(SteamInterface: ISteamMatchmakingServers; hRequest: HServerListRequest): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamMatchmakingServers_GetServerCount(SteamInterface: ISteamMatchmakingServers; hRequest: HServerListRequest): Longint; cdecl; external STEAMLIB;
procedure SteamAPI_ISteamMatchmakingServers_RefreshServer(SteamInterface: ISteamMatchmakingServers; hRequest: HServerListRequest; iServer: Longint); cdecl; external STEAMLIB;
function SteamAPI_ISteamMatchmakingServers_PingServer(SteamInterface: ISteamMatchmakingServers; unIP: uint32; usPort: uint16; pRequestServersResponse: ISteamMatchmakingPingResponse): HServerQuery; cdecl; external STEAMLIB;
function SteamAPI_ISteamMatchmakingServers_PlayerDetails(SteamInterface: ISteamMatchmakingServers; unIP: uint32; usPort: uint16; pRequestServersResponse: ISteamMatchmakingPlayersResponse): HServerQuery; cdecl; external STEAMLIB;
function SteamAPI_ISteamMatchmakingServers_ServerRules(SteamInterface: ISteamMatchmakingServers; unIP: uint32; usPort: uint16; pRequestServersResponse: ISteamMatchmakingRulesResponse): HServerQuery; cdecl; external STEAMLIB;
procedure SteamAPI_ISteamMatchmakingServers_CancelServerQuery(SteamInterface: ISteamMatchmakingServers; hServerQuery: HServerQuery); cdecl; external STEAMLIB;


function SteamAPI_SteamGameSearch_v001(): ISteamGameSearch; cdecl; external STEAMLIB;

function SteamAPI_ISteamGameSearch_AddGameSearchParams(SteamInterface: ISteamGameSearch; pchKeyToFind: PChar; pchValuesToFind: PChar): EGameSearchErrorCode_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamGameSearch_SearchForGameWithLobby(SteamInterface: ISteamGameSearch; steamIDLobby: TSteamID; nPlayerMin: Longint; nPlayerMax: Longint): EGameSearchErrorCode_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamGameSearch_SearchForGameSolo(SteamInterface: ISteamGameSearch; nPlayerMin: Longint; nPlayerMax: Longint): EGameSearchErrorCode_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamGameSearch_AcceptGame(SteamInterface: ISteamGameSearch): EGameSearchErrorCode_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamGameSearch_DeclineGame(SteamInterface: ISteamGameSearch): EGameSearchErrorCode_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamGameSearch_RetrieveConnectionDetails(SteamInterface: ISteamGameSearch; steamIDHost: TSteamID; pchConnectionDetails: PChar; cubConnectionDetails: Longint): EGameSearchErrorCode_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamGameSearch_EndGameSearch(SteamInterface: ISteamGameSearch): EGameSearchErrorCode_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamGameSearch_SetGameHostParams(SteamInterface: ISteamGameSearch; pchKey: PChar; pchValue: PChar): EGameSearchErrorCode_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamGameSearch_SetConnectionDetails(SteamInterface: ISteamGameSearch; pchConnectionDetails: PChar; cubConnectionDetails: Longint): EGameSearchErrorCode_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamGameSearch_RequestPlayersForGame(SteamInterface: ISteamGameSearch; nPlayerMin: Longint; nPlayerMax: Longint; nMaxTeamSize: Longint): EGameSearchErrorCode_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamGameSearch_HostConfirmGameStart(SteamInterface: ISteamGameSearch; ullUniqueGameID: uint64): EGameSearchErrorCode_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamGameSearch_CancelRequestPlayersForGame(SteamInterface: ISteamGameSearch): EGameSearchErrorCode_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamGameSearch_SubmitPlayerResult(SteamInterface: ISteamGameSearch; ullUniqueGameID: uint64; steamIDPlayer: TSteamID; EPlayerResult: EPlayerResult_t): EGameSearchErrorCode_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamGameSearch_EndGame(SteamInterface: ISteamGameSearch; ullUniqueGameID: uint64): EGameSearchErrorCode_t; cdecl; external STEAMLIB;


function SteamAPI_SteamParties_v002(): ISteamParties; cdecl; external STEAMLIB;

function SteamAPI_ISteamParties_GetNumActiveBeacons(SteamInterface: ISteamParties): uint32; cdecl; external STEAMLIB;
function SteamAPI_ISteamParties_GetBeaconByIndex(SteamInterface: ISteamParties; unIndex: uint32): PartyBeaconID_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamParties_GetBeaconDetails(SteamInterface: ISteamParties; ulBeaconID: PartyBeaconID_t; pSteamIDBeaconOwner: PSteamID; pLocation: pSteamPartyBeaconLocation_t; pchMetadata: PChar; cchMetadata: Longint): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamParties_JoinParty(SteamInterface: ISteamParties; ulBeaconID: PartyBeaconID_t): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamParties_GetNumAvailableBeaconLocations(SteamInterface: ISteamParties; puNumLocations: puint32): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamParties_GetAvailableBeaconLocations(SteamInterface: ISteamParties; pLocationList: pSteamPartyBeaconLocation_t; uMaxNumLocations: uint32): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamParties_CreateBeacon(SteamInterface: ISteamParties; unOpenSlots: uint32; pBeaconLocation: pSteamPartyBeaconLocation_t; pchConnectString: PChar; pchMetadata: PChar): SteamAPICall_t; cdecl; external STEAMLIB;
procedure SteamAPI_ISteamParties_OnReservationCompleted(SteamInterface: ISteamParties; ulBeacon: PartyBeaconID_t; steamIDUser: TSteamID); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamParties_CancelReservation(SteamInterface: ISteamParties; ulBeacon: PartyBeaconID_t; steamIDUser: TSteamID); cdecl; external STEAMLIB;
function SteamAPI_ISteamParties_ChangeNumOpenSlots(SteamInterface: ISteamParties; ulBeacon: PartyBeaconID_t; unOpenSlots: uint32): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamParties_DestroyBeacon(SteamInterface: ISteamParties; ulBeacon: PartyBeaconID_t): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamParties_GetBeaconLocationData(SteamInterface: ISteamParties; BeaconLocation: SteamPartyBeaconLocation_t; eData: ESteamPartyBeaconLocationData; pchDataStringOut: PChar; cchDataStringOut: Longint): Boolean; cdecl; external STEAMLIB;


function SteamAPI_SteamRemoteStorage_v014(): ISteamRemoteStorage; cdecl; external STEAMLIB;

function SteamAPI_ISteamRemoteStorage_FileWrite(SteamInterface: ISteamRemoteStorage; pchFile: PChar; pvData: Pointer; cubData: int32): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamRemoteStorage_FileRead(SteamInterface: ISteamRemoteStorage; pchFile: PChar; pvData: Pointer; cubDataToRead: int32): int32; cdecl; external STEAMLIB;
function SteamAPI_ISteamRemoteStorage_FileWriteAsync(SteamInterface: ISteamRemoteStorage; pchFile: PChar; pvData: Pointer; cubData: uint32): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamRemoteStorage_FileReadAsync(SteamInterface: ISteamRemoteStorage; pchFile: PChar; nOffset: uint32; cubToRead: uint32): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamRemoteStorage_FileReadAsyncComplete(SteamInterface: ISteamRemoteStorage; hReadCall: SteamAPICall_t; pvBuffer: Pointer; cubToRead: uint32): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamRemoteStorage_FileForget(SteamInterface: ISteamRemoteStorage; pchFile: PChar): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamRemoteStorage_FileDelete(SteamInterface: ISteamRemoteStorage; pchFile: PChar): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamRemoteStorage_FileShare(SteamInterface: ISteamRemoteStorage; pchFile: PChar): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamRemoteStorage_SetSyncPlatforms(SteamInterface: ISteamRemoteStorage; pchFile: PChar; eRemoteStoragePlatform: ERemoteStoragePlatform): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamRemoteStorage_FileWriteStreamOpen(SteamInterface: ISteamRemoteStorage; pchFile: PChar): UGCFileWriteStreamHandle_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamRemoteStorage_FileWriteStreamWriteChunk(SteamInterface: ISteamRemoteStorage; writeHandle: UGCFileWriteStreamHandle_t; pvData: Pointer; cubData: int32): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamRemoteStorage_FileWriteStreamClose(SteamInterface: ISteamRemoteStorage; writeHandle: UGCFileWriteStreamHandle_t): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamRemoteStorage_FileWriteStreamCancel(SteamInterface: ISteamRemoteStorage; writeHandle: UGCFileWriteStreamHandle_t): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamRemoteStorage_FileExists(SteamInterface: ISteamRemoteStorage; pchFile: PChar): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamRemoteStorage_FilePersisted(SteamInterface: ISteamRemoteStorage; pchFile: PChar): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamRemoteStorage_GetFileSize(SteamInterface: ISteamRemoteStorage; pchFile: PChar): int32; cdecl; external STEAMLIB;
function SteamAPI_ISteamRemoteStorage_GetFileTimestamp(SteamInterface: ISteamRemoteStorage; pchFile: PChar): int64; cdecl; external STEAMLIB;
function SteamAPI_ISteamRemoteStorage_GetSyncPlatforms(SteamInterface: ISteamRemoteStorage; pchFile: PChar): ERemoteStoragePlatform; cdecl; external STEAMLIB;
function SteamAPI_ISteamRemoteStorage_GetFileCount(SteamInterface: ISteamRemoteStorage): int32; cdecl; external STEAMLIB;
function SteamAPI_ISteamRemoteStorage_GetFileNameAndSize(SteamInterface: ISteamRemoteStorage; iFile: Longint; pnFileSizeInBytes: pint32): PChar; cdecl; external STEAMLIB;
function SteamAPI_ISteamRemoteStorage_GetQuota(SteamInterface: ISteamRemoteStorage; pnTotalBytes: puint64; puAvailableBytes: puint64): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamRemoteStorage_IsCloudEnabledForAccount(SteamInterface: ISteamRemoteStorage): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamRemoteStorage_IsCloudEnabledForApp(SteamInterface: ISteamRemoteStorage): Boolean; cdecl; external STEAMLIB;
procedure SteamAPI_ISteamRemoteStorage_SetCloudEnabledForApp(SteamInterface: ISteamRemoteStorage; bEnabled: Boolean); cdecl; external STEAMLIB;
function SteamAPI_ISteamRemoteStorage_UGCDownload(SteamInterface: ISteamRemoteStorage; hContent: UGCHandle_t; unPriority: uint32): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamRemoteStorage_GetUGCDownloadProgress(SteamInterface: ISteamRemoteStorage; hContent: UGCHandle_t; pnBytesDownloaded: pint32; pnBytesExpected: pint32): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamRemoteStorage_GetUGCDetails(SteamInterface: ISteamRemoteStorage; hContent: UGCHandle_t; pnAppID: pAppId_t; ppchName: PPChar; pnFileSizeInBytes: pint32; pSteamIDOwner: PSteamID): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamRemoteStorage_UGCRead(SteamInterface: ISteamRemoteStorage; hContent: UGCHandle_t; pvData: Pointer; cubDataToRead: int32; cOffset: uint32; eAction: EUGCReadAction): int32; cdecl; external STEAMLIB;
function SteamAPI_ISteamRemoteStorage_GetCachedUGCCount(SteamInterface: ISteamRemoteStorage): int32; cdecl; external STEAMLIB;
function SteamAPI_ISteamRemoteStorage_GetCachedUGCHandle(SteamInterface: ISteamRemoteStorage; iCachedContent: int32): UGCHandle_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamRemoteStorage_PublishWorkshopFile(SteamInterface: ISteamRemoteStorage; pchFile: PChar; pchPreviewFile: PChar; nConsumerAppId: AppId_t; pchTitle: PChar; pchDescription: PChar; eVisibility: ERemoteStoragePublishedFileVisibility; pTags: pSteamParamStringArray_t; eWorkshopFileType: EWorkshopFileType): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamRemoteStorage_CreatePublishedFileUpdateRequest(SteamInterface: ISteamRemoteStorage; unPublishedFileId: PublishedFileId_t): PublishedFileUpdateHandle_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamRemoteStorage_UpdatePublishedFileFile(SteamInterface: ISteamRemoteStorage; updateHandle: PublishedFileUpdateHandle_t; pchFile: PChar): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamRemoteStorage_UpdatePublishedFilePreviewFile(SteamInterface: ISteamRemoteStorage; updateHandle: PublishedFileUpdateHandle_t; pchPreviewFile: PChar): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamRemoteStorage_UpdatePublishedFileTitle(SteamInterface: ISteamRemoteStorage; updateHandle: PublishedFileUpdateHandle_t; pchTitle: PChar): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamRemoteStorage_UpdatePublishedFileDescription(SteamInterface: ISteamRemoteStorage; updateHandle: PublishedFileUpdateHandle_t; pchDescription: PChar): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamRemoteStorage_UpdatePublishedFileVisibility(SteamInterface: ISteamRemoteStorage; updateHandle: PublishedFileUpdateHandle_t; eVisibility: ERemoteStoragePublishedFileVisibility): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamRemoteStorage_UpdatePublishedFileTags(SteamInterface: ISteamRemoteStorage; updateHandle: PublishedFileUpdateHandle_t; pTags: pSteamParamStringArray_t): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamRemoteStorage_CommitPublishedFileUpdate(SteamInterface: ISteamRemoteStorage; updateHandle: PublishedFileUpdateHandle_t): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamRemoteStorage_GetPublishedFileDetails(SteamInterface: ISteamRemoteStorage; unPublishedFileId: PublishedFileId_t; unMaxSecondsOld: uint32): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamRemoteStorage_DeletePublishedFile(SteamInterface: ISteamRemoteStorage; unPublishedFileId: PublishedFileId_t): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamRemoteStorage_EnumerateUserPublishedFiles(SteamInterface: ISteamRemoteStorage; unStartIndex: uint32): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamRemoteStorage_SubscribePublishedFile(SteamInterface: ISteamRemoteStorage; unPublishedFileId: PublishedFileId_t): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamRemoteStorage_EnumerateUserSubscribedFiles(SteamInterface: ISteamRemoteStorage; unStartIndex: uint32): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamRemoteStorage_UnsubscribePublishedFile(SteamInterface: ISteamRemoteStorage; unPublishedFileId: PublishedFileId_t): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamRemoteStorage_UpdatePublishedFileSetChangeDescription(SteamInterface: ISteamRemoteStorage; updateHandle: PublishedFileUpdateHandle_t; pchChangeDescription: PChar): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamRemoteStorage_GetPublishedItemVoteDetails(SteamInterface: ISteamRemoteStorage; unPublishedFileId: PublishedFileId_t): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamRemoteStorage_UpdateUserPublishedItemVote(SteamInterface: ISteamRemoteStorage; unPublishedFileId: PublishedFileId_t; bVoteUp: Boolean): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamRemoteStorage_GetUserPublishedItemVoteDetails(SteamInterface: ISteamRemoteStorage; unPublishedFileId: PublishedFileId_t): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamRemoteStorage_EnumerateUserSharedWorkshopFiles(SteamInterface: ISteamRemoteStorage; steamId: TSteamID; unStartIndex: uint32; pRequiredTags: pSteamParamStringArray_t; pExcludedTags: pSteamParamStringArray_t): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamRemoteStorage_PublishVideo(SteamInterface: ISteamRemoteStorage; eVideoProvider: EWorkshopVideoProvider; pchVideoAccount: PChar; pchVideoIdentifier: PChar; pchPreviewFile: PChar; nConsumerAppId: AppId_t; pchTitle: PChar; pchDescription: PChar; eVisibility: ERemoteStoragePublishedFileVisibility; pTags: pSteamParamStringArray_t): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamRemoteStorage_SetUserPublishedFileAction(SteamInterface: ISteamRemoteStorage; unPublishedFileId: PublishedFileId_t; eAction: EWorkshopFileAction): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamRemoteStorage_EnumeratePublishedFilesByUserAction(SteamInterface: ISteamRemoteStorage; eAction: EWorkshopFileAction; unStartIndex: uint32): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamRemoteStorage_EnumeratePublishedWorkshopFiles(SteamInterface: ISteamRemoteStorage; eEnumerationType: EWorkshopEnumerationType; unStartIndex: uint32; unCount: uint32; unDays: uint32; pTags: pSteamParamStringArray_t; pUserTags: pSteamParamStringArray_t): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamRemoteStorage_UGCDownloadToLocation(SteamInterface: ISteamRemoteStorage; hContent: UGCHandle_t; pchLocation: PChar; unPriority: uint32): SteamAPICall_t; cdecl; external STEAMLIB;


function SteamAPI_SteamUserStats_v011(): ISteamUserStats; cdecl; external STEAMLIB;

function SteamAPI_ISteamUserStats_RequestCurrentStats(SteamInterface: ISteamUserStats): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUserStats_GetStatInt32(SteamInterface: ISteamUserStats; pchName: PChar; pData: pint32): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUserStats_GetStatFloat(SteamInterface: ISteamUserStats; pchName: PChar; pData: psingle): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUserStats_SetStatInt32(SteamInterface: ISteamUserStats; pchName: PChar; nData: int32): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUserStats_SetStatFloat(SteamInterface: ISteamUserStats; pchName: PChar; fData: Single): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUserStats_UpdateAvgRateStat(SteamInterface: ISteamUserStats; pchName: PChar; flCountThisSession: Single; dSessionLength: Double): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUserStats_GetAchievement(SteamInterface: ISteamUserStats; pchName: PChar; pbAchieved: pboolean): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUserStats_SetAchievement(SteamInterface: ISteamUserStats; pchName: PChar): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUserStats_ClearAchievement(SteamInterface: ISteamUserStats; pchName: PChar): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUserStats_GetAchievementAndUnlockTime(SteamInterface: ISteamUserStats; pchName: PChar; pbAchieved: pboolean; punUnlockTime: puint32): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUserStats_StoreStats(SteamInterface: ISteamUserStats): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUserStats_GetAchievementIcon(SteamInterface: ISteamUserStats; pchName: PChar): Longint; cdecl; external STEAMLIB;
function SteamAPI_ISteamUserStats_GetAchievementDisplayAttribute(SteamInterface: ISteamUserStats; pchName: PChar; pchKey: PChar): PChar; cdecl; external STEAMLIB;
function SteamAPI_ISteamUserStats_IndicateAchievementProgress(SteamInterface: ISteamUserStats; pchName: PChar; nCurProgress: uint32; nMaxProgress: uint32): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUserStats_GetNumAchievements(SteamInterface: ISteamUserStats): uint32; cdecl; external STEAMLIB;
function SteamAPI_ISteamUserStats_GetAchievementName(SteamInterface: ISteamUserStats; iAchievement: uint32): PChar; cdecl; external STEAMLIB;
function SteamAPI_ISteamUserStats_RequestUserStats(SteamInterface: ISteamUserStats; steamIDUser: TSteamID): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamUserStats_GetUserStatInt32(SteamInterface: ISteamUserStats; steamIDUser: TSteamID; pchName: PChar; pData: pint32): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUserStats_GetUserStatFloat(SteamInterface: ISteamUserStats; steamIDUser: TSteamID; pchName: PChar; pData: psingle): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUserStats_GetUserAchievement(SteamInterface: ISteamUserStats; steamIDUser: TSteamID; pchName: PChar; pbAchieved: pboolean): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUserStats_GetUserAchievementAndUnlockTime(SteamInterface: ISteamUserStats; steamIDUser: TSteamID; pchName: PChar; pbAchieved: pboolean; punUnlockTime: puint32): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUserStats_ResetAllStats(SteamInterface: ISteamUserStats; bAchievementsToo: Boolean): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUserStats_FindOrCreateLeaderboard(SteamInterface: ISteamUserStats; pchLeaderboardName: PChar; eLeaderboardSortMethod: ELeaderboardSortMethod; eLeaderboardDisplayType: ELeaderboardDisplayType): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamUserStats_FindLeaderboard(SteamInterface: ISteamUserStats; pchLeaderboardName: PChar): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamUserStats_GetLeaderboardName(SteamInterface: ISteamUserStats; hSteamLeaderboard: SteamLeaderboard_t): PChar; cdecl; external STEAMLIB;
function SteamAPI_ISteamUserStats_GetLeaderboardEntryCount(SteamInterface: ISteamUserStats; hSteamLeaderboard: SteamLeaderboard_t): Longint; cdecl; external STEAMLIB;
function SteamAPI_ISteamUserStats_GetLeaderboardSortMethod(SteamInterface: ISteamUserStats; hSteamLeaderboard: SteamLeaderboard_t): ELeaderboardSortMethod; cdecl; external STEAMLIB;
function SteamAPI_ISteamUserStats_GetLeaderboardDisplayType(SteamInterface: ISteamUserStats; hSteamLeaderboard: SteamLeaderboard_t): ELeaderboardDisplayType; cdecl; external STEAMLIB;
function SteamAPI_ISteamUserStats_DownloadLeaderboardEntries(SteamInterface: ISteamUserStats; hSteamLeaderboard: SteamLeaderboard_t; eLeaderboardDataRequest: ELeaderboardDataRequest; nRangeStart: Longint; nRangeEnd: Longint): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamUserStats_DownloadLeaderboardEntriesForUsers(SteamInterface: ISteamUserStats; hSteamLeaderboard: SteamLeaderboard_t; prgUsers: PSteamID; cUsers: Longint): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamUserStats_GetDownloadedLeaderboardEntry(SteamInterface: ISteamUserStats; hSteamLeaderboardEntries: SteamLeaderboardEntries_t; index: Longint; pLeaderboardEntry: pLeaderboardEntry_t; pDetails: pint32; cDetailsMax: Longint): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUserStats_UploadLeaderboardScore(SteamInterface: ISteamUserStats; hSteamLeaderboard: SteamLeaderboard_t; eLeaderboardUploadScoreMethod: ELeaderboardUploadScoreMethod; nScore: int32; pScoreDetails: pint32; cScoreDetailsCount: Longint): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamUserStats_AttachLeaderboardUGC(SteamInterface: ISteamUserStats; hSteamLeaderboard: SteamLeaderboard_t; hUGC: UGCHandle_t): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamUserStats_GetNumberOfCurrentPlayers(SteamInterface: ISteamUserStats): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamUserStats_RequestGlobalAchievementPercentages(SteamInterface: ISteamUserStats): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamUserStats_GetMostAchievedAchievementInfo(SteamInterface: ISteamUserStats; pchName: PChar; unNameBufLen: uint32; pflPercent: psingle; pbAchieved: pboolean): Longint; cdecl; external STEAMLIB;
function SteamAPI_ISteamUserStats_GetNextMostAchievedAchievementInfo(SteamInterface: ISteamUserStats; iIteratorPrevious: Longint; pchName: PChar; unNameBufLen: uint32; pflPercent: psingle; pbAchieved: pboolean): Longint; cdecl; external STEAMLIB;
function SteamAPI_ISteamUserStats_GetAchievementAchievedPercent(SteamInterface: ISteamUserStats; pchName: PChar; pflPercent: psingle): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUserStats_RequestGlobalStats(SteamInterface: ISteamUserStats; nHistoryDays: Longint): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamUserStats_GetGlobalStatInt64(SteamInterface: ISteamUserStats; pchStatName: PChar; pData: pint64): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUserStats_GetGlobalStatDouble(SteamInterface: ISteamUserStats; pchStatName: PChar; pData: pdouble): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUserStats_GetGlobalStatHistoryInt64(SteamInterface: ISteamUserStats; pchStatName: PChar; pData: pint64; cubData: uint32): int32; cdecl; external STEAMLIB;
function SteamAPI_ISteamUserStats_GetGlobalStatHistoryDouble(SteamInterface: ISteamUserStats; pchStatName: PChar; pData: pdouble; cubData: uint32): int32; cdecl; external STEAMLIB;


function SteamAPI_SteamApps_v008(): ISteamApps; cdecl; external STEAMLIB;

function SteamAPI_ISteamApps_BIsSubscribed(SteamInterface: ISteamApps): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamApps_BIsLowViolence(SteamInterface: ISteamApps): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamApps_BIsCybercafe(SteamInterface: ISteamApps): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamApps_BIsVACBanned(SteamInterface: ISteamApps): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamApps_GetCurrentGameLanguage(SteamInterface: ISteamApps): PChar; cdecl; external STEAMLIB;
function SteamAPI_ISteamApps_GetAvailableGameLanguages(SteamInterface: ISteamApps): PChar; cdecl; external STEAMLIB;
function SteamAPI_ISteamApps_BIsSubscribedApp(SteamInterface: ISteamApps; appID: AppId_t): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamApps_BIsDlcInstalled(SteamInterface: ISteamApps; appID: AppId_t): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamApps_GetEarliestPurchaseUnixTime(SteamInterface: ISteamApps; nAppID: AppId_t): uint32; cdecl; external STEAMLIB;
function SteamAPI_ISteamApps_BIsSubscribedFromFreeWeekend(SteamInterface: ISteamApps): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamApps_GetDLCCount(SteamInterface: ISteamApps): Longint; cdecl; external STEAMLIB;
function SteamAPI_ISteamApps_BGetDLCDataByIndex(SteamInterface: ISteamApps; iDLC: Longint; pAppID: pAppId_t; pbAvailable: pboolean; pchName: PChar; cchNameBufferSize: Longint): Boolean; cdecl; external STEAMLIB;
procedure SteamAPI_ISteamApps_InstallDLC(SteamInterface: ISteamApps; nAppID: AppId_t); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamApps_UninstallDLC(SteamInterface: ISteamApps; nAppID: AppId_t); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamApps_RequestAppProofOfPurchaseKey(SteamInterface: ISteamApps; nAppID: AppId_t); cdecl; external STEAMLIB;
function SteamAPI_ISteamApps_GetCurrentBetaName(SteamInterface: ISteamApps; pchName: PChar; cchNameBufferSize: Longint): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamApps_MarkContentCorrupt(SteamInterface: ISteamApps; bMissingFilesOnly: Boolean): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamApps_GetInstalledDepots(SteamInterface: ISteamApps; appID: AppId_t; pvecDepots: pDepotId_t; cMaxDepots: uint32): uint32; cdecl; external STEAMLIB;
function SteamAPI_ISteamApps_GetAppInstallDir(SteamInterface: ISteamApps; appID: AppId_t; pchFolder: PChar; cchFolderBufferSize: uint32): uint32; cdecl; external STEAMLIB;
function SteamAPI_ISteamApps_BIsAppInstalled(SteamInterface: ISteamApps; appID: AppId_t): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamApps_GetAppOwner(SteamInterface: ISteamApps): TSteamID; cdecl; external STEAMLIB;
function SteamAPI_ISteamApps_GetLaunchQueryParam(SteamInterface: ISteamApps; pchKey: PChar): PChar; cdecl; external STEAMLIB;
function SteamAPI_ISteamApps_GetDlcDownloadProgress(SteamInterface: ISteamApps; nAppID: AppId_t; punBytesDownloaded: puint64; punBytesTotal: puint64): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamApps_GetAppBuildId(SteamInterface: ISteamApps): Longint; cdecl; external STEAMLIB;
procedure SteamAPI_ISteamApps_RequestAllProofOfPurchaseKeys(SteamInterface: ISteamApps); cdecl; external STEAMLIB;
function SteamAPI_ISteamApps_GetFileDetails(SteamInterface: ISteamApps; pszFileName: PChar): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamApps_GetLaunchCommandLine(SteamInterface: ISteamApps; pszCommandLine: PChar; cubCommandLine: Longint): Longint; cdecl; external STEAMLIB;
function SteamAPI_ISteamApps_BIsSubscribedFromFamilySharing(SteamInterface: ISteamApps): Boolean; cdecl; external STEAMLIB;


function SteamAPI_SteamNetworking_v006(): ISteamNetworking; cdecl; external STEAMLIB;

function SteamAPI_ISteamNetworking_SendP2PPacket(SteamInterface: ISteamNetworking; steamIDRemote: TSteamID; pubData: Pointer; cubData: uint32; eP2PSendType: EP2PSend; nChannel: Longint): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworking_IsP2PPacketAvailable(SteamInterface: ISteamNetworking; pcubMsgSize: puint32; nChannel: Longint): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworking_ReadP2PPacket(SteamInterface: ISteamNetworking; pubDest: Pointer; cubDest: uint32; pcubMsgSize: puint32; psteamIDRemote: PSteamID; nChannel: Longint): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworking_AcceptP2PSessionWithUser(SteamInterface: ISteamNetworking; steamIDRemote: TSteamID): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworking_CloseP2PSessionWithUser(SteamInterface: ISteamNetworking; steamIDRemote: TSteamID): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworking_CloseP2PChannelWithUser(SteamInterface: ISteamNetworking; steamIDRemote: TSteamID; nChannel: Longint): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworking_GetP2PSessionState(SteamInterface: ISteamNetworking; steamIDRemote: TSteamID; pConnectionState: pP2PSessionState_t): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworking_AllowP2PPacketRelay(SteamInterface: ISteamNetworking; bAllow: Boolean): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworking_CreateListenSocket(SteamInterface: ISteamNetworking; nVirtualP2PPort: Longint; nIP: SteamIPAddress_t; nPort: uint16; bAllowUseOfPacketRelay: Boolean): SNetListenSocket_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworking_CreateP2PConnectionSocket(SteamInterface: ISteamNetworking; steamIDTarget: TSteamID; nVirtualPort: Longint; nTimeoutSec: Longint; bAllowUseOfPacketRelay: Boolean): SNetSocket_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworking_CreateConnectionSocket(SteamInterface: ISteamNetworking; nIP: SteamIPAddress_t; nPort: uint16; nTimeoutSec: Longint): SNetSocket_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworking_DestroySocket(SteamInterface: ISteamNetworking; hSocket: SNetSocket_t; bNotifyRemoteEnd: Boolean): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworking_DestroyListenSocket(SteamInterface: ISteamNetworking; hSocket: SNetListenSocket_t; bNotifyRemoteEnd: Boolean): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworking_SendDataOnSocket(SteamInterface: ISteamNetworking; hSocket: SNetSocket_t; pubData: Pointer; cubData: uint32; bReliable: Boolean): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworking_IsDataAvailableOnSocket(SteamInterface: ISteamNetworking; hSocket: SNetSocket_t; pcubMsgSize: puint32): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworking_RetrieveDataFromSocket(SteamInterface: ISteamNetworking; hSocket: SNetSocket_t; pubDest: Pointer; cubDest: uint32; pcubMsgSize: puint32): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworking_IsDataAvailable(SteamInterface: ISteamNetworking; hListenSocket: SNetListenSocket_t; pcubMsgSize: puint32; phSocket: pSNetSocket_t): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworking_RetrieveData(SteamInterface: ISteamNetworking; hListenSocket: SNetListenSocket_t; pubDest: Pointer; cubDest: uint32; pcubMsgSize: puint32; phSocket: pSNetSocket_t): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworking_GetSocketInfo(SteamInterface: ISteamNetworking; hSocket: SNetSocket_t; pSteamIDRemote: PSteamID; peSocketStatus: PInteger; punIPRemote: pSteamIPAddress_t; punPortRemote: puint16): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworking_GetListenSocketInfo(SteamInterface: ISteamNetworking; hListenSocket: SNetListenSocket_t; pnIP: pSteamIPAddress_t; pnPort: puint16): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworking_GetSocketConnectionType(SteamInterface: ISteamNetworking; hSocket: SNetSocket_t): ESNetSocketConnectionType; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworking_GetMaxPacketSize(SteamInterface: ISteamNetworking; hSocket: SNetSocket_t): Longint; cdecl; external STEAMLIB;


function SteamAPI_SteamScreenshots_v003(): ISteamScreenshots; cdecl; external STEAMLIB;

function SteamAPI_ISteamScreenshots_WriteScreenshot(SteamInterface: ISteamScreenshots; pubRGB: Pointer; cubRGB: uint32; nWidth: Longint; nHeight: Longint): ScreenshotHandle; cdecl; external STEAMLIB;
function SteamAPI_ISteamScreenshots_AddScreenshotToLibrary(SteamInterface: ISteamScreenshots; pchFilename: PChar; pchThumbnailFilename: PChar; nWidth: Longint; nHeight: Longint): ScreenshotHandle; cdecl; external STEAMLIB;
procedure SteamAPI_ISteamScreenshots_TriggerScreenshot(SteamInterface: ISteamScreenshots); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamScreenshots_HookScreenshots(SteamInterface: ISteamScreenshots; bHook: Boolean); cdecl; external STEAMLIB;
function SteamAPI_ISteamScreenshots_SetLocation(SteamInterface: ISteamScreenshots; hScreenshot: ScreenshotHandle; pchLocation: PChar): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamScreenshots_TagUser(SteamInterface: ISteamScreenshots; hScreenshot: ScreenshotHandle; steamID: TSteamID): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamScreenshots_TagPublishedFile(SteamInterface: ISteamScreenshots; hScreenshot: ScreenshotHandle; unPublishedFileID: PublishedFileId_t): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamScreenshots_IsScreenshotsHooked(SteamInterface: ISteamScreenshots): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamScreenshots_AddVRScreenshotToLibrary(SteamInterface: ISteamScreenshots; eType: EVRScreenshotType; pchFilename: PChar; pchVRFilename: PChar): ScreenshotHandle; cdecl; external STEAMLIB;


function SteamAPI_SteamMusic_v001(): ISteamMusic; cdecl; external STEAMLIB;

function SteamAPI_ISteamMusic_BIsEnabled(SteamInterface: ISteamMusic): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamMusic_BIsPlaying(SteamInterface: ISteamMusic): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamMusic_GetPlaybackStatus(SteamInterface: ISteamMusic): AudioPlayback_Status; cdecl; external STEAMLIB;
procedure SteamAPI_ISteamMusic_Play(SteamInterface: ISteamMusic); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamMusic_Pause(SteamInterface: ISteamMusic); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamMusic_PlayPrevious(SteamInterface: ISteamMusic); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamMusic_PlayNext(SteamInterface: ISteamMusic); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamMusic_SetVolume(SteamInterface: ISteamMusic; flVolume: Single); cdecl; external STEAMLIB;
function SteamAPI_ISteamMusic_GetVolume(SteamInterface: ISteamMusic): Single; cdecl; external STEAMLIB;


function SteamAPI_SteamMusicRemote_v001(): ISteamMusicRemote; cdecl; external STEAMLIB;

function SteamAPI_ISteamMusicRemote_RegisterSteamMusicRemote(SteamInterface: ISteamMusicRemote; pchName: PChar): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamMusicRemote_DeregisterSteamMusicRemote(SteamInterface: ISteamMusicRemote): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamMusicRemote_BIsCurrentMusicRemote(SteamInterface: ISteamMusicRemote): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamMusicRemote_BActivationSuccess(SteamInterface: ISteamMusicRemote; bValue: Boolean): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamMusicRemote_SetDisplayName(SteamInterface: ISteamMusicRemote; pchDisplayName: PChar): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamMusicRemote_SetPNGIcon_64x64(SteamInterface: ISteamMusicRemote; pvBuffer: Pointer; cbBufferLength: uint32): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamMusicRemote_EnablePlayPrevious(SteamInterface: ISteamMusicRemote; bValue: Boolean): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamMusicRemote_EnablePlayNext(SteamInterface: ISteamMusicRemote; bValue: Boolean): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamMusicRemote_EnableShuffled(SteamInterface: ISteamMusicRemote; bValue: Boolean): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamMusicRemote_EnableLooped(SteamInterface: ISteamMusicRemote; bValue: Boolean): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamMusicRemote_EnableQueue(SteamInterface: ISteamMusicRemote; bValue: Boolean): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamMusicRemote_EnablePlaylists(SteamInterface: ISteamMusicRemote; bValue: Boolean): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamMusicRemote_UpdatePlaybackStatus(SteamInterface: ISteamMusicRemote; nStatus: AudioPlayback_Status): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamMusicRemote_UpdateShuffled(SteamInterface: ISteamMusicRemote; bValue: Boolean): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamMusicRemote_UpdateLooped(SteamInterface: ISteamMusicRemote; bValue: Boolean): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamMusicRemote_UpdateVolume(SteamInterface: ISteamMusicRemote; flValue: Single): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamMusicRemote_CurrentEntryWillChange(SteamInterface: ISteamMusicRemote): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamMusicRemote_CurrentEntryIsAvailable(SteamInterface: ISteamMusicRemote; bAvailable: Boolean): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamMusicRemote_UpdateCurrentEntryText(SteamInterface: ISteamMusicRemote; pchText: PChar): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamMusicRemote_UpdateCurrentEntryElapsedSeconds(SteamInterface: ISteamMusicRemote; nValue: Longint): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamMusicRemote_UpdateCurrentEntryCoverArt(SteamInterface: ISteamMusicRemote; pvBuffer: Pointer; cbBufferLength: uint32): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamMusicRemote_CurrentEntryDidChange(SteamInterface: ISteamMusicRemote): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamMusicRemote_QueueWillChange(SteamInterface: ISteamMusicRemote): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamMusicRemote_ResetQueueEntries(SteamInterface: ISteamMusicRemote): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamMusicRemote_SetQueueEntry(SteamInterface: ISteamMusicRemote; nID: Longint; nPosition: Longint; pchEntryText: PChar): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamMusicRemote_SetCurrentQueueEntry(SteamInterface: ISteamMusicRemote; nID: Longint): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamMusicRemote_QueueDidChange(SteamInterface: ISteamMusicRemote): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamMusicRemote_PlaylistWillChange(SteamInterface: ISteamMusicRemote): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamMusicRemote_ResetPlaylistEntries(SteamInterface: ISteamMusicRemote): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamMusicRemote_SetPlaylistEntry(SteamInterface: ISteamMusicRemote; nID: Longint; nPosition: Longint; pchEntryText: PChar): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamMusicRemote_SetCurrentPlaylistEntry(SteamInterface: ISteamMusicRemote; nID: Longint): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamMusicRemote_PlaylistDidChange(SteamInterface: ISteamMusicRemote): Boolean; cdecl; external STEAMLIB;


function SteamAPI_SteamHTTP_v003(): ISteamHTTP; cdecl; external STEAMLIB;

function SteamAPI_ISteamHTTP_CreateHTTPRequest(SteamInterface: ISteamHTTP; eHTTPRequestMethod: EHTTPMethod; pchAbsoluteURL: PChar): HTTPRequestHandle; cdecl; external STEAMLIB;
function SteamAPI_ISteamHTTP_SetHTTPRequestContextValue(SteamInterface: ISteamHTTP; hRequest: HTTPRequestHandle; ulContextValue: uint64): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamHTTP_SetHTTPRequestNetworkActivityTimeout(SteamInterface: ISteamHTTP; hRequest: HTTPRequestHandle; unTimeoutSeconds: uint32): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamHTTP_SetHTTPRequestHeaderValue(SteamInterface: ISteamHTTP; hRequest: HTTPRequestHandle; pchHeaderName: PChar; pchHeaderValue: PChar): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamHTTP_SetHTTPRequestGetOrPostParameter(SteamInterface: ISteamHTTP; hRequest: HTTPRequestHandle; pchParamName: PChar; pchParamValue: PChar): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamHTTP_SendHTTPRequest(SteamInterface: ISteamHTTP; hRequest: HTTPRequestHandle; pCallHandle: pSteamAPICall_t): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamHTTP_SendHTTPRequestAndStreamResponse(SteamInterface: ISteamHTTP; hRequest: HTTPRequestHandle; pCallHandle: pSteamAPICall_t): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamHTTP_DeferHTTPRequest(SteamInterface: ISteamHTTP; hRequest: HTTPRequestHandle): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamHTTP_PrioritizeHTTPRequest(SteamInterface: ISteamHTTP; hRequest: HTTPRequestHandle): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamHTTP_GetHTTPResponseHeaderSize(SteamInterface: ISteamHTTP; hRequest: HTTPRequestHandle; pchHeaderName: PChar; unResponseHeaderSize: puint32): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamHTTP_GetHTTPResponseHeaderValue(SteamInterface: ISteamHTTP; hRequest: HTTPRequestHandle; pchHeaderName: PChar; pHeaderValueBuffer: puint8; unBufferSize: uint32): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamHTTP_GetHTTPResponseBodySize(SteamInterface: ISteamHTTP; hRequest: HTTPRequestHandle; unBodySize: puint32): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamHTTP_GetHTTPResponseBodyData(SteamInterface: ISteamHTTP; hRequest: HTTPRequestHandle; pBodyDataBuffer: puint8; unBufferSize: uint32): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamHTTP_GetHTTPStreamingResponseBodyData(SteamInterface: ISteamHTTP; hRequest: HTTPRequestHandle; cOffset: uint32; pBodyDataBuffer: puint8; unBufferSize: uint32): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamHTTP_ReleaseHTTPRequest(SteamInterface: ISteamHTTP; hRequest: HTTPRequestHandle): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamHTTP_GetHTTPDownloadProgressPct(SteamInterface: ISteamHTTP; hRequest: HTTPRequestHandle; pflPercentOut: psingle): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamHTTP_SetHTTPRequestRawPostBody(SteamInterface: ISteamHTTP; hRequest: HTTPRequestHandle; pchContentType: PChar; pubBody: puint8; unBodyLen: uint32): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamHTTP_CreateCookieContainer(SteamInterface: ISteamHTTP; bAllowResponsesToModify: Boolean): HTTPCookieContainerHandle; cdecl; external STEAMLIB;
function SteamAPI_ISteamHTTP_ReleaseCookieContainer(SteamInterface: ISteamHTTP; hCookieContainer: HTTPCookieContainerHandle): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamHTTP_SetCookie(SteamInterface: ISteamHTTP; hCookieContainer: HTTPCookieContainerHandle; pchHost: PChar; pchUrl: PChar; pchCookie: PChar): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamHTTP_SetHTTPRequestCookieContainer(SteamInterface: ISteamHTTP; hRequest: HTTPRequestHandle; hCookieContainer: HTTPCookieContainerHandle): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamHTTP_SetHTTPRequestUserAgentInfo(SteamInterface: ISteamHTTP; hRequest: HTTPRequestHandle; pchUserAgentInfo: PChar): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamHTTP_SetHTTPRequestRequiresVerifiedCertificate(SteamInterface: ISteamHTTP; hRequest: HTTPRequestHandle; bRequireVerifiedCertificate: Boolean): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamHTTP_SetHTTPRequestAbsoluteTimeoutMS(SteamInterface: ISteamHTTP; hRequest: HTTPRequestHandle; unMilliseconds: uint32): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamHTTP_GetHTTPRequestWasTimedOut(SteamInterface: ISteamHTTP; hRequest: HTTPRequestHandle; pbWasTimedOut: pboolean): Boolean; cdecl; external STEAMLIB;


function SteamAPI_SteamInput_v001(): ISteamInput; cdecl; external STEAMLIB;

function SteamAPI_ISteamInput_Init(SteamInterface: ISteamInput): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamInput_Shutdown(SteamInterface: ISteamInput): Boolean; cdecl; external STEAMLIB;
procedure SteamAPI_ISteamInput_RunFrame(SteamInterface: ISteamInput); cdecl; external STEAMLIB;
function SteamAPI_ISteamInput_GetConnectedControllers(SteamInterface: ISteamInput; handlesOut: pInputHandle_t): Longint; cdecl; external STEAMLIB;
function SteamAPI_ISteamInput_GetActionSetHandle(SteamInterface: ISteamInput; pszActionSetName: PChar): InputActionSetHandle_t; cdecl; external STEAMLIB;
procedure SteamAPI_ISteamInput_ActivateActionSet(SteamInterface: ISteamInput; inputHandle: InputHandle_t; actionSetHandle: InputActionSetHandle_t); cdecl; external STEAMLIB;
function SteamAPI_ISteamInput_GetCurrentActionSet(SteamInterface: ISteamInput; inputHandle: InputHandle_t): InputActionSetHandle_t; cdecl; external STEAMLIB;
procedure SteamAPI_ISteamInput_ActivateActionSetLayer(SteamInterface: ISteamInput; inputHandle: InputHandle_t; actionSetLayerHandle: InputActionSetHandle_t); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamInput_DeactivateActionSetLayer(SteamInterface: ISteamInput; inputHandle: InputHandle_t; actionSetLayerHandle: InputActionSetHandle_t); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamInput_DeactivateAllActionSetLayers(SteamInterface: ISteamInput; inputHandle: InputHandle_t); cdecl; external STEAMLIB;
function SteamAPI_ISteamInput_GetActiveActionSetLayers(SteamInterface: ISteamInput; inputHandle: InputHandle_t; handlesOut: pInputActionSetHandle_t): Longint; cdecl; external STEAMLIB;
function SteamAPI_ISteamInput_GetDigitalActionHandle(SteamInterface: ISteamInput; pszActionName: PChar): InputDigitalActionHandle_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamInput_GetDigitalActionData(SteamInterface: ISteamInput; inputHandle: InputHandle_t; digitalActionHandle: InputDigitalActionHandle_t): InputDigitalActionData_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamInput_GetDigitalActionOrigins(SteamInterface: ISteamInput; inputHandle: InputHandle_t; actionSetHandle: InputActionSetHandle_t; digitalActionHandle: InputDigitalActionHandle_t; originsOut: EInputActionOrigin): Longint; cdecl; external STEAMLIB;
function SteamAPI_ISteamInput_GetAnalogActionHandle(SteamInterface: ISteamInput; pszActionName: PChar): InputAnalogActionHandle_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamInput_GetAnalogActionData(SteamInterface: ISteamInput; inputHandle: InputHandle_t; analogActionHandle: InputAnalogActionHandle_t): InputAnalogActionData_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamInput_GetAnalogActionOrigins(SteamInterface: ISteamInput; inputHandle: InputHandle_t; actionSetHandle: InputActionSetHandle_t; analogActionHandle: InputAnalogActionHandle_t; originsOut: EInputActionOrigin): Longint; cdecl; external STEAMLIB;
function SteamAPI_ISteamInput_GetGlyphForActionOrigin(SteamInterface: ISteamInput; eOrigin: EInputActionOrigin): PChar; cdecl; external STEAMLIB;
function SteamAPI_ISteamInput_GetStringForActionOrigin(SteamInterface: ISteamInput; eOrigin: EInputActionOrigin): PChar; cdecl; external STEAMLIB;
procedure SteamAPI_ISteamInput_StopAnalogActionMomentum(SteamInterface: ISteamInput; inputHandle: InputHandle_t; eAction: InputAnalogActionHandle_t); cdecl; external STEAMLIB;
function SteamAPI_ISteamInput_GetMotionData(SteamInterface: ISteamInput; inputHandle: InputHandle_t): InputMotionData_t; cdecl; external STEAMLIB;
procedure SteamAPI_ISteamInput_TriggerVibration(SteamInterface: ISteamInput; inputHandle: InputHandle_t; usLeftSpeed: Word; usRightSpeed: Word); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamInput_SetLEDColor(SteamInterface: ISteamInput; inputHandle: InputHandle_t; nColorR: uint8; nColorG: uint8; nColorB: uint8; nFlags: Cardinal); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamInput_TriggerHapticPulse(SteamInterface: ISteamInput; inputHandle: InputHandle_t; eTargetPad: ESteamControllerPad; usDurationMicroSec: Word); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamInput_TriggerRepeatedHapticPulse(SteamInterface: ISteamInput; inputHandle: InputHandle_t; eTargetPad: ESteamControllerPad; usDurationMicroSec: Word; usOffMicroSec: Word; unRepeat: Word; nFlags: Cardinal); cdecl; external STEAMLIB;
function SteamAPI_ISteamInput_ShowBindingPanel(SteamInterface: ISteamInput; inputHandle: InputHandle_t): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamInput_GetInputTypeForHandle(SteamInterface: ISteamInput; inputHandle: InputHandle_t): ESteamInputType; cdecl; external STEAMLIB;
function SteamAPI_ISteamInput_GetControllerForGamepadIndex(SteamInterface: ISteamInput; nIndex: Longint): InputHandle_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamInput_GetGamepadIndexForController(SteamInterface: ISteamInput; ulinputHandle: InputHandle_t): Longint; cdecl; external STEAMLIB;
function SteamAPI_ISteamInput_GetStringForXboxOrigin(SteamInterface: ISteamInput; eOrigin: EXboxOrigin): PChar; cdecl; external STEAMLIB;
function SteamAPI_ISteamInput_GetGlyphForXboxOrigin(SteamInterface: ISteamInput; eOrigin: EXboxOrigin): PChar; cdecl; external STEAMLIB;
function SteamAPI_ISteamInput_GetActionOriginFromXboxOrigin(SteamInterface: ISteamInput; inputHandle: InputHandle_t; eOrigin: EXboxOrigin): EInputActionOrigin; cdecl; external STEAMLIB;
function SteamAPI_ISteamInput_TranslateActionOrigin(SteamInterface: ISteamInput; eDestinationInputType: ESteamInputType; eSourceOrigin: EInputActionOrigin): EInputActionOrigin; cdecl; external STEAMLIB;
function SteamAPI_ISteamInput_GetDeviceBindingRevision(SteamInterface: ISteamInput; inputHandle: InputHandle_t; pMajor: PInteger; pMinor: PInteger): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamInput_GetRemotePlaySessionID(SteamInterface: ISteamInput; inputHandle: InputHandle_t): uint32; cdecl; external STEAMLIB;


function SteamAPI_SteamController_v007(): ISteamController; cdecl; external STEAMLIB;

function SteamAPI_ISteamController_Init(SteamInterface: ISteamController): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamController_Shutdown(SteamInterface: ISteamController): Boolean; cdecl; external STEAMLIB;
procedure SteamAPI_ISteamController_RunFrame(SteamInterface: ISteamController); cdecl; external STEAMLIB;
function SteamAPI_ISteamController_GetConnectedControllers(SteamInterface: ISteamController; handlesOut: pControllerHandle_t): Longint; cdecl; external STEAMLIB;
function SteamAPI_ISteamController_GetActionSetHandle(SteamInterface: ISteamController; pszActionSetName: PChar): ControllerActionSetHandle_t; cdecl; external STEAMLIB;
procedure SteamAPI_ISteamController_ActivateActionSet(SteamInterface: ISteamController; controllerHandle: ControllerHandle_t; actionSetHandle: ControllerActionSetHandle_t); cdecl; external STEAMLIB;
function SteamAPI_ISteamController_GetCurrentActionSet(SteamInterface: ISteamController; controllerHandle: ControllerHandle_t): ControllerActionSetHandle_t; cdecl; external STEAMLIB;
procedure SteamAPI_ISteamController_ActivateActionSetLayer(SteamInterface: ISteamController; controllerHandle: ControllerHandle_t; actionSetLayerHandle: ControllerActionSetHandle_t); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamController_DeactivateActionSetLayer(SteamInterface: ISteamController; controllerHandle: ControllerHandle_t; actionSetLayerHandle: ControllerActionSetHandle_t); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamController_DeactivateAllActionSetLayers(SteamInterface: ISteamController; controllerHandle: ControllerHandle_t); cdecl; external STEAMLIB;
function SteamAPI_ISteamController_GetActiveActionSetLayers(SteamInterface: ISteamController; controllerHandle: ControllerHandle_t; handlesOut: pControllerActionSetHandle_t): Longint; cdecl; external STEAMLIB;
function SteamAPI_ISteamController_GetDigitalActionHandle(SteamInterface: ISteamController; pszActionName: PChar): ControllerDigitalActionHandle_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamController_GetDigitalActionData(SteamInterface: ISteamController; controllerHandle: ControllerHandle_t; digitalActionHandle: ControllerDigitalActionHandle_t): InputDigitalActionData_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamController_GetDigitalActionOrigins(SteamInterface: ISteamController; controllerHandle: ControllerHandle_t; actionSetHandle: ControllerActionSetHandle_t; digitalActionHandle: ControllerDigitalActionHandle_t; originsOut: EControllerActionOrigin): Longint; cdecl; external STEAMLIB;
function SteamAPI_ISteamController_GetAnalogActionHandle(SteamInterface: ISteamController; pszActionName: PChar): ControllerAnalogActionHandle_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamController_GetAnalogActionData(SteamInterface: ISteamController; controllerHandle: ControllerHandle_t; analogActionHandle: ControllerAnalogActionHandle_t): InputAnalogActionData_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamController_GetAnalogActionOrigins(SteamInterface: ISteamController; controllerHandle: ControllerHandle_t; actionSetHandle: ControllerActionSetHandle_t; analogActionHandle: ControllerAnalogActionHandle_t; originsOut: EControllerActionOrigin): Longint; cdecl; external STEAMLIB;
function SteamAPI_ISteamController_GetGlyphForActionOrigin(SteamInterface: ISteamController; eOrigin: EControllerActionOrigin): PChar; cdecl; external STEAMLIB;
function SteamAPI_ISteamController_GetStringForActionOrigin(SteamInterface: ISteamController; eOrigin: EControllerActionOrigin): PChar; cdecl; external STEAMLIB;
procedure SteamAPI_ISteamController_StopAnalogActionMomentum(SteamInterface: ISteamController; controllerHandle: ControllerHandle_t; eAction: ControllerAnalogActionHandle_t); cdecl; external STEAMLIB;
function SteamAPI_ISteamController_GetMotionData(SteamInterface: ISteamController; controllerHandle: ControllerHandle_t): InputMotionData_t; cdecl; external STEAMLIB;
procedure SteamAPI_ISteamController_TriggerHapticPulse(SteamInterface: ISteamController; controllerHandle: ControllerHandle_t; eTargetPad: ESteamControllerPad; usDurationMicroSec: Word); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamController_TriggerRepeatedHapticPulse(SteamInterface: ISteamController; controllerHandle: ControllerHandle_t; eTargetPad: ESteamControllerPad; usDurationMicroSec: Word; usOffMicroSec: Word; unRepeat: Word; nFlags: Cardinal); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamController_TriggerVibration(SteamInterface: ISteamController; controllerHandle: ControllerHandle_t; usLeftSpeed: Word; usRightSpeed: Word); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamController_SetLEDColor(SteamInterface: ISteamController; controllerHandle: ControllerHandle_t; nColorR: uint8; nColorG: uint8; nColorB: uint8; nFlags: Cardinal); cdecl; external STEAMLIB;
function SteamAPI_ISteamController_ShowBindingPanel(SteamInterface: ISteamController; controllerHandle: ControllerHandle_t): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamController_GetInputTypeForHandle(SteamInterface: ISteamController; controllerHandle: ControllerHandle_t): ESteamInputType; cdecl; external STEAMLIB;
function SteamAPI_ISteamController_GetControllerForGamepadIndex(SteamInterface: ISteamController; nIndex: Longint): ControllerHandle_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamController_GetGamepadIndexForController(SteamInterface: ISteamController; ulControllerHandle: ControllerHandle_t): Longint; cdecl; external STEAMLIB;
function SteamAPI_ISteamController_GetStringForXboxOrigin(SteamInterface: ISteamController; eOrigin: EXboxOrigin): PChar; cdecl; external STEAMLIB;
function SteamAPI_ISteamController_GetGlyphForXboxOrigin(SteamInterface: ISteamController; eOrigin: EXboxOrigin): PChar; cdecl; external STEAMLIB;
function SteamAPI_ISteamController_GetActionOriginFromXboxOrigin(SteamInterface: ISteamController; controllerHandle: ControllerHandle_t; eOrigin: EXboxOrigin): EControllerActionOrigin; cdecl; external STEAMLIB;
function SteamAPI_ISteamController_TranslateActionOrigin(SteamInterface: ISteamController; eDestinationInputType: ESteamInputType; eSourceOrigin: EControllerActionOrigin): EControllerActionOrigin; cdecl; external STEAMLIB;
function SteamAPI_ISteamController_GetControllerBindingRevision(SteamInterface: ISteamController; controllerHandle: ControllerHandle_t; pMajor: PInteger; pMinor: PInteger): Boolean; cdecl; external STEAMLIB;


function SteamAPI_SteamUGC_v014(): ISteamUGC; cdecl; external STEAMLIB;
function SteamAPI_SteamGameServerUGC_v014(): ISteamUGC; cdecl; external STEAMLIB;

function SteamAPI_ISteamUGC_CreateQueryUserUGCRequest(SteamInterface: ISteamUGC; unAccountID: AccountID_t; eListType: EUserUGCList; eMatchingUGCType: EUGCMatchingUGCType; eSortOrder: EUserUGCListSortOrder; nCreatorAppID: AppId_t; nConsumerAppID: AppId_t; unPage: uint32): UGCQueryHandle_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_CreateQueryAllUGCRequestPage(SteamInterface: ISteamUGC; eQueryType: EUGCQuery; eMatchingeMatchingUGCTypeFileType: EUGCMatchingUGCType; nCreatorAppID: AppId_t; nConsumerAppID: AppId_t; unPage: uint32): UGCQueryHandle_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_CreateQueryAllUGCRequestCursor(SteamInterface: ISteamUGC; eQueryType: EUGCQuery; eMatchingeMatchingUGCTypeFileType: EUGCMatchingUGCType; nCreatorAppID: AppId_t; nConsumerAppID: AppId_t; pchCursor: PChar): UGCQueryHandle_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_CreateQueryUGCDetailsRequest(SteamInterface: ISteamUGC; pvecPublishedFileID: pPublishedFileId_t; unNumPublishedFileIDs: uint32): UGCQueryHandle_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_SendQueryUGCRequest(SteamInterface: ISteamUGC; handle: UGCQueryHandle_t): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_GetQueryUGCResult(SteamInterface: ISteamUGC; handle: UGCQueryHandle_t; index: uint32; pDetails: pSteamUGCDetails_t): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_GetQueryUGCPreviewURL(SteamInterface: ISteamUGC; handle: UGCQueryHandle_t; index: uint32; pchURL: PChar; cchURLSize: uint32): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_GetQueryUGCMetadata(SteamInterface: ISteamUGC; handle: UGCQueryHandle_t; index: uint32; pchMetadata: PChar; cchMetadatasize: uint32): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_GetQueryUGCChildren(SteamInterface: ISteamUGC; handle: UGCQueryHandle_t; index: uint32; pvecPublishedFileID: pPublishedFileId_t; cMaxEntries: uint32): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_GetQueryUGCStatistic(SteamInterface: ISteamUGC; handle: UGCQueryHandle_t; index: uint32; eStatType: EItemStatistic; pStatValue: puint64): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_GetQueryUGCNumAdditionalPreviews(SteamInterface: ISteamUGC; handle: UGCQueryHandle_t; index: uint32): uint32; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_GetQueryUGCAdditionalPreview(SteamInterface: ISteamUGC; handle: UGCQueryHandle_t; index: uint32; previewIndex: uint32; pchURLOrVideoID: PChar; cchURLSize: uint32; pchOriginalFileName: PChar; cchOriginalFileNameSize: uint32; pPreviewType: EItemPreviewType): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_GetQueryUGCNumKeyValueTags(SteamInterface: ISteamUGC; handle: UGCQueryHandle_t; index: uint32): uint32; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_GetQueryUGCKeyValueTag(SteamInterface: ISteamUGC; handle: UGCQueryHandle_t; index: uint32; keyValueTagIndex: uint32; pchKey: PChar; cchKeySize: uint32; pchValue: PChar; cchValueSize: uint32): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_GetQueryFirstUGCKeyValueTag(SteamInterface: ISteamUGC; handle: UGCQueryHandle_t; index: uint32; pchKey: PChar; pchValue: PChar; cchValueSize: uint32): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_ReleaseQueryUGCRequest(SteamInterface: ISteamUGC; handle: UGCQueryHandle_t): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_AddRequiredTag(SteamInterface: ISteamUGC; handle: UGCQueryHandle_t; pTagName: PChar): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_AddRequiredTagGroup(SteamInterface: ISteamUGC; handle: UGCQueryHandle_t; pTagGroups: pSteamParamStringArray_t): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_AddExcludedTag(SteamInterface: ISteamUGC; handle: UGCQueryHandle_t; pTagName: PChar): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_SetReturnOnlyIDs(SteamInterface: ISteamUGC; handle: UGCQueryHandle_t; bReturnOnlyIDs: Boolean): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_SetReturnKeyValueTags(SteamInterface: ISteamUGC; handle: UGCQueryHandle_t; bReturnKeyValueTags: Boolean): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_SetReturnLongDescription(SteamInterface: ISteamUGC; handle: UGCQueryHandle_t; bReturnLongDescription: Boolean): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_SetReturnMetadata(SteamInterface: ISteamUGC; handle: UGCQueryHandle_t; bReturnMetadata: Boolean): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_SetReturnChildren(SteamInterface: ISteamUGC; handle: UGCQueryHandle_t; bReturnChildren: Boolean): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_SetReturnAdditionalPreviews(SteamInterface: ISteamUGC; handle: UGCQueryHandle_t; bReturnAdditionalPreviews: Boolean): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_SetReturnTotalOnly(SteamInterface: ISteamUGC; handle: UGCQueryHandle_t; bReturnTotalOnly: Boolean): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_SetReturnPlaytimeStats(SteamInterface: ISteamUGC; handle: UGCQueryHandle_t; unDays: uint32): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_SetLanguage(SteamInterface: ISteamUGC; handle: UGCQueryHandle_t; pchLanguage: PChar): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_SetAllowCachedResponse(SteamInterface: ISteamUGC; handle: UGCQueryHandle_t; unMaxAgeSeconds: uint32): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_SetCloudFileNameFilter(SteamInterface: ISteamUGC; handle: UGCQueryHandle_t; pMatchCloudFileName: PChar): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_SetMatchAnyTag(SteamInterface: ISteamUGC; handle: UGCQueryHandle_t; bMatchAnyTag: Boolean): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_SetSearchText(SteamInterface: ISteamUGC; handle: UGCQueryHandle_t; pSearchText: PChar): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_SetRankedByTrendDays(SteamInterface: ISteamUGC; handle: UGCQueryHandle_t; unDays: uint32): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_AddRequiredKeyValueTag(SteamInterface: ISteamUGC; handle: UGCQueryHandle_t; pKey: PChar; pValue: PChar): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_RequestUGCDetails(SteamInterface: ISteamUGC; nPublishedFileID: PublishedFileId_t; unMaxAgeSeconds: uint32): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_CreateItem(SteamInterface: ISteamUGC; nConsumerAppId: AppId_t; eFileType: EWorkshopFileType): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_StartItemUpdate(SteamInterface: ISteamUGC; nConsumerAppId: AppId_t; nPublishedFileID: PublishedFileId_t): UGCUpdateHandle_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_SetItemTitle(SteamInterface: ISteamUGC; handle: UGCUpdateHandle_t; pchTitle: PChar): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_SetItemDescription(SteamInterface: ISteamUGC; handle: UGCUpdateHandle_t; pchDescription: PChar): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_SetItemUpdateLanguage(SteamInterface: ISteamUGC; handle: UGCUpdateHandle_t; pchLanguage: PChar): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_SetItemMetadata(SteamInterface: ISteamUGC; handle: UGCUpdateHandle_t; pchMetaData: PChar): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_SetItemVisibility(SteamInterface: ISteamUGC; handle: UGCUpdateHandle_t; eVisibility: ERemoteStoragePublishedFileVisibility): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_SetItemTags(SteamInterface: ISteamUGC; updateHandle: UGCUpdateHandle_t; pTags: pSteamParamStringArray_t): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_SetItemContent(SteamInterface: ISteamUGC; handle: UGCUpdateHandle_t; pszContentFolder: PChar): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_SetItemPreview(SteamInterface: ISteamUGC; handle: UGCUpdateHandle_t; pszPreviewFile: PChar): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_SetAllowLegacyUpload(SteamInterface: ISteamUGC; handle: UGCUpdateHandle_t; bAllowLegacyUpload: Boolean): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_RemoveAllItemKeyValueTags(SteamInterface: ISteamUGC; handle: UGCUpdateHandle_t): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_RemoveItemKeyValueTags(SteamInterface: ISteamUGC; handle: UGCUpdateHandle_t; pchKey: PChar): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_AddItemKeyValueTag(SteamInterface: ISteamUGC; handle: UGCUpdateHandle_t; pchKey: PChar; pchValue: PChar): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_AddItemPreviewFile(SteamInterface: ISteamUGC; handle: UGCUpdateHandle_t; pszPreviewFile: PChar; _type: EItemPreviewType): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_AddItemPreviewVideo(SteamInterface: ISteamUGC; handle: UGCUpdateHandle_t; pszVideoID: PChar): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_UpdateItemPreviewFile(SteamInterface: ISteamUGC; handle: UGCUpdateHandle_t; index: uint32; pszPreviewFile: PChar): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_UpdateItemPreviewVideo(SteamInterface: ISteamUGC; handle: UGCUpdateHandle_t; index: uint32; pszVideoID: PChar): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_RemoveItemPreview(SteamInterface: ISteamUGC; handle: UGCUpdateHandle_t; index: uint32): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_SubmitItemUpdate(SteamInterface: ISteamUGC; handle: UGCUpdateHandle_t; pchChangeNote: PChar): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_GetItemUpdateProgress(SteamInterface: ISteamUGC; handle: UGCUpdateHandle_t; punBytesProcessed: puint64; punBytesTotal: puint64): EItemUpdateStatus; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_SetUserItemVote(SteamInterface: ISteamUGC; nPublishedFileID: PublishedFileId_t; bVoteUp: Boolean): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_GetUserItemVote(SteamInterface: ISteamUGC; nPublishedFileID: PublishedFileId_t): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_AddItemToFavorites(SteamInterface: ISteamUGC; nAppId: AppId_t; nPublishedFileID: PublishedFileId_t): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_RemoveItemFromFavorites(SteamInterface: ISteamUGC; nAppId: AppId_t; nPublishedFileID: PublishedFileId_t): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_SubscribeItem(SteamInterface: ISteamUGC; nPublishedFileID: PublishedFileId_t): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_UnsubscribeItem(SteamInterface: ISteamUGC; nPublishedFileID: PublishedFileId_t): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_GetNumSubscribedItems(SteamInterface: ISteamUGC): uint32; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_GetSubscribedItems(SteamInterface: ISteamUGC; pvecPublishedFileID: pPublishedFileId_t; cMaxEntries: uint32): uint32; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_GetItemState(SteamInterface: ISteamUGC; nPublishedFileID: PublishedFileId_t): uint32; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_GetItemInstallInfo(SteamInterface: ISteamUGC; nPublishedFileID: PublishedFileId_t; punSizeOnDisk: puint64; pchFolder: PChar; cchFolderSize: uint32; punTimeStamp: puint32): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_GetItemDownloadInfo(SteamInterface: ISteamUGC; nPublishedFileID: PublishedFileId_t; punBytesDownloaded: puint64; punBytesTotal: puint64): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_DownloadItem(SteamInterface: ISteamUGC; nPublishedFileID: PublishedFileId_t; bHighPriority: Boolean): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_BInitWorkshopForGameServer(SteamInterface: ISteamUGC; unWorkshopDepotID: DepotId_t; pszFolder: PChar): Boolean; cdecl; external STEAMLIB;
procedure SteamAPI_ISteamUGC_SuspendDownloads(SteamInterface: ISteamUGC; bSuspend: Boolean); cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_StartPlaytimeTracking(SteamInterface: ISteamUGC; pvecPublishedFileID: pPublishedFileId_t; unNumPublishedFileIDs: uint32): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_StopPlaytimeTracking(SteamInterface: ISteamUGC; pvecPublishedFileID: pPublishedFileId_t; unNumPublishedFileIDs: uint32): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_StopPlaytimeTrackingForAllItems(SteamInterface: ISteamUGC): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_AddDependency(SteamInterface: ISteamUGC; nParentPublishedFileID: PublishedFileId_t; nChildPublishedFileID: PublishedFileId_t): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_RemoveDependency(SteamInterface: ISteamUGC; nParentPublishedFileID: PublishedFileId_t; nChildPublishedFileID: PublishedFileId_t): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_AddAppDependency(SteamInterface: ISteamUGC; nPublishedFileID: PublishedFileId_t; nAppID: AppId_t): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_RemoveAppDependency(SteamInterface: ISteamUGC; nPublishedFileID: PublishedFileId_t; nAppID: AppId_t): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_GetAppDependencies(SteamInterface: ISteamUGC; nPublishedFileID: PublishedFileId_t): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamUGC_DeleteItem(SteamInterface: ISteamUGC; nPublishedFileID: PublishedFileId_t): SteamAPICall_t; cdecl; external STEAMLIB;


function SteamAPI_SteamAppList_v001(): ISteamAppList; cdecl; external STEAMLIB;

function SteamAPI_ISteamAppList_GetNumInstalledApps(SteamInterface: ISteamAppList): uint32; cdecl; external STEAMLIB;
function SteamAPI_ISteamAppList_GetInstalledApps(SteamInterface: ISteamAppList; pvecAppID: pAppId_t; unMaxAppIDs: uint32): uint32; cdecl; external STEAMLIB;
function SteamAPI_ISteamAppList_GetAppName(SteamInterface: ISteamAppList; nAppID: AppId_t; pchName: PChar; cchNameMax: Longint): Longint; cdecl; external STEAMLIB;
function SteamAPI_ISteamAppList_GetAppInstallDir(SteamInterface: ISteamAppList; nAppID: AppId_t; pchDirectory: PChar; cchNameMax: Longint): Longint; cdecl; external STEAMLIB;
function SteamAPI_ISteamAppList_GetAppBuildId(SteamInterface: ISteamAppList; nAppID: AppId_t): Longint; cdecl; external STEAMLIB;


function SteamAPI_SteamHTMLSurface_v005(): ISteamHTMLSurface; cdecl; external STEAMLIB;

type
EHTMLMouseButton = (
  eHTMLMouseButton_Left = 0,
  eHTMLMouseButton_Right = 1,
  eHTMLMouseButton_Middle = 2
);
type
EMouseCursor = (
  dc_user = 0,
  dc_none = 1,
  dc_arrow = 2,
  dc_ibeam = 3,
  dc_hourglass = 4,
  dc_waitarrow = 5,
  dc_crosshair = 6,
  dc_up = 7,
  dc_sizenw = 8,
  dc_sizese = 9,
  dc_sizene = 10,
  dc_sizesw = 11,
  dc_sizew = 12,
  dc_sizee = 13,
  dc_sizen = 14,
  dc_sizes = 15,
  dc_sizewe = 16,
  dc_sizens = 17,
  dc_sizeall = 18,
  dc_no = 19,
  dc_hand = 20,
  dc_blank = 21,
  dc_middle_pan = 22,
  dc_north_pan = 23,
  dc_north_east_pan = 24,
  dc_east_pan = 25,
  dc_south_east_pan = 26,
  dc_south_pan = 27,
  dc_south_west_pan = 28,
  dc_west_pan = 29,
  dc_north_west_pan = 30,
  dc_alias = 31,
  dc_cell = 32,
  dc_colresize = 33,
  dc_copycur = 34,
  dc_verticaltext = 35,
  dc_rowresize = 36,
  dc_zoomin = 37,
  dc_zoomout = 38,
  dc_help = 39,
  dc_custom = 40,
  dc_last = 41
);
type
EHTMLKeyModifiers = (
  k_eHTMLKeyModifier_None = 0,
  k_eHTMLKeyModifier_AltDown = 1,
  k_eHTMLKeyModifier_CtrlDown = 2,
  k_eHTMLKeyModifier_ShiftDown = 4
);

function SteamAPI_ISteamHTMLSurface_Init(SteamInterface: ISteamHTMLSurface): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamHTMLSurface_Shutdown(SteamInterface: ISteamHTMLSurface): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamHTMLSurface_CreateBrowser(SteamInterface: ISteamHTMLSurface; pchUserAgent: PChar; pchUserCSS: PChar): SteamAPICall_t; cdecl; external STEAMLIB;
procedure SteamAPI_ISteamHTMLSurface_RemoveBrowser(SteamInterface: ISteamHTMLSurface; unBrowserHandle: HHTMLBrowser); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamHTMLSurface_LoadURL(SteamInterface: ISteamHTMLSurface; unBrowserHandle: HHTMLBrowser; pchURL: PChar; pchPostData: PChar); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamHTMLSurface_SetSize(SteamInterface: ISteamHTMLSurface; unBrowserHandle: HHTMLBrowser; unWidth: uint32; unHeight: uint32); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamHTMLSurface_StopLoad(SteamInterface: ISteamHTMLSurface; unBrowserHandle: HHTMLBrowser); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamHTMLSurface_Reload(SteamInterface: ISteamHTMLSurface; unBrowserHandle: HHTMLBrowser); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamHTMLSurface_GoBack(SteamInterface: ISteamHTMLSurface; unBrowserHandle: HHTMLBrowser); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamHTMLSurface_GoForward(SteamInterface: ISteamHTMLSurface; unBrowserHandle: HHTMLBrowser); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamHTMLSurface_AddHeader(SteamInterface: ISteamHTMLSurface; unBrowserHandle: HHTMLBrowser; pchKey: PChar; pchValue: PChar); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamHTMLSurface_ExecuteJavascript(SteamInterface: ISteamHTMLSurface; unBrowserHandle: HHTMLBrowser; pchScript: PChar); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamHTMLSurface_MouseUp(SteamInterface: ISteamHTMLSurface; unBrowserHandle: HHTMLBrowser; eMouseButton: EHTMLMouseButton); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamHTMLSurface_MouseDown(SteamInterface: ISteamHTMLSurface; unBrowserHandle: HHTMLBrowser; eMouseButton: EHTMLMouseButton); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamHTMLSurface_MouseDoubleClick(SteamInterface: ISteamHTMLSurface; unBrowserHandle: HHTMLBrowser; eMouseButton: EHTMLMouseButton); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamHTMLSurface_MouseMove(SteamInterface: ISteamHTMLSurface; unBrowserHandle: HHTMLBrowser; x: Longint; y: Longint); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamHTMLSurface_MouseWheel(SteamInterface: ISteamHTMLSurface; unBrowserHandle: HHTMLBrowser; nDelta: int32); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamHTMLSurface_KeyDown(SteamInterface: ISteamHTMLSurface; unBrowserHandle: HHTMLBrowser; nNativeKeyCode: uint32; eHTMLKeyModifiers: EHTMLKeyModifiers; bIsSystemKey: Boolean); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamHTMLSurface_KeyUp(SteamInterface: ISteamHTMLSurface; unBrowserHandle: HHTMLBrowser; nNativeKeyCode: uint32; eHTMLKeyModifiers: EHTMLKeyModifiers); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamHTMLSurface_KeyChar(SteamInterface: ISteamHTMLSurface; unBrowserHandle: HHTMLBrowser; cUnicodeChar: uint32; eHTMLKeyModifiers: EHTMLKeyModifiers); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamHTMLSurface_SetHorizontalScroll(SteamInterface: ISteamHTMLSurface; unBrowserHandle: HHTMLBrowser; nAbsolutePixelScroll: uint32); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamHTMLSurface_SetVerticalScroll(SteamInterface: ISteamHTMLSurface; unBrowserHandle: HHTMLBrowser; nAbsolutePixelScroll: uint32); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamHTMLSurface_SetKeyFocus(SteamInterface: ISteamHTMLSurface; unBrowserHandle: HHTMLBrowser; bHasKeyFocus: Boolean); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamHTMLSurface_ViewSource(SteamInterface: ISteamHTMLSurface; unBrowserHandle: HHTMLBrowser); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamHTMLSurface_CopyToClipboard(SteamInterface: ISteamHTMLSurface; unBrowserHandle: HHTMLBrowser); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamHTMLSurface_PasteFromClipboard(SteamInterface: ISteamHTMLSurface; unBrowserHandle: HHTMLBrowser); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamHTMLSurface_Find(SteamInterface: ISteamHTMLSurface; unBrowserHandle: HHTMLBrowser; pchSearchStr: PChar; bCurrentlyInFind: Boolean; bReverse: Boolean); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamHTMLSurface_StopFind(SteamInterface: ISteamHTMLSurface; unBrowserHandle: HHTMLBrowser); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamHTMLSurface_GetLinkAtPosition(SteamInterface: ISteamHTMLSurface; unBrowserHandle: HHTMLBrowser; x: Longint; y: Longint); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamHTMLSurface_SetCookie(SteamInterface: ISteamHTMLSurface; pchHostname: PChar; pchKey: PChar; pchValue: PChar; pchPath: PChar; nExpires: RTime32; bSecure: Boolean; bHTTPOnly: Boolean); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamHTMLSurface_SetPageScaleFactor(SteamInterface: ISteamHTMLSurface; unBrowserHandle: HHTMLBrowser; flZoom: Single; nPointX: Longint; nPointY: Longint); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamHTMLSurface_SetBackgroundMode(SteamInterface: ISteamHTMLSurface; unBrowserHandle: HHTMLBrowser; bBackgroundMode: Boolean); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamHTMLSurface_SetDPIScalingFactor(SteamInterface: ISteamHTMLSurface; unBrowserHandle: HHTMLBrowser; flDPIScaling: Single); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamHTMLSurface_OpenDeveloperTools(SteamInterface: ISteamHTMLSurface; unBrowserHandle: HHTMLBrowser); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamHTMLSurface_AllowStartRequest(SteamInterface: ISteamHTMLSurface; unBrowserHandle: HHTMLBrowser; bAllowed: Boolean); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamHTMLSurface_JSDialogResponse(SteamInterface: ISteamHTMLSurface; unBrowserHandle: HHTMLBrowser; bResult: Boolean); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamHTMLSurface_FileLoadDialogResponse(SteamInterface: ISteamHTMLSurface; unBrowserHandle: HHTMLBrowser; pchSelectedFiles: PPAnsiChar); cdecl; external STEAMLIB;


function SteamAPI_SteamInventory_v003(): ISteamInventory; cdecl; external STEAMLIB;

function SteamAPI_ISteamInventory_GetResultStatus(SteamInterface: ISteamInventory; resultHandle: SteamInventoryResult_t): EResult; cdecl; external STEAMLIB;
function SteamAPI_ISteamInventory_GetResultItems(SteamInterface: ISteamInventory; resultHandle: SteamInventoryResult_t; pOutItemsArray: pSteamItemDetails_t; punOutItemsArraySize: puint32): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamInventory_GetResultItemProperty(SteamInterface: ISteamInventory; resultHandle: SteamInventoryResult_t; unItemIndex: uint32; pchPropertyName: PChar; pchValueBuffer: PChar; punValueBufferSizeOut: puint32): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamInventory_GetResultTimestamp(SteamInterface: ISteamInventory; resultHandle: SteamInventoryResult_t): uint32; cdecl; external STEAMLIB;
function SteamAPI_ISteamInventory_CheckResultSteamID(SteamInterface: ISteamInventory; resultHandle: SteamInventoryResult_t; steamIDExpected: TSteamID): Boolean; cdecl; external STEAMLIB;
procedure SteamAPI_ISteamInventory_DestroyResult(SteamInterface: ISteamInventory; resultHandle: SteamInventoryResult_t); cdecl; external STEAMLIB;
function SteamAPI_ISteamInventory_GetAllItems(SteamInterface: ISteamInventory; pResultHandle: pSteamInventoryResult_t): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamInventory_GetItemsByID(SteamInterface: ISteamInventory; pResultHandle: pSteamInventoryResult_t; pInstanceIDs: pSteamItemInstanceID_t; unCountInstanceIDs: uint32): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamInventory_SerializeResult(SteamInterface: ISteamInventory; resultHandle: SteamInventoryResult_t; pOutBuffer: Pointer; punOutBufferSize: puint32): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamInventory_DeserializeResult(SteamInterface: ISteamInventory; pOutResultHandle: pSteamInventoryResult_t; pBuffer: Pointer; unBufferSize: uint32; bRESERVED_MUST_BE_FALSE: Boolean): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamInventory_GenerateItems(SteamInterface: ISteamInventory; pResultHandle: pSteamInventoryResult_t; pArrayItemDefs: pSteamItemDef_t; punArrayQuantity: puint32; unArrayLength: uint32): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamInventory_GrantPromoItems(SteamInterface: ISteamInventory; pResultHandle: pSteamInventoryResult_t): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamInventory_AddPromoItem(SteamInterface: ISteamInventory; pResultHandle: pSteamInventoryResult_t; itemDef: SteamItemDef_t): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamInventory_AddPromoItems(SteamInterface: ISteamInventory; pResultHandle: pSteamInventoryResult_t; pArrayItemDefs: pSteamItemDef_t; unArrayLength: uint32): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamInventory_ConsumeItem(SteamInterface: ISteamInventory; pResultHandle: pSteamInventoryResult_t; itemConsume: SteamItemInstanceID_t; unQuantity: uint32): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamInventory_ExchangeItems(SteamInterface: ISteamInventory; pResultHandle: pSteamInventoryResult_t; pArrayGenerate: pSteamItemDef_t; punArrayGenerateQuantity: puint32; unArrayGenerateLength: uint32; pArrayDestroy: pSteamItemInstanceID_t; punArrayDestroyQuantity: puint32; unArrayDestroyLength: uint32): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamInventory_TransferItemQuantity(SteamInterface: ISteamInventory; pResultHandle: pSteamInventoryResult_t; itemIdSource: SteamItemInstanceID_t; unQuantity: uint32; itemIdDest: SteamItemInstanceID_t): Boolean; cdecl; external STEAMLIB;
procedure SteamAPI_ISteamInventory_SendItemDropHeartbeat(SteamInterface: ISteamInventory); cdecl; external STEAMLIB;
function SteamAPI_ISteamInventory_TriggerItemDrop(SteamInterface: ISteamInventory; pResultHandle: pSteamInventoryResult_t; dropListDefinition: SteamItemDef_t): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamInventory_TradeItems(SteamInterface: ISteamInventory; pResultHandle: pSteamInventoryResult_t; steamIDTradePartner: TSteamID; pArrayGive: pSteamItemInstanceID_t; pArrayGiveQuantity: puint32; nArrayGiveLength: uint32; pArrayGet: pSteamItemInstanceID_t; pArrayGetQuantity: puint32; nArrayGetLength: uint32): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamInventory_LoadItemDefinitions(SteamInterface: ISteamInventory): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamInventory_GetItemDefinitionIDs(SteamInterface: ISteamInventory; pItemDefIDs: pSteamItemDef_t; punItemDefIDsArraySize: puint32): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamInventory_GetItemDefinitionProperty(SteamInterface: ISteamInventory; iDefinition: SteamItemDef_t; pchPropertyName: PChar; pchValueBuffer: PChar; punValueBufferSizeOut: puint32): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamInventory_RequestEligiblePromoItemDefinitionsIDs(SteamInterface: ISteamInventory; steamID: TSteamID): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamInventory_GetEligiblePromoItemDefinitionIDs(SteamInterface: ISteamInventory; steamID: TSteamID; pItemDefIDs: pSteamItemDef_t; punItemDefIDsArraySize: puint32): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamInventory_StartPurchase(SteamInterface: ISteamInventory; pArrayItemDefs: pSteamItemDef_t; punArrayQuantity: puint32; unArrayLength: uint32): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamInventory_RequestPrices(SteamInterface: ISteamInventory): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamInventory_GetNumItemsWithPrices(SteamInterface: ISteamInventory): uint32; cdecl; external STEAMLIB;
function SteamAPI_ISteamInventory_GetItemsWithPrices(SteamInterface: ISteamInventory; pArrayItemDefs: pSteamItemDef_t; pCurrentPrices: puint64; pBasePrices: puint64; unArrayLength: uint32): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamInventory_GetItemPrice(SteamInterface: ISteamInventory; iDefinition: SteamItemDef_t; pCurrentPrice: puint64; pBasePrice: puint64): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamInventory_StartUpdateProperties(SteamInterface: ISteamInventory): SteamInventoryUpdateHandle_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamInventory_RemoveProperty(SteamInterface: ISteamInventory; handle: SteamInventoryUpdateHandle_t; nItemID: SteamItemInstanceID_t; pchPropertyName: PChar): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamInventory_SetPropertyString(SteamInterface: ISteamInventory; handle: SteamInventoryUpdateHandle_t; nItemID: SteamItemInstanceID_t; pchPropertyName: PChar; pchPropertyValue: PChar): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamInventory_SetPropertyBool(SteamInterface: ISteamInventory; handle: SteamInventoryUpdateHandle_t; nItemID: SteamItemInstanceID_t; pchPropertyName: PChar; bValue: Boolean): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamInventory_SetPropertyInt64(SteamInterface: ISteamInventory; handle: SteamInventoryUpdateHandle_t; nItemID: SteamItemInstanceID_t; pchPropertyName: PChar; nValue: int64): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamInventory_SetPropertyFloat(SteamInterface: ISteamInventory; handle: SteamInventoryUpdateHandle_t; nItemID: SteamItemInstanceID_t; pchPropertyName: PChar; flValue: Single): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamInventory_SubmitUpdateProperties(SteamInterface: ISteamInventory; handle: SteamInventoryUpdateHandle_t; pResultHandle: pSteamInventoryResult_t): Boolean; cdecl; external STEAMLIB;


function SteamAPI_SteamVideo_v002(): ISteamVideo; cdecl; external STEAMLIB;

procedure SteamAPI_ISteamVideo_GetVideoURL(SteamInterface: ISteamVideo; unVideoAppID: AppId_t); cdecl; external STEAMLIB;
function SteamAPI_ISteamVideo_IsBroadcasting(SteamInterface: ISteamVideo; pnNumViewers: PInteger): Boolean; cdecl; external STEAMLIB;
procedure SteamAPI_ISteamVideo_GetOPFSettings(SteamInterface: ISteamVideo; unVideoAppID: AppId_t); cdecl; external STEAMLIB;
function SteamAPI_ISteamVideo_GetOPFStringForApp(SteamInterface: ISteamVideo; unVideoAppID: AppId_t; pchBuffer: PChar; pnBufferSize: pint32): Boolean; cdecl; external STEAMLIB;


function SteamAPI_SteamTV_v001(): ISteamTV; cdecl; external STEAMLIB;

function SteamAPI_ISteamTV_IsBroadcasting(SteamInterface: ISteamTV; pnNumViewers: PInteger): Boolean; cdecl; external STEAMLIB;
procedure SteamAPI_ISteamTV_AddBroadcastGameData(SteamInterface: ISteamTV; pchKey: PChar; pchValue: PChar); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamTV_RemoveBroadcastGameData(SteamInterface: ISteamTV; pchKey: PChar); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamTV_AddTimelineMarker(SteamInterface: ISteamTV; pchTemplateName: PChar; bPersistent: Boolean; nColorR: uint8; nColorG: uint8; nColorB: uint8); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamTV_RemoveTimelineMarker(SteamInterface: ISteamTV); cdecl; external STEAMLIB;
function SteamAPI_ISteamTV_AddRegion(SteamInterface: ISteamTV; pchElementName: PChar; pchTimelineDataSection: PChar; pSteamTVRegion: pSteamTVRegion_t; eSteamTVRegionBehavior: ESteamTVRegionBehavior): uint32; cdecl; external STEAMLIB;
procedure SteamAPI_ISteamTV_RemoveRegion(SteamInterface: ISteamTV; unRegionHandle: uint32); cdecl; external STEAMLIB;


function SteamAPI_SteamParentalSettings_v001(): ISteamParentalSettings; cdecl; external STEAMLIB;

function SteamAPI_ISteamParentalSettings_BIsParentalLockEnabled(SteamInterface: ISteamParentalSettings): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamParentalSettings_BIsParentalLockLocked(SteamInterface: ISteamParentalSettings): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamParentalSettings_BIsAppBlocked(SteamInterface: ISteamParentalSettings; nAppID: AppId_t): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamParentalSettings_BIsAppInBlockList(SteamInterface: ISteamParentalSettings; nAppID: AppId_t): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamParentalSettings_BIsFeatureBlocked(SteamInterface: ISteamParentalSettings; eFeature: EParentalFeature): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamParentalSettings_BIsFeatureInBlockList(SteamInterface: ISteamParentalSettings; eFeature: EParentalFeature): Boolean; cdecl; external STEAMLIB;


function SteamAPI_SteamRemotePlay_v001(): ISteamRemotePlay; cdecl; external STEAMLIB;

function SteamAPI_ISteamRemotePlay_GetSessionCount(SteamInterface: ISteamRemotePlay): uint32; cdecl; external STEAMLIB;
function SteamAPI_ISteamRemotePlay_GetSessionID(SteamInterface: ISteamRemotePlay; iSessionIndex: Longint): RemotePlaySessionID_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamRemotePlay_GetSessionSteamID(SteamInterface: ISteamRemotePlay; unSessionID: RemotePlaySessionID_t): TSteamID; cdecl; external STEAMLIB;
function SteamAPI_ISteamRemotePlay_GetSessionClientName(SteamInterface: ISteamRemotePlay; unSessionID: RemotePlaySessionID_t): PChar; cdecl; external STEAMLIB;
function SteamAPI_ISteamRemotePlay_GetSessionClientFormFactor(SteamInterface: ISteamRemotePlay; unSessionID: RemotePlaySessionID_t): ESteamDeviceFormFactor; cdecl; external STEAMLIB;
function SteamAPI_ISteamRemotePlay_BGetSessionClientResolution(SteamInterface: ISteamRemotePlay; unSessionID: RemotePlaySessionID_t; pnResolutionX: PInteger; pnResolutionY: PInteger): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamRemotePlay_BSendRemotePlayTogetherInvite(SteamInterface: ISteamRemotePlay; steamIDFriend: TSteamID): Boolean; cdecl; external STEAMLIB;


function SteamAPI_SteamNetworkingSockets_v008(): ISteamNetworkingSockets; cdecl; external STEAMLIB;
function SteamAPI_SteamGameServerNetworkingSockets_v008(): ISteamNetworkingSockets; cdecl; external STEAMLIB;

function SteamAPI_ISteamNetworkingSockets_CreateListenSocketIP(SteamInterface: ISteamNetworkingSockets; localAddress: PSteamNetworkingIPAddr; nOptions: Longint; pOptions: pSteamNetworkingConfigValue_t): HSteamListenSocket; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworkingSockets_ConnectByIPAddress(SteamInterface: ISteamNetworkingSockets; address: PSteamNetworkingIPAddr; nOptions: Longint; pOptions: pSteamNetworkingConfigValue_t): HSteamNetConnection; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworkingSockets_CreateListenSocketP2P(SteamInterface: ISteamNetworkingSockets; nVirtualPort: Longint; nOptions: Longint; pOptions: pSteamNetworkingConfigValue_t): HSteamListenSocket; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworkingSockets_ConnectP2P(SteamInterface: ISteamNetworkingSockets; identityRemote: PSteamNetworkingIdentity; nVirtualPort: Longint; nOptions: Longint; pOptions: pSteamNetworkingConfigValue_t): HSteamNetConnection; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworkingSockets_AcceptConnection(SteamInterface: ISteamNetworkingSockets; hConn: HSteamNetConnection): EResult; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworkingSockets_CloseConnection(SteamInterface: ISteamNetworkingSockets; hPeer: HSteamNetConnection; nReason: Longint; pszDebug: PChar; bEnableLinger: Boolean): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworkingSockets_CloseListenSocket(SteamInterface: ISteamNetworkingSockets; hSocket: HSteamListenSocket): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworkingSockets_SetConnectionUserData(SteamInterface: ISteamNetworkingSockets; hPeer: HSteamNetConnection; nUserData: int64): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworkingSockets_GetConnectionUserData(SteamInterface: ISteamNetworkingSockets; hPeer: HSteamNetConnection): int64; cdecl; external STEAMLIB;
procedure SteamAPI_ISteamNetworkingSockets_SetConnectionName(SteamInterface: ISteamNetworkingSockets; hPeer: HSteamNetConnection; pszName: PChar); cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworkingSockets_GetConnectionName(SteamInterface: ISteamNetworkingSockets; hPeer: HSteamNetConnection; pszName: PChar; nMaxLen: Longint): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworkingSockets_SendMessageToConnection(SteamInterface: ISteamNetworkingSockets; hConn: HSteamNetConnection; pData: Pointer; cbData: uint32; nSendFlags: Longint; pOutMessageNumber: pint64): EResult; cdecl; external STEAMLIB;
procedure SteamAPI_ISteamNetworkingSockets_SendMessages(SteamInterface: ISteamNetworkingSockets; nMessages: Longint; const pMessages: pSteamNetworkingMessage_t; pOutMessageNumberOrResult: pint64); cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworkingSockets_FlushMessagesOnConnection(SteamInterface: ISteamNetworkingSockets; hConn: HSteamNetConnection): EResult; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworkingSockets_ReceiveMessagesOnConnection(SteamInterface: ISteamNetworkingSockets; hConn: HSteamNetConnection; ppOutMessages: pSteamNetworkingMessage_t; nMaxMessages: Longint): Longint; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworkingSockets_GetConnectionInfo(SteamInterface: ISteamNetworkingSockets; hConn: HSteamNetConnection; pInfo: pSteamNetConnectionInfo_t): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworkingSockets_GetQuickConnectionStatus(SteamInterface: ISteamNetworkingSockets; hConn: HSteamNetConnection; pStats: pSteamNetworkingQuickConnectionStatus): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworkingSockets_GetDetailedConnectionStatus(SteamInterface: ISteamNetworkingSockets; hConn: HSteamNetConnection; pszBuf: PChar; cbBuf: Longint): Longint; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworkingSockets_GetListenSocketAddress(SteamInterface: ISteamNetworkingSockets; hSocket: HSteamListenSocket; address: pSteamNetworkingIPAddr): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworkingSockets_CreateSocketPair(SteamInterface: ISteamNetworkingSockets; pOutConnection1: pHSteamNetConnection; pOutConnection2: pHSteamNetConnection; bUseNetworkLoopback: Boolean; pIdentity1: pSteamNetworkingIdentity; pIdentity2: pSteamNetworkingIdentity): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworkingSockets_GetIdentity(SteamInterface: ISteamNetworkingSockets; pIdentity: pSteamNetworkingIdentity): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworkingSockets_InitAuthentication(SteamInterface: ISteamNetworkingSockets): ESteamNetworkingAvailability; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworkingSockets_GetAuthenticationStatus(SteamInterface: ISteamNetworkingSockets; pDetails: pSteamNetAuthenticationStatus_t): ESteamNetworkingAvailability; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworkingSockets_CreatePollGroup(SteamInterface: ISteamNetworkingSockets): HSteamNetPollGroup; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworkingSockets_DestroyPollGroup(SteamInterface: ISteamNetworkingSockets; hPollGroup: HSteamNetPollGroup): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworkingSockets_SetConnectionPollGroup(SteamInterface: ISteamNetworkingSockets; hConn: HSteamNetConnection; hPollGroup: HSteamNetPollGroup): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworkingSockets_ReceiveMessagesOnPollGroup(SteamInterface: ISteamNetworkingSockets; hPollGroup: HSteamNetPollGroup; ppOutMessages: pSteamNetworkingMessage_t; nMaxMessages: Longint): Longint; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworkingSockets_ReceivedRelayAuthTicket(SteamInterface: ISteamNetworkingSockets; pvTicket: Pointer; cbTicket: Longint; pOutParsedTicket: pSteamDatagramRelayAuthTicket): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworkingSockets_FindRelayAuthTicketForServer(SteamInterface: ISteamNetworkingSockets; identityGameServer: PSteamNetworkingIdentity; nVirtualPort: Longint; pOutParsedTicket: pSteamDatagramRelayAuthTicket): Longint; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworkingSockets_ConnectToHostedDedicatedServer(SteamInterface: ISteamNetworkingSockets; identityTarget: PSteamNetworkingIdentity; nVirtualPort: Longint; nOptions: Longint; pOptions: pSteamNetworkingConfigValue_t): HSteamNetConnection; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworkingSockets_GetHostedDedicatedServerPort(SteamInterface: ISteamNetworkingSockets): uint16; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworkingSockets_GetHostedDedicatedServerPOPID(SteamInterface: ISteamNetworkingSockets): SteamNetworkingPOPID; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworkingSockets_GetHostedDedicatedServerAddress(SteamInterface: ISteamNetworkingSockets; pRouting: pSteamDatagramHostedAddress): EResult; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworkingSockets_CreateHostedDedicatedServerListenSocket(SteamInterface: ISteamNetworkingSockets; nVirtualPort: Longint; nOptions: Longint; pOptions: pSteamNetworkingConfigValue_t): HSteamListenSocket; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworkingSockets_GetGameCoordinatorServerLogin(SteamInterface: ISteamNetworkingSockets; pLoginInfo: pSteamDatagramGameCoordinatorServerLogin; pcbSignedBlob: PInteger; pBlob: Pointer): EResult; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworkingSockets_ConnectP2PCustomSignaling(SteamInterface: ISteamNetworkingSockets; pSignaling: ISteamNetworkingConnectionCustomSignaling; pPeerIdentity: pSteamNetworkingIdentity; nOptions: Longint; pOptions: pSteamNetworkingConfigValue_t): HSteamNetConnection; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworkingSockets_ReceivedP2PCustomSignal(SteamInterface: ISteamNetworkingSockets; pMsg: Pointer; cbMsg: Longint; pContext: ISteamNetworkingCustomSignalingRecvContext): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworkingSockets_GetCertificateRequest(SteamInterface: ISteamNetworkingSockets; pcbBlob: PInteger; pBlob: Pointer; errMsg: PSteamNetworkingErrMsg): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworkingSockets_SetCertificate(SteamInterface: ISteamNetworkingSockets; pCertificate: Pointer; cbCertificate: Longint; errMsg: PSteamNetworkingErrMsg): Boolean; cdecl; external STEAMLIB;



function SteamAPI_ISteamNetworkingConnectionCustomSignaling_SendSignal(SteamInterface: ISteamNetworkingConnectionCustomSignaling; hConn: HSteamNetConnection; info: PSteamNetConnectionInfo_t; pMsg: Pointer; cbMsg: Longint): Boolean; cdecl; external STEAMLIB;
procedure SteamAPI_ISteamNetworkingConnectionCustomSignaling_Release(SteamInterface: ISteamNetworkingConnectionCustomSignaling); cdecl; external STEAMLIB;



function SteamAPI_ISteamNetworkingCustomSignalingRecvContext_OnConnectRequest(SteamInterface: ISteamNetworkingCustomSignalingRecvContext; hConn: HSteamNetConnection; identityPeer: PSteamNetworkingIdentity): ISteamNetworkingConnectionCustomSignaling; cdecl; external STEAMLIB;
procedure SteamAPI_ISteamNetworkingCustomSignalingRecvContext_SendRejectionSignal(SteamInterface: ISteamNetworkingCustomSignalingRecvContext; identityPeer: PSteamNetworkingIdentity; pMsg: Pointer; cbMsg: Longint); cdecl; external STEAMLIB;


function SteamAPI_SteamNetworkingUtils_v003(): ISteamNetworkingUtils; cdecl; external STEAMLIB;

function SteamAPI_ISteamNetworkingUtils_AllocateMessage(SteamInterface: ISteamNetworkingUtils; cbAllocateBuffer: Longint): pSteamNetworkingMessage_t; cdecl; external STEAMLIB;
procedure SteamAPI_ISteamNetworkingUtils_InitRelayNetworkAccess(SteamInterface: ISteamNetworkingUtils); cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworkingUtils_GetRelayNetworkStatus(SteamInterface: ISteamNetworkingUtils; pDetails: pSteamRelayNetworkStatus_t): ESteamNetworkingAvailability; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworkingUtils_GetLocalPingLocation(SteamInterface: ISteamNetworkingUtils; result: PSteamNetworkPingLocation_t): Single; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworkingUtils_EstimatePingTimeBetweenTwoLocations(SteamInterface: ISteamNetworkingUtils; location1: PSteamNetworkPingLocation_t; location2: PSteamNetworkPingLocation_t): Longint; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworkingUtils_EstimatePingTimeFromLocalHost(SteamInterface: ISteamNetworkingUtils; remoteLocation: PSteamNetworkPingLocation_t): Longint; cdecl; external STEAMLIB;
procedure SteamAPI_ISteamNetworkingUtils_ConvertPingLocationToString(SteamInterface: ISteamNetworkingUtils; location: PSteamNetworkPingLocation_t; pszBuf: PChar; cchBufSize: Longint); cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworkingUtils_ParsePingLocationString(SteamInterface: ISteamNetworkingUtils; pszString: PChar; result: PSteamNetworkPingLocation_t): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworkingUtils_CheckPingDataUpToDate(SteamInterface: ISteamNetworkingUtils; flMaxAgeSeconds: Single): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworkingUtils_GetPingToDataCenter(SteamInterface: ISteamNetworkingUtils; popID: SteamNetworkingPOPID; pViaRelayPoP: pSteamNetworkingPOPID): Longint; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworkingUtils_GetDirectPingToPOP(SteamInterface: ISteamNetworkingUtils; popID: SteamNetworkingPOPID): Longint; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworkingUtils_GetPOPCount(SteamInterface: ISteamNetworkingUtils): Longint; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworkingUtils_GetPOPList(SteamInterface: ISteamNetworkingUtils; list: pSteamNetworkingPOPID; nListSz: Longint): Longint; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworkingUtils_GetLocalTimestamp(SteamInterface: ISteamNetworkingUtils): SteamNetworkingMicroseconds; cdecl; external STEAMLIB;
type FSteamNetworkingSocketsDebugOutput = procedure (nType: ESteamNetworkingSocketsDebugOutputType; pszMsg: PChar); cdecl;

procedure SteamAPI_ISteamNetworkingUtils_SetDebugOutputFunction(SteamInterface: ISteamNetworkingUtils; eDetailLevel: ESteamNetworkingSocketsDebugOutputType; pfnFunc: FSteamNetworkingSocketsDebugOutput); cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworkingUtils_SetGlobalConfigValueInt32(SteamInterface: ISteamNetworkingUtils; eValue: ESteamNetworkingConfigValue; val: int32): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworkingUtils_SetGlobalConfigValueFloat(SteamInterface: ISteamNetworkingUtils; eValue: ESteamNetworkingConfigValue; val: Single): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworkingUtils_SetGlobalConfigValueString(SteamInterface: ISteamNetworkingUtils; eValue: ESteamNetworkingConfigValue; val: PChar): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworkingUtils_SetConnectionConfigValueInt32(SteamInterface: ISteamNetworkingUtils; hConn: HSteamNetConnection; eValue: ESteamNetworkingConfigValue; val: int32): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworkingUtils_SetConnectionConfigValueFloat(SteamInterface: ISteamNetworkingUtils; hConn: HSteamNetConnection; eValue: ESteamNetworkingConfigValue; val: Single): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworkingUtils_SetConnectionConfigValueString(SteamInterface: ISteamNetworkingUtils; hConn: HSteamNetConnection; eValue: ESteamNetworkingConfigValue; val: PChar): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworkingUtils_SetConfigValue(SteamInterface: ISteamNetworkingUtils; eValue: ESteamNetworkingConfigValue; eScopeType: ESteamNetworkingConfigScope; scopeObj: intptr; eDataType: ESteamNetworkingConfigDataType; pArg: Pointer): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworkingUtils_SetConfigValueStruct(SteamInterface: ISteamNetworkingUtils; opt: PSteamNetworkingConfigValue_t; eScopeType: ESteamNetworkingConfigScope; scopeObj: intptr): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworkingUtils_GetConfigValue(SteamInterface: ISteamNetworkingUtils; eValue: ESteamNetworkingConfigValue; eScopeType: ESteamNetworkingConfigScope; scopeObj: intptr; pOutDataType: pESteamNetworkingConfigDataType; var pResult; cbResult: pcsize_t): ESteamNetworkingGetConfigValueResult; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworkingUtils_GetConfigValueInfo(SteamInterface: ISteamNetworkingUtils; eValue: ESteamNetworkingConfigValue; pOutName: PPAnsiChar; pOutDataType: pESteamNetworkingConfigDataType; pOutScope: pESteamNetworkingConfigScope; pOutNextValue: pESteamNetworkingConfigValue): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworkingUtils_GetFirstConfigValue(SteamInterface: ISteamNetworkingUtils): ESteamNetworkingConfigValue; cdecl; external STEAMLIB;
procedure SteamAPI_ISteamNetworkingUtils_SteamNetworkingIPAddr_ToString(SteamInterface: ISteamNetworkingUtils; addr: PSteamNetworkingIPAddr; buf: PChar; cbBuf: uint32; bWithPort: Boolean); cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworkingUtils_SteamNetworkingIPAddr_ParseString(SteamInterface: ISteamNetworkingUtils; pAddr: pSteamNetworkingIPAddr; pszStr: PChar): Boolean; cdecl; external STEAMLIB;
procedure SteamAPI_ISteamNetworkingUtils_SteamNetworkingIdentity_ToString(SteamInterface: ISteamNetworkingUtils; identity: PSteamNetworkingIdentity; buf: PChar; cbBuf: uint32); cdecl; external STEAMLIB;
function SteamAPI_ISteamNetworkingUtils_SteamNetworkingIdentity_ParseString(SteamInterface: ISteamNetworkingUtils; pIdentity: pSteamNetworkingIdentity; pszStr: PChar): Boolean; cdecl; external STEAMLIB;




function SteamAPI_SteamGameServer_v013(): ISteamGameServer; cdecl; external STEAMLIB;

procedure SteamAPI_ISteamGameServer_SetProduct(SteamInterface: ISteamGameServer; pszProduct: PChar); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamGameServer_SetGameDescription(SteamInterface: ISteamGameServer; pszGameDescription: PChar); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamGameServer_SetModDir(SteamInterface: ISteamGameServer; pszModDir: PChar); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamGameServer_SetDedicatedServer(SteamInterface: ISteamGameServer; bDedicated: Boolean); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamGameServer_LogOn(SteamInterface: ISteamGameServer; pszToken: PChar); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamGameServer_LogOnAnonymous(SteamInterface: ISteamGameServer); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamGameServer_LogOff(SteamInterface: ISteamGameServer); cdecl; external STEAMLIB;
function SteamAPI_ISteamGameServer_BLoggedOn(SteamInterface: ISteamGameServer): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamGameServer_BSecure(SteamInterface: ISteamGameServer): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamGameServer_GetSteamID(SteamInterface: ISteamGameServer): TSteamID; cdecl; external STEAMLIB;
function SteamAPI_ISteamGameServer_WasRestartRequested(SteamInterface: ISteamGameServer): Boolean; cdecl; external STEAMLIB;
procedure SteamAPI_ISteamGameServer_SetMaxPlayerCount(SteamInterface: ISteamGameServer; cPlayersMax: Longint); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamGameServer_SetBotPlayerCount(SteamInterface: ISteamGameServer; cBotplayers: Longint); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamGameServer_SetServerName(SteamInterface: ISteamGameServer; pszServerName: PChar); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamGameServer_SetMapName(SteamInterface: ISteamGameServer; pszMapName: PChar); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamGameServer_SetPasswordProtected(SteamInterface: ISteamGameServer; bPasswordProtected: Boolean); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamGameServer_SetSpectatorPort(SteamInterface: ISteamGameServer; unSpectatorPort: uint16); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamGameServer_SetSpectatorServerName(SteamInterface: ISteamGameServer; pszSpectatorServerName: PChar); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamGameServer_ClearAllKeyValues(SteamInterface: ISteamGameServer); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamGameServer_SetKeyValue(SteamInterface: ISteamGameServer; pKey: PChar; pValue: PChar); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamGameServer_SetGameTags(SteamInterface: ISteamGameServer; pchGameTags: PChar); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamGameServer_SetGameData(SteamInterface: ISteamGameServer; pchGameData: PChar); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamGameServer_SetRegion(SteamInterface: ISteamGameServer; pszRegion: PChar); cdecl; external STEAMLIB;
function SteamAPI_ISteamGameServer_SendUserConnectAndAuthenticate(SteamInterface: ISteamGameServer; unIPClient: uint32; pvAuthBlob: Pointer; cubAuthBlobSize: uint32; pSteamIDUser: PSteamID): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamGameServer_CreateUnauthenticatedUserConnection(SteamInterface: ISteamGameServer): TSteamID; cdecl; external STEAMLIB;
procedure SteamAPI_ISteamGameServer_SendUserDisconnect(SteamInterface: ISteamGameServer; steamIDUser: TSteamID); cdecl; external STEAMLIB;
function SteamAPI_ISteamGameServer_BUpdateUserData(SteamInterface: ISteamGameServer; steamIDUser: TSteamID; pchPlayerName: PChar; uScore: uint32): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamGameServer_GetAuthSessionTicket(SteamInterface: ISteamGameServer; pTicket: Pointer; cbMaxTicket: Longint; pcbTicket: puint32): HAuthTicket; cdecl; external STEAMLIB;
function SteamAPI_ISteamGameServer_BeginAuthSession(SteamInterface: ISteamGameServer; pAuthTicket: Pointer; cbAuthTicket: Longint; steamID: TSteamID): EBeginAuthSessionResult; cdecl; external STEAMLIB;
procedure SteamAPI_ISteamGameServer_EndAuthSession(SteamInterface: ISteamGameServer; steamID: TSteamID); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamGameServer_CancelAuthTicket(SteamInterface: ISteamGameServer; hAuthTicket: HAuthTicket); cdecl; external STEAMLIB;
function SteamAPI_ISteamGameServer_UserHasLicenseForApp(SteamInterface: ISteamGameServer; steamID: TSteamID; appID: AppId_t): EUserHasLicenseForAppResult; cdecl; external STEAMLIB;
function SteamAPI_ISteamGameServer_RequestUserGroupStatus(SteamInterface: ISteamGameServer; steamIDUser: TSteamID; steamIDGroup: TSteamID): Boolean; cdecl; external STEAMLIB;
procedure SteamAPI_ISteamGameServer_GetGameplayStats(SteamInterface: ISteamGameServer); cdecl; external STEAMLIB;
function SteamAPI_ISteamGameServer_GetServerReputation(SteamInterface: ISteamGameServer): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamGameServer_GetPublicIP(SteamInterface: ISteamGameServer): SteamIPAddress_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamGameServer_HandleIncomingPacket(SteamInterface: ISteamGameServer; pData: Pointer; cbData: Longint; srcIP: uint32; srcPort: uint16): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamGameServer_GetNextOutgoingPacket(SteamInterface: ISteamGameServer; pOut: Pointer; cbMaxOut: Longint; pNetAdr: puint32; pPort: puint16): Longint; cdecl; external STEAMLIB;
procedure SteamAPI_ISteamGameServer_EnableHeartbeats(SteamInterface: ISteamGameServer; bActive: Boolean); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamGameServer_SetHeartbeatInterval(SteamInterface: ISteamGameServer; iHeartbeatInterval: Longint); cdecl; external STEAMLIB;
procedure SteamAPI_ISteamGameServer_ForceHeartbeat(SteamInterface: ISteamGameServer); cdecl; external STEAMLIB;
function SteamAPI_ISteamGameServer_AssociateWithClan(SteamInterface: ISteamGameServer; steamIDClan: TSteamID): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamGameServer_ComputeNewPlayerCompatibility(SteamInterface: ISteamGameServer; steamIDNewPlayer: TSteamID): SteamAPICall_t; cdecl; external STEAMLIB;


function SteamAPI_SteamGameServerStats_v001(): ISteamGameServerStats; cdecl; external STEAMLIB;

function SteamAPI_ISteamGameServerStats_RequestUserStats(SteamInterface: ISteamGameServerStats; steamIDUser: TSteamID): SteamAPICall_t; cdecl; external STEAMLIB;
function SteamAPI_ISteamGameServerStats_GetUserStatInt32(SteamInterface: ISteamGameServerStats; steamIDUser: TSteamID; pchName: PChar; pData: pint32): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamGameServerStats_GetUserStatFloat(SteamInterface: ISteamGameServerStats; steamIDUser: TSteamID; pchName: PChar; pData: psingle): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamGameServerStats_GetUserAchievement(SteamInterface: ISteamGameServerStats; steamIDUser: TSteamID; pchName: PChar; pbAchieved: pboolean): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamGameServerStats_SetUserStatInt32(SteamInterface: ISteamGameServerStats; steamIDUser: TSteamID; pchName: PChar; nData: int32): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamGameServerStats_SetUserStatFloat(SteamInterface: ISteamGameServerStats; steamIDUser: TSteamID; pchName: PChar; fData: Single): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamGameServerStats_UpdateUserAvgRateStat(SteamInterface: ISteamGameServerStats; steamIDUser: TSteamID; pchName: PChar; flCountThisSession: Single; dSessionLength: Double): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamGameServerStats_SetUserAchievement(SteamInterface: ISteamGameServerStats; steamIDUser: TSteamID; pchName: PChar): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamGameServerStats_ClearUserAchievement(SteamInterface: ISteamGameServerStats; steamIDUser: TSteamID; pchName: PChar): Boolean; cdecl; external STEAMLIB;
function SteamAPI_ISteamGameServerStats_StoreUserStats(SteamInterface: ISteamGameServerStats; steamIDUser: TSteamID): SteamAPICall_t; cdecl; external STEAMLIB;


procedure SteamAPI_SteamNetworkingIPAddr_Clear(pThis: PSteamNetworkingIPAddr); cdecl; external STEAMLIB;
function SteamAPI_SteamNetworkingIPAddr_IsIPv6AllZeros(const pThis: PSteamNetworkingIPAddr): Boolean; cdecl; external STEAMLIB;
procedure SteamAPI_SteamNetworkingIPAddr_SetIPv6(pThis: PSteamNetworkingIPAddr; const ipv6: puint8; nPort: uint16); cdecl; external STEAMLIB;
procedure SteamAPI_SteamNetworkingIPAddr_SetIPv4(pThis: PSteamNetworkingIPAddr; nIP: uint32; nPort: uint16); cdecl; external STEAMLIB;
function SteamAPI_SteamNetworkingIPAddr_IsIPv4(const pThis: PSteamNetworkingIPAddr): Boolean; cdecl; external STEAMLIB;
function SteamAPI_SteamNetworkingIPAddr_GetIPv4(const pThis: PSteamNetworkingIPAddr): uint32; cdecl; external STEAMLIB;
procedure SteamAPI_SteamNetworkingIPAddr_SetIPv6LocalHost(pThis: PSteamNetworkingIPAddr; nPort: uint16); cdecl; external STEAMLIB;
function SteamAPI_SteamNetworkingIPAddr_IsLocalHost(const pThis: PSteamNetworkingIPAddr): Boolean; cdecl; external STEAMLIB;
procedure SteamAPI_SteamNetworkingIPAddr_ToString(const pAddr: PSteamNetworkingIPAddr; buf: PChar; cbBuf: csize_t; bWithPort: Boolean); cdecl; external STEAMLIB;
function SteamAPI_SteamNetworkingIPAddr_ParseString(pAddr: PSteamNetworkingIPAddr; pszStr: PChar): Boolean; cdecl; external STEAMLIB;

procedure SteamAPI_SteamNetworkingIdentity_Clear(pThis: PSteamNetworkingIdentity); cdecl; external STEAMLIB;
function SteamAPI_SteamNetworkingIdentity_IsInvalid(const pThis: PSteamNetworkingIdentity): Boolean; cdecl; external STEAMLIB;
procedure SteamAPI_SteamNetworkingIdentity_SetSteamID64(pThis: PSteamNetworkingIdentity; steamID: uint64); cdecl; external STEAMLIB;
function SteamAPI_SteamNetworkingIdentity_GetSteamID64(const pThis: PSteamNetworkingIdentity): uint64; cdecl; external STEAMLIB;
procedure SteamAPI_SteamNetworkingIdentity_SetIPAddr(pThis: PSteamNetworkingIdentity; const pAddr: PSteamNetworkingIPAddr); cdecl; external STEAMLIB;
function SteamAPI_SteamNetworkingIdentity_GetIPAddr(pThis: PSteamNetworkingIdentity): PSteamNetworkingIPAddr; cdecl; external STEAMLIB;
procedure SteamAPI_SteamNetworkingIdentity_SetLocalHost(pThis: PSteamNetworkingIdentity); cdecl; external STEAMLIB;
function SteamAPI_SteamNetworkingIdentity_IsLocalHost(const pThis: PSteamNetworkingIdentity): Boolean; cdecl; external STEAMLIB;
function SteamAPI_SteamNetworkingIdentity_SetGenericString(pThis: PSteamNetworkingIdentity; pszString: PChar): Boolean; cdecl; external STEAMLIB;
function SteamAPI_SteamNetworkingIdentity_GetGenericString(const pThis: PSteamNetworkingIdentity): PChar; cdecl; external STEAMLIB;
function SteamAPI_SteamNetworkingIdentity_SetGenericBytes(pThis: PSteamNetworkingIdentity; const data: Pointer; cbLen: csize_t): Boolean; cdecl; external STEAMLIB;
function SteamAPI_SteamNetworkingIdentity_GetGenericBytes(const pThis: PSteamNetworkingIdentity; pOutLen: PInteger): puint8; cdecl; external STEAMLIB;
function SteamAPI_SteamNetworkingIdentity_IsEqualTo(const a: PSteamNetworkingIdentity; const b: PSteamNetworkingIdentity): Boolean; cdecl; external STEAMLIB;

procedure SteamAPI_SteamNetworkingIdentity_ToString(const identity: PSteamNetworkingIdentity; buf: PChar;cbBuf: csize_t); cdecl; external STEAMLIB;
function SteamAPI_SteamNetworkingIdentity_ParseString(pIdentity: PSteamNetworkingIdentity; pszStr: PChar): Boolean; cdecl; external STEAMLIB;


type
  Int8 = shortint;
  pInt8 = ^Int8;
  int16 = SmallInt;
  pInt16 = ^int16;
  int32 = Integer;
  pInt32 = ^int32;
  uint8 = Byte;
  pUInt8 = ^uint8;
  uint16 = Word;
  pUInt16 = ^uint16;
  uint32 = Cardinal;
  pUInt32 = ^uint32;
  puint64 = ^uint64;


  TSteamUtils = class
  public
    SteamUtilsInterface: ISteamUtils;
    constructor Init(SteamInterface: ISteamUtils);
    function GetAppId(): LongInt;
    function GetImageSize(Image: Integer; Width: pUint32; Height: pUint32): Boolean;
    function GetImageRGBA(Image: Integer; Dest: pUint8; DestBufferSize: Integer): Boolean;
    procedure SetWarningMessageHook(Fn: TSteamAPIWarningMessageHook);
    function IsOverlayEnabled(): Boolean;
  end;

  TSteamUser = class
  public
    SteamUserInterface: ISteamUser;
    constructor Init(SteamInterface: ISteamUser);
    function BLoggedOn(): Boolean;
    function GetSteamID(): TSteamID;
    function GetAvailableVoice(Compressed, cUncompressed: pUint32; UncompressedVoiceDesiredSampleRate: uint32): EVoiceResult; cdecl;
    function GetVoice(WantCompressed: Boolean; DestBuffer: Pointer; cDestBufferSize: uint32; BytesWritten: pUint32; WantUncompressed: Boolean; UncompressedDestBuffer: Pointer; cUncompressedDestBufferSize: uint32; nUncompressBytesWritten: pUint32; UncompressedVoiceDesiredSampleRate: uint32): EVoiceResult;
    function DecompressVoice(Compressed: Pointer; cCompressed: uint32; DestBuffer: Pointer; DestBufferSize: uint32; BytesWritten: pUint32; DesiredSampleRate: uint32): EVoiceResult;
    procedure StartVoiceRecording(); cdecl;
    procedure StopVoiceRecording(); cdecl;
    function GetAuthSessionTicket(Ticket: Pointer; MaxTicket: Integer; cTicket: pUint32): TAuthTicket;
    function BeginAuthSession(AuthTicket: Pointer; cAuthTicket: Integer; steamID: TSteamID): EBeginAuthSessionResult;
    procedure EndAuthSession(steamID: TSteamID);
    procedure CancelAuthTicket(AuthTicket: TAuthTicket);
    function UserHasLicenseForApp(steamID: TSteamID; appID: appid_t): EUserHasLicenseForAppResult;
    function BIsBehindNAT(): Boolean;
    procedure AdvertiseGame(steamIDGameServer: TSteamID; IPServer: uint32; PortServer: uint16);
    function RequestEncryptedAppTicket(DataToInclude: Pointer; cDataToInclude: Integer): SteamAPICall_t;
    function GetEncryptedAppTicket(Ticket: Pointer; MaxTicket: Integer; cTicket: pUint32): Boolean;
    function GetGameBadgeLevel(Series: Integer; Foil: Boolean): Integer;
    function GetPlayerSteamLevel(): Integer;
    function RequestStoreAuthURL(pchRedirectURL: PChar): SteamAPICall_t;
    function BIsPhoneVerified(): Boolean;
    function BIsTwoFactorEnabled(): Boolean;
    function BIsPhoneIdentifying(): Boolean;
    function BIsPhoneRequiringVerification(): Boolean;
    function GetMarketEligibility(): SteamAPICall_t;
  end;

  TSteamFriends = class
  public
    SteamFriendsInterface: ISteamFriends;
    constructor Init(SteamInterface: ISteamFriends);
    function GetPersonaName(): pAnsiChar;
    function SetPersonaName(Name: pAnsiChar): uint64;
    function GetPersonaState(): EPersonaState;
    function GetFriendCount(FriendFlags: Integer): Integer;
    function GetFriendByIndex(Friendindex_, FriendFlags: Integer): TSteamID;
    function GetFriendRelationship(FriendID: TSteamID): EFriendRelationship;
    function GetFriendPersonaState(FriendID: TSteamID): EPersonaState;
    function GetFriendPersonaName(FriendID: TSteamID): pAnsiChar;
    function GetFriendPersonaNameHistory(FriendID: TSteamID; PersonaNameNum: Integer): pAnsiChar;
    function GetPlayerNickname(PlayerID: TSteamID): pAnsiChar;
    function HasFriend(FriendID: TSteamID; FriendFlags: Integer): Boolean;
    function GetClanCount(): Integer;
    function GetClanByIndex(Clan: Integer): TSteamID;
    function GetClanName(ClanID: TSteamID): pAnsiChar;
    function GetClanTag(ClanID: TSteamID): pAnsiChar;
    function GetClanActivityCounts(ClanID: TSteamID; OnlineCount: pInteger; InGameCount: pInteger; ChattingCount: pInteger): Boolean;
    function DownloadClanActivityCounts(ClansIDs: pSteamID; ClansToRequestCount: Integer): uint64;
    function GetFriendCountFromSource(SourceID: TSteamID): Integer;
    function GetFriendFromSourceByIndex(SourceID: TSteamID; Friendindex_: Integer): TSteamID;
    function IsUserInSource(UserID: TSteamID; SourceID: TSteamID): Boolean;
    procedure SetInGameVoiceSpeaking(UserID: TSteamID; IsSpeaking: Boolean);
    procedure ActivateGameOverlay(Dialog: pAnsiChar);
    procedure ActivateGameOverlayToUser(Dialog: pAnsiChar; steamID: TSteamID);
    procedure ActivateGameOverlayToWebPage(URL: pAnsiChar; eMode: EActivateGameOverlayToWebPageMode);
    procedure ActivateGameOverlayToStore(nAppID: AppId_t; eFlag: EOverlayToStoreFlag);
    procedure SetPlayedWith(UserPlayedWithID: TSteamID);
    procedure ActivateGameOverlayInviteDialog(LobbyID: TSteamID);
    function GetSmallFriendAvatar(FriendID: TSteamID): Integer;
    function GetMediumFriendAvatar(FriendID: TSteamID): Integer;
    function GetLargeFriendAvatar(FriendID: TSteamID): Integer;
    function RequestUserInformation(UserID: TSteamID; IsRequireNameOnly: Boolean): Boolean;
    function RequestClanOfficerList(ClanID: TSteamID): uint64;
    function GetClanOwner(ClanID: TSteamID): TSteamID;
    function GetClanOfficerCount(ClanID: TSteamID): Integer;
    function GetClanOfficerByIndex(ClanID: TSteamID; Officerindex_: Integer): TSteamID;
    function GetUserRestrictions(): uint32;
    function SetRichPresence(Key: pAnsiChar; Value: pAnsiChar): Boolean;
    procedure ClearRichPresence();
    function GetFriendRichPresence(FriendID: TSteamID; Key: pAnsiChar): pAnsiChar;
    function GetFriendRichPresenceKeyCount(FriendID: TSteamID): Integer;
    function GetFriendRichPresenceKeyByIndex(FriendID: TSteamID; Keyindex_: Integer): pAnsiChar;
    procedure RequestFriendRichPresence(FriendID: TSteamID);
    function InviteUserToGame(FriendID: TSteamID; ConnectString: pAnsiChar): Boolean;
    function GetCoplayFriendCount(): Integer;
    function GetCoplayFriend(CoplayFriend: Integer): TSteamID;
    function GetFriendCoplayTime(FriendID: TSteamID): Integer;
    function GetFriendCoplayGame(FriendID: TSteamID): uint32;
    function JoinClanChatRoom(ClanID: TSteamID): uint64;
    function LeaveClanChatRoom(ClanID: TSteamID): Boolean;
    function GetClanChatMemberCount(ClanID: TSteamID): Integer;
    function GetChatMemberByIndex(ClanID: TSteamID; Userindex_: Integer): TSteamID;
    function SendClanChatMessage(ClanChatID: TSteamID; Text: pAnsiChar): Boolean;
    function GetClanChatMessage(ClanChatID: TSteamID; Messageindex_: Integer; pText: Pointer; TextMax: Integer; ChatEntryType: EChatEntryType; TeamIDChatter: pSteamID): Integer;
    function IsClanChatAdmin(ClanChatID: TSteamID; UserID: TSteamID): Boolean;
    function IsClanChatWindowOpenInSteam(ClanChatID: TSteamID): Boolean;
    function OpenClanChatWindowInSteam(ClanChatID: TSteamID): Boolean;
    function CloseClanChatWindowInSteam(ClanChatID: TSteamID): Boolean;
    function SetListenForFriendsMessages(IsInterceptEnabled: Boolean): Boolean;
    function ReplyToFriendMessage(FriendID: TSteamID; MsgToSend: pAnsiChar): Boolean;
    function GetFriendMessage(FriendID: TSteamID; Messageindex_: Integer; Data: Pointer; DataSize: Integer; ChatEntryType: EChatEntryType): Integer;
    function GetFollowerCount(steamID: TSteamID): uint64;
    function IsFollowing(steamID: TSteamID): uint64;
    function EnumerateFollowingList(Startindex_: uint32): uint64;
    function IsClanPublic(steamIDClan: TSteamID): Boolean;
    function IsClanOfficialGameGroup(steamIDClan: TSteamID): Boolean;
    function GetNumChatsWithUnreadPriorityMessages(): Integer;
  end;

  TSteamGameServer = class
  public
    SteamGameServerInterface: ISteamGameServer;
    constructor Init(SteamInterface: ISteamGameServer);
    procedure Shutdown();
    procedure RunCallbacks();
    procedure SetProduct(Product: pAnsiChar);
    procedure SetGameDescription(GameDescription: pAnsiChar);
    procedure SetModDir(ModDir: pAnsiChar);
    procedure SetDedicatedServer(IsDedicated: Boolean);
    procedure LogOn(Token: pAnsiChar);
    procedure LogOnAnonymous();
    procedure LogOff();
    function BLoggedOn(): Boolean;
    function BSecure(): Boolean;
    function GetSteamID(): TSteamID;
    function WasRestartRequested(): Boolean;
    procedure SetMaxPlayerCount(PlayersMaxCount: Integer);
    procedure SetBotPlayerCount(BotplayersCount: Integer);
    procedure SetServerName(ServerName: pAnsiChar);
    procedure SetMapName(MapName: pAnsiChar);
    procedure SetPasswordProtected(IsPasswordProtected: Boolean);
    procedure SetSpectatorPort(SpectatorPort: uint16);
    procedure SetSpectatorServerName(SpectatorServerName: pAnsiChar);
    procedure ClearAllKeyValues();
    procedure SetKeyValue(Key, Value: pAnsiChar);
    procedure SetGameTags(GameTags: pAnsiChar);
    procedure SetGameData(GameData: pAnsiChar);
    procedure SetRegion(Region: pAnsiChar);
    function SendUserConnectAndAuthenticate(ClientIP: uint32; AuthBlob: Pointer; AuthBlobSize: uint32; UserSteamID: pSteamID): Boolean;
    function CreateUnauthenticatedUserConnection(): TSteamID;
    procedure SendUserDisconnect(steamIDUser: TSteamID);
    function BUpdateUserData(UserID: TSteamID; PlayerName: pAnsiChar; Score: uint32): Boolean;
    function GetAuthSessionTicket(Ticket: Pointer; MaxTicket: Integer; ActualTicketLength: pUint32): uint32;
    function BeginAuthSession(AuthTicket: Pointer; AuthTicketSize: Integer; steamID: TSteamID): EBeginAuthSessionResult;
    procedure EndAuthSession(steamID: TSteamID);
    procedure CancelAuthTicket(AuthTicket: uint32);
    function UserHasLicenseForApp(steamID: TSteamID; appID: uint32): EUserHasLicenseForAppResult;
    function RequestUserGroupStatus(UserID, GroupID: TSteamID): Boolean;
    function GetPublicIP(): SteamIPAddress_t;
    function HandleIncomingPacket(Data: Pointer; DataSize: Integer; SourceIP: uint32; SourcePort: uint16): Boolean;
    function GetNextOutgoingPacket(pOut: Pointer; MaxOutCount: Integer; NetAddress: pUint32; Port: pUint16): Integer;
    procedure EnableHeartbeats(IsActive: Boolean);
    procedure SetHeartbeatInterval(HeartbeatInterval: Integer);
    procedure ForceHeartbeat();
    function AssociateWithClan(ClanID: TSteamID): uint64;
    function ComputeNewPlayerCompatibility(NewPlayerID: TSteamID): uint64;
  end;

  TSteamGameServerStats = class
  public
    SteamGameServerStatsInterface: ISteamGameServerStats;
    constructor Init(SteamInterface: ISteamGameServerStats);
    function RequestUserStats(steamIDUser: TSteamID): SteamAPICall_t;
    function GetUserStatInt32(steamIDUser: TSteamID; pchName: PChar; pData: pint32): Boolean;
    function GetUserStatFloat(steamIDUser: TSteamID; pchName: PChar; pData: pSingle): Boolean;
    function GetUserAchievement(steamIDUser: TSteamID; pchName: PChar; pbAchieved: pBoolean): Boolean;
    function SetUserStatInt32(steamIDUser: TSteamID; pchName: PChar; nData: int32): Boolean;
    function SetUserStatFloat(steamIDUser: TSteamID; pchName: PChar; fData: single): Boolean;
    function UpdateUserAvgRateStat(steamIDUser: TSteamID; pchName: PChar; flCountThisSession: Single; dSessionLength: Double): Boolean;
    function SetUserAchievement(steamIDUser: TSteamID; pchName: PChar): Boolean;
    function ClearUserAchievement(steamIDUser: TSteamID; pchName: PChar): Boolean;
    function StoreUserStats(steamIDUser: TSteamID): SteamAPICall_t;
  end;

  TSteamScreenshots = class
  public
    SteamScreenshotsInterface: ISteamScreenshots;
    constructor Init(SteamInterface: ISteamScreenshots);
    function WriteScreenshot(pRGB: Pointer; cubRGB: uint32; Width, Height: Integer): uint32;
    function AddScreenshotToLibrary(Filename: pAnsiChar; ThumbnailFilename: pAnsiChar; Width, Height: Integer): uint32;
    procedure TriggerScreenshot(); cdecl;
    procedure HookScreenshots(Hook: Boolean);
    function SetLocation(Screenshot: uint32; Location: pAnsiChar): Boolean;
    function TagUser(Screenshot: uint32; steamID: TSteamID): Boolean;
    function TagPublishedFile(Screenshot: uint32; PublishedFileId: uint64): Boolean;
    function IsScreenshotsHooked(): Boolean;
  end;

  TSteamUGC = class
  public
    SteamUGCInterface: ISteamUGC;
    constructor Init(SteamInterface: ISteamUGC);
    function CreateQueryUserUGCRequest(AccountID: uint32; ListType: EUserUGCList; eMatchingUGCType: EUGCMatchingUGCType; eSortOrder: EUserUGCListSortOrder; nCreatorAppID, nConsumerAppId, unPage: uint32): uint64;
    function CreateQueryAllUGCRequestPage(QueryType: EUGCQuery; MatchingeMatchingUGCTypeFileType: EUGCMatchingUGCType; nCreatorAppID, nConsumerAppId, unPage: uint32): uint64;
    function CreateQueryAllUGCRequestCursor(QueryType: EUGCQuery; MatchingeMatchingUGCTypeFileType: EUGCMatchingUGCType; nCreatorAppID, nConsumerAppId: uint32; pchCursor: PChar): uint64;
    function CreateQueryUGCDetailsRequest(pvecPublishedFileID: pPublishedFileId_t; unNumPublishedFileIDs: uint32): UGCQueryHandle_t;
    function SendQueryUGCRequest(Handle: uint64): uint64;
    function GetQueryUGCResult(Handle: uint64; index_: uint32; Details: pSteamUGCDetails_t): Boolean;
    function ReleaseQueryUGCRequest(Handle: uint64): Boolean;
    function RequestUGCDetails(PublishedFileId: uint64; MaxAgeSeconds: uint32): uint64;
    function GetItemUpdateProgress(Handle: uint64; BytesProcessed, BytesTotal: puint64): EItemUpdateStatus;
    function SubscribeItem(PublishedFileId: uint64): uint64;
    function UnsubscribeItem(PublishedFileId: uint64): uint64;
    function GetNumSubscribedItems: uint32;
    function GetSubscribedItems(PublishedFileId: puint64; MaxEntries: uint32): uint32;
    function GetItemInstallInfo(PublishedFileId: uint64; SizeOnDisk: puint64; Folder: pAnsiChar; FolderSize: uint32; TimeStamp: puint32): Boolean;
    function GetItemState(nPublishedFileID: uint64): uint32;
    function GetItemDownloadInfo(nPublishedFileID: uint64; punBytesDownloaded: puint64; punBytesTotal: puint64): Boolean;
    function DownloadItem(nPublishedFileID: uint64; bHighPriority: Boolean): Boolean;
    function BInitWorkshopForGameServer(unWorkshopDepotID: uint32; pszFolder: PAnsiChar): Boolean;
    procedure SuspendDownloads(bSuspend: Boolean);
    function StartPlaytimeTracking(pvecPublishedFileID: puint64; unNumPublishedFileIDs: uint32): uint64;
    function StopPlaytimeTracking(pvecPublishedFileID: puint64; unNumPublishedFileIDs: uint32): uint64;
    function StopPlaytimeTrackingForAllItems(): uint64;
    function GetAppDependencies(nPublishedFileID: PublishedFileId_t): SteamAPICall_t;
    function SetReturnChildren(handle: UGCQueryHandle_t; bReturnChildren: Boolean): Boolean;
    function SetReturnOnlyIDs(handle: UGCQueryHandle_t; bReturnOnlyIDs: Boolean): Boolean;
    function GetQueryUGCChildren(handle: UGCQueryHandle_t; index_: uint32; pvecPublishedFileID: pPublishedFileId_t; cMaxEntries: uint32): Boolean;
  end;

  TSteam = class
  public
    SteamPipeHandle: HSteamPipe;
    Utils: TSteamUtils;
    User: TSteamUser;
    Screenshots: TSTeamScreenshots;
    Friends: TSteamFriends;
    UGC: TSteamUGC;
    constructor Init();
  end;

  TSteamGS = class
  public
    SteamPipeHandle: HSteamPipe;
    Utils: TSteamUtils;
    GameServer: TSteamGameServer;
    GameServerStats: TSteamGameServerStats;
    UGC: TSteamUGC;
    constructor Init(unIP: uint32; usGamePort: uint16; usQueryPort: uint16; ServerMode: EServerMode; pchVersionString: PChar);
  end;

implementation

constructor TSteam.Init;
begin
  if not SteamAPI_Init() then
    raise Exception.Create('SteamAPI_Init has failed');
  
  SteamPipeHandle := SteamAPI_GetHSteamPipe();

  if SteamPipeHandle = 0 then
    raise Exception.Create('SteamPipeHandle is null');

  UGC := TSteamUGC.Init(SteamAPI_SteamUGC_v014());
  Utils := TSteamUtils.Init(SteamAPI_SteamUtils_v009());
  User := TSteamUser.Init(SteamAPI_SteamUser_v021());
  Screenshots := TSteamScreenshots.Init(SteamAPI_SteamScreenshots_v003());
  Friends := TSteamFriends.Init(SteamAPI_SteamFriends_v017());
end;

constructor TSteamGS.Init(unIP: uint32; usGamePort: uint16; usQueryPort: uint16; ServerMode: EServerMode; pchVersionString: PChar);
begin
  if not SteamInternal_GameServer_Init(unIP, 0, usGamePort, usQueryPort, ServerMode, pchVersionString) then
    raise Exception.Create('SteamAPI_GameServer_Init has failed');

  SteamPipeHandle := SteamGameServer_GetHSteamPipe();

  UGC := TSteamUGC.Init(SteamAPI_SteamGameServerUGC_v014());
  Utils := TSteamUtils.Init(SteamAPI_SteamGameServerUtils_v009());
  GameServer := TSteamGameServer.Init(SteamAPI_SteamGameServer_v013());
  GameServerStats := TSteamGameServerStats.Init(SteamAPI_SteamGameServerStats_v001());
end;


constructor TSteamUtils.Init(SteamInterface: ISteamUtils);
begin
  if SteamInterface = nil then
    raise Exception.Create('TSteamUtils.Init has failed');
  SteamUtilsInterface := SteamInterface;
end;

function TSteamUtils.GetAppID(): longint;
begin
  Result := SteamAPI_ISteamUtils_GetAppID(SteamUtilsInterface);
end;

function TSteamUtils.GetImageSize(Image: Integer; Width: pUint32; Height: pUint32): Boolean;
begin
  Result := SteamAPI_ISteamUtils_GetImageSize(SteamUtilsInterface, Image, Width, Height);
end;

function TSteamUtils.GetImageRGBA(Image: Integer; Dest: pUint8; DestBufferSize: Integer): Boolean;
begin
  Result := SteamAPI_ISteamUtils_GetImageRGBA(SteamUtilsInterface, Image, Dest, DestBufferSize);
end;

procedure TSteamUtils.SetWarningMessageHook(Fn: TSteamAPIWarningMessageHook);
begin
  //SteamAPI_ISteamUtils_SetWarningMessageHook(SteamUtilsInterface, Fn);
end;

function TSteamUtils.IsOverlayEnabled(): Boolean;
begin
  Result := SteamAPI_ISteamUtils_IsOverlayEnabled(SteamUtilsInterface);
end;

constructor TSteamUser.Init(SteamInterface: ISteamUser);
begin
  if SteamInterface = nil then
    raise Exception.Create('TSteamUser.Init has failed');
  SteamUserInterface := SteamInterface;
end;

function TSteamUser.BLoggedOn(): Boolean;
begin
  Result := SteamAPI_ISteamUser_BLoggedOn(SteamUserInterface);
end;

function TSteamUser.GetSteamID(): TSteamID;
begin
  Result := SteamAPI_ISteamUser_GetSteamID(SteamUserInterface);
end;

function TSteamUser.GetAvailableVoice(Compressed, cUncompressed: pUint32; UncompressedVoiceDesiredSampleRate: uint32): EVoiceResult; cdecl;
begin
  Result := SteamAPI_ISteamUser_GetAvailableVoice(SteamUserInterface, Compressed, cUncompressed, UncompressedVoiceDesiredSampleRate);
end;

function TSteamUser.GetVoice(WantCompressed: Boolean; DestBuffer: Pointer; cDestBufferSize: uint32; BytesWritten: pUint32; WantUncompressed: Boolean; UncompressedDestBuffer: Pointer; cUncompressedDestBufferSize: uint32; nUncompressBytesWritten: pUint32; UncompressedVoiceDesiredSampleRate: uint32): EVoiceResult;
begin
  Result := SteamAPI_ISteamUser_GetVoice(SteamUserInterface, WantCompressed, DestBuffer, cDestBufferSize, BytesWritten, WantUncompressed, UncompressedDestBuffer, cUncompressedDestBufferSize, nUncompressBytesWritten, UncompressedVoiceDesiredSampleRate);
end;

function TSteamUser.DecompressVoice(Compressed: Pointer; cCompressed: uint32; DestBuffer: Pointer; DestBufferSize: uint32; BytesWritten: pUint32; DesiredSampleRate: uint32): EVoiceResult;
begin
  Result := SteamAPI_ISteamUser_DecompressVoice(SteamUserInterface, Compressed, cCompressed, DestBuffer, DestBufferSize, BytesWritten, DesiredSampleRate);
end;

procedure TSteamUser.StartVoiceRecording(); cdecl;
begin
  SteamAPI_ISteamUser_StartVoiceRecording(SteamUserInterface);
end;

procedure TSteamUser.StopVoiceRecording(); cdecl;
begin
  SteamAPI_ISteamUser_StopVoiceRecording(SteamUserInterface);
end;

function TSteamUser.GetAuthSessionTicket(Ticket: Pointer; MaxTicket: Integer; cTicket: pUint32): TAuthTicket;
begin
  Result := SteamAPI_ISteamUser_GetAuthSessionTicket(SteamUserInterface, Ticket, MaxTicket, cTicket);
end;

function TSteamUser.BeginAuthSession(AuthTicket: Pointer; cAuthTicket: Integer; steamID: TSteamID): EBeginAuthSessionResult;
begin
  Result := SteamAPI_ISteamUser_BeginAuthSession(SteamUserInterface, AuthTicket, cAuthTicket, steamID);
end;

procedure TSteamUser.EndAuthSession(steamID: TSteamID);
begin
  SteamAPI_ISteamUser_EndAuthSession(SteamUserInterface, steamID);
end;

procedure TSteamUser.CancelAuthTicket(AuthTicket: TAuthTicket);
begin
  SteamAPI_ISteamUser_CancelAuthTicket(SteamUserInterface, AuthTicket);
end;

function TSteamUser.UserHasLicenseForApp(steamID: TSteamID; appID: appid_t): EUserHasLicenseForAppResult;
begin
  Result := SteamAPI_ISteamUser_UserHasLicenseForApp(SteamUserInterface, steamID, appID);
end;
function TSteamUser.BIsBehindNAT(): Boolean;
begin
  Result := SteamAPI_ISteamUser_BIsBehindNAT(SteamUserInterface);
end;
procedure TSteamUser.AdvertiseGame(steamIDGameServer: TSteamID; IPServer: uint32; PortServer: uint16);
begin
  SteamAPI_ISteamUser_AdvertiseGame(SteamUserInterface, steamIDGameServer, IPServer, PortServer);
end;
function TSteamUser.RequestEncryptedAppTicket(DataToInclude: Pointer; cDataToInclude: Integer): SteamAPICall_t;
begin
  Result := SteamAPI_ISteamUser_RequestEncryptedAppTicket(SteamUserInterface, DataToInclude, cDataToInclude);
end;
function TSteamUser.GetEncryptedAppTicket(Ticket: Pointer; MaxTicket: Integer; cTicket: pUint32): Boolean;
begin
  Result := SteamAPI_ISteamUser_GetEncryptedAppTicket(SteamUserInterface, Ticket, MaxTicket, cTicket);
end;
function TSteamUser.GetGameBadgeLevel(Series: Integer; Foil: Boolean): Integer;
begin
  Result := SteamAPI_ISteamUser_GetGameBadgeLevel(SteamUserInterface, Series, Foil);
end;
function TSteamUser.GetPlayerSteamLevel(): Integer;
begin
  Result := SteamAPI_ISteamUser_GetPlayerSteamLevel(SteamUserInterface);
end;
function TSteamUser.RequestStoreAuthURL(pchRedirectURL: PChar): SteamAPICall_t;
begin
  Result := SteamAPI_ISteamUser_RequestStoreAuthURL(SteamUserInterface, pchRedirectURL);
end;
function TSteamUser.BIsPhoneVerified(): Boolean;
begin
  Result := SteamAPI_ISteamUser_BIsPhoneVerified(SteamUserInterface);
end;
function TSteamUser.BIsTwoFactorEnabled(): Boolean;
begin
  Result := SteamAPI_ISteamUser_BIsTwoFactorEnabled(SteamUserInterface);
end;
function TSteamUser.BIsPhoneIdentifying(): Boolean;
begin
  Result := SteamAPI_ISteamUser_BIsPhoneIdentifying(SteamUserInterface);
end;
function TSteamUser.BIsPhoneRequiringVerification(): Boolean;
begin
  Result := SteamAPI_ISteamUser_BIsPhoneRequiringVerification(SteamUserInterface);
end;
function TSteamUser.GetMarketEligibility(): SteamAPICall_t;
begin
  Result := SteamAPI_ISteamUser_GetMarketEligibility(SteamUserInterface);
end;

constructor TSteamScreenshots.Init(SteamInterface: ISteamScreenshots);
begin
  if SteamInterface = nil then
    raise Exception.Create('TSteamScreenshots.Init has failed');
  SteamScreenshotsInterface := SteamInterface;
end;

function TSteamScreenshots.WriteScreenshot(pRGB: Pointer; cubRGB: uint32; Width, Height: Integer): uint32;
begin
  Result := SteamAPI_ISteamScreenshots_WriteScreenshot(SteamScreenshotsInterface, pRGB, cubRGB, Width, Height);
end;
function TSteamScreenshots.AddScreenshotToLibrary(Filename: pAnsiChar; ThumbnailFilename: pAnsiChar; Width, Height: Integer): uint32;
begin
  Result := SteamAPI_ISteamScreenshots_AddScreenshotToLibrary(SteamScreenshotsInterface, Filename, ThumbnailFilename, Width, Height);
end;
procedure TSteamScreenshots.TriggerScreenshot(); cdecl;
begin
  SteamAPI_ISteamScreenshots_TriggerScreenshot(SteamScreenshotsInterface);
end;
procedure TSteamScreenshots.HookScreenshots(Hook: Boolean);
begin
  SteamAPI_ISteamScreenshots_HookScreenshots(SteamScreenshotsInterface, Hook);
end;
function TSteamScreenshots.SetLocation(Screenshot: uint32; Location: pAnsiChar): Boolean;
begin
  Result := SteamAPI_ISteamScreenshots_SetLocation(SteamScreenshotsInterface, Screenshot, Location);
end;
function TSteamScreenshots.TagUser(Screenshot: uint32; steamID: TSteamID): Boolean;
begin
  Result := SteamAPI_ISteamScreenshots_TagUser(SteamScreenshotsInterface, Screenshot, steamID);
end;
function TSteamScreenshots.TagPublishedFile(Screenshot: uint32; PublishedFileId: uint64): Boolean;
begin
  Result := SteamAPI_ISteamScreenshots_TagPublishedFile(SteamScreenshotsInterface, Screenshot, PublishedFileId);
end;
function TSteamScreenshots.IsScreenshotsHooked(): Boolean;
begin
  Result := SteamAPI_ISteamScreenshots_IsScreenshotsHooked(SteamScreenshotsInterface);
end;

constructor TSteamFriends.Init(SteamInterface: Pointer);
begin
  SteamFriendsInterface := SteamInterface;
end;

function TSteamFriends.GetPersonaName(): pAnsiChar;
begin
  Result := SteamAPI_ISteamFriends_GetPersonaName(SteamFriendsInterface);
end;

function TSteamFriends.SetPersonaName(Name: pAnsiChar): uint64;
begin
  Result := SteamAPI_ISteamFriends_SetPersonaName(SteamFriendsInterface, Name);
end;
function TSteamFriends.GetPersonaState(): EPersonaState;
begin
  Result := SteamAPI_ISteamFriends_GetPersonaState(SteamFriendsInterface);
end;
function TSteamFriends.GetFriendCount(FriendFlags: Integer): Integer;
begin
  Result := SteamAPI_ISteamFriends_GetFriendCount(SteamFriendsInterface, FriendFlags);
end;
function TSteamFriends.GetFriendByIndex(Friendindex_, FriendFlags: Integer): TSteamID;
begin
  Result := SteamAPI_ISteamFriends_GetFriendByIndex(SteamFriendsInterface, Friendindex_, FriendFlags);
end;
function TSteamFriends.GetFriendRelationship(FriendID: TSteamID): EFriendRelationship;
begin
  Result := SteamAPI_ISteamFriends_GetFriendRelationship(SteamFriendsInterface, FriendID);
end;
function TSteamFriends.GetFriendPersonaState(FriendID: TSteamID): EPersonaState;
begin
  Result := SteamAPI_ISteamFriends_GetFriendPersonaState(SteamFriendsInterface, FriendID);
end;
function TSteamFriends.GetFriendPersonaName(FriendID: TSteamID): pAnsiChar;
begin
  Result := SteamAPI_ISteamFriends_GetFriendPersonaName(SteamFriendsInterface, FriendID);
end;
function TSteamFriends.GetFriendPersonaNameHistory(FriendID: TSteamID; PersonaNameNum: Integer): pAnsiChar;
begin
  Result := SteamAPI_ISteamFriends_GetFriendPersonaNameHistory(SteamFriendsInterface, FriendID, PersonaNameNum);
end;
function TSteamFriends.GetPlayerNickname(PlayerID: TSteamID): pAnsiChar;
begin
  Result := SteamAPI_ISteamFriends_GetPlayerNickname(SteamFriendsInterface, PlayerID);
end;
function TSteamFriends.HasFriend(FriendID: TSteamID; FriendFlags: Integer): Boolean;
begin
  Result := SteamAPI_ISteamFriends_HasFriend(SteamFriendsInterface, FriendID, FriendFlags);
end;
function TSteamFriends.GetClanCount(): Integer;
begin
  Result := SteamAPI_ISteamFriends_GetClanCount(SteamFriendsInterface);
end;
function TSteamFriends.GetClanByIndex(Clan: Integer): TSteamID;
begin
  Result := SteamAPI_ISteamFriends_GetClanByIndex(SteamFriendsInterface, Clan);
end;
function TSteamFriends.GetClanName(ClanID: TSteamID): pAnsiChar;
begin
  Result := SteamAPI_ISteamFriends_GetClanName(SteamFriendsInterface, ClanID);
end;
function TSteamFriends.GetClanTag(ClanID: TSteamID): pAnsiChar;
begin
  Result := SteamAPI_ISteamFriends_GetClanTag(SteamFriendsInterface, ClanID);
end;
function TSteamFriends.GetClanActivityCounts(ClanID: TSteamID; OnlineCount: pInteger; InGameCount: pInteger; ChattingCount: pInteger): Boolean;
begin
  Result := SteamAPI_ISteamFriends_GetClanActivityCounts(SteamFriendsInterface, ClanID, OnlineCount, InGameCount, ChattingCount);
end;
function TSteamFriends.DownloadClanActivityCounts(ClansIDs: pSteamID; ClansToRequestCount: Integer): uint64;
begin
  Result := SteamAPI_ISteamFriends_DownloadClanActivityCounts(SteamFriendsInterface, ClansIDs, ClansToRequestCount);
end;
function TSteamFriends.GetFriendCountFromSource(SourceID: TSteamID): Integer;
begin
  Result := SteamAPI_ISteamFriends_GetFriendCountFromSource(SteamFriendsInterface, SourceID);
end;
function TSteamFriends.GetFriendFromSourceByIndex(SourceID: TSteamID; Friendindex_: Integer): TSteamID;
begin
  Result := SteamAPI_ISteamFriends_GetFriendFromSourceByIndex(SteamFriendsInterface, SourceID, Friendindex_);
end;
function TSteamFriends.IsUserInSource(UserID: TSteamID; SourceID: TSteamID): Boolean;
begin
  Result := SteamAPI_ISteamFriends_IsUserInSource(SteamFriendsInterface, UserID, SourceID);
end;
procedure TSteamFriends.SetInGameVoiceSpeaking(UserID: TSteamID; IsSpeaking: Boolean);
begin
  SteamAPI_ISteamFriends_SetInGameVoiceSpeaking(SteamFriendsInterface, UserID, IsSpeaking);
end;
procedure TSteamFriends.ActivateGameOverlay(Dialog: pAnsiChar);
begin
  SteamAPI_ISteamFriends_ActivateGameOverlay(SteamFriendsInterface, Dialog);
end;
procedure TSteamFriends.ActivateGameOverlayToUser(Dialog: pAnsiChar; steamID: TSteamID);
begin
  SteamAPI_ISteamFriends_ActivateGameOverlayToUser(SteamFriendsInterface, Dialog, steamID);
end;
procedure TSteamFriends.ActivateGameOverlayToWebPage(URL: pAnsiChar; eMode: EActivateGameOverlayToWebPageMode);
begin
  SteamAPI_ISteamFriends_ActivateGameOverlayToWebPage(SteamFriendsInterface, URL, eMode);
end;
procedure TSteamFriends.ActivateGameOverlayToStore(nAppID: AppId_t; eFlag: EOverlayToStoreFlag);
begin
  SteamAPI_ISteamFriends_ActivateGameOverlayToStore(SteamFriendsInterface, nAppID, eFlag);
end;
procedure TSteamFriends.SetPlayedWith(UserPlayedWithID: TSteamID);
begin
  SteamAPI_ISteamFriends_SetPlayedWith(SteamFriendsInterface, UserPlayedWithID);
end;
procedure TSteamFriends.ActivateGameOverlayInviteDialog(LobbyID: TSteamID);
begin
  SteamAPI_ISteamFriends_ActivateGameOverlayInviteDialog(SteamFriendsInterface, LobbyID);
end;
function TSteamFriends.GetSmallFriendAvatar(FriendID: TSteamID): Integer;
begin
  Result := SteamAPI_ISteamFriends_GetSmallFriendAvatar(SteamFriendsInterface, FriendID);
end;
function TSteamFriends.GetMediumFriendAvatar(FriendID: TSteamID): Integer;
begin
  Result := SteamAPI_ISteamFriends_GetMediumFriendAvatar(SteamFriendsInterface, FriendID);
end;
function TSteamFriends.GetLargeFriendAvatar(FriendID: TSteamID): Integer;
begin
  Result := SteamAPI_ISteamFriends_GetLargeFriendAvatar(SteamFriendsInterface, FriendID);
end;
function TSteamFriends.RequestUserInformation(UserID: TSteamID; IsRequireNameOnly: Boolean): Boolean;
begin
  Result := SteamAPI_ISteamFriends_RequestUserInformation(SteamFriendsInterface, UserID, IsRequireNameOnly);
end;
function TSteamFriends.RequestClanOfficerList(ClanID: TSteamID): uint64;
begin
  Result := SteamAPI_ISteamFriends_RequestClanOfficerList(SteamFriendsInterface, ClanID);
end;
function TSteamFriends.GetClanOwner(ClanID: TSteamID): TSteamID;
begin
  Result := SteamAPI_ISteamFriends_GetClanOwner(SteamFriendsInterface, ClanID);
end;
function TSteamFriends.GetClanOfficerCount(ClanID: TSteamID): Integer;
begin
  Result := SteamAPI_ISteamFriends_GetClanOfficerCount(SteamFriendsInterface, ClanID);
end;
function TSteamFriends.GetClanOfficerByIndex(ClanID: TSteamID; Officerindex_: Integer): TSteamID;
begin
  Result := SteamAPI_ISteamFriends_GetClanOfficerByIndex(SteamFriendsInterface, ClanID, Officerindex_);
end;
function TSteamFriends.GetUserRestrictions(): uint32;
begin
  Result := SteamAPI_ISteamFriends_GetUserRestrictions(SteamFriendsInterface);
end;
function TSteamFriends.SetRichPresence(Key: pAnsiChar; Value: pAnsiChar): Boolean;
begin
  Result := SteamAPI_ISteamFriends_SetRichPresence(SteamFriendsInterface, Key, Value);
end;
procedure TSteamFriends.ClearRichPresence();
begin
  SteamAPI_ISteamFriends_ClearRichPresence(SteamFriendsInterface);
end;
function TSteamFriends.GetFriendRichPresence(FriendID: TSteamID; Key: pAnsiChar): pAnsiChar;
begin
  Result := SteamAPI_ISteamFriends_GetFriendRichPresence(SteamFriendsInterface, FriendID, Key);
end;
function TSteamFriends.GetFriendRichPresenceKeyCount(FriendID: TSteamID): Integer;
begin
  Result := SteamAPI_ISteamFriends_GetFriendRichPresenceKeyCount(SteamFriendsInterface, FriendID);
end;
function TSteamFriends.GetFriendRichPresenceKeyByIndex(FriendID: TSteamID; Keyindex_: Integer): pAnsiChar;
begin
  Result := SteamAPI_ISteamFriends_GetFriendRichPresenceKeyByIndex(SteamFriendsInterface, FriendID, Keyindex_);
end;
procedure TSteamFriends.RequestFriendRichPresence(FriendID: TSteamID);
begin
  SteamAPI_ISteamFriends_RequestFriendRichPresence(SteamFriendsInterface, FriendID);
end;
function TSteamFriends.InviteUserToGame(FriendID: TSteamID; ConnectString: pAnsiChar): Boolean;
begin
  Result := SteamAPI_ISteamFriends_InviteUserToGame(SteamFriendsInterface, FriendID, ConnectString);
end;
function TSteamFriends.GetCoplayFriendCount(): Integer;
begin
  Result := SteamAPI_ISteamFriends_GetCoplayFriendCount(SteamFriendsInterface);
end;
function TSteamFriends.GetCoplayFriend(CoplayFriend: Integer): TSteamID;
begin
  Result := SteamAPI_ISteamFriends_GetCoplayFriend(SteamFriendsInterface, CoplayFriend);
end;
function TSteamFriends.GetFriendCoplayTime(FriendID: TSteamID): Integer;
begin
  Result := SteamAPI_ISteamFriends_GetFriendCoplayTime(SteamFriendsInterface, FriendID);
end;
function TSteamFriends.GetFriendCoplayGame(FriendID: TSteamID): uint32;
begin
  Result := SteamAPI_ISteamFriends_GetFriendCoplayGame(SteamFriendsInterface, FriendID);
end;
function TSteamFriends.JoinClanChatRoom(ClanID: TSteamID): uint64;
begin
  Result := SteamAPI_ISteamFriends_JoinClanChatRoom(SteamFriendsInterface, ClanID);
end;
function TSteamFriends.LeaveClanChatRoom(ClanID: TSteamID): Boolean;
begin
  Result := SteamAPI_ISteamFriends_LeaveClanChatRoom(SteamFriendsInterface, ClanID);
end;
function TSteamFriends.GetClanChatMemberCount(ClanID: TSteamID): Integer;
begin
  Result := SteamAPI_ISteamFriends_GetClanChatMemberCount(SteamFriendsInterface, ClanID);
end;
function TSteamFriends.GetChatMemberByIndex(ClanID: TSteamID; Userindex_: Integer): TSteamID;
begin
  Result := SteamAPI_ISteamFriends_GetChatMemberByIndex(SteamFriendsInterface, ClanID, Userindex_);
end;
function TSteamFriends.SendClanChatMessage(ClanChatID: TSteamID; Text: pAnsiChar): Boolean;
begin
  Result := SteamAPI_ISteamFriends_SendClanChatMessage(SteamFriendsInterface, ClanChatID, Text);
end;
function TSteamFriends.GetClanChatMessage(ClanChatID: TSteamID; Messageindex_: Integer; pText: Pointer; TextMax: Integer; ChatEntryType: EChatEntryType; TeamIDChatter: pSteamID): Integer;
begin
  Result := SteamAPI_ISteamFriends_GetClanChatMessage(SteamFriendsInterface, ClanChatID, Messageindex_, pText, TextMax, ChatEntryType, TeamIDChatter);
end;
function TSteamFriends.IsClanChatAdmin(ClanChatID: TSteamID; UserID: TSteamID): Boolean;
begin
  Result := SteamAPI_ISteamFriends_IsClanChatAdmin(SteamFriendsInterface, ClanChatID, UserID);
end;
function TSteamFriends.IsClanChatWindowOpenInSteam(ClanChatID: TSteamID): Boolean;
begin
  Result := SteamAPI_ISteamFriends_IsClanChatWindowOpenInSteam(SteamFriendsInterface, ClanChatID);
end;
function TSteamFriends.OpenClanChatWindowInSteam(ClanChatID: TSteamID): Boolean;
begin
  Result := SteamAPI_ISteamFriends_OpenClanChatWindowInSteam(SteamFriendsInterface, ClanChatID);
end;
function TSteamFriends.CloseClanChatWindowInSteam(ClanChatID: TSteamID): Boolean;
begin
  Result := SteamAPI_ISteamFriends_CloseClanChatWindowInSteam(SteamFriendsInterface, ClanChatID);
end;
function TSteamFriends.SetListenForFriendsMessages(IsInterceptEnabled: Boolean): Boolean;
begin
  Result := SteamAPI_ISteamFriends_SetListenForFriendsMessages(SteamFriendsInterface, IsInterceptEnabled);
end;
function TSteamFriends.ReplyToFriendMessage(FriendID: TSteamID; MsgToSend: pAnsiChar): Boolean;
begin
  Result := SteamAPI_ISteamFriends_ReplyToFriendMessage(SteamFriendsInterface, FriendID, MsgToSend);
end;
function TSteamFriends.GetFriendMessage(FriendID: TSteamID; Messageindex_: Integer; Data: Pointer; DataSize: Integer; ChatEntryType: EChatEntryType): Integer;
begin
  Result := SteamAPI_ISteamFriends_GetFriendMessage(SteamFriendsInterface, FriendID, Messageindex_, Data, DataSize, ChatEntryType);
end;
function TSteamFriends.GetFollowerCount(steamID: TSteamID): uint64;
begin
  Result := SteamAPI_ISteamFriends_GetFollowerCount(SteamFriendsInterface, steamID);
end;
function TSteamFriends.IsFollowing(steamID: TSteamID): uint64;
begin
  Result := SteamAPI_ISteamFriends_IsFollowing(SteamFriendsInterface, steamID);
end;
function TSteamFriends.EnumerateFollowingList(Startindex_: uint32): uint64;
begin
  Result := SteamAPI_ISteamFriends_EnumerateFollowingList(SteamFriendsInterface, Startindex_);
end;
function TSteamFriends.IsClanPublic(steamIDClan: TSteamID): Boolean;
begin
  Result := SteamAPI_ISteamFriends_IsClanPublic(SteamFriendsInterface, steamIDClan);
end;
function TSteamFriends.IsClanOfficialGameGroup(steamIDClan: TSteamID): Boolean;
begin
  Result := SteamAPI_ISteamFriends_IsClanOfficialGameGroup(SteamFriendsInterface, steamIDClan);
end;
function TSteamFriends.GetNumChatsWithUnreadPriorityMessages(): Integer;
begin
  Result := SteamAPI_ISteamFriends_GetNumChatsWithUnreadPriorityMessages(SteamFriendsInterface);
end;

constructor TSteamGameServer.Init(SteamInterface: Pointer);
begin
  SteamGameServerInterface := SteamInterface;
end;
procedure TSteamGameServer.Shutdown();
begin
  SteamGameServer_Shutdown(SteamGameServerInterface);
end;
procedure TSteamGameServer.RunCallbacks();
begin
  SteamGameServer_RunCallbacks(SteamGameServerInterface);
end;
procedure TSteamGameServer.SetProduct(Product: pAnsiChar);
begin
  SteamAPI_ISteamGameServer_SetProduct(SteamGameServerInterface, Product);
end;
procedure TSteamGameServer.SetGameDescription(GameDescription: pAnsiChar);
begin
  SteamAPI_ISteamGameServer_SetGameDescription(SteamGameServerInterface, GameDescription);
end;
procedure TSteamGameServer.SetModDir(ModDir: pAnsiChar);
begin
  SteamAPI_ISteamGameServer_SetModDir(SteamGameServerInterface, ModDir);
end;
procedure TSteamGameServer.SetDedicatedServer(IsDedicated: Boolean);
begin
  SteamAPI_ISteamGameServer_SetDedicatedServer(SteamGameServerInterface, IsDedicated);
end;
procedure TSteamGameServer.LogOn(Token: pAnsiChar);
begin
  SteamAPI_ISteamGameServer_LogOn(SteamGameServerInterface, Token);
end;
procedure TSteamGameServer.LogOnAnonymous();
begin
  SteamAPI_ISteamGameServer_LogOnAnonymous(SteamGameServerInterface);
end;
procedure TSteamGameServer.LogOff();
begin
  SteamAPI_ISteamGameServer_LogOff(SteamGameServerInterface);
end;
function TSteamGameServer.BLoggedOn(): Boolean;
begin
  Result := SteamAPI_ISteamGameServer_BLoggedOn(SteamGameServerInterface);
end;
function TSteamGameServer.BSecure(): Boolean;
begin
  Result := SteamAPI_ISteamGameServer_BSecure(SteamGameServerInterface);
end;
function TSteamGameServer.GetSteamID(): TSteamID;
begin
  Result := SteamAPI_ISteamGameServer_GetSteamID(SteamGameServerInterface);
end;
function TSteamGameServer.WasRestartRequested(): Boolean;
begin
  Result := SteamAPI_ISteamGameServer_WasRestartRequested(SteamGameServerInterface);
end;
procedure TSteamGameServer.SetMaxPlayerCount(PlayersMaxCount: Integer);
begin
  SteamAPI_ISteamGameServer_SetMaxPlayerCount(SteamGameServerInterface, PlayersMaxCount);
end;
procedure TSteamGameServer.SetBotPlayerCount(BotplayersCount: Integer);
begin
  SteamAPI_ISteamGameServer_SetBotPlayerCount(SteamGameServerInterface, BotplayersCount);
end;
procedure TSteamGameServer.SetServerName(ServerName: pAnsiChar);
begin
  SteamAPI_ISteamGameServer_SetServerName(SteamGameServerInterface, ServerName);
end;
procedure TSteamGameServer.SetMapName(MapName: pAnsiChar);
begin
  SteamAPI_ISteamGameServer_SetMapName(SteamGameServerInterface, MapName);
end;
procedure TSteamGameServer.SetPasswordProtected(IsPasswordProtected: Boolean);
begin
  SteamAPI_ISteamGameServer_SetPasswordProtected(SteamGameServerInterface, IsPasswordProtected);
end;
procedure TSteamGameServer.SetSpectatorPort(SpectatorPort: uint16);
begin
  SteamAPI_ISteamGameServer_SetSpectatorPort(SteamGameServerInterface, SpectatorPort);
end;
procedure TSteamGameServer.SetSpectatorServerName(SpectatorServerName: pAnsiChar);
begin
  SteamAPI_ISteamGameServer_SetSpectatorServerName(SteamGameServerInterface, SpectatorServerName);
end;
procedure TSteamGameServer.ClearAllKeyValues();
begin
  SteamAPI_ISteamGameServer_ClearAllKeyValues(SteamGameServerInterface);
end;
procedure TSteamGameServer.SetKeyValue(Key, Value: pAnsiChar);
begin
  SteamAPI_ISteamGameServer_SetKeyValue(SteamGameServerInterface, Key, Value);
end;
procedure TSteamGameServer.SetGameTags(GameTags: pAnsiChar);
begin
  SteamAPI_ISteamGameServer_SetGameTags(SteamGameServerInterface, GameTags);
end;
procedure TSteamGameServer.SetGameData(GameData: pAnsiChar);
begin
  SteamAPI_ISteamGameServer_SetGameData(SteamGameServerInterface, GameData);
end;
procedure TSteamGameServer.SetRegion(Region: pAnsiChar);
begin
  SteamAPI_ISteamGameServer_SetRegion(SteamGameServerInterface, Region);
end;
function TSteamGameServer.SendUserConnectAndAuthenticate(ClientIP: uint32; AuthBlob: Pointer; AuthBlobSize: uint32; UserSteamID: pSteamID): Boolean;
begin
  Result := SteamAPI_ISteamGameServer_SendUserConnectAndAuthenticate(SteamGameServerInterface, ClientIP, AuthBlob, AuthBlobSize, UserSteamID);
end;
function TSteamGameServer.CreateUnauthenticatedUserConnection(): TSteamID;
begin
  Result := SteamAPI_ISteamGameServer_CreateUnauthenticatedUserConnection(SteamGameServerInterface);
end;
procedure TSteamGameServer.SendUserDisconnect(steamIDUser: TSteamID);
begin
  SteamAPI_ISteamGameServer_SendUserDisconnect(SteamGameServerInterface, steamIDUser);
end;
function TSteamGameServer.BUpdateUserData(UserID: TSteamID; PlayerName: pAnsiChar; Score: uint32): Boolean;
begin
  Result := SteamAPI_ISteamGameServer_BUpdateUserDAta(SteamGameServerInterface, UserID, PlayerName, Score);
end;
function TSteamGameServer.GetAuthSessionTicket(Ticket: Pointer; MaxTicket: Integer; ActualTicketLength: pUint32): uint32;
begin
  Result := SteamAPI_ISteamGameServer_GetAuthSessionTicket(SteamGameServerInterface, Ticket, MaxTicket, ActualTicketLength);
end;
function TSteamGameServer.BeginAuthSession(AuthTicket: Pointer; AuthTicketSize: Integer; steamID: TSteamID): EBeginAuthSessionResult;
begin
  Result := SteamAPI_ISteamGameServer_BeginAuthSession(SteamGameServerInterface, AuthTicket, AuthTicketSize, steamID);
end;
procedure TSteamGameServer.EndAuthSession(steamID: TSteamID);
begin
  SteamAPI_ISteamGameServer_EndAuthSession(SteamGameServerInterface, steamID);
end;
procedure TSteamGameServer.CancelAuthTicket(AuthTicket: uint32);
begin
  SteamAPI_ISteamGameServer_CancelAuthTicket(SteamGameServerInterface, AuthTicket);
end;
function TSteamGameServer.UserHasLicenseForApp(steamID: TSteamID; appID: uint32): EUserHasLicenseForAppResult;
begin
  Result := SteamAPI_ISteamGameServer_UserHasLicenseForApp(SteamGameServerInterface, steamID, appID);
end;
function TSteamGameServer.RequestUserGroupStatus(UserID, GroupID: TSteamID): Boolean;
begin
  Result := SteamAPI_ISteamGameServer_RequestUserGroupStatus(SteamGameServerInterface, UserID, GroupID);
end;
function TSteamGameServer.GetPublicIP(): SteamIPAddress_t;
begin
  Result := SteamAPI_ISteamGameServer_GetPublicIP(SteamGameServerInterface);
end;
function TSteamGameServer.HandleIncomingPacket(Data: Pointer; DataSize: Integer; SourceIP: uint32; SourcePort: uint16): Boolean;
begin
  Result := SteamAPI_ISteamGameServer_HandleIncomingPacket(SteamGameServerInterface, Data, DataSize, SourceIP, SourcePort);
end;
function TSteamGameServer.GetNextOutgoingPacket(pOut: Pointer; MaxOutCount: Integer; NetAddress: pUint32; Port: pUint16): Integer;
begin
  Result := SteamAPI_ISteamGameServer_GetNextOutgoingPacket(SteamGameServerInterface, pOut, MaxOutCount, NetAddress, Port);
end;
procedure TSteamGameServer.EnableHeartbeats(IsActive: Boolean);
begin
  SteamAPI_ISteamGameServer_EnableHeartbeats(SteamGameServerInterface, IsActive);
end;
procedure TSteamGameServer.SetHeartbeatInterval(HeartbeatInterval: Integer);
begin
  SteamAPI_ISteamGameServer_SetHeartbeatInterval(SteamGameServerInterface, HeartbeatInterval);
end;
procedure TSteamGameServer.ForceHeartbeat();
begin
  SteamAPI_ISteamGameServer_ForceHeartbeat(SteamGameServerInterface);
end;
function TSteamGameServer.AssociateWithClan(ClanID: TSteamID): uint64;
begin
  Result := SteamAPI_ISteamGameServer_AssociateWithClan(SteamGameServerInterface, ClanID);
end;
function TSteamGameServer.ComputeNewPlayerCompatibility(NewPlayerID: TSteamID): uint64;
begin
  Result := SteamAPI_ISteamGameServer_ComputeNewPlayerCompatibility(SteamGameServerInterface, NewPlayerID);
end;

constructor TSteamGameServerStats.Init(SteamInterface: Pointer);
begin
  SteamGameServerStatsInterface := SteamInterface;
end;


function TSteamGameServerStats.RequestUserStats(steamIDUser: TSteamID): SteamAPICall_t;
begin
  Result := SteamAPI_ISteamGameServerStats_RequestUserStats(SteamGameServerStatsInterface, steamIDUser);
end;
function TSteamGameServerStats.GetUserStatInt32(steamIDUser: TSteamID; pchName: PChar; pData: pint32): Boolean;
begin
  Result := SteamAPI_ISteamGameServerStats_GetUserStatInt32(SteamGameServerStatsInterface, steamIDUser, pchName, pData);
end;
function TSteamGameServerStats.GetUserStatFloat(steamIDUser: TSteamID; pchName: PChar; pData: pSingle): Boolean;
begin
  Result := SteamAPI_ISteamGameServerStats_GetUserStatFloat(SteamGameServerStatsInterface, steamIDUser, pchName, pData);
end;
function TSteamGameServerStats.GetUserAchievement(steamIDUser: TSteamID; pchName: PChar; pbAchieved: pBoolean): Boolean;
begin
  Result := SteamAPI_ISteamGameServerStats_GetUserAchievement(SteamGameServerStatsInterface, steamIDUser, pchName, pbAchieved);
end;
function TSteamGameServerStats.SetUserStatInt32(steamIDUser: TSteamID; pchName: PChar; nData: int32): Boolean;
begin
  Result := SteamAPI_ISteamGameServerStats_SetUserStatInt32(SteamGameServerStatsInterface, steamIDUser, pchName, nData);
end;
function TSteamGameServerStats.SetUserStatFloat(steamIDUser: TSteamID; pchName: PChar; fData: single): Boolean;
begin
  Result := SteamAPI_ISteamGameServerStats_SetUserStatFloat(SteamGameServerStatsInterface, steamIDUser, pchName, fData);
end;
function TSteamGameServerStats.UpdateUserAvgRateStat(steamIDUser: TSteamID; pchName: PChar; flCountThisSession: Single; dSessionLength: Double): Boolean;
begin
  Result := SteamAPI_ISteamGameServerStats_UpdateUserAvgRateStat(SteamGameServerStatsInterface, steamIDUser, pchName, flCountThisSession, dSessionLength);
end;
function TSteamGameServerStats.SetUserAchievement(steamIDUser: TSteamID; pchName: PChar): Boolean;
begin
  Result := SteamAPI_ISteamGameServerStats_SetUserAchievement(SteamGameServerStatsInterface, steamIDUser, pchName);
end;
function TSteamGameServerStats.ClearUserAchievement(steamIDUser: TSteamID; pchName: PChar): Boolean;
begin
  Result := SteamAPI_ISteamGameServerStats_ClearUserAchievement(SteamGameServerStatsInterface, steamIDUser, pchName);
end;
function TSteamGameServerStats.StoreUserStats(steamIDUser: TSteamID): SteamAPICall_t;
begin
  Result := SteamAPI_ISteamGameServerStats_StoreUserStats(SteamGameServerStatsInterface, steamIDUser);
end;


constructor TSteamUGC.Init(SteamInterface: ISteamUGC);
begin
  if SteamInterface = nil then
    raise Exception.Create('TSteamUGC.Init has failed');
  SteamUGCInterface := SteamInterface;
end;

function TSteamUGC.CreateQueryUserUGCRequest(AccountID: uint32; ListType: EUserUGCList; eMatchingUGCType: EUGCMatchingUGCType; eSortOrder: EUserUGCListSortOrder; nCreatorAppID, nConsumerAppId, unPage: uint32): uint64;
begin
  Result := SteamAPI_ISteamUGC_CreateQueryUserUGCRequest(SteamUGCInterface, AccountID, ListType, eMatchingUGCType, eSortOrder, nCreatorAppID, nConsumerAppId, unPage);
end;
function TSteamUGC.CreateQueryAllUGCRequestPage(QueryType: EUGCQuery; MatchingeMatchingUGCTypeFileType: EUGCMatchingUGCType; nCreatorAppID, nConsumerAppId, unPage: uint32): uint64;
begin
  Result := SteamAPI_ISteamUGC_CreateQueryAllUGCRequestPage(SteamUGCInterface, QueryType, MatchingeMatchingUGCTypeFileType, nCreatorAppID, nConsumerAppId, unPage);
end;
function TSteamUGC.CreateQueryAllUGCRequestCursor(QueryType: EUGCQuery; MatchingeMatchingUGCTypeFileType: EUGCMatchingUGCType; nCreatorAppID, nConsumerAppId: uint32; pchCursor: PChar): uint64;
begin
  Result := SteamAPI_ISteamUGC_CreateQueryAllUGCRequestCursor(SteamUGCInterface, QueryType, MatchingeMatchingUGCTypeFileType, nCreatorAppID, nConsumerAppId, pchCursor);
end;
function TSteamUGC.CreateQueryUGCDetailsRequest(pvecPublishedFileID: pPublishedFileId_t; unNumPublishedFileIDs: uint32): UGCQueryHandle_t;
begin
  Result := SteamAPI_ISteamUGC_CreateQueryUGCDetailsRequest(SteamUGCInterface, pvecPublishedFileID, unNumPublishedFileIDs);
end;
function TSteamUGC.SendQueryUGCRequest(Handle: uint64): uint64;
begin
  Result := SteamAPI_ISteamUGC_SendQueryUGCRequest(SteamUGCInterface, Handle);
end;
function TSteamUGC.GetQueryUGCResult(Handle: uint64; index_: uint32; Details: pSteamUGCDetails_t): Boolean;
begin
  Result := SteamAPI_ISteamUGC_GetQueryUGCResult(SteamUGCInterface, Handle, index_, Details);
end;
function TSteamUGC.ReleaseQueryUGCRequest(Handle: uint64): Boolean;
begin
  Result := SteamAPI_ISteamUGC_ReleaseQueryUGCRequest(SteamUGCInterface, Handle);
end;
function TSteamUGC.RequestUGCDetails(PublishedFileId: uint64; MaxAgeSeconds: uint32): uint64;
begin
  Result := SteamAPI_ISteamUGC_RequestUGCDetails(SteamUGCInterface, PublishedFileId, MaxAgeSeconds);
end;
function TSteamUGC.GetItemUpdateProgress(Handle: uint64; BytesProcessed, BytesTotal: puint64): EItemUpdateStatus;
begin
  Result := SteamAPI_ISteamUGC_GetItemUpdateProgress(SteamUGCInterface, Handle, BytesProcessed, BytesTotal);
end;
function TSteamUGC.SubscribeItem(PublishedFileId: uint64): uint64;
begin
  Result := SteamAPI_ISteamUGC_SubscribeItem(SteamUGCInterface, PublishedFileId);
end;
function TSteamUGC.UnsubscribeItem(PublishedFileId: uint64): uint64;
begin
  Result := SteamAPI_ISteamUGC_UnsubscribeItem(SteamUGCInterface, PublishedFileId);
end;
function TSteamUGC.GetNumSubscribedItems(): uint32; cdecl;
begin
  Result := SteamAPI_ISteamUGC_GetNumSubscribedItems(SteamUGCInterface);
end;
function TSteamUGC.GetSubscribedItems(PublishedFileId: puint64; MaxEntries: uint32): uint32;
begin
  Result := SteamAPI_ISteamUGC_GetSubscribedItems(SteamUGCInterface, PublishedFileId, MaxEntries);
end;
function TSteamUGC.GetItemInstallInfo(PublishedFileId: uint64; SizeOnDisk: puint64; Folder: pAnsiChar; FolderSize: uint32; TimeStamp: puint32): Boolean;
begin
  Result := SteamAPI_ISteamUGC_GetItemInstallInfo(SteamUGCInterface, PublishedFileId, SizeOnDisk, Folder, FolderSize, TimeStamp);
end;
function TSteamUGC.GetItemState(nPublishedFileID: uint64): uint32;
begin
  Result := SteamAPI_ISteamUGC_GetItemState(SteamUGCInterface, nPublishedFileId);
end;
function TSteamUGC.GetItemDownloadInfo(nPublishedFileID: uint64; punBytesDownloaded: puint64; punBytesTotal: puint64): Boolean;
begin
  Result := SteamAPI_ISteamUGC_GetItemDownloadInfo(SteamUGCInterface, nPublishedFileId, punBytesDownloaded, punBytesTotal);
end;
function TSteamUGC.DownloadItem(nPublishedFileID: uint64; bHighPriority: Boolean): Boolean;
begin
  Result := SteamAPI_ISteamUGC_DownloadItem(SteamUGCInterface, nPublishedFileId, bHighPriority);
end;
function TSteamUGC.BInitWorkshopForGameServer(unWorkshopDepotID: uint32; pszFolder: PAnsiChar): Boolean;
begin
  Result := SteamAPI_ISteamUGC_BInitWorkshopForGameServer(SteamUGCInterface, unWorkshopDepotID, pszFolder);
end;
procedure TSteamUGC.SuspendDownloads(bSuspend: Boolean);
begin
  SteamAPI_ISteamUGC_SuspendDownloads(SteamUGCInterface, bSuspend);
end;
function TSteamUGC.StartPlaytimeTracking(pvecPublishedFileID: puint64; unNumPublishedFileIDs: uint32): uint64;
begin
  Result := SteamAPI_ISteamUGC_StartPlaytimeTracking(SteamUGCInterface, pvecPublishedFileID, unNumPublishedFileIDs);
end;
function TSteamUGC.StopPlaytimeTracking(pvecPublishedFileID: puint64; unNumPublishedFileIDs: uint32): uint64;
begin
  Result := SteamAPI_ISteamUGC_StopPlaytimeTracking(SteamUGCInterface, pvecPublishedFileID, unNumPublishedFileIDs);
end;
function TSteamUGC.StopPlaytimeTrackingForAllItems(): uint64;
begin
  Result := SteamAPI_ISteamUGC_StopPlaytimeTrackingForAllItems(SteamUGCInterface);
end;
function TSteamUGC.GetAppDependencies(nPublishedFileID: PublishedFileId_t): SteamAPICall_t;
begin
  Result := SteamAPI_ISteamUGC_GetAppDependencies(SteamUGCInterface, nPublishedFileID);
end;
function TSteamUGC.SetReturnChildren(handle: UGCQueryHandle_t; bReturnChildren: Boolean): Boolean;
begin
  Result := SteamAPI_ISteamUGC_SetReturnChildren(SteamUGCInterface, handle, bReturnChildren);
end;
function TSteamUGC.SetReturnOnlyIDs(handle: UGCQueryHandle_t; bReturnOnlyIDs: Boolean): Boolean;
begin
  Result := SteamAPI_ISteamUGC_SetReturnOnlyIDs(SteamUGCInterface, handle, bReturnOnlyIDs);
end;
function TSteamUGC.GetQueryUGCChildren(handle: UGCQueryHandle_t; index_: uint32; pvecPublishedFileID: pPublishedFileId_t; cMaxEntries: uint32): Boolean;
begin
  Result := SteamAPI_ISteamUGC_GetQueryUGCChildren(SteamUGCInterface, handle, index_, pvecPublishedFileID, cMaxEntries);
end;

end.
