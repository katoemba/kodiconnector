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

public class KodiPlayer: PlayerProtocol {
    private let userDefaults: UserDefaults
    public var controllerType: String
    
    public var uniqueID: String {
        return "\(KodiPlayer.uniqueIDForPlayer(self))"
    }

    public private(set) var name: String
    private var host: String
    private var port: Int

    public var model: String {
            return "Kodi"
    }
    
    public private(set) var discoverMode = DiscoverMode.automatic
    public private(set) var version: String
    public private(set) var connectionWarning = nil as String?

    public var description: String {
        return "Kodi"
    }
    
    public var connectionProperties: [String : Any] {
        get {
            let password = (self.loadSetting(id: ConnectionProperties.Password.rawValue) as? StringSetting)?.value ?? ""
            return [ConnectionProperties.Name.rawValue: name,
                    ConnectionProperties.Host.rawValue: host,
                    ConnectionProperties.Port.rawValue: port,
                    ConnectionProperties.Password.rawValue: password]
        }
    }

    
    public var status: StatusProtocol
    
    public var control: ControlProtocol
    
    public var browse: BrowseProtocol
    
    private static func uniqueIDForPlayer(_ player: KodiPlayer) -> String {
        return uniqueIDForPlayer(host: player.host, port: player.port)
    }
    
    static func uniqueIDForPlayer(host: String, port: Int) -> String {
        return "\(host):\(port)"
    }
    
    // Test scheduler that can be passed down to mpdstatus, mpdcontrol, and mpdbrowse
    private var scheduler: SchedulerType?
    // Serial scheduler that is used to synchronize commands sent via mpdcontrol
    private var serialScheduler: SchedulerType?
    private let bag = DisposeBag()

    public init(name: String,
                host: String,
                port: Int,
                password: String? = nil,
                scheduler: SchedulerType? = nil,
                version: String = "",
                discoverMode: DiscoverMode = .automatic,
                connectionWarning: String? = nil,
                userDefaults: UserDefaults) {
        self.name = name
        self.host = host
        self.port = port
        let initialUniqueID = KodiPlayer.uniqueIDForPlayer(host: host, port: port)

        if password != nil {
            userDefaults.set(password, forKey: ConnectionProperties.Password.rawValue + "." + initialUniqueID)
        }

        self.scheduler = scheduler
        self.serialScheduler = scheduler ?? SerialDispatchQueueScheduler.init(qos: .background, internalSerialQueueName: "com.katoemba.mpdplayer")
        self.connectionWarning = connectionWarning
        self.version = version
        self.discoverMode = discoverMode
        self.userDefaults = userDefaults
    }
    
    public func copy() -> PlayerProtocol {
        return KodiPlayer.init(name: name, host: host, port: port, userDefaults: userDefaults)
    }
    
    public func activate() {
    }
    
    public func deactivate() {
    }
    
    public var settings: [PlayerSettingGroup] {
        get {
            return []
        }
    }
    
    public func updateSetting(_ setting: PlayerSetting) {
    }
    
    public func loadSetting(id: String) -> PlayerSetting? {
        return nil
    }
    
}
