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
    public var controllerType: String {
        KodiPlayer.controllerType
    }
    private let kodiNetServiceBrowser : NetServiceBrowser
    private let backgroundScheduler = ConcurrentDispatchQueueScheduler.init(qos: .background)
    private var isListening = false
    
    public var addPlayerObservable: Observable<PlayerProtocol>
    public var removePlayerObservable: Observable<PlayerProtocol>
    private let addManualPlayerSubject = PublishSubject<PlayerProtocol>()
    private let removeManualPlayerSubject = PublishSubject<PlayerProtocol>()
    
    private let settingsChangedSubject = PublishSubject<KodiPlayer>()
    private var userDefaults: UserDefaults
    
    private let bag = DisposeBag()
    
    public init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
        let localSettingsChangedSubject = settingsChangedSubject
        
        kodiNetServiceBrowser = NetServiceBrowser()
        
        let discoveredPlayerObservable = kodiNetServiceBrowser.rx.serviceAdded
            .flatMap { (service) -> Observable<PlayerProtocol> in
                guard let hostName = service.hostName else { return Observable.empty() }
                
                let kodi = KodiWrapper(kodi: KodiAddress(ip: hostName, port: service.port, websocketPort: 9090))
                return kodi.ping()
                    .filter({ (pingSuccessful) -> Bool in
                        pingSuccessful == true
                    })
                    .flatMap({ (_) -> Observable<String> in
                        kodi.getKodiVersion()
                    })
                    .map({ (kodiVersion) -> PlayerProtocol in
                        KodiPlayer(name: service.name, host: hostName, port: service.port, version: kodiVersion, userDefaults: userDefaults, settingsChangedSubject: localSettingsChangedSubject)
                    })
        }
        
        addPlayerObservable = Observable.merge(discoveredPlayerObservable, addManualPlayerSubject)
            .share(replay: 1)
        
        let lostPlayerObservable = kodiNetServiceBrowser.rx.serviceRemoved
            .map({ (service) -> PlayerProtocol in
                KodiPlayer(name: service.name, host: service.hostName ?? "Unknown", port: service.port, userDefaults: userDefaults)
            })
        
        removePlayerObservable = Observable.merge(lostPlayerObservable, removeManualPlayerSubject)
            .share(replay: 1)
    }
    
    public func startListening() {
        guard isListening == false else {
            return
        }
        
        isListening = true
        kodiNetServiceBrowser.searchForServices(ofType: "_http._tcp.", inDomain: "")
        
        let persistedPlayers = userDefaults.dictionary(forKey: "kodi.browser.manualplayers") ?? [String: [String: Any]]()
        for persistedPlayer in persistedPlayers.keys {
            addManualPlayerSubject.onNext(KodiPlayer(connectionProperties: persistedPlayers[persistedPlayer] as! [String: Any], discoverMode: .manual, userDefaults: userDefaults))
        }
    }
    
    public func stopListening() {
        guard isListening == true else {
            return
        }
        
        isListening = false
        kodiNetServiceBrowser.stop()
    }
    
    public func playerForConnectionProperties(_ connectionProperties: [String : Any]) -> Observable<PlayerProtocol?> {
        guard connectionProperties[ConnectionProperties.controllerType.rawValue] as? String == KodiPlayer.controllerType,
            let name = connectionProperties[ConnectionProperties.name.rawValue] as? String,
            let hostName = connectionProperties[ConnectionProperties.host.rawValue] as? String,
            let port = connectionProperties[ConnectionProperties.port.rawValue] as? Int,
            let websocketPort = connectionProperties[KodiConnectionProperties.websocketPort.rawValue] as? Int
            else { return Observable.just(nil) }
        
        let kodi = KodiWrapper(kodi: KodiAddress(ip: hostName, port: port, websocketPort: websocketPort))
        return kodi.ping()
            .flatMap({ [weak self] (success) -> Observable<PlayerProtocol?> in
                guard let weakSelf = self else { return Observable.just(nil) }
                if success {
                    return Observable.just(KodiPlayer(name: name, host: hostName, port: port, websocketPort: websocketPort, userDefaults: weakSelf.userDefaults))
                }
                else {
                    return Observable.just(nil)
                }
            })
    }
    
    public func persistPlayer(_ connectionProperties: [String : Any]) {
        guard connectionProperties[ConnectionProperties.controllerType.rawValue] as? String == KodiPlayer.controllerType else { return }
        
        var persistedPlayers = userDefaults.dictionary(forKey: "kodi.browser.manualplayers") ?? [String: [String: Any]]()
        
        if persistedPlayers[connectionProperties[ConnectionProperties.name.rawValue] as! String] != nil {
            removeManualPlayerSubject.onNext(KodiPlayer(connectionProperties: connectionProperties, userDefaults: userDefaults))
        }
        persistedPlayers[connectionProperties[ConnectionProperties.name.rawValue] as! String] = connectionProperties
        addManualPlayerSubject.onNext(KodiPlayer(connectionProperties: connectionProperties, discoverMode: .manual, userDefaults: userDefaults))
        
        userDefaults.set(persistedPlayers, forKey: "kodi.browser.manualplayers")
    }
    
    public func removePlayer(_ player: PlayerProtocol) {
        guard player.controllerType == KodiPlayer.controllerType else { return }
        
        var persistedPlayers = userDefaults.dictionary(forKey: "kodi.browser.manualplayers") ?? [String: [String: Any]]()
        
        if persistedPlayers[player.name] != nil {
            removeManualPlayerSubject.onNext(player)
            persistedPlayers.removeValue(forKey: player.name)
            userDefaults.set(persistedPlayers, forKey: "kodi.browser.manualplayers")
        }
    }
    
    public var addManualPlayerSettings: [PlayerSettingGroup] {
        get {
            let hostSetting = StringSetting.init(id: ConnectionProperties.host.rawValue,
                                                 description: "IP Address",
                                                 placeholder: "IP Address or Hostname",
                                                 value: "",
                                                 restriction: .regular)
            hostSetting.validation = { (setting, value) -> String? in
                ((value as? String?) ?? "") == ""  ? "Enter a valid ip-address for the player." : nil
            }
            
            let portSetting = StringSetting.init(id: ConnectionProperties.port.rawValue,
                                                 description: "Port",
                                                 placeholder: "Portnumber",
                                                 value: "8080",
                                                 restriction: .numeric)
            portSetting.validation = { (setting, value) -> String? in
                ((value as? Int?) ?? 0) == 0 ? "Enter a valid port number for the player (default = 8080)." : nil
            }
            
            let nameSetting = StringSetting.init(id: ConnectionProperties.name.rawValue,
                                                 description: "Name",
                                                 placeholder: "Player name",
                                                 value: "",
                                                 restriction: .regular)
            nameSetting.validation = { (setting, value) -> String? in
                ((value as? String?) ?? "") == "" ? "Enter a name for the player." : nil
            }

            let websocketPortSetting = StringSetting.init(id: KodiConnectionProperties.websocketPort.rawValue,
                                                          description: "Websocket Port",
                                                          placeholder: "Portnumber",
                                                          value: "9090",
                                                          restriction: .numeric)
            websocketPortSetting.validation = { (setting, value) -> String? in
                ((value as? Int?) ?? 0) == 0 ? "Enter a valid websocket port number for the player (default = 9090)." : nil
            }

            return [PlayerSettingGroup(title: "Connection Settings", description: "Some players can't be automatically detected. In that case you can add it manually by entering the connection settings here.\n" +
                "After entering them, click 'Test' to let Rigelian test if it can connect to the player.\n\n" +
                "For details on the connection settings, refer to the documentation that comes with your player.",
                                       settings:[nameSetting, hostSetting, portSetting, websocketPortSetting])]
        }
    }
}
