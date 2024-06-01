# Localization

Translations are handled using godots translation system using the asset packs as an abtraction layer.
All of the string translations are in the assets repository in the lang dir.
Each locale has their own translation json file.
This should prevent merge conflicts caused by translation updates.

## Adding translation keys

All translation keys ***MUST*** be added to the english locale since that is the fallback language.
In addition to that all translation key have to be listed below.
This is important so that people who want to translate to a new langauge have more context of the texts purpose to better translate it.
It also is easier for the developers to just look up an item here than to scroll to the english json file.

## Adding a new translation

**All translations are now managed in the asstes repository**
The translation files use a json format now.
If you want to translate the contents to a new langauge just add a json file with named with the locale (eg. `es.json` or `de_de.json`) and translate the keys as needed.
You can find a list of valid locale values [in the godot documentation](https://docs.godotengine.org/en/4.2/tutorials/i18n/locales.html#doc-locales).
The translations get automatically imported during runtime, there is no need to import them in godot directly.

## Testing the translation

To test if a translation works you can set the locale to test in `poject settings -> General -> Internationalization -> Test`
Just input the locale you want to test and launch the game.
It will use the specified locale where possible and fall back to english in case a key is missing.

# List of translation keys

## Settings menu

The settings menu uses two key prefixes at the moment.
Individual settings start with `SETTINGS:` while the other UI elements (like tabs and the confirm button) start with `SETTINGS_`
This is followed by a conrete name of what they are for.

* `SETTINGS_TAB_DISPLAY` the display settings tab
* `SETTING:FULLSCREEN` the fullscreen toggle option

* `SETTINGS_TAB_CAMERA` the camera settigns tab
* `SETTING:CAMERA_SPEED_LABEL` the label above the camera speed slider
* `SETTING:CAMERA_EDGE_MARGIN_LABEL` the label above the camera edge margin slider
* `SETTING:CAMERA_MAX_ZOOM_LABEL` the label above the camera max zoom level
* `SETTING:CAMERA_CENTERED` the text next to the toggle button to switch if the camera should stay centered on the player

* `SETTINGS_MENU_CONFIRM` the text on the settings confirm button
* `SETTINGS_MENU_EXIT_GAME` the text on the exit game button

## Startup

* `STARTUP:STATUS_CONNECTING` The generic message displayed during connection establishment.
* `STARTUP:STATUS_CONNECT_CLIENT` Displayed when connecting as Client to a different Server
* `STARTUP:STATUS_CLIENT_FAILED` Displayed when the client connection failed
* `STARTUP:STATUS_CREATE_SERVER` Displayed while the server is launching

* `STARTUP:ATTEMPTS` Shows the number of tried attemps (needs to contain a `%d`)

* `STARTUP:HOST_GAME` The host game button
* `STARTUP:RECONNECT` A button to retry connecting
* `STARTUP:EXIT` A button to exit the game
