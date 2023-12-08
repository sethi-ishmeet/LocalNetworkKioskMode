//
//  ContentView.swift
//  LocalNetworkKioskMode
//
//  Created by Ishmeet Sethi on 2023-12-08.
//

import SwiftUI
import Network

class ViewModel: ObservableObject {
    private var browser: NWBrowser?
    @Published var status = "Not started"
    
    @MainActor
    func requestLocalNetworkAccess() {
        browser = getBrowser()
        browser?.start(queue: .main)
    }
    
    private func getBrowser() -> NWBrowser {
        let nwBrowser = NWBrowser(for: NWBrowser.Descriptor.bonjour(type: "_teamspaceapp._udp", domain: "local."), using: NWParameters())
        nwBrowser.stateUpdateHandler = { [weak self] state in
            
            guard let self = self else {
                return
            }
            
            switch state {
            case .ready:
                let secondsToDelay = 0.1
                
                DispatchQueue.main.asyncAfter(deadline: .now() + secondsToDelay) { [weak self] in
                    
                    guard let self = self else {
                        return
                    }
                    
                    if browser != nil {
                        let lastState = browser?.state
                        browser?.cancel()
                        switch lastState {
                        case .ready:
                            status = "Ready"
                        case let .waiting(error):
                            status = "Waiting: \(error)"
                        case let .failed(error):
                            status = "failed: \(error)"
                        case .cancelled:
                            status = "cancelled"
                        default:
                            status = "default"
                        }
                    } else {
                        status = "browser nil"
                    }
                }
            case let .failed(error):
                if browser != nil {
                    browser?.cancel()
                    status = "browser failed state: \(error)"
                } else {
                    status = "browser failed state, browser nil: \(error)"
                }
            default:
                // The only two remaining states are setup and canceled
                // Setup state is not a state change so it does not trigger the handler
                // Canceled state is only called after a completion block has been ran
                break
            }
        }
        return nwBrowser
    }
}

struct ContentView: View {
    @ObservedObject var vm = ViewModel()
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Status: \(vm.status)")
            
            Button {
                vm.requestLocalNetworkAccess()
            } label: {
                Text("Request Local network access")
            }
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
