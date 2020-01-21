//
//  KodiPlayer.swift
//  KodiConnector
//
//  Created by Berrie Kremers on 02/12/2018.
//  Copyright © 2018 Katoemba Software. All rights reserved.
//

import Foundation
import ConnectorProtocol
import RxSwift
import os

public enum KodiConnectionProperties: String {
    case websocketPort = "Kodi.WebsocketPort"
    case version = "Kodi.Version"
}

public class KodiPlayer: PlayerProtocol {
    private let userDefaults: UserDefaults
    private var kodi: KodiProtocol
    public var controllerType: String {
        return "Kodi"
    }
    
    public var uniqueID: String {
        return "\(KodiPlayer.uniqueIDForPlayer(self))"
    }

    public private(set) var name: String
    private var host: String
    private var port: Int
    private var websocketPort: Int
    private let settingsChangedSubject: PublishSubject<KodiPlayer>?

    public var model: String {
            return "Kodi"
    }
    
    public private(set) var discoverMode = DiscoverMode.automatic
    public private(set) var version: String
    public private(set) var connectionWarning = nil as String?

    public var description: String {
        return "Kodi \(version)"
    }
    
    public var supportedFunctions: [Functions] {
        return [.recentlyAddedAlbums, .twentyRandomSongs, .randomAlbums]
    }
    
    public var connectionProperties: [String : Any] {
        get {
            let password = (self.loadSetting(id: ConnectionProperties.Password.rawValue) as? StringSetting)?.value ?? ""
            return [ConnectionProperties.Name.rawValue: name,
                    ConnectionProperties.Host.rawValue: host,
                    ConnectionProperties.Port.rawValue: port,
                    KodiConnectionProperties.websocketPort.rawValue: websocketPort,
                    ConnectionProperties.Password.rawValue: password]
        }
    }

    private var kodiStatus: KodiStatus
    public  var status: StatusProtocol {
        return kodiStatus
    }

    public var control : ControlProtocol {
        return KodiControl(kodi: kodi, kodiStatus: kodiStatus)
    }

    public var browse : BrowseProtocol {
        return KodiBrowse(kodi: kodi)
    }
    
    private static func uniqueIDForPlayer(_ player: KodiPlayer) -> String {
        return uniqueIDForPlayer(host: player.host, port: player.port)
    }
    
    static func uniqueIDForPlayer(host: String, port: Int) -> String {
        return "\(host):\(port)"
    }
    
    // Test scheduler that can be passed down to mpdstatus, mpdcontrol, and mpdbrowse
    private var scheduler: SchedulerType?
    private let bag = DisposeBag()

    /// Initialize a new player object
    ///
    /// - Parameters:
    ///   - kodi: Injection point for a class that implements the KodiProtocol, to call the jsonrpc webservices provided by a player.
    ///   - name: Name of the player.
    ///   - host: Host ip-address to connect to.
    ///   - port: Port to connect to.
    ///   - websocketPort: Websocket port to connect for status notifications. Shall only be added when a new manual player is created.
    ///   - password: Password to use when connection, default is ""
    ///   - scheduler: A scheduler on which to perform background activities.
    ///   - discoverMode: How the player was created, either from network discovery or manually created.
    ///   - connectionWarning: Warning that can be presented in case a connection couldn't be established.
    ///   - userDefaults: Injection point for a class that implements getting and setting defaults.
    ///   - settingsChangedSubject: Injection point for a subject on which to post settings changes and listen for changes.
    public init(kodi: KodiProtocol? = nil,
                name: String,
                host: String,
                port: Int,
                websocketPort: Int? = nil,
                password: String? = nil,
                scheduler: SchedulerType? = nil,
                version: String = "",
                discoverMode: DiscoverMode = .automatic,
                connectionWarning: String? = nil,
                userDefaults: UserDefaults,
                settingsChangedSubject: PublishSubject<KodiPlayer>? = nil) {
        let initialUniqueID = KodiPlayer.uniqueIDForPlayer(host: host, port: port)

        self.name = name
        self.host = host
        self.port = port
        self.userDefaults = userDefaults
        
        let playerSpecificId = "\(KodiConnectionProperties.websocketPort.rawValue).\(initialUniqueID)"
        var websocketPortToUse = 9090
        if websocketPort != nil {
            websocketPortToUse = websocketPort!
            userDefaults.set("\(websocketPortToUse)", forKey: playerSpecificId)
        }
        else {
            websocketPortToUse = Int(userDefaults.string(forKey: playerSpecificId) ?? "") ?? 9090
        }
        self.websocketPort = websocketPortToUse
        self.kodi = kodi ?? KodiWrapper(kodi: KodiAddress(ip: host, port: port, websocketPort: websocketPortToUse))

        if password != nil {
            userDefaults.set(password, forKey: ConnectionProperties.Password.rawValue + "." + initialUniqueID)
        }

        self.scheduler = scheduler
        self.connectionWarning = connectionWarning
        self.version = version
        self.discoverMode = discoverMode

        kodiStatus = KodiStatus(kodi: self.kodi, scheduler: self.scheduler)
        
        self.settingsChangedSubject = settingsChangedSubject
        settingsChangedSubject?
            .filter({ [weak self] (player) -> Bool in
                guard let weakSelf = self else { return false }
                return weakSelf.uniqueID == player.uniqueID
            })
            .subscribe(onNext: { [weak self] (_) in
                guard let weakSelf = self else { return }
                
                let playerSpecificId = "\(KodiConnectionProperties.websocketPort.rawValue).\(weakSelf.uniqueID)"

                weakSelf.websocketPort = Int(userDefaults.string(forKey: playerSpecificId) ?? "") ?? 9090
                weakSelf.kodi = KodiWrapper(kodi: KodiAddress(ip: weakSelf.kodi.kodiAddress.ip, port: weakSelf.kodi.kodiAddress.port, websocketPort: weakSelf.websocketPort))
                weakSelf.kodiStatus.kodiSettingsChanged(kodi: weakSelf.kodi)
            })
            .disposed(by: bag)
    }
    
    /// Init an instance of a KodiPlayer based on a connectionProperties dictionary
    ///
    /// - Parameters:
    ///   - kodi: Injection point for a class that implements the KodiProtocol, to call the jsonrpc webservices provided by a player.
    ///   - connectionProperties: dictionary of properties
    ///   - scheduler: A scheduler on which to perform background activities.
    ///   - userDefaults: Injection point for a class that implements getting and setting defaults.
    ///   - settingsChangedSubject: Injection point for a subject on which to post settings changes and listen for changes.
    public convenience init(kodi: KodiProtocol? = nil,
                            connectionProperties: [String: Any],
                            scheduler: SchedulerType? = nil,
                            version: String = "",
                            userDefaults: UserDefaults,
                            settingsChangedSubject: PublishSubject<KodiPlayer>? = nil) {
        guard let name = connectionProperties[ConnectionProperties.Name.rawValue] as? String,
            let host = connectionProperties[ConnectionProperties.Host.rawValue] as? String,
            let port = connectionProperties[ConnectionProperties.Port.rawValue] as? Int,
            let websocketPort = connectionProperties[KodiConnectionProperties.websocketPort.rawValue] as? Int else {
                self.init(kodi: kodi,
                          name: "",
                          host: "",
                          port: 8080,
                          websocketPort: 9090,
                          scheduler: scheduler,
                          userDefaults: userDefaults,
                          settingsChangedSubject: settingsChangedSubject)
                return
        }
        
        self.init(kodi: kodi,
                  name: name,
                  host: host,
                  port: port,
                  websocketPort: websocketPort,
                  scheduler: scheduler,
                  userDefaults: userDefaults,
                  settingsChangedSubject: settingsChangedSubject)
    }

    /// Create a copy of a player
    ///
    /// - Returns: copy of the this player
    public func copy() -> PlayerProtocol {
        //return KodiPlayer(name: name, host: host, port: port, websocketPort: websocketPort, userDefaults: userDefaults, settingsChangedSubject: settingsChangedSubject)
        return KodiPlayer(connectionProperties: connectionProperties, userDefaults: userDefaults, settingsChangedSubject: settingsChangedSubject)
    }
    
    /// Upon activation, the status object starts monitoring the player status.
    public func activate() {
        kodiStatus.startMonitoring()
    }
    
    /// Upon deactivation, the shared status object starts monitoring the player status, and open connections are closed.
    public func deactivate() {
        kodiStatus.stopMonitoring()
    }
    
    /// Return the settings definition for a player.
    public var settings: [PlayerSettingGroup] {
        get {
            return [PlayerSettingGroup(title: "Player Settings", description: "", settings:[loadSetting(id: KodiConnectionProperties.websocketPort.rawValue)!]),
                    PlayerSettingGroup(title: "Music Library", description: "", settings:[ActionSetting.init(id: "KodiScan", description: "Rescan library", action: { [weak self] () -> Observable<String> in
                        guard let weakSelf = self else { return Observable.just("Scan not initiated") }
                        return weakSelf.kodi.scan()
                            .map({ (result) -> String in
                                result == true ? "Scan initiated" : "Scan not initiated"
                            })
                    }),
                                                                                          ActionSetting.init(id: "KodiClean", description: "Remove unused items", action: { [weak self] () -> Observable<String> in
                                                                                            guard let weakSelf = self else { return Observable.just("Cleanup not initiated") }
                                                                                            return weakSelf.kodi.clean()
                                                                                                .map({ (result) -> String in
                                                                                                    result == true ? "Cleanup initiated" : "Cleanup not initiated"
                                                                                                })
                                                                                            })])]
        }
    }
    
    /// Store setting.value into user-defaults and perform any other required actions
    ///
    /// - Parameter setting: the settings definition, including the value
    public func updateSetting(_ setting: PlayerSetting) {
        let playerSpecificId = setting.id + "." + uniqueID
        
        if setting.id == KodiConnectionProperties.websocketPort.rawValue {
            let stringSetting = setting as! StringSetting
            userDefaults.set(stringSetting.value, forKey: playerSpecificId)
            userDefaults.synchronize()
            
            settingsChangedSubject?.onNext(self)
        }
        else if setting.id == ConnectionProperties.Password.rawValue {
            let stringSetting = setting as! StringSetting
            userDefaults.set(stringSetting.value, forKey: playerSpecificId)
            userDefaults.synchronize()

            settingsChangedSubject?.onNext(self)
        }
    }
    
    /// Get data for a specific setting
    ///
    /// - Parameter id: the id of the setting to load
    /// - Returns: a new PlayerSetting object containing the value of the requested setting, or nil if the setting is not found.
    public func loadSetting(id: String) -> PlayerSetting? {
        let playerSpecificId = id + "." + uniqueID
        
        if id == KodiConnectionProperties.websocketPort.rawValue {
            return StringSetting.init(id: id,
                                      description: "Websocket Port",
                                      placeholder: "Websocket Port",
                                      value: userDefaults.string(forKey: playerSpecificId) ?? "",
                                      restriction: .numeric)
        }
        else if id == ConnectionProperties.Password.rawValue {
            return StringSetting.init(id: id,
                                      description: "Password",
                                      placeholder: "Password",
                                      value: userDefaults.string(forKey: playerSpecificId) ?? "",
                                      restriction: .password)
        }

        return nil
    }
    
}
