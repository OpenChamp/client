# External Reference Sheet
## 🖥️ Dedicated Server Instance
### Server Parameters
**Available Arguments:**
| Short | Long | Description |
|-------|------|-------------|
| -ip | --host | IPv4 address of the host GameServer Instance |
| -sid | --serverid | ContainerID (debugging purposes) |
| -ws | --webid | Websocket ID for user authentication *(User tells server, server queries api, api tells client secret, secret is verified on game)* |
| -p | --port | GameServer Port to connect to (7000 default) |
| -m | --map | **SERVER** - Sets map  based on mapname |
| -mp | --maxplayers | Sets lobby maximum players|
| -gm | --gamemode | Sets lobby GameMode based on gamemode name |
| -ds | --dedicated | Enables server mode. (*use with --headless*)

## Looking for more?
Documentation for the Primary Server ([OpenchampPS](https://github.com/openchamp/openchampps)) will be on that repository for organizational reasons. If you need assistance with features, feel free to ask in the [Discord](https://discord.gg/aS4BUSEzxt)