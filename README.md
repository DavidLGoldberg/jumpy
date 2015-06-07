# Jumpy
An Atom package that creates dynamic hotkeys to jump around files and across visible panes.

## How to jump
1. Hit <kbd>shift</kbd> + <kbd>enter</kbd>
2. Choose from your presented labels:
3. Enter two characters.
4. Keep coding!

[ ![Jumpy in Action! - (gif made with recordit.co)][1]](https://raw.githubusercontent.com/DavidLGoldberg/jumpy/master/_images/jumpy.gif)

[1]: https://raw.githubusercontent.com/DavidLGoldberg/jumpy/master/_images/jumpy.gif

## Install
On command line:
```
apm install jumpy
```

## Notes
* Works great with or without [vim-mode](https://github.com/atom/vim-mode "vim-mode's Homepage")!
    * Vim modes supported:
        * command mode
        * insert mode
        * visual mode (expands selections with <kbd>v</kbd> or <kbd>V</kbd>)
    * Recommended key mappings to replace 'f' in vim-mode see 'Settings' below.
* Recommended custom cursors:
    * [slightly pulsing green cursor](https://gist.github.com/DavidLGoldberg/166646fce043710ef920 "green cursor gist")
    * [neon-cursor](https://atom.io/packages/neon-cursor) (This conflicts with the Jumpy homing beacon effect, but you *probably* won't need the beacon anymore!)

## Key Bindings
### Defaults
* Enter jump mode
    * <kbd>shift</kbd> + <kbd>enter</kbd>
* Reset first character entered
    * <kbd>backspace</kbd>
* Cancel/exit jump mode (any)
    * <kbd>shift</kbd> + <kbd>enter</kbd>
    * <kbd>enter</kbd>
    * <kbd>esc</kbd>
    * <kbd>space</kbd>

## Settings

### Jumpy preferences
( Preferences <kbd>cmd</kbd>+<kbd>,</kbd> ) -> search for 'jumpy'

* <b>Font Size</b>:
If set, must be a decimal value less than 1.
* <b>High Contrast</b>:
If checked, uses a more colorful and fun (usually green) label.
* <b>Match Pattern</b>:
Provide a custom regex to match labels with.
* <b>Use Homing Beacon Effect On Jumps</b>
*(needs React Editor enabled, see below)*:
If left on, will display a homing beacon (usually red) after all jumps.

*Note*: After selecting <b>'Use React Editor'</b> in Preferences -> Settings you will have to either restart Atom
or enter ctrl+alt+cmd+l (lower case L).


![Jumpy settings](https://raw.githubusercontent.com/DavidLGoldberg/jumpy/master/_images/jumpy-settings.png)

*Example*:

![Jumpy example](https://raw.githubusercontent.com/DavidLGoldberg/jumpy/master/_images/jumpy-high-contrast-font-camel.png)

(image after settings set to .85 font size, high contrast, and default camel case matching pattern)

### 'vim-mode' Users (Strongly Recommended Override)
Put this override in your **'Atom'** -> **'Open Your Keymap'** settings:

    'atom-text-editor:not(.mini).vim-mode:not(.insert-mode):not(.jumpy-jump-mode)':
        'f': 'jumpy:toggle'

This will **bind 'f' to toggle Jumpy**.

This is not the default because it **changes vim's native behavior**.
Instead, with Jumpy, after jumping to the nearest word, you can easily word or character jump over to your target.
The [Vimium chrome extension](https://chrome.google.com/webstore/detail/vimium/dbepggeogbaibhgnhhndojpepiihcmeb?hl=en) chose this binding.
Please let me know what you think about this binding for Jumpy [here](https://discuss.atom.io/t/introducing-jumpy-new-package/10980/28)!

### Jumpy Styles
Note: Styles can be overridden in **'Atom' -> 'Open Your Stylesheet'**
(see examples below)
```less
atom-text-editor::shadow .jumpy {
    &.label {
    }
    &.jump {
    }
}
```
[Example](https://gist.github.com/DavidLGoldberg/58b96b80902724ba3c5a "Example orange labels") (orange labels)

## Keywords
(A little SEO juice)

* Shortcuts
* Navigation
* Productivity
* Mouseless
* Plugin
* Extension
