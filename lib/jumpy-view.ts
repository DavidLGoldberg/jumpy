'use babel';

// TODO: Merge in @johngeorgewright's code for treeview
// TODO: Merge in @willdady's code for better accuracy.

/* global atom */
import { CompositeDisposable, Point } from 'atom';
import * as _ from 'lodash';

import { LabelEnvironment, Label } from './label-interface';
import getWordLabels from './labelers/words';
import getTabLabels from './labelers/tabs';
import getTreeItemLabels from './labelers/tree-items';
import labelReducer from './label-reducer';
import { getKeySet } from './keys';
import { removeJumpModeClasses } from './viewHelpers';

export default class JumpyView {
    workspaceElement: any;
    disposables: CompositeDisposable;
    commands: CompositeDisposable;
    stateMachine: any;
    active: boolean;
    allLabels: Array<Label>; // TODO: these lists of labels seem a little much.
    currentLabels: Array<Label>;
    drawnLabels: Array<Label>;
    keydownListener: any;
    settings: any;
    statusBarElement: HTMLElement | null;

    constructor(serializedState: any, stateMachine: any) {
        this.workspaceElement = atom.views.getView(atom.workspace);
        this.disposables = new CompositeDisposable();
        this.drawnLabels = [];
        this.commands = new CompositeDisposable();
        this.stateMachine = stateMachine;

        this.setSettings();

        // Subscribe:
        this.stateMachine.ports.validKeyEntered.subscribe((keyLabel: string) => {
            for (const label of this.drawnLabels) {
                if (!label.keyLabel || !label.element) {
                    continue;
                }
                if (!label.keyLabel.startsWith(keyLabel)) {
                    label.element.classList.add('irrelevant');
                }
            }

            this.currentLabels = labelReducer(this.currentLabels, keyLabel);
        });

        this.stateMachine.ports.labelJumped.subscribe((keyLabel: string) => {
            _.find(this.currentLabels, (label) => label.keyLabel === keyLabel).jump();
        });

        this.stateMachine.ports.activeChanged.subscribe((active: boolean) => {
            this.active = active;

            if (!this.active) {
                this.turnOffListeners();
                this.clearJumpMode();
            }
        });

        this.stateMachine.ports.statusChanged.subscribe((statusMarkup: string) => {
            if (this.statusBarElement) {
                this.statusBarElement.innerHTML = statusMarkup;
            }
        });

        this.keydownListener = (event: any) => {
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
                this.stateMachine.ports.key.send(key.charCodeAt());
            }
        };

        this.commands.add(atom.commands.add('atom-workspace', {
            'jumpy:toggle': () => { this.toggle() },
            'jumpy:reset': () => { this.reset(); },
            'jumpy:clear': () => {
                this.stateMachine.ports.exit.send(null);
            }
        }));
    }

    initializeStatusBar() {
        // NOTE: This needs to be called when status bar is ready, so can't be called from constructor

        if (this.statusBarElement) {
            return;
        }

        const atomStatusBar = <HTMLElement>document.querySelector('status-bar');
        if (atomStatusBar) {
            const statusBarElement = document.createElement('div');
            this.statusBarElement = statusBarElement;
            statusBarElement.id = 'status-bar-jumpy-container';
            statusBarElement.classList.add('inline-block');
            statusBarElement.innerHTML = "<div id='status-bar-jumpy'>Jumpy: <span class='status'>Jump Mode!</span></div>";
            atomStatusBar.addLeftTile({
                item: statusBarElement,
                priority: -1
            });
        }
    }

    setSettings() {
        let fontSize:number = atom.config.get('jumpy.fontSize');
        if (isNaN(fontSize) || fontSize > 1) {
            fontSize = .75; // default
        }
        const fontSizeString:string = `${fontSize * 100}%`;
        this.settings = {
            fontSize: fontSizeString,
            highContrast: <boolean>atom.config.get('jumpy.highContrast'),
            wordsPattern: new RegExp (atom.config.get('jumpy.matchPattern'), 'g')
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
        const environment:LabelEnvironment = {
            keys: getKeySet(atom.config.get('jumpy.customKeys')),
            settings: this.settings
        };

        // TODO: reduce with concat all labelers -> labeler.getLabels()
        const wordLabels:Array<Label> = getWordLabels(environment);
        const tabLabels:Array<Label> = getTabLabels(environment);
        const treeItemLabels:Array<Label> = getTreeItemLabels(environment);

        // TODO: I really think alllabels can just be drawnlabels
        // maybe I call labeler.draw() still returns back anyway? Less functional?
        this.allLabels = [
            ...wordLabels,
            ...tabLabels
            ...treeItemLabels
        ];

        for (const label of this.allLabels) {
            this.drawnLabels.push(label.drawLabel());
        }

        this.currentLabels = _.clone(this.allLabels);

        this.stateMachine.ports.getLabels.send(
            this.currentLabels
                .filter((label) => label.keyLabel) // ie. tabs open after limit reached
                .map((label) => label.keyLabel)
        );
    }

    toggle() {
        if (!this.active) {
            this.loadLabels();
            this.initializeStatusBar();
            this.turnOnListeners();

        } else { // Turn off:
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
        const treeView:HTMLCollectionOf<Element> = document.getElementsByClassName('tree-view');
        if (treeView.length) {
            removeJumpModeClasses(treeView[0]);
        }
        for (const editor of atom.workspace.getTextEditors()) {
            const editorView = atom.views.getView(editor);
            removeJumpModeClasses(editorView);
        }
        clearAllLabels();
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
