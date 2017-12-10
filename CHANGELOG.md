## 4.2.0 - Add custom keys for labels
*   Merge @taylon PR to add custom keys!

## 4.1.1 - Fix performance issue with current Atom

## 4.1.0 - Add ability to jump while tree-view is focused
* Should work with 'shift-enter' or 'f' bindings in vim-mode!
* Alert users about current atom release's performance issues.

## 4.0.0 - New Architecture + Jump to Tabs!
* Add ability to jump to tabs!
* Preps for @johngeorgewright's code for tree-view labels and other initiatives.
* Convert all core code from CoffeeScript to TypeScript.
* Pull out into modules and use javascript-state-machine.
* Use workspaceElement for key listening.  No more preregistered commands.
* Add an extra css class to jumpy jump mode to make it more specific.
* Remove code registering commands for jumpy keys for each letter.
* Fix small bug of no match case after 2nd character.
* Remove all space-pen / jQuery.
* Add note about vim-mode-plus and hydrogen packages in README.md.

## 3.1.3 - Remove deprecation (Object.observe)
*   Simplify and Remove logic that used Object.observe for key maps.

## 3.1.2 - Fix beacon
*   Merge @johngeorgewright PR to restore the beacon functionality!

## 3.1.1 - Add Travis CI Badge
*   First run of Travis!

## 3.1.0 Gitter and Travis Continuous Integration
*   Adds .travis.yml to project for Travis Continuous Integration.
*   Adds a gitter badge to the README.md.

## 3.0.3
* Fix issue #84 (PR: #85) from Danny Arnold (@despairblue)

## 3.0.2
* Fix issue when switching tabs if jump mode is open.

## 3.0.1
* Is the actual released version of the below (had to deal with some publishing issues in core).

## 3.0.0
* Fix new Atom releases performance issue (tiling changes) by using
  markers and decorations.
* Big refactor.
* BREAKING CHANGES: See README.md for new custom styling methods.

## 2.0.10
* Fix broken labels with atom-material-ui theme.  Thanks to @livelazily for some help with this!

## 2.0.9
* Fix broken beacon animation (finally got around to this).
* Update README.md with new way to style Jumpy labels etc (using shadow dom).

## 2.0.8
* Remove deprecation warning for styles. Fixes (61 & 62).

## 2.0.7
* Update README.md with fix for 'f' hotkey with new Atom.
* Fixes #59 & #60. Jumpy broke with Atom 0.206.0, and now works / tested with 0.207.0 (coincidence)
  * Handles changes to Atom rendering by tiles.
  * Includes Shadow dom and keymap fixes.

## 2.0.6
* Fixes #45 Let's a keymap command contain a non string.

## 2.0.5
* Fixes #54 for performance issue / leak found by @despairblue.
* Few other minor performance issues.
* Memory leak prevention of commands.
* Added descriptions to the config options.
* Add test for find-and-replace
* Adds tests for command activation/deactivation.

## 2.0.4
* Minor precaution using addEventListener instead of onblur.

## 2.0.3
* Fixes #39 - Calls to mini panes (like cmd+f, cmd+p) lock up when in jump mode.
* Merge @badem4o's pull request to fix some more deprecations in the shadow dom selectors.
* Fix deprecated method calls.
* *Slight* performance improvements.
* Improve tests.

## 2.0.2
* Fixed regression: restore consecutive labels across open tabs.

## 2.0.1
* Fixed regression: scroll event was no longer clearing jump-mode.

## 2.0.0
* 2.0.0 for reasons listed below:
* Almost every LOC changed to support new Atom APIs.  All tests passing with no deprecations!
* "Breaking" 2.0 changes because of shadow dom architectural changes.
  NOTE: Expect your user custom styling approaches to be defunct.
  Nothing I could have done here sorry, blame Atom (JK). New suggestions of how to style in an updated README.md coming soon!
* Planned 2.1 release will include @willdady's pull request (technically adds to the "breaking" change in functionality to improve "accuracy" - that is more labels!)
* Temporarily disabled "homing beacon" feature as this broke with the new shadow dom architecture.  Will need further investigation.
* Closes #42. (Doesn't work with the "Shadow DOM" flag enabled)

## 1.9.4
* Fixed #37 - No labels printed when tab dragged from different pane.

## 1.9.3
* Fixed default keymap to handle new editions to mac bindings in core
  Atom as of atom 0.131.0.
* New Atom default uses shift-enter for inserting a new line.
  * They added it for consistency.
  * You probably don't *need* it.

## 1.9.2
* Fixed some deprecated calls to restore performance times.
* Toggles were taking as long as 1 second to load with the deprecation
  stack.
* This fix restores toggle times back down to 15-40ms!

## 1.9.1
* Fixing CHANGELOG.md.  Had wrong versions.
* I goofed the branches up a bit.

## 1.9.0
* Makes the camel case + underscore regex match pattern the new default for Jumpy!
* This affords much better jump accuracy at no cost.
* If you prefer the old default (can't imagine why) set the old pattern with the custom match pattern setting to:
  '([\\w]){2,}'
* In the future I will probably support {}'s and other similar operators that need jumping to.
  Let me know if you have a tested regex that I can use!

## 1.8.3
* Fixes a bug where labels after zz were getting labeled as 'undefined'.
* Uses patterns like Aa-> Zz for the next 676 and then aA -> zZ for the next.
* Updates README.md's jumpy.gif.
* Adds new settings example image that contains .85 font, high contrast,
  and camel case match pattern.

## 1.8.2
* Updating README.md with new suggested match pattern regex override.
    * This regex pattern can detect camel casing and underscore separated variable names.
    * It has some dedicated spec tests as well.
    * More labels do not seem to get in the way.
    * It may become the default at some point!
* Updates spec tests to test published camel case and underscore pattern.

## 1.8.1
* Updating README.md and settings image.

## 1.8.0
* Adds custom match patterns.  I am not sure how useful this is yet.
    * Will be interesting to see if people find some good use cases.
      maybe for very particular programming languages or spoken languages etc.
* Adds a placeholder spec test for camel case matching.
    * I would really like jumpy to detect all camel humps (and underscores) and print a label there!

## 1.7.0
* Adds a warning message (usually orange) to the status bar if
  input does not match any labels (ie: zz, probably not on the page).
  This works at the input of first or second character.
  Effectively, Jumpy no longer clears the labels with invalid entries,
  but rather lets you try again.  A reset (usually backspace) is only
  necessary if you want to undo the first entered character and restore
  to all of the labels.

## 1.6.0
* Jump while highlighted selection.
* Works with 'v' (visual mode) in vim-mode.

## 1.5.0
* Jumpy now works with code folding and soft wraps (word wraps).
* NOTE: vim-mode seems to have very unexpected behavior with toggles and
  word wraps (even with Jumpy disabled).  Better behavior in insert mode!
* Although there are a few more features in the pipeline planned.
  This completes the last of the known unexpected behavior (bugs).

## 1.4.1
* Added some very useful instructions about how to bind 'f' to
  jumpy:toggle.  This of course replaces native 'f' functionality.

## 1.4.0
* Jumpy now clears irrelevant labels after the first character is
  entered.  This helps home in on your target.

## 1.3.1
* Fixes shift-enter (backward search) on find and replace's mini pane.

## 1.3.0
* Adds new homing beacon feature with setting to disable.
* Adds some missing spec tests.

## 0.1.7
* Reset current first character entered (triggered with backspace)
* Status bar updates with current first character entered
* Working spec tests
* No known bugs

## 0.1.0 - First Release
* Every feature added
* Every bug fixed
