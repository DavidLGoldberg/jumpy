'use babel';

import { LabelEnvironment, Label, Labeler } from '../label-interface';
import { TextEditor, Pane } from 'atom';

class TabLabel implements Label {
    // TODO: check I need these defined again?
    keyLabel: string | undefined;
    textEditor: TextEditor | null;
    element: HTMLElement | null;
    settings: any;

    destroy() {
        if (this.element) {
            this.element.remove();
        }
    }

    drawLabel(): Label {
        const tabsPane:Pane = atom.workspace.paneForItem(this.textEditor);
        const tabsPaneElement:HTMLElement = atom.views.getView(tabsPane);
        const foundTab:HTMLElement | null = <HTMLElement>tabsPaneElement
            .querySelector(`[data-path='${this.textEditor.getPath()}'`);

        if (!foundTab) {
            return this;
        }

        const labelElement:HTMLElement = document.createElement('div');
        if (this.keyLabel) {
            labelElement.textContent = this.keyLabel;
        }
        labelElement.style.position = 'fixed';
        labelElement.classList.add('jumpy-label'); // For styling and tests
        labelElement.classList.add('tab-label');
        labelElement.style.fontSize = this.settings.fontSize;

        if (this.settings.highContrast) {
           labelElement.classList.add('high-contrast');
        }

        this.element = labelElement;
        foundTab.appendChild(labelElement);

        return this;
    }

    animateBeacon() {
        // TODO: abstract function to find tab!
        const tabsPane:Pane = atom.workspace.paneForItem(this.textEditor);
        const tabsPaneElement:HTMLElement = atom.views.getView(tabsPane);
        const foundTab:HTMLElement | null = <HTMLElement>tabsPaneElement
            .querySelector(`[data-path='${this.textEditor.getPath()}'`);

        if (foundTab) {
            const beacon = document.createElement('span');
            beacon.style.position = 'relative';
            beacon.style.zIndex = '4';
            beacon.classList.add('beacon'); // For styling and tests
            beacon.classList.add('tab-beacon');

            foundTab.appendChild(beacon);
            setTimeout(function() {
                beacon.remove();
            } , 150);
        }
    }

    jump() {
        const pane = atom.workspace.paneForItem(this.textEditor);
        pane.activate();
        pane.activateItem(this.textEditor);

        if (atom.config.get('jumpy.useHomingBeaconEffectOnJumps')) {
            this.animateBeacon();
        }
    }
}

const labeler: Labeler = function(env:LabelEnvironment):Array<TabLabel> {
    const labels:Array<TabLabel> = [];

    for (const textEditor of atom.workspace.getPaneItems()) {
        if (!(textEditor instanceof TextEditor) || !textEditor.buffer) {
            continue;
        }

        const keyLabel:string | undefined = env.keys.shift();

        const label = new TabLabel();
        label.settings = env.settings;
        label.keyLabel = keyLabel;
        label.textEditor = textEditor;
        labels.push(label);
    }

    return labels;
}

export default labeler;
