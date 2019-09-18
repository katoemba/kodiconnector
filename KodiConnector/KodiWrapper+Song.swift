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
    public static let songProperties = ["album", "displayartist", "albumartist", "duration", "track", "thumbnail", "year", "genre", "file", "albumartistid", "albumid", "artistid"]
    
    public func getCurrentSong() -> Observable<KodiSong?> {
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
            .catchError({ (error) -> Observable<KodiSong?> in
                print(error)
                return Observable.just(nil)
            })
    }
    
    public func getSong(_ songid: Int) -> Observable<KodiSong> {
        struct Root: Decodable {
            var result: SongDetails
        }
        struct SongDetails: Decodable {
            var songdetails: KodiSong
        }
        
        let parameters = ["jsonrpc": "2.0",
                          "method": "AudioLibrary.GetSongDetails",
                          "params": ["properties": KodiWrapper.songProperties,
                                     "songid": songid],
                          "id": "getSongDetails"] as [String : Any]
        
        return dataPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, data) -> (KodiSong) in
                let root = try JSONDecoder().decode(Root.self, from: data)
                return root.result.songdetails
            })
            .catchError({ (error) -> Observable<KodiSong> in
                print(error)
                return Observable.empty()
            })
    }
    
    public func getSongsWithFilter(_ filter: [String: Any], sort: [String: Any], limit: Int = 0) -> Observable<[KodiSong]> {
        struct Root: Decodable {
            var result: Result
        }
        struct Result: Decodable {
            var songs: [KodiSong]
        }
        
        var params = ["properties": KodiWrapper.songProperties,
                      "filter": filter,
                      "sort": sort] as [String: Any]
        if limit > 0 {
            params["limits"] = ["start": 0, "end": limit]
        }
        let parameters = ["jsonrpc": "2.0",
                          "method": "AudioLibrary.GetSongs",
                          "params": params,
                          "id": "getSongsOnAlbum"] as [String : Any]
        
        return dataPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, data) -> ([KodiSong]) in
                let json = try JSONDecoder().decode(Root.self, from: data)
                return json.result.songs
            })
            .catchError({ (error) -> Observable<[KodiSong]> in
                print(error)
                return Observable.just([])
            })
    }

    public func getSongsOnAlbum(_ albumid: Int) -> Observable<[KodiSong]> {
        return getSongsWithFilter(["albumid": albumid],
                                  sort: ["method": "track", "order": "ascending"])
    }
 
    public func searchSongs(_ search: String, limit: Int) -> Observable<[KodiSong]> {
        return getSongsWithFilter(["field": "title", "operator": "contains", "value": search],
                                  sort: ["method": "playcount", "order": "descending"],
                                  limit: limit)
    }

    public func playSong(_ songid: Int) -> Observable<Bool> {
        let parameters = ["jsonrpc": "2.0",
                          "method": "Player.Open",
                          "params": ["item": ["songid": songid]],
                          "id": "playSong"] as [String : Any]
        
        return dataPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, data) -> (Bool) in
                return true
            })
            .catchError({ (error) -> Observable<(Bool)> in
                print(error)
                return Observable.just(false)
            })
    }

    public func addSongs(_ songids: [Int]) -> Observable<Bool> {
        let songParam = songids.map { (songid) -> [String: Int] in
            ["songid": songid]
        }
        let parameters = ["jsonrpc": "2.0",
                          "method": "Playlist.Add",
                          "params": ["playlistid": 0,
                                     "item": songParam],
                          "id": "addSongs"] as [String : Any]
        
        return dataPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, data) -> (Bool) in
                return true
            })
            .catchError({ (error) -> Observable<(Bool)> in
                print(error)
                return Observable.just(false)
            })
    }

    public func insertSongs(_ songids: [Int], at: Int) -> Observable<Bool> {
        let songParam = songids.map { (songid) -> [String: Int] in
            ["songid": songid]
        }
        let parameters = ["jsonrpc": "2.0",
                          "method": "Playlist.Insert",
                          "params": ["playlistid": 0,
                                     "position": at,
                                     "item": songParam],
                          "id": "insertSongs"] as [String : Any]
        
        return dataPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, data) -> (Bool) in
                return true
            })
            .catchError({ (error) -> Observable<(Bool)> in
                print(error)
                return Observable.just(false)
            })
    }
}
