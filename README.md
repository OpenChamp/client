
# OpenChamp
 OpenChamp is an attempt at an Open Source League of Legends competitor, post the Vanguard update. 
 
 The goal is to allow anyone anywhere to play, commit and enjoy the game however they'd like. The source code for the server and client will be hosted on github for all to enjoy!

 This is in the very _VERY_ early stages and will not be ready for some time, but I will push releases when progress is far enough to be enjoyed!

 If you'd like to contribute or just hang around, I've created a Discord 
 https://discord.gg/f6DGjvTWYT

 Thanks!

## Setup

To start working on this project you will need the godot editor.
You can get the latest version from [https://godotengine.org/](https://godotengine.org/).
At the moment we use godot 4.2 without C# support.

## Running the game

To properly run the game you will need the default assets in your user directory.
In the future the launcher will handle this, but for now this has to be done manually.

The content has to be placed in `user://external/`
That is the directory where the [assets repository](https://github.com/OpenChamp/default_assets) has to be cloned to.
You could also create a new directory there and extract the contents of the [latest release](https://github.com/OpenChamp/default_assets/releases/latest) there.
This will result in `user://external/default_assets/OpenChamp/...`

The user prefix is in the following location:

* Windows: `%APPDATA%\Godot\app_userdata\OpenChamp`
* macOS: `~/Library/Application Support/Godot/app_userdata/OpenChamp`
* Linux: `~/.local/share/godot/app_userdata/OpenChamp`
 
## Contributing

Contributions are always welcome!

See CONTRIBUTING.md for basic guidelines.
