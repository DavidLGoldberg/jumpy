export function addJumpModeClasses(element: HTMLElement) {
    element.classList.add('jumpy-jump-mode',
        'jumpy-more-specific1', 'jumpy-more-specific2');
}

export function removeJumpModeClasses(element: HTMLElement) {
    element.classList.remove('jumpy-jump-mode',
        'jumpy-more-specific1', 'jumpy-more-specific2');
}
