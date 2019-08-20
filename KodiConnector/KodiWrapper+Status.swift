//
//  KodiWrapper+Status.swift
//  KodiConnector
//
//  Created by Berrie Kremers on 18/08/2019.
//  Copyright © 2019 Katoemba Software. All rights reserved.
//

import Foundation
import RxSwift

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
                Observable.just(0)
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
                Observable.empty()
            })
    }

}
