## 2.0.3
* Fix deprecated method calls.
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
