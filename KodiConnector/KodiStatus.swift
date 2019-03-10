//
//  KodiStatus.swift
//  KodiConnector
//
//  Created by Berrie Kremers on 10/03/2019.
//  Copyright © 2019 Katoemba Software. All rights reserved.
//

import Foundation
import ConnectorProtocol
import RxSwift
import RxCocoa

public class KodiStatus: StatusProtocol {
    private var connectionStatus = BehaviorRelay<ConnectionStatus>(value: .unknown)
    public var connectionStatusObservable: Observable<ConnectionStatus> {
        return connectionStatus.asObservable()
    }
    
    private var playerStatus = BehaviorRelay<PlayerStatus>(value: PlayerStatus())
    public var playerStatusObservable: Observable<PlayerStatus> {
        return playerStatus.asObservable()
    }
    
    public init() {
        
    }
    
    public func playqueueSongs(start: Int, end: Int) -> [Song] {
        return []
    }
    
    public func forceStatusRefresh() {
    }
}
