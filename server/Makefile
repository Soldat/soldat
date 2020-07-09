.PHONY: build all windows linux osx windows_i386 windows_x86_64 linux_i386 linux_x86_64 osx_i386 osx_x86_64 clean

EXECUTABLE = soldatserver

TRUE = true
MKDIR = mkdir -p
PATHSEP = /

ifeq ($(OS),Windows_NT)
  SYSTEM = windows
  
  ifdef ComSpec
    TRUE = echo.>NUL
    MKDIR = mkdir
    PATHSEP = \\
  endif

  ifeq ($(PROCESSOR_ARCHITEW6432),AMD64)
    ARCH = x86_64
    ARCH_EXT = _x64
    EXECUTABLE_ARCH = $(EXECUTABLE)$(ARCH_EXT)
    SYSTEM_ARCH = win64
  else
    ifeq ($(PROCESSOR_ARCHITECTURE),AMD64)
      ARCH = x86_64
      EXECUTABLE_ARCH = $(EXECUTABLE)$(ARCH_EXT)
      SYSTEM_ARCH = win64
    endif
    ifeq ($(PROCESSOR_ARCHITECTURE),x86)
      ARCH = i386
      ARCH_EXT = ""
      EXECUTABLE_ARCH = $(EXECUTABLE)$(ARCH_EXT)
      SYSTEM_ARCH = win32
    endif
    ifeq ($(PROCESSOR_ARCHITECTURE),ARM64)
      ARCH = arm
      ARCH_EXT = _arm
      EXECUTABLE_ARCH = $(EXECUTABLE)$(ARCH_EXT)
      SYSTEM_ARCH = arm
    endif
  endif
else
  ifeq ($(shell uname -o), GNU/Linux)
    SYSTEM = linux
    steam = on
    SYSTEM_ARCH = linux
  else
    ifeq ($(shell uname), Darwin)
      SYSTEM = osx
      steam = on
      SYSTEM_ARCH = darwin
    else
      SYSTEM = unknown
    endif
  endif
  UNAME_M := $(shell uname -m)
  ifeq ($(UNAME_M),x86_64)
    ARCH = x86_64
    ARCH_EXT = _x64
    EXECUTABLE_ARCH = $(EXECUTABLE)$(ARCH_EXT)
  endif
  ifneq ($(filter %86,$(UNAME_M)),)
    ARCH = i386
    ARCH_EXT = ""
    EXECUTABLE_ARCH = $(EXECUTABLE)$(ARCH_EXT)
  endif
  ifneq ($(filter arm%,$(UNAME_M)),)
    ARCH = arm
    ARCH_EXT = _arm
    EXECUTABLE_ARCH = $(EXECUTABLE)$(ARCH_EXT)
  endif
endif

ifeq ($(mode),release)
  CFLAGS = -O3 -Os -CX -OoREGVAR -Xs -XX -vewibq -vn-h-
  ifeq ($(MAKECMDGOALS),windows_$(ARCH))
    CFLAGS += -WB -WR
  endif
else
  mode = debug
  CFLAGS = -O1 -g -gl -l -vewnibq -vh- -dDEBUG -dDEVELOPMENT -gs -gw -Ci -Co -Cr -CR -Ct  -gl -gt
endif

ifeq ($(steam),on)
  CFLAGS += -dSTEAM
endif

COMPILER = fpc -l -B -MDelphi -Scgi ${CFLAGS} \
-Fi../3rdparty/Indy10/Lib/System \
-Fi../3rdparty/Indy10/Lib/Core \
-Fi../shared \
-Fl./libs \
-Fu./libs \
-Fu../3rdparty/pascalscript/Source \
-Fu../3rdparty/Indy10/Lib/System \
-Fu../3rdparty/Indy10/Lib/Core \
-Fu../shared \
-Fu../shared/libs \
-Fu../shared/libs/GameNetworkingSockets \
-Fu../shared/libs/PhysFS \
-Fu../shared/libs/SteamWrapper \
-Fu../shared/mechanics \
-Fu../shared/network \
-Fu./scriptcore \
-FE./build/ \
-dSERVER \
-dSCRIPT \
-dRCON \
-dPS_USESSUPPORT \
-vm3123 -vm3124 # hide fgl inlining warnings

build: $(SYSTEM)_$(ARCH)

all: windows linux osx

windows: windows_$(ARCH)

linux: linux_$(ARCH)

osx: osx_$(ARCH)

unix_common:
	$(MKDIR) build$(PATHSEP)$(ARCH)-$(SYSTEM_ARCH) || $(TRUE)
	echo -e "480\n638500" &> build$(PATHSEP)steam_appid.txt || $(TRUE)

windows_$(ARCH):
	$(MKDIR) build$(PATHSEP)$(ARCH)-$(SYSTEM_ARCH) || $(TRUE)
	$(COMPILER) -o./build/$(EXECUTABLE_ARCH).exe -FU./build/$(ARCH)-$(SYSTEM_ARCH) -T$(SYSTEM_ARCH) -P$(ARCH) $(EXECUTABLE).lpr

linux_$(ARCH): unix_common
	$(COMPILER) -o./build/$(EXECUTABLE_ARCH) -k-rpath -k'\$$ORIGIN/' -FU./build/$(ARCH)-$(SYSTEM_ARCH) -T$(SYSTEM_ARCH) -P$(ARCH) $(EXECUTABLE).lpr

osx_$(ARCH): unix_common
	$(COMPILER) -o./build/$(EXECUTABLE_ARCH) -Fu./client/macOS/Frameworks -Fl../client/macOS/Frameworks -k"-F../client/macOS/Frameworks" -k"-rpath" -k"@executable_path" -k"-rpath" -k"@executable_path/../Frameworks" -FU./build/$(ARCH)-$(SYSTEM_ARCH) -T$(SYSTEM_ARCH) -P$(ARCH) $(EXECUTABLE).lpr


clean:
	rm -rf \
build/i386-linux/* \
build/x86_64-linux/* \
build/i386-win32/* \
build/x86_64-win64/* \
build/i386-darwin/* \
build/x86_64-darwin/* \
build/$(EXECUTABLE) \
build/$(EXECUTABLE).exe \
build/$(EXECUTABLE)_x64 \
build/$(EXECUTABLE)_x64.exe
