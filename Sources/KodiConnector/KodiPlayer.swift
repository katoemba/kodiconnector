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
    public var playerStreamURL: URL?
    
    private let userDefaults: UserDefaults
    private var kodi: KodiProtocol
    public static let controllerType = "Kodi"
    public var controllerType: String {
        KodiPlayer.controllerType
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
        return [.recentlyAddedAlbums, .twentyRandomSongs, .randomAlbums, .playlists]
    }
    
    public var connectionProperties: [String : Any] {
        get {
            let password = (self.loadSetting(id: ConnectionProperties.password.rawValue) as? StringSetting)?.value ?? ""
            let urlCoverArt = (self.loadSetting(id: ConnectionProperties.urlCoverArt.rawValue) as? ToggleSetting)?.value ?? false
            let discogsCoverArt = (self.loadSetting(id: ConnectionProperties.discogsCoverArt.rawValue) as? ToggleSetting)?.value ?? false
            let musicbrainzCoverArt = (self.loadSetting(id: ConnectionProperties.musicbrainzCoverArt.rawValue) as? ToggleSetting)?.value ?? false

            return [ConnectionProperties.controllerType.rawValue: KodiPlayer.controllerType,
                    ConnectionProperties.name.rawValue: name,
                    ConnectionProperties.host.rawValue: host,
                    ConnectionProperties.port.rawValue: port,
                    KodiConnectionProperties.websocketPort.rawValue: websocketPort,
                    ConnectionProperties.password.rawValue: password,
                    ConnectionProperties.urlCoverArt.rawValue: urlCoverArt,
                    ConnectionProperties.discogsCoverArt.rawValue: discogsCoverArt,
                    ConnectionProperties.musicbrainzCoverArt.rawValue: musicbrainzCoverArt]
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
        self.kodi = kodi ?? KodiWrapper(kodi: KodiAddress(ip: host, port: port, websocketPort: websocketPortToUse), getPlayerId: true)
        
        if password != nil {
            userDefaults.set(password, forKey: ConnectionProperties.password.rawValue + "." + initialUniqueID)
        }
        if userDefaults.object(forKey: ConnectionProperties.urlCoverArt.rawValue) == nil {
            userDefaults.set(true, forKey: ConnectionProperties.urlCoverArt.rawValue)
            userDefaults.set(false, forKey: ConnectionProperties.discogsCoverArt.rawValue)
            userDefaults.set(false, forKey: ConnectionProperties.musicbrainzCoverArt.rawValue)
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
                weakSelf.kodi = KodiWrapper(kodi: KodiAddress(ip: weakSelf.kodi.kodiAddress.ip, port: weakSelf.kodi.kodiAddress.port, websocketPort: weakSelf.websocketPort), getPlayerId: true)
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
                            discoverMode: DiscoverMode = .automatic,
                            userDefaults: UserDefaults,
                            settingsChangedSubject: PublishSubject<KodiPlayer>? = nil) {
        guard let name = connectionProperties[ConnectionProperties.name.rawValue] as? String,
            let host = connectionProperties[ConnectionProperties.host.rawValue] as? String,
            let port = connectionProperties[ConnectionProperties.port.rawValue] as? Int,
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
                  discoverMode: discoverMode,
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
            var settingsToReturn = [PlayerSettingGroup]()

            let playerSettings = PlayerSettingGroup(title: "Player Settings", description: "", settings:[ loadSetting(id: ConnectionProperties.name.rawValue)!,
                                                                                             loadSetting(id: ConnectionProperties.host.rawValue)!,
                                                                                             loadSetting(id: ConnectionProperties.port.rawValue)!,
                                                                                             loadSetting(id: KodiConnectionProperties.websocketPort.rawValue)!])
            settingsToReturn.append(playerSettings)
            
            let librarySettings = PlayerSettingGroup(title: "Music Library", description: "", settings:[ActionSetting.init(id: "KodiScan", description: "Rescan library", action: { [weak self] () -> Observable<String> in
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
                                                                                          })])
            settingsToReturn.append(librarySettings)

            let coverArtDescription = "These settings define how cover art is retrieved. Always leave 'Standard URL' enabled. Discogs and MusicBrainz can be used as " +
                "backup for albums / tracks for which no cover art is present in your media library."
            let coverArtSettings: [PlayerSetting] = [loadSetting(id: ConnectionProperties.urlCoverArt.rawValue)!,
                                                     loadSetting(id: ConnectionProperties.discogsCoverArt.rawValue)!,
                                                     loadSetting(id: ConnectionProperties.musicbrainzCoverArt.rawValue)!]
            let coverArtSettingGroup = PlayerSettingGroup(title: "Cover Art Sources", description: coverArtDescription, settings: coverArtSettings)
            settingsToReturn.append(coverArtSettingGroup)
            
            return settingsToReturn
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
        else if setting.id == ConnectionProperties.password.rawValue {
            let stringSetting = setting as! StringSetting
            userDefaults.set(stringSetting.value, forKey: playerSpecificId)
            userDefaults.synchronize()
            
            settingsChangedSubject?.onNext(self)
        }
        else if let toggleSetting = setting as? ToggleSetting {
            userDefaults.set(toggleSetting.value, forKey: playerSpecificId)
        }
    }
    
    /// Get data for a specific setting
    ///
    /// - Parameter id: the id of the setting to load
    /// - Returns: a new PlayerSetting object containing the value of the requested setting, or nil if the setting is not found.
    public func loadSetting(id: String) -> PlayerSetting? {
        let playerSpecificId = id + "." + uniqueID
        
        if id == ConnectionProperties.name.rawValue {
            return StringSetting.init(id: id,
                                      description: "Name",
                                      placeholder: "",
                                      value: name,
                                      restriction: .readonly)
        }
        else if id == ConnectionProperties.host.rawValue {
            return StringSetting.init(id: id,
                                      description: "Host",
                                      placeholder: "",
                                      value: host,
                                      restriction: .readonly)
        }
        else if id == ConnectionProperties.port.rawValue {
            return StringSetting.init(id: id,
                                      description: "Port",
                                      placeholder: "",
                                      value: "\(port)",
                restriction: .readonly)
        }
        else if id == KodiConnectionProperties.websocketPort.rawValue {
            return StringSetting.init(id: id,
                                      description: "Websocket Port",
                                      placeholder: "Websocket Port",
                                      value: userDefaults.string(forKey: playerSpecificId) ?? "",
                                      restriction: .numeric)
        }
        else if id == ConnectionProperties.password.rawValue {
            return StringSetting.init(id: id,
                                      description: "Password",
                                      placeholder: "Password",
                                      value: userDefaults.string(forKey: playerSpecificId) ?? "",
                                      restriction: .password)
        }
        else if id == ConnectionProperties.urlCoverArt.rawValue {
            return ToggleSetting.init(id: id,
                                      description: "Standard URL",
                                      value: userDefaults.bool(forKey: playerSpecificId))
        }
        else if id == ConnectionProperties.discogsCoverArt.rawValue {
            return ToggleSetting.init(id: id,
                                      description: "Discogs",
                                      value: userDefaults.bool(forKey: playerSpecificId))
        }
        else if id == ConnectionProperties.musicbrainzCoverArt.rawValue {
            return ToggleSetting.init(id: id,
                                      description: "Musicbrainz",
                                      value: userDefaults.bool(forKey: playerSpecificId))
        }

        return nil
    }
    
}
