//
//  KodiPlayerBrowser.swift
//  KodiConnector
//
//  Created by Berrie Kremers on 10/03/2019.
//  Copyright © 2019 Katoemba Software. All rights reserved.
//

import Foundation
import ConnectorProtocol
import RxSwift

/// Class to monitor kodiPlayers appearing and disappearing from the network.
public class KodiPlayerBrowser: PlayerBrowserProtocol {
    public var addPlayerObservable: Observable<PlayerProtocol>
    
    public var removePlayerObservable: Observable<PlayerProtocol>
    
    public init(userDefaults: UserDefaults) {
        addPlayerObservable = Observable.empty()
        removePlayerObservable = Observable.empty()
    }
    
    public func startListening() {
    }
    
    public func stopListening() {
    }
    
    public func playerForConnectionProperties(_ connectionProperties: [String : Any]) -> Observable<PlayerProtocol?> {
        return Observable.empty()
    }
    
    public func persistPlayer(_ connectionProperties: [String : Any]) {
    }
    
    public func removePlayer(_ player: PlayerProtocol) {
    }
}
