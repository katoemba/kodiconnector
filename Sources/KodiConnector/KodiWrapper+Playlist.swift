//
//  KodiWrapper+Playqueue.swift
//  KodiConnector
//
//  Created by Berrie Kremers on 19/08/2019.
//  Copyright © 2019 Katoemba Software. All rights reserved.
//

import Foundation
import RxSwift

extension KodiWrapper {
    public func getPropertiesForPlaylist(_ playlistId: Int) -> Observable<(Int, String)> {
        struct Root: Decodable {
            var result: Result
        }
        struct Result: Decodable {
            var size: Int
            var type: String
        }

        let parameters = ["jsonrpc": "2.0",
                          "method": "Playlist.GetProperties",
                          "params": ["playlistid": playlistId,
                                     "properties": ["type", "size"]],
                          "id": "getPlaylistProperties"] as [String : Any]
        
        return dataPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, data) -> (Int, String) in
                let json = try JSONDecoder().decode(Root.self, from: data)
                
                return (json.result.size, json.result.type)
            })
            .catch({ (error) -> Observable<(Int, String)> in
                print(error)
                return Observable.empty()
            })
    }

    public func getPlaylist(_ playlistId: Int, start: Int, end: Int) -> Observable<[KodiSong]> {
        struct Root: Decodable {
            var result: Result
        }
        struct Result: Decodable {
            var items: [KodiSong]?
            var limits: Limits
        }
        struct Limits: Decodable {
            var start: Int
            var end: Int
            var total: Int
        }

        let parameters = ["jsonrpc": "2.0",
                          "method": "Playlist.GetItems",
                          "params": ["playlistid": playlistId,
                                     "properties": KodiWrapper.songProperties,
                                     "limits": ["start": start, "end": end]],
                          "id": "getPlaylistItems"] as [String : Any]
        
        return dataPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, data) -> ([KodiSong]) in
                let json = try JSONDecoder().decode(Root.self, from: data)

                return json.result.items ?? []
            })
            .catch({ (error) -> Observable<[KodiSong]> in
                print(error)
                return Observable.just([])
            })
    }
    
    public func clearPlaylist(_ playlistId: Int) -> Observable<Bool> {
        let parameters = ["jsonrpc": "2.0",
                          "method": "Playlist.Clear",
                          "params": ["playlistid": playlistId],
                          "id": "playlistClear"] as [String : Any]
        
        return dataPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, data) -> (Bool) in
                return true
            })
            .catch({ (error) -> Observable<(Bool)> in
                print(error)
                return Observable.just(false)
            })
    }
    
    public func startPlaylist(_ playlistId: Int, at: Int) -> Observable<Bool> {
        let parameters = ["jsonrpc": "2.0",
                          "method": "Player.Open",
                          "params": ["item": ["playlistid": playlistId, "position": at]],
                          "id": "startInPlayqueue"] as [String : Any]
        
        return dataPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, data) -> (Bool) in
                return true
            })
            .catch({ (error) -> Observable<(Bool)> in
                print(error)
                return Observable.just(false)
            })
    }
    
    public func removeFromPlaylist(_ playlistId: Int, position: Int) -> Observable<Bool> {
        let parameters = ["jsonrpc": "2.0",
                          "method": "Playlist.Remove",
                          "params": ["playlistid": playlistId, "position": position],
                          "id": "removeFromPlaylist"] as [String : Any]
        
        return dataPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, data) -> (Bool) in
                return true
            })
            .catch({ (error) -> Observable<(Bool)> in
                print(error)
                return Observable.just(false)
            })
    }

    public func swapItemsInPlaylist(_ playlistId: Int, position1: Int, position2: Int) -> Observable<Bool> {
        let parameters = ["jsonrpc": "2.0",
                          "method": "Playlist.Swap",
                          "params": ["playlistid": playlistId, "position1": position1, "position2": position2],
                          "id": "swapItemsInPlaylist"] as [String : Any]
        
        return dataPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, data) -> (Bool) in
                return true
            })
            .catch({ (error) -> Observable<(Bool)> in
                print(error)
                return Observable.just(false)
            })
    }
    
    // Not used because not working well
    public func addPlaylist(_ playlist: String, shuffle: Bool) -> Observable<Bool> {
        let parameters = ["jsonrpc": "2.0",
                          "method": "Playlist.Add",
                          "params": ["playlistid": 0,
                                     "item": ["file": playlist]],
                          "id": "addPlaylist"] as [String : Any]
        
        return dataPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, data) -> (Bool) in
                return true
            })
            .catch({ (error) -> Observable<(Bool)> in
                print(error)
                return Observable.just(false)
            })
    }

    // Not used because not working well
    public func playPlaylist(_ playlist: String, shuffle: Bool) -> Observable<Bool> {
        let parameters = ["jsonrpc": "2.0",
                          "method": "Player.Open",
                          "params": ["item": ["file": playlist]],
                          "id": "playPlaylist"] as [String : Any]
        
        return dataPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, data) -> (Bool) in
                return true
            })
            .catch({ (error) -> Observable<(Bool)> in
                print(error)
                return Observable.just(false)
            })
    }
}
