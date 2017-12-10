'use babel';

// TODO: Merge in @johngeorgewright's code for treeview
// TODO: Merge in @willdady's code for better accuracy.

/* global atom */
import { CompositeDisposable, Point } from 'atom';
import * as _ from 'lodash';

import { LabelEnvironment, Label } from './label-interface';
import getWordLabels from './labelers/words';
import getTabLabels from './labelers/tabs';
import * as StateMachine from 'javascript-state-machine';
import labelReducer from './label-reducer';
import { getKeySet } from './keys';
import { addJumpModeClasses, removeJumpModeClasses } from './viewHelpers';

export default class JumpyView {
    workspaceElement: any;
    disposables: CompositeDisposable;
    commands: CompositeDisposable;
    fsm: any;
    currentKeys: string;
    allLabels: Array<Label>; // TODO: these lists of labels seem a little much.
    currentLabels: Array<Label>;
    drawnLabels: Array<Label>;
    keydownListener: any;
    settings: any;
    statusBar: HTMLElement | null;
    statusBarJumpy: HTMLElement | null;
    statusBarJumpyStatus: HTMLElement | null;
    savedInheritedDisplay: any;

    constructor(serializedState: any) {
        this.workspaceElement = atom.views.getView(atom.workspace);
        this.disposables = new CompositeDisposable();
        this.drawnLabels = [];
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
                onactivate: (event: any, from: string, to: string ) => {
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
                            this.fsm.key(key);
                        }
                    };

                    this.setSettings();

                    this.currentKeys = '';

                    this.workspaceElement.addEventListener('keydown', this.keydownListener, true);
                    for (const e of ['blur', 'click', 'scroll']) {
                        this.workspaceElement.addEventListener(e, () => this.clearJumpModeHandler(), true);
                    }

                    const treeView:HTMLCollectionOf<Element> = document.getElementsByClassName('tree-view');
                    if (treeView.length) {
                        addJumpModeClasses(treeView[0]);
                    }

                    const environment:LabelEnvironment = {
                        keys: getKeySet(atom.config.get('jumpy.customKeys')),
                        settings: this.settings
                    };

                    // TODO: reduce with concat all labelers -> labeler.getLabels()
                    const wordLabels:Array<Label> = getWordLabels(environment);
                    const tabLabels:Array<Label> = getTabLabels(environment);

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

                onkey: (event: any, from: string, to: string, character: string) => {
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

                    this.currentLabels = labelReducer(this.currentLabels, this.currentKeys);

                    if (this.currentLabels.length === 1 && this.currentKeys.length === 2) {
                        if (this.fsm.can('jump')) {
                            this.fsm.jump(this.currentLabels[0]);
                        }
                    }
                },

                onjump: (event: any, from: string, to: string, location: Label) => {
                    location.jump();
                },

                onreset: (event: any, from: string, to: string) => {
                    this.currentKeys = '';
                    this.currentLabels = _.clone(this.allLabels);
                    for (const label of this.currentLabels) {
                        if (label.element) {
                            label.element.classList.remove('irrelevant');
                        }
                    }
                },

                // STATE CHANGES:
                onoff: (event: any, from: string, to: string) => {
                    if (from === 'on') {
                        this.clearJumpMode();
                    }
                    if (this.statusBarJumpy) {
                        this.statusBarJumpy.style.display = 'none';
                    }
                    this.setStatus(''); // Just for correctness really
                },

                onbeforeevent: (event: any, from: string, to: string) => {
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

        this.statusBar = <HTMLElement>document.querySelector('status-bar');
        if (this.statusBar) {
            const statusBarJumpyElement = document.createElement('div');
            statusBarJumpyElement.id = 'status-bar-jumpy';
            statusBarJumpyElement.classList.add('inline-block');
            statusBarJumpyElement.innerHTML = 'Jumpy: <span class="status"></span>';
            this.statusBar.addLeftTile({
                item: statusBarJumpyElement,
                priority: -1
            });
            this.statusBarJumpy = <HTMLElement>this.statusBar.querySelector('#status-bar-jumpy');
            if (this.statusBarJumpy) {
                this.statusBarJumpyStatus = <HTMLElement>this.statusBarJumpy.querySelector('.status');
                this.savedInheritedDisplay = this.statusBarJumpy.style.display;
            }
        }
    }

    showStatus() { // restore typical status bar display (inherited)
        if (this.statusBarJumpy) {
            this.statusBarJumpy.style.display = this.savedInheritedDisplay;
        }
    }

    setStatus(status: string) {
        if (this.statusBarJumpyStatus) {
            this.statusBarJumpyStatus.innerHTML = status;
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
