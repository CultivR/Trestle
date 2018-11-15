//
//  ButtonState.swift
//  Trestle
//
//  Created by Jordan Kay on 8/11/17.
//  Copyright © 2017 Cultivr. All rights reserved.
//

final class ButtonState {
    private(set) var highlightedState = false
    private(set) var loadingState = false
    
    private(set) var toggledState = false {
        didSet {
            delegate.state(self, didToggle: toggledState)
        }
    }
    
    private weak var delegate: ButtonStateDelegate!

    init(source: Void, delegate: ButtonStateDelegate) {
        self.delegate = delegate
    }
}

extension ButtonState {
    func toggle() {
        try! toggledState.transition(with: .toggle) {
            toggledState = $0
        }
    }
    
    func toggle(to state: Bool) {
        try! toggledState.transition(with: .toggleIfNotAlready(state)) {
            toggledState = $0
        }
    }
    
    func toggleHighlighted() {
        try! highlightedState.transition(with: .toggle) {
            highlightedState = $0
        }
    }
    
    func toggleLoading() {
        try! loadingState.transition(with: .toggle) {
            loadingState = $0
        }
    }
}

extension ButtonState: StateHolder {
    func reset() {
        return
    }
}

protocol ButtonStateDelegate: class {
    func state(_ state: ButtonState, didToggle toggled: Bool)
}
