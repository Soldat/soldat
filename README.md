<div align="center">
  <img src="https://i.imgur.com/HrYPYjh.png" />
  <h2>Soldat</h2>
</div>

Soldat is a unique 2D (side-view) multiplayer action game. It has been influenced by the best of games such as Liero, Worms, Quake, Counter-Strike, and provides a fast-paced gaming experience with tons of blood and flesh.

This repository contains the source code of the so-called 1.8 version. Compared to the original version, the code has undergone many changes but is not in a finished state. We hope that by open-sourcing Soldat we can empower our community to improve the game at a faster pace.

## Dependencies

- FreePascal 3.0.4
- SDL 2.0.12
- OpenAL
- FreeType 2.6.1
- PhysFS 3.0.2
- GameNetworkingSockets

## Building Soldat

Soldat compiles on Windows, Linux and macOS.

1. Install [Lazarus IDE](https://www.lazarus-ide.org/) (or a standalone [FreePascal Compiler](https://freepascal.org) if you want to use Makefiles)
2. Download [pre-built libraries](https://github.com/Soldat/prebuilt-libs/archive/master.zip) and copy libraries from `win64_dlls` to `client/build` and `server/build`
3. Clone [base repository](https://github.com/soldat/base) and run `create_smod.sh` from it to create a game base archive
4. Copy `soldat.smod` to `client/build` and `server/build`
5. Copy `base/client/play-regular.ttf` to `client/build`

### Compilation using Lazarus IDE

1. Open `server/soldatserver.lpi` with Lazarus, press F9 to compile and start the server
2. Start another instance of Lazarus and open `client/soldat.lpi`, press F9 to build the game client

### Compilation using Makefiles

0. Create build directory structure: `mkdir -p server/build/linux; mkdir -p client/build/linux`
1. Compile options: make -e build ARCH=(x86_64|x86|arm) SYSTEM=(windows|linux|osx) SYSTEM_ARCH=(win64,win32,arm,linux,darwin) steam=(on|off) ARCH_EXT=(_x64|_arm|"")
2. Compile server: `cd server; make linux`
3. Compile client: `cd client; make linux`
4. Run server: `server/build/soldatserver$(ARCH_EXT`
5. Run client: `client/build/soldat$(ARCH_EXT) -join 127.0.0.1 23073`
