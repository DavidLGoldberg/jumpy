'use babel';

// TODO: Merge in @johngeorgewright's code for treeview
// TODO: Merge in @willdady's code for better accuracy.
// TODO: Remove space-pen?

/* global atom */
import { CompositeDisposable, Point } from 'atom';
import { $ } from 'space-pen';
import * as _ from 'lodash';

import words from '../dist/labelers/words';
import StateMachine from 'javascript-state-machine';
import labelReducer from '../dist/label-reducer';
import { getKeySet, drawLabel, drawBeacon } from '../dist/label';

export default class JumpyView {

    constructor(serializedState) {
        this.workspaceElement = atom.views.getView(atom.workspace);
        this.disposables = new CompositeDisposable();
        this.decorations = [];
        this.commands = new CompositeDisposable();

        this.fsm = StateMachine.create({
            initial: 'off',
            events: [
                { name: 'activate', from: 'off', to: 'on' },
                { name: 'key', from: 'on', to: 'on' },
                { name: 'reset', from: 'on', to: 'on' },
                { name: 'jump', from: 'on', to: 'off' },
                { name: 'exit', from: 'on', to: 'off'  }
            ],
            callbacks: {
                onactivate: (event, from, to ) => {
                    this.keydownListener = (event) => {
                        // use the code property for testing if
                        // the key is relevant to Jumpy
                        // that is, that it's an alpha char.
                        // use the key character to pass the exact key
                        // that is, (upper or lower) to the state machine.
                        // if jumpy catches it...stop the event propagation.
                        const {code, key, metaKey, ctrlKey, altKey} = event;
                        if (metaKey || ctrlKey || altKey) {
                            return;
                        }

                        if (/^Key[A-Z]{1}$/.test(code)) {
                            event.preventDefault();
                            event.stopPropagation();
                            this.fsm.key(key);
                        }
                    };

                    this.setSettings();

                    this.currentKeys = '';

                    // important to keep this up here and not in the observe
                    // text editor to not crash if no more keys left!
                    // this shouldn't have to be this way, but for now.
                    this.keys = getKeySet();

                    this.allLabels = [];
                    this.currentLabels = [];

                    this.workspaceElement.addEventListener('keydown', this.keydownListener, true);
                    for (const e of ['blur', 'click', 'scroll']) {
                        this.workspaceElement.addEventListener(e, () => this.clearJumpModeHandler(), true);
                    }

                    this.settings.wordsPattern.lastIndex = 0; // reset the RegExp for subsequent calls.
                    this.disposables.add(atom.workspace.observeTextEditors((editor) => {
                        const editorView = atom.views.getView(editor);
                        if ($(editorView).is(':not(:visible)')) {
                            return;
                        }

                        // 'jumpy-jump-mode is for keymaps and utilized by tests
                        editorView.classList.add('jumpy-jump-mode',
                            'jumpy-more-specific1', 'jumpy-more-specific2');

                        // current labels for current editor in observe.
                        if (!this.keys.length) {
                            return;
                        }
                        const currentEditorLabels = words.getLabels(editor, editorView, this.keys, this.settings);
                        // only draw new labels
                        for (const label of currentEditorLabels) {
                            this.decorations.push(drawLabel(label, this.settings));
                        }

                        this.allLabels = this.allLabels.concat(currentEditorLabels);
                        this.currentLabels = _.clone(this.allLabels);
                    }));
                },

                onkey: (event, from, to, character) => {
                    // instead... of the following, maybe do with
                    // some substate ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ?
                    const testKeys = this.currentKeys + character;
                    const matched = this.currentLabels.some((label) => {
                        return label.keyLabel.startsWith(testKeys);
                    });

                    if (!matched) {
                        if (this.statusBarJumpy) {
                            this.statusBarJumpy.classList.add('no-match');
                        }
                        this.setStatus('No Match!');
                        return;
                    }
                    // ^ the above makes this func feel not single responsibility
                    // some substate ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ?

                    this.currentKeys = testKeys;

                    for (const decoration of this.decorations) {
                        const element = decoration.getProperties().item;
                        if (!element.textContent.startsWith(this.currentKeys)) {
                            element.classList.add('irrelevant');
                        }
                    }

                    this.setStatus(character);

                    this.currentLabels = labelReducer(this.currentLabels, this.currentKeys);

                    if (this.currentLabels.length === 1 && this.currentKeys.length === 2) {
                        if (this.fsm.can('jump')) {
                            this.fsm.jump(this.currentLabels[0]);
                        }
                    }
                },

                onjump: (event, from, to, location) => {
                    const currentEditor = location.editor;
                    const editorView = atom.views.getView(currentEditor);

                    // Prevent other editors from jumping cursors as well
                    // TODO: make a test for this if return
                    if (currentEditor.id !== location.editor.id) {
                        return;
                    }

                    const pane = atom.workspace.paneForItem(currentEditor);
                    pane.activate();

                    // isVisualMode is for vim-mode or vim-mode-plus:
                    const isVisualMode = editorView.classList.contains('visual-mode');
                    // isSelected is for regular selection in atom or in insert-mode in vim
                    const isSelected = (currentEditor.getSelections().length === 1 &&
                        currentEditor.getSelectedText() !== '');
                    const position = Point(location.lineNumber, location.column);
                    if (isVisualMode || isSelected) {
                        currentEditor.selectToScreenPosition(position);
                    } else {
                        currentEditor.setCursorScreenPosition(position);
                    }

                    if (atom.config.get('jumpy.useHomingBeaconEffectOnJumps')) {
                        drawBeacon(currentEditor, position);
                    }
                },

                onreset: (event, from, to) => {
                    this.currentKeys = '';
                    this.currentLabels = _.clone(this.allLabels);
                    for (const decoration of this.decorations) {
                        element = decoration.getProperties().item;
                        element.classList.remove('irrelevant');
                    }
                },

                // STATE CHANGES:
                onoff: (event, from, to) => {
                    if (from === 'on') {
                        this.clearJumpMode();
                    }
                    if (this.statusBarJumpy) {
                        this.statusBarJumpy.style.display = 'none';
                    }
                    this.setStatus(''); // Just for correctness really
                },

                onbeforeevent: (event, from, to) => {
                    this.initializeStatusBar();

                    // Reset statuses:
                    this.setStatus('Jump Mode!');
                    this.showStatus();
                    if (this.statusBarJumpy) {
                        this.statusBarJumpy.classList.remove('no-match');
                    }
                }
            }
        });

        // TODO: do I need the () => or just =>
        this.commands.add(atom.commands.add('atom-workspace', {
            'jumpy:toggle': () => { this.toggle() },
            'jumpy:reset': () => {
                if (this.fsm.can('reset')) {
                    this.fsm.reset();
                }
            },
            'jumpy:clear': () => {
                if(this.fsm.can('exit')) {
                    this.fsm.exit();
                }
            }
        }));
    }

    // This needs to be called when status bar is ready, so can't be called from constructor
    initializeStatusBar() {
        if (this.statusBar) {
            return;
        }

        this.statusBar = document.querySelector('status-bar');
        if (this.statusBar) {
            this.statusBar.addLeftTile({
                item: $('<div id="status-bar-jumpy" class="inline-block"> \
                        Jumpy: <span class="status"></span> \
                    </div>'),
                priority: -1
            });
            this.statusBarJumpy = this.statusBar.querySelector('#status-bar-jumpy');
            if (this.statusBarJumpy) {
                this.statusBarJumpyStatus = this.statusBarJumpy.querySelector('.status');
                console.log('!!?!!?', this.statusBarJumpyStatus);
                this.savedInheritedDisplay = this.statusBarJumpy.style.display;
            }
        }
    }

    showStatus() { // restore typical status bar display (inherited)
        if (this.statusBarJumpy) {
            this.statusBarJumpy.style.display = this.savedInheritedDisplay;
        }
    }

    setStatus(status) {
        if (this.statusBarJumpyStatus) {
            this.statusBarJumpyStatus.innerHTML = status;
        }
    }

    setSettings() {
        fontSize = atom.config.get('jumpy.fontSize');
        if (isNaN(fontSize) || fontSize > 1) {
            fontSize = .75; // default
        }
        fontSize = (fontSize * 100) + '%';
        this.settings = {
            fontSize,
            highContrast: atom.config.get('jumpy.highContrast'),
            wordsPattern: new RegExp (atom.config.get('jumpy.matchPattern'), 'g')
        };
    }

    toggle() {
        if (this.fsm.can('activate')) {
            this.fsm.activate();
        } else if (this.fsm.can('exit')) {
            this.fsm.exit();
        }
    }

    clearJumpModeHandler() {
        if (this.fsm.can('exit')) {
            this.fsm.exit();
        }
    }

    // TODO: move into fsm? change callers too
    clearJumpMode() {
        clearAllMarkers = () => {
            for (const decoration of this.decorations) {
                decoration.getMarker().destroy();
            }
            this.decorations = []; // Very important for GC.
            // Verifiable in Dev Tools -> Timeline -> Nodes.
        };

        this.allLabels = [];
        this.workspaceElement.removeEventListener('keydown', this.keydownListener, true);
        for (const e of ['blur', 'click', 'scroll']) {
            this.workspaceElement.removeEventListener(e, () => this.clearJumpModeHandler(), true);
        }
        this.disposables.add(atom.workspace.observeTextEditors((editor) => {
            const editorView = atom.views.getView(editor);

            editorView.classList.remove('jumpy-jump-mode',
                'jumpy-more-specific1', 'jumpy-more-specific2');
        }));
        clearAllMarkers();
        this.decorations = []; // Very important for GC.
        if (this.disposables) {
            this.disposables.dispose();
        }
    }

    // Returns an object that can be retrieved when package is activated
    serialize() {}

    // Tear down any state and detach
    destroy() {
        if (this.commands) {
            this.commands.dispose();
        }
        this.clearJumpMode();
    }
}
