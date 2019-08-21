//
//  KodiWrapper+Song.swift
//  KodiConnector
//
//  Created by Berrie Kremers on 19/08/2019.
//  Copyright © 2019 Katoemba Software. All rights reserved.
//

import Foundation
import RxSwift

extension KodiWrapper {
    public static let songProperties = ["album", "displayartist", "albumartist", "duration", "track", "thumbnail", "year", "genre", "file"]
    
    public func getCurrentSong() -> Observable<KodiSong> {
        struct Root: Decodable {
            var result: Result
        }
        struct Result: Decodable {
            var item: KodiSong
        }

        let parameters = ["jsonrpc": "2.0",
                          "method": "Player.GetItem",
                          "params": ["playerid": playerId, "properties": KodiWrapper.songProperties],
                          "id": "getCurrentSong"] as [String : Any]
        
        return dataPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, data) -> (KodiSong) in
                let json = try JSONDecoder().decode(Root.self, from: data)
                return json.result.item
            })
            .catchError({ (error) -> Observable<KodiSong> in
                Observable.empty()
            })
    }
    
    public func getSongsWithFilter(_ filter: [String: Any]) -> Observable<[KodiSong]> {
        struct Root: Decodable {
            var result: Result
        }
        struct Result: Decodable {
            var songs: [KodiSong]
        }
        
        let parameters = ["jsonrpc": "2.0",
                          "method": "AudioLibrary.GetSongs",
                          "params": ["properties": KodiWrapper.songProperties,
                                     "filter": filter,
                                     "sort": ["order": "ascending", "method": "track"]],
                          "id": "getSongsOnAlbum"] as [String : Any]
        
        return dataPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, data) -> ([KodiSong]) in
                let json = try JSONDecoder().decode(Root.self, from: data)
                return json.result.songs
            })
            .catchError({ (error) -> Observable<[KodiSong]> in
                Observable.just([])
            })
    }

    public func getSongsOnAlbum(_ albumid: Int) -> Observable<[KodiSong]> {
        return getSongsWithFilter(["albumid": albumid])
    }
    
}
