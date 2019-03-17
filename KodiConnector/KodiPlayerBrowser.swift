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
import RxNetService
import Alamofire
import RxAlamofire

/// Class to monitor kodiPlayers appearing and disappearing from the network.
public class KodiPlayerBrowser: PlayerBrowserProtocol {
    private let kodiNetServiceBrowser : NetServiceBrowser
    private let backgroundScheduler = ConcurrentDispatchQueueScheduler.init(qos: .background)

    public var addPlayerObservable: Observable<PlayerProtocol>
    public var removePlayerObservable: Observable<PlayerProtocol>

    private var userDefaults: UserDefaults

    private let bag = DisposeBag()
    
    public init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
        
        kodiNetServiceBrowser = NetServiceBrowser()
        addPlayerObservable = kodiNetServiceBrowser.rx.serviceAdded
            .flatMap { (service) -> Observable<PlayerProtocol> in
                guard let hostName = service.hostName else { return Observable.empty() }

                let kodi = KodiWrapper(kodi: KodiAddress(ip: hostName, port: service.port))
                return kodi.pong()
                    .filter({ (pongSuccessful) -> Bool in
                        pongSuccessful == true
                    })
                    .flatMap({ (_) -> Observable<String> in
                        kodi.getKodiVersion()
                    })
                    .map({ (kodiVersion) -> PlayerProtocol in
                        KodiPlayer(name: service.name, host: hostName, port: service.port, version: kodiVersion, userDefaults: userDefaults)
                    })
            }
            .share(replay: 1)
        
        removePlayerObservable = kodiNetServiceBrowser.rx.serviceRemoved
            .map({ (service) -> PlayerProtocol in
                KodiPlayer(name: service.name, host: service.hostName ?? "Unknown", port: service.port, userDefaults: userDefaults)
            })
            .share(replay: 1)
    }
    
    public func startListening() {
        kodiNetServiceBrowser.searchForServices(ofType: "_http._tcp.", inDomain: "")
    }
    
    public func stopListening() {
        kodiNetServiceBrowser.stop()
    }
    
    public func playerForConnectionProperties(_ connectionProperties: [String : Any]) -> Observable<PlayerProtocol?> {
        return Observable.empty()
    }
    
    public func persistPlayer(_ connectionProperties: [String : Any]) {
    }
    
    public func removePlayer(_ player: PlayerProtocol) {
    }
}
