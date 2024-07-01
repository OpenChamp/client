
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
At the moment we use godot 4.3 without C# support.

In addition to that a gdextension is not part of the project.
In order to run the game you either need to download the latest compiled version or compile the extension yourself.
            
When you pull, use `git submodule update --init` if you've already got a local copy, or `git pull --recursive` on a fresh pull to pull the assets from our [default assets](https://github.com/openchamp/default_assets) repository

### Downloading the extension

The `extensions.zip` is distributed as part of the releases.
I case the CI fails, you can also download it from the CI artifacts directly.

Simply extract the archive file to the `bin` directory and you are good to go.

### Compiling the extension

The following tools are required to compile the extension:

* [cmake](https://cmake.org/download/)
* [ninja-build](https://ninja-build.org/)
* python (This is a dependency of ninja so you should already have it.)
* A C++ compiler (g++/cmake/msvc anything *should* work)

If you want to compile the code for a different CPU architecture you will also need docker.

Before you compile the code make sure you have initialized the submodule.
You can use `git submodule update --init --recursive` to set them up.

To compile the code you can simply run the following command in the root of the project:

```bash
python ./extensions/scripts/compile.py
```

This works on every operating system and also installs the built file to the bin dir.
If you want to see all the available options just use the `--help` command line option.

## Running the game

All of the default assets are in the default_assets submodule.
If you set up all the submodules most of the data should already be present.
The only thing that needs to be done after each update is generating the manifest files.
This can be done with the following command:

```bash
python ./default_assets/manifests.py
```

## Additional/overwirtten asset packs

It is possible to have additional asset packs or override data of existing ones.
To do this you need asset packs in the user dir.

The packs have to be placed in `user://external/`
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
