'use babel';

import { LabelEnvironment, Label, Labeler } from '../label-interface';
import { addJumpModeClasses } from '../viewHelpers';
import { TextEditor, Pane } from 'atom';

class TreeItemLabel implements Label {
    // TODO: check I need these defined again?
    keyLabel: string | undefined;
    textEditor: TextEditor | null;
    element: HTMLElement | null;
    settings: any;

    // TreeItemLabel specific:
    item: HTMLElement;

    destroy() {
        if (this.element) {
            this.element.remove();
        }
    }

    drawLabel(): Label {
        const labelElement:HTMLElement = document.createElement('div');
        if (this.keyLabel) {
            labelElement.textContent = this.keyLabel;
        }
        labelElement.style.position = 'absolute';
        labelElement.classList.add('jumpy-label'); // For styling and tests
        labelElement.classList.add('tree-item-label');
        labelElement.style.fontSize = this.settings.fontSize;

        if (this.settings.highContrast) {
           labelElement.classList.add('high-contrast');
        }

        this.element = labelElement;
        const parent = this.item.parentElement
        if (parent) {
            parent.appendChild(labelElement);
        }

        return this;
    }

    animateBeacon() {
        const beacon = document.createElement('span');
        beacon.style.position = 'relative';
        beacon.style.zIndex = '4';
        beacon.classList.add('beacon'); // For styling and tests
        beacon.classList.add('tree-item-beacon');

        this.item.appendChild(beacon);
        setTimeout(function() {
            beacon.remove();
        } , 150);
    }

    jump() {
        function triggerMouseEvent(element:HTMLElement, eventType:string): void {
            var clickEvent = new MouseEvent("click", {
                bubbles: true,
                cancelable: true,
                view: window
            });
            element.dispatchEvent(clickEvent);
        }
        const treeItem = this.item.parentElement;
        if (treeItem) {
            // TODO: use only 1 of these with a guard statement.
            atom.commands.dispatch(treeItem, 'tree-view:toggle-focus');
            triggerMouseEvent(treeItem, 'mousedown');
            atom.commands.dispatch(treeItem, 'tree-view:toggle-focus');
        }
        // this.item.parentElement.click();
        if (atom.config.get('jumpy.useHomingBeaconEffectOnJumps')) {
            this.animateBeacon();
        }
    }
}

const labeler: Labeler = function(env:LabelEnvironment):Array<TreeItemLabel> {
    const labels:Array<TreeItemLabel> = [];

    // just here for hotkey cascading:
    const treeView = <HTMLElement>document.querySelector('.tree-view');
    if (treeView) {
        addJumpModeClasses(treeView);
    }

    const treeItems:NodeListOf<Element> = document.querySelectorAll('.tree-view-root .directory .list-item .name');

    for (const treeItem of treeItems) {
        const keyLabel:string | undefined = env.keys.shift();

        const label = new TreeItemLabel();
        label.settings = env.settings;
        label.keyLabel = keyLabel;
        label.item = treeItem;
        labels.push(label);
    }

    return labels;
}

export default labeler;
