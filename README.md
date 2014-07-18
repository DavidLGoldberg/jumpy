# Jumpy
An Atom plugin that creates dynamic hot keys to jump around files across visible panes.

## How to jump
1. Hit <kbd>cmd</kbd> + <kbd>space</kbd>
2. Choose from your presented labels:
3. Enter two characters.
4. Keep coding!

![Jumpy in Action! - (gif made with recordit.co)](https://raw.githubusercontent.com/DavidLGoldberg/jumpy/master/jumpy.gif)

## Settings
```less
// Styles can be overriden in "Atom" -> "Open Your Stylesheets"
.jumpy {
    &.label {
    }
    &.jump {
    }
}
```

## Key Bindings
### Defaults
* Enter jump mode (default): <kbd>alt</kbd> + <kbd>space</kbd>
* Cancel/exit jump mode (defualt): <kbd>esc</kbd> or <kbd>space</kbd>

## Notes
* Works great with or without [vim-mode](https://github.com/atom/vim-mode "vim-mode's Homepage")!
    * Modes supported:
        * command mode
        * insert mode
        * visual mode (sorry cancels select at the moment)

## TODO
* Remove unreachable highlights after first character hit (to reduce noise).
* Reset first character entered: <kbd>backspace</kbd> and repaint all
  labels to the screen.
* Better highlighting in visual mode.
