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
const label_reducer_1 = require("./label-reducer");
const keys_1 = require("./keys");
const viewHelpers_1 = require("./viewHelpers");
class JumpyView {
    constructor(serializedState, stateMachine) {
        this.workspaceElement = atom.views.getView(atom.workspace);
        this.disposables = new atom_1.CompositeDisposable();
        this.drawnLabels = [];
        this.commands = new atom_1.CompositeDisposable();
        this.stateMachine = stateMachine;
        this.setSettings();
        this.setUpJumpModeClasses();
        // Subscribe:
        this.stateMachine.ports.validKeyEntered.subscribe((keyLabel) => {
            for (const label of this.drawnLabels) {
                if (!label.keyLabel || !label.element) {
                    continue;
                }
                if (!label.keyLabel.startsWith(keyLabel)) {
                    label.element.classList.add('irrelevant');
                }
            }
            this.currentLabels = label_reducer_1.default(this.currentLabels, keyLabel);
        });
        this.stateMachine.ports.labelJumped.subscribe((keyLabel) => {
            _.find(this.currentLabels, (label) => label.keyLabel === keyLabel).jump();
        });
        this.stateMachine.ports.activeChanged.subscribe((active) => {
            this.active = active;
            if (!this.active) {
                this.turnOffListeners();
                this.clearJumpMode();
            }
        });
        this.stateMachine.ports.statusChanged.subscribe((statusMarkup) => {
            if (this.statusBarElement) {
                this.statusBarElement.innerHTML = statusMarkup;
            }
        });
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
                this.stateMachine.ports.key.send(key.charCodeAt());
            }
        };
        this.commands.add(atom.commands.add('atom-workspace', {
            'jumpy:toggle': () => { this.toggle(); },
            'jumpy:reset': () => { this.reset(); },
            'jumpy:clear': () => {
                this.stateMachine.ports.exit.send(null);
            }
        }));
    }
    setUpJumpModeClasses() {
        const treeView = document.getElementsByClassName('tree-view');
        if (treeView.length) {
            viewHelpers_1.addJumpModeClasses(treeView[0]);
        }
    }
    initializeStatusBar() {
        // NOTE: This needs to be called when status bar is ready, so can't be called from constructor
        if (this.statusBarElement) {
            return;
        }
        const atomStatusBar = document.querySelector('status-bar');
        if (atomStatusBar) {
            const statusBarElement = document.createElement('div');
            this.statusBarElement = statusBarElement;
            statusBarElement.id = 'status-bar-jumpy-container';
            statusBarElement.classList.add('inline-block');
            statusBarElement.innerHTML = "<div id='status-bar-jumpy'>Jumpy: <span>Jump Mode!</span></div>";
            atomStatusBar.addLeftTile({
                item: statusBarElement,
                priority: -1
            });
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
    reset() {
        this.currentLabels = _.clone(this.allLabels);
        for (const label of this.currentLabels) {
            if (label.element) {
                label.element.classList.remove('irrelevant');
            }
        }
        this.stateMachine.ports.reset.send(null);
    }
    loadLabels() {
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
        this.stateMachine.ports.labels.send(this.currentLabels
            .filter((label) => label.keyLabel) // ie. tabs open after limit reached
            .map((label) => label.keyLabel));
    }
    toggle() {
        if (!this.active) {
            this.loadLabels();
            this.initializeStatusBar();
            this.turnOnListeners();
        }
        else {
            this.stateMachine.ports.exit.send(null);
        }
    }
    turnOnListeners() {
        this.workspaceElement.addEventListener('keydown', this.keydownListener, true);
        for (const e of ['blur', 'click', 'scroll']) {
            this.workspaceElement.addEventListener(e, () => this.clearJumpModeHandler(), true);
        }
    }
    turnOffListeners() {
        this.workspaceElement.removeEventListener('keydown', this.keydownListener, true);
        for (const e of ['blur', 'click', 'scroll']) {
            this.workspaceElement.removeEventListener(e, () => this.clearJumpModeHandler(), true);
        }
    }
    clearJumpModeHandler() {
        this.stateMachine.ports.exit.send(null);
        this.clearJumpMode();
    }
    clearJumpMode() {
        const clearAllLabels = () => {
            for (const label of this.drawnLabels) {
                label.destroy();
            }
            this.drawnLabels = []; // Very important for GC.
            // Verifiable in Dev Tools -> Timeline -> Nodes.
        };
        this.allLabels = [];
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