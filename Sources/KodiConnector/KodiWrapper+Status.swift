//
//  KodiWrapper+Status.swift
//  KodiConnector
//
//  Created by Berrie Kremers on 18/08/2019.
//  Copyright © 2019 Katoemba Software. All rights reserved.
//

import Foundation
import RxSwift

public struct Item: Decodable {
    let id: Int?
    let title: String?
    let type: String
}
public struct Player: Decodable {
    let playerid: Int
    let speed: Int?
    let time: Time?
}
public struct Time: Decodable {
    let hours: Int
    let minutes: Int
    let seconds: Int
}

public enum NotificationType: String, Decodable {
    case playerOnPropertyChanged = "Player.OnPropertyChanged"
    case applicationOnVolumeChanged = "Application.OnVolumeChanged"
    case playerOnPlay = "Player.OnPlay"
    case playerOnPause = "Player.OnPause"
    case playerOnStop = "Player.OnStop"
    case playerOnSeek = "Player.OnSeek"
    case playlistOnAdd = "Playlist.OnAdd"
    case playlistOnRemove = "Playlist.OnRemove"
    case playlistOnClear = "Playlist.OnClear"
}
public protocol Notification: Decodable {
    static var method: NotificationType { get }
}

public struct PlayerOnPropertyChanged: Notification {
    public static let method = NotificationType.playerOnPropertyChanged
    let data: PlayerOnPropertyChangedData
}
public struct PlayerOnPropertyChangedData: Decodable {
    let property: Property
}
public struct Property: Decodable {
    let shuffled: Bool?
    let `repeat`: String?
}

public struct ApplicationOnVolumeChanged: Notification {
    public static let method = NotificationType.applicationOnVolumeChanged
    let data: ApplicationOnVolumeChangedData
}
public struct ApplicationOnVolumeChangedData: Decodable {
    let muted: Bool
    let volume: Float
}

public struct PlayerOnPlay: Notification {
    public static let method = NotificationType.playerOnPlay
    let data: PlayerOnPlayData
}
public struct PlayerOnPlayData: Decodable {
    let item: Item
    let player: Player
}

public struct PlayerOnPause: Notification {
    public static let method = NotificationType.playerOnPause
    let data: PlayerOnPauseData
}
public struct PlayerOnPauseData: Decodable {
    let item: Item
    let player: Player
}

public struct PlayerOnStop: Notification {
    public static let method = NotificationType.playerOnStop
    let data: PlayerOnStopData
}
public struct PlayerOnStopData: Decodable {
    let item: Item
    let end: Bool
}

public struct PlayerOnSeek: Notification {
    public static let method = NotificationType.playerOnSeek
    let data: PlayerOnSeekData
}
public struct PlayerOnSeekData: Decodable {
    let item: Item
    let player: Player
}

public struct PlaylistOnAdd: Notification {
    public static let method = NotificationType.playlistOnAdd
    let data: PlaylistOnAddData
}
public struct PlaylistOnAddData: Decodable {
    let playlistid: Int
    let position: Int
    let item: PlaylistItem
}
public struct PlaylistItem: Decodable {
    let id: Int
    let type: String
}

public struct PlaylistOnRemove: Notification {
    public static let method = NotificationType.playlistOnRemove
    let data: PlaylistOnRemoveData
}
public struct PlaylistOnRemoveData: Decodable {
    let playlistid: Int
    let position: Int
}

public struct PlaylistOnClear: Notification {
    public static let method = NotificationType.playlistOnClear
    let data: PlaylistOnClearData
}
public struct PlaylistOnClearData: Decodable {
    let playlistid: Int
}

struct ServerResponse: Decodable {
    let method: NotificationType
    let params: Notification
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        method = try values.decode(NotificationType.self, forKey: .method)
        switch method {
        case .playerOnPropertyChanged:
            params = try values.decode(PlayerOnPropertyChanged.self, forKey: .params)
        case .playerOnPlay:
            params = try values.decode(PlayerOnPlay.self, forKey: .params)
        case .playerOnPause:
            params = try values.decode(PlayerOnPause.self, forKey: .params)
        case .playerOnStop:
            params = try values.decode(PlayerOnStop.self, forKey: .params)
        case .playerOnSeek:
            params = try values.decode(PlayerOnSeek.self, forKey: .params)
        case .applicationOnVolumeChanged:
            params = try values.decode(ApplicationOnVolumeChanged.self, forKey: .params)
        case .playlistOnAdd:
            params = try values.decode(PlaylistOnAdd.self, forKey: .params)
        case .playlistOnRemove:
            params = try values.decode(PlaylistOnRemove.self, forKey: .params)
        case .playlistOnClear:
            params = try values.decode(PlaylistOnClear.self, forKey: .params)
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case method, params
    }
}

extension KodiWrapper {
    public func getAudioPlaylist() -> Observable<Int> {
        struct Root: Decodable {
            var result: Result
        }
        struct Result: Decodable {
            var playlists: [Playlist]
        }
        struct Playlist: Decodable {
            var playlistid: Int
            var type: String
        }

        let parameters = ["jsonrpc": "2.0",
                          "method": "Playlist.GetPlaylists",
                          "id": "getPlaylists"] as [String : Any]
        
        return dataPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, data) -> (Int) in
                let json = try JSONDecoder().decode(Root.self, from: data)
                for playlist in json.result.playlists {
                    if playlist.type == "audio" {
                        return playlist.playlistid
                    }
                }
                
                return 0
            })
            .catchError({ (error) -> Observable<(Int)> in
                print(error)
                return Observable.just(0)
            })
    }
    
    public func getPlayerProperties() -> Observable<KodiPlayerProperties> {
        struct Root: Decodable {
            var result: KodiPlayerProperties
        }

        let parameters = ["jsonrpc": "2.0",
                          "method": "Player.GetProperties",
                          "params": ["playerid": playerId, "properties": ["position", "time", "totaltime", "canseek", "type", "shuffled", "repeat", "speed", "playlistid"]],
                          "id": "getPlayerProperties"] as [String : Any]
        
        return dataPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, data) -> (KodiPlayerProperties) in
                let json = try JSONDecoder().decode(Root.self, from: data)
                return json.result
            })
            .catchError({ (error) -> Observable<KodiPlayerProperties> in
                print(error)
                return Observable.empty()
            })
    }

    public func parseNotification(_ notification: Data) -> Notification? {
        let json = try? JSONDecoder().decode(ServerResponse.self, from: notification)
        
        return json?.params
    }
}
