# OpenChamp - Open Source MOBA

> **⚠️ ALPHA STAGE - NOT PLAYABLE YET**
> 
> This project is in active development. The game is **NOT ready for regular play**. Expect frequent changes, bugs, crashes, and incomplete features.

Welcome to OpenChamp! This is an open-source MOBA built with Godot. This repository contains both the game client and dedicated server implementation, but the Matchmaking server can be found [here](https://github.com/openchamp/openchampps)
## ⚠️ Early Access Notice

This is an **ALPHA** release. Please be aware:

- ❌ **Not feature complete** - Many systems are still in development
- ❌ **Not optimized** - Performance may be poor
- ❌ **Frequent updates** - Expect breaking changes
- ❌ **Bugs expected** - The game may crash or behave unexpectedly

**What this means:** If you want a playable game, this is not it yet. If you want to help develop an open-source MOBA, this is the place!

## 🚀 Getting Started

1. **New Player:** Download from [Releases](../../releases) and jump in!
2. **Developing?** Read [CONTRIBUTING.md](./CONTRIBUTING.md)
3. **Building external tools?** Check [EXTERNAL_REF.md](./EXTERNAL_REF.md)
4. **Interested in the pipeline?** See [.github/README.md](./.github/README.md)
5. 
## 🐛 Known Bugs
See [Issues](../../issues) for known issues


## 📥 Downloads

Game builds are available under [**Releases**](../../releases). Choose the appropriate build for your platform:

- **Windows Desktop** (.exe) - Play on Windows
- **macOS Desktop** (.app) - Play on macOS  
- **Linux Desktop** - Play on Linux
- **Server Builds** - For running dedicated servers


## ✨ Features (In Development)

- 🎮 **MOBA Gameplay** - Classic MOBA mechanics
- 👥 **Multiple Champions** - Different characters to play
- 🗺️ **Multiple Maps** - Different arenas to battle in
- 🎯 **Ability System** - 4 unique abilities per champion
- 💰 **Item System** - Build your character with items
- 🌐 **Multiplayer** - Play with friends (when working!)
- 🖥️ **Dedicated Servers** - Host your own servers
- 🔧 **Cross-Platform** - Windows, macOS, Linux

## 🎮 Playing the Game

### Requirements
- Windows 10+, macOS 10.12+, or Linux (x86_64)
- At least 4GB RAM
- Relatively modern GPU

### Connection

The game will try to connect to a server. You can:
- Wait for public servers to come online
- Host your own server (see [Server Setup](#server-setup))
- Check the console for connection status

## 🚧 For Developers

### Want to Contribute?

We'd love your help! See [CONTRIBUTING.md](./CONTRIBUTING.md) for:
- How to set up your development environment
- Folder structure and naming conventions
- Code style guidelines
- How to submit pull requests

### Want to Build External Clients?

Check out [EXTERNAL_REF.md](./EXTERNAL_REF.md) for:
- WebSocket server API documentation
- Python and JavaScript connection examples
- Available commands and data structures

## 🖥️ Server Setup


### **Host Local Match:**
1. Download the Server build from [Releases](../../releases)
2. Extract and run:
   ```bash
   ./OpenChamp_Linux_Server \
     --dedicated \
     --port 7000 \
     --maxplayers 10 \
     --map "the_ring" \
     --gamemode "onslaught"
    ```
    
   > Be sure to replace OpenChamp_Linux_Server with whichever server binary you downloaded.

See [EXTERNAL_REF.md](./EXTERNAL_REF.md) for complete argument documentation.
### **Host Everything**
 - WIP

## 📚 Documentation

- **[CONTRIBUTING.md](./CONTRIBUTING.md)** - Developer guide with setup instructions
- **[EXTERNAL_REF.md](./EXTERNAL_REF.md)** - API documentation for external clients
- **[.github/README.md](./.github/README.md)** - CI/CD pipeline documentation
- **[CHANGELOG.md](./CHANGELOG.md)** - Version history and release notes
- 
## 🤝 Contributing
We welcome contributions! Please read [CONTRIBUTING.md](./CONTRIBUTING.md) first, then:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📞 Support & Communication

- **Bugs:** Report bugs in [Issues](../../issues)
- **Discussions:** Join our [Discord](https://discord.gg/aS4BUSEzxt)
- **Releases:** Check [Releases](../../releases) for updates

## 🙏 Acknowledgments

- Built with [Godot Engine](https://godotengine.org/)
- Inspired by MOBAs
- Thanks to all contributors!

---


