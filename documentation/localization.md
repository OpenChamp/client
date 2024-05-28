# Localization

Translations are handled using godots translation system.
All of the string translations are in the lang dir.
Each language has their own translation csv file.
This should prevent merge conflicts caused by translation updates.

For more general information about the translation files check out the [godot documentation on importing translations](https://docs.godotengine.org/en/3.1/getting_started/workflow/assets/importing_translations.html).
Make sure you have LF as the line ending like everywhere in godot.

## Adding translation keys

All translation keys ***MUST*** be added to the english locale since that is the fallback language.
In addition to that all translation key have to be listed below.
This is important so that people who want to translate to a new langauge have more context of the texts purpose to better translate it.
It also is easier for the developers to just look up an item here than to scroll to the english csv file.

## Adding a new translation

If you want to translate the contents to a new langauge just add a csv file with named with the locale (eg. `en.csv` or `jp.csv`) and translate the keys as needed.
You can find a list of valid locale values [in the godot documentation](https://docs.godotengine.org/en/3.1/tutorials/i18n/locales.html#doc-locales).
After the comma between the rows there must not be a space.
So `MYSTRING,"some text"` is okay but `MYSTRING, "some text"` is not.
This is especially important for the top row.
Please escape the translated text.
This way you can use a comma inside of it.

In general each csv file should only contain one language.
However they may contain the language variants in the same file to make organization a bit easier.
So de and en are separate files but en_us and en_uk may both be in the same en file.

To make the translation avaible you have to open godot and go to `project settings -> Localization -> Add... -> select lang/new_lang.new_lang.translation`
It's important to select the .translation file not the csv here.
The csv automatically gets imported into godot.

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
