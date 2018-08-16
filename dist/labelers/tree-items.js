"use strict";
'use babel';
Object.defineProperty(exports, "__esModule", { value: true });
const viewHelpers_1 = require("../viewHelpers");
class TreeItemLabel {
    destroy() {
        if (this.element) {
            this.element.remove();
        }
    }
    drawLabel() {
        const labelElement = document.createElement('div');
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
        const parent = this.item.parentElement;
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
        setTimeout(function () {
            beacon.remove();
        }, 150);
    }
    jump() {
        function triggerMouseEvent(element, eventType) {
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
const labeler = function (env) {
    const labels = [];
    // just here for hotkey cascading:
    const treeView = document.querySelector('.tree-view');
    if (treeView) {
        viewHelpers_1.addJumpModeClasses(treeView);
    }
    const treeItems = document.querySelectorAll('.tree-view-root .directory .list-item .name');
    for (const treeItem of treeItems) {
        const keyLabel = env.keys.shift();
        const label = new TreeItemLabel();
        label.settings = env.settings;
        label.keyLabel = keyLabel;
        label.item = treeItem;
        labels.push(label);
    }
    return labels;
};
exports.default = labeler;
//# sourceMappingURL=tree-items.js.map