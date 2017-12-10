"use strict";
'use babel';
Object.defineProperty(exports, "__esModule", { value: true });
// TODO: Merge in @johngeorgewright's code for treeview
// TODO: Merge in @willdady's code for better accuracy.
/* global atom */
const atom_1 = require("atom");
const _ = require("lodash");
const words_1 = require("./labelers/words");
const tabs_1 = require("./labelers/tabs");
const StateMachine = require("javascript-state-machine");
const label_reducer_1 = require("./label-reducer");
const keys_1 = require("./keys");
const viewHelpers_1 = require("./viewHelpers");
class JumpyView {
    constructor(serializedState) {
        this.workspaceElement = atom.views.getView(atom.workspace);
        this.disposables = new atom_1.CompositeDisposable();
        this.drawnLabels = [];
        this.commands = new atom_1.CompositeDisposable();
        this.fsm = StateMachine.create({
            initial: 'off',
            events: [
                { name: 'activate', from: 'off', to: 'on' },
                { name: 'key', from: 'on', to: 'on' },
                { name: 'reset', from: 'on', to: 'on' },
                { name: 'jump', from: 'on', to: 'off' },
                { name: 'exit', from: 'on', to: 'off' }
            ],
            callbacks: {
                onactivate: (event, from, to) => {
                    this.keydownListener = (event) => {
                        // use the code property for testing if
                        // the key is relevant to Jumpy
                        // that is, that it's an alpha char.
                        // use the key character to pass the exact key
                        // that is, (upper or lower) to the state machine.
                        // if jumpy catches it...stop the event propagation.
                        const { code, key, metaKey, ctrlKey, altKey } = event;
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
                    this.workspaceElement.addEventListener('keydown', this.keydownListener, true);
                    for (const e of ['blur', 'click', 'scroll']) {
                        this.workspaceElement.addEventListener(e, () => this.clearJumpModeHandler(), true);
                    }
                    const treeView = document.getElementsByClassName('tree-view');
                    if (treeView.length) {
                        viewHelpers_1.addJumpModeClasses(treeView[0]);
                    }
                    const environment = {
                        keys: keys_1.getKeySet(atom.config.get('jumpy.customKeys')),
                        settings: this.settings
                    };
                    // TODO: reduce with concat all labelers -> labeler.getLabels()
                    const wordLabels = words_1.default(environment);
                    const tabLabels = tabs_1.default(environment);
                    // TODO: I really think alllabels can just be drawnlabels
                    // maybe I call labeler.draw() still returns back anyway? Less functional?
                    this.allLabels = [
                        ...wordLabels,
                        ...tabLabels
                    ];
                    for (const label of this.allLabels) {
                        this.drawnLabels.push(label.drawLabel());
                    }
                    this.currentLabels = _.clone(this.allLabels);
                },
                onkey: (event, from, to, character) => {
                    // TODO: instead... of the following, maybe do with
                    // some substate ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ?
                    const testKeys = this.currentKeys + character;
                    const matched = this.currentLabels.some((label) => {
                        if (!label.keyLabel) {
                            return false;
                        }
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
                    for (const label of this.drawnLabels) {
                        if (!label.keyLabel || !label.element) {
                            continue;
                        }
                        if (!label.keyLabel.startsWith(this.currentKeys)) {
                            label.element.classList.add('irrelevant');
                        }
                    }
                    this.setStatus(character);
                    this.currentLabels = label_reducer_1.default(this.currentLabels, this.currentKeys);
                    if (this.currentLabels.length === 1 && this.currentKeys.length === 2) {
                        if (this.fsm.can('jump')) {
                            this.fsm.jump(this.currentLabels[0]);
                        }
                    }
                },
                onjump: (event, from, to, location) => {
                    location.jump();
                },
                onreset: (event, from, to) => {
                    this.currentKeys = '';
                    this.currentLabels = _.clone(this.allLabels);
                    for (const label of this.currentLabels) {
                        if (label.element) {
                            label.element.classList.remove('irrelevant');
                        }
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
            'jumpy:toggle': () => { this.toggle(); },
            'jumpy:reset': () => {
                if (this.fsm.can('reset')) {
                    this.fsm.reset();
                }
            },
            'jumpy:clear': () => {
                if (this.fsm.can('exit')) {
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
            const statusBarJumpyElement = document.createElement('div');
            statusBarJumpyElement.id = 'status-bar-jumpy';
            statusBarJumpyElement.classList.add('inline-block');
            statusBarJumpyElement.innerHTML = 'Jumpy: <span class="status"></span>';
            this.statusBar.addLeftTile({
                item: statusBarJumpyElement,
                priority: -1
            });
            this.statusBarJumpy = this.statusBar.querySelector('#status-bar-jumpy');
            if (this.statusBarJumpy) {
                this.statusBarJumpyStatus = this.statusBarJumpy.querySelector('.status');
                this.savedInheritedDisplay = this.statusBarJumpy.style.display;
            }
        }
    }
    showStatus() {
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
        let fontSize = atom.config.get('jumpy.fontSize');
        if (isNaN(fontSize) || fontSize > 1) {
            fontSize = .75; // default
        }
        const fontSizeString = `${fontSize * 100}%`;
        this.settings = {
            fontSize: fontSizeString,
            highContrast: atom.config.get('jumpy.highContrast'),
            wordsPattern: new RegExp(atom.config.get('jumpy.matchPattern'), 'g')
        };
    }
    toggle() {
        if (this.fsm.can('activate')) {
            this.fsm.activate();
        }
        else if (this.fsm.can('exit')) {
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
        const clearAllLabels = () => {
            for (const label of this.drawnLabels) {
                label.destroy();
            }
            this.drawnLabels = []; // Very important for GC.
            // Verifiable in Dev Tools -> Timeline -> Nodes.
        };
        this.allLabels = [];
        this.workspaceElement.removeEventListener('keydown', this.keydownListener, true);
        for (const e of ['blur', 'click', 'scroll']) {
            this.workspaceElement.removeEventListener(e, () => this.clearJumpModeHandler(), true);
        }
        const treeView = document.getElementsByClassName('tree-view');
        if (treeView.length) {
            viewHelpers_1.removeJumpModeClasses(treeView[0]);
        }
        for (const editor of atom.workspace.getTextEditors()) {
            const editorView = atom.views.getView(editor);
            viewHelpers_1.removeJumpModeClasses(editorView);
        }
        clearAllLabels();
        if (this.disposables) {
            this.disposables.dispose();
        }
    }
    // Returns an object that can be retrieved when package is activated
    serialize() { }
    // Tear down any state and detach
    destroy() {
        if (this.commands) {
            this.commands.dispose();
        }
        this.clearJumpMode();
    }
}
exports.default = JumpyView;
//# sourceMappingURL=jumpy-view.js.map