# Openchamp Initial Configuration Guide

## Before you begin
Please not that this guide is up to date as of 11/12/2025, and due to the nature of active development may not reflect the current state of the environmental setup for this project.

## Prerequisites:
- GoLang LTS
- Godot 4.6 (dev3 at time of writing)
- Git
- Podman
- Python3 (optional)
- NodeJS LTS (24, optional for external client usage)

## Installation

### 0. Getting Everything together
```sh
cd ~/Documents;
mkdir openchamp;
cd openchamp;
git clone https://github.com/openchamp/openchampps;
git clone https://github.com/openchamp/openchamppc;
```
leave the terminal open after this
### 1. Creating your Database
Create a postgres container and record the username and password, or use something like the following:
```sh
podman run -d --name "openchamp_db" -e POSTGRES_USER="openchamp" -e POSTGRES_DB="openchamp" -e POSTGRES_PASSWORD="openchamp" --publish "127.0.0.1:5432:5432/tcp" "postgres"
```
you can add the `-v` flag if you pan on manipulating the database outside of podman
### 2. Hosting the server
```sh
cd ~/Documents/openchamp/openchampps;
cp .env.example ./.env;
go run main.go;
```
### 3. Connecting with the game client
Open Godot, click Import Project, navigate to the openchamppc folder and double click on Project.godot to import the game. When you hit the play button, one of 2 things will happen:
- If the debug settings are turned on and clients are provided either `-ip` or `-ds`, they will skip the in-game client and go straight into the ingame.tscn scene after loading the args
- Otherwise, we go to the Main Menu and are prompted to connect to the server (localhost by default)
