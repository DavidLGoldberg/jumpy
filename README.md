# Jumpy

[![Join the chat at https://gitter.im/jumpy-atom/Lobby](https://badges.gitter.im/jumpy-atom/Lobby.svg)](https://gitter.im/jumpy-atom/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
![](https://img.shields.io/apm/dm/jumpy.svg)
![](https://img.shields.io/apm/v/jumpy.svg)
[![Build Status](https://travis-ci.org/DavidLGoldberg/jumpy.svg?branch=master)](https://travis-ci.org/DavidLGoldberg/jumpy)

An Atom package that creates dynamic hotkeys to jump around files and across visible panes.

## How to jump

1.  Hit <kbd>shift</kbd> + <kbd>enter</kbd>
2.  Choose from your presented labels:
3.  Enter two characters.
4.  Keep coding!

[ ![Jumpy in Action! - (gif made with recordit.co)][1]](https://raw.githubusercontent.com/DavidLGoldberg/jumpy/master/_images/jumpy.gif)

[1]: https://raw.githubusercontent.com/DavidLGoldberg/jumpy/master/_images/jumpy.gif

## Install
On command line:
```
apm install jumpy
```

## Notes

*   Works great with or without [vim-mode](https://github.com/atom/vim-mode "vim-mode's Homepage")!
  *   Vim modes supported:
      *   command mode
      *   insert mode
      *   visual mode (expands selections with <kbd>v</kbd> or <kbd>V</kbd>)
  *   Recommended key mappings to replace 'f' in vim-mode see 'Settings' below.

## Key Bindings

### Defaults

*   Enter jump mode
    *   <kbd>shift</kbd> + <kbd>enter</kbd>
*   Reset first character entered
    *   <kbd>backspace</kbd>
*   Cancel/exit jump mode (any)
    *   <kbd>shift</kbd> + <kbd>enter</kbd>
    *   <kbd>enter</kbd>
    *   <kbd>esc</kbd>
    *   <kbd>space</kbd>

## Settings

### Jumpy preferences

( Preferences <kbd>cmd</kbd>+<kbd>,</kbd> ) -> search for 'jumpy'

*   **Font Size**:
If set, must be a decimal value less than 1.
*   **High Contrast**:
If checked, uses a more colorful and fun (usually green) label.
*   **Match Pattern**:
Provide a custom regex to match labels with.
*   **Use Homing Beacon Effect On Jumps**:
If left on, will display a homing beacon (usually red) after all jumps.

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
atom-text-editor {
    .jumpy-label {
        // Regular labels
        background-color: black;
        color: white;
        &.high-contrast {
            // High Contrast labels (activated in settings)
            background-color: green;
        }
    }
}
```

## My other Atom package :)

*   [Qolor](https://atom.io/packages/qolor)

## Keywords

(A little SEO juice)

*   Shortcuts
*   Navigation
*   Productivity
*   Mouseless
*   Plugin
*   Extension
