"use strict";
'use babel';
Object.defineProperty(exports, "__esModule", { value: true });
const atom_1 = require("atom");
class TabLabel {
    destroy() {
        if (this.element) {
            this.element.remove();
        }
    }
    drawLabel() {
        const tabsPane = atom.workspace.paneForItem(this.textEditor);
        const tabsPaneElement = atom.views.getView(tabsPane);
        const foundTab = tabsPaneElement
            .querySelector(`[data-path='${this.textEditor.getPath()}'`);
        if (!foundTab) {
            return this;
        }
        const labelElement = document.createElement('div');
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
        const tabsPane = atom.workspace.paneForItem(this.textEditor);
        const tabsPaneElement = atom.views.getView(tabsPane);
        const foundTab = tabsPaneElement
            .querySelector(`[data-path='${this.textEditor.getPath()}'`);
        if (foundTab) {
            const beacon = document.createElement('span');
            beacon.style.position = 'relative';
            beacon.style.zIndex = '4';
            beacon.classList.add('beacon'); // For styling and tests
            beacon.classList.add('tab-beacon');
            foundTab.appendChild(beacon);
            setTimeout(function () {
                beacon.remove();
            }, 150);
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
const labeler = function (env) {
    const labels = [];
    for (const textEditor of atom.workspace.getPaneItems()) {
        if (!(textEditor instanceof atom_1.TextEditor) || !textEditor.buffer) {
            continue;
        }
        const keyLabel = env.keys.shift();
        const label = new TabLabel();
        label.settings = env.settings;
        label.keyLabel = keyLabel;
        label.textEditor = textEditor;
        labels.push(label);
    }
    return labels;
};
exports.default = labeler;
//# sourceMappingURL=tabs.js.map