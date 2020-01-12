//
//  KodiWrapper+Album.swift
//  KodiConnector
//
//  Created by Berrie Kremers on 19/08/2019.
//  Copyright © 2019 Katoemba Software. All rights reserved.
//

import Foundation
import RxSwift

extension KodiWrapper {
    private static let albumProperties = ["displayartist", "thumbnail", "year", "genre"]
    
    public func getRecentAlbums(count: Int) -> Observable<KodiAlbums> {
        struct Root: Decodable {
            var result: KodiAlbums
        }

        let parameters = ["jsonrpc": "2.0",
                          "method": "AudioLibrary.GetRecentlyAddedAlbums",
                          "params": ["properties": KodiWrapper.albumProperties,
                                     "limits": ["start": 0, "end": count],
                                     "sort": ["order": "descending", "method": "date"]],
                          "id": "getRecentAlbums"] as [String : Any]
        
        return dataPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, data) -> (KodiAlbums) in
                let root = try JSONDecoder().decode(Root.self, from: data)
                return root.result
            })
            .catchError({ (error) -> Observable<KodiAlbums> in
                print(error)
                return Observable.just(KodiAlbums(albums:[], limits: Limits(start: 0, end: 0, total: 0)))
            })
    }
    
    public func getAlbums(start: Int, end: Int, sort: [String: Any]) -> Observable<KodiAlbums> {
        struct Root: Decodable {
            var result: KodiAlbums
        }

        let params = ["properties": KodiWrapper.albumProperties,
                      "limits": ["start": start, "end": end],
                      "sort": sort] as [String : Any]
        let parameters = ["jsonrpc": "2.0",
                          "method": "AudioLibrary.GetAlbums",
                          "params": params,
                          "id": "getAlbums"] as [String : Any]
        
        return dataPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, data) -> (KodiAlbums) in
                let root = try JSONDecoder().decode(Root.self, from: data)
                return root.result
            })
            .catchError({ (error) -> Observable<KodiAlbums> in
                print(error)
                return Observable.just(KodiAlbums(albums:[], limits: Limits(start: 0, end: 0, total: 0)))
            })
    }
    
    public func getAlbum(_ albumid: Int) -> Observable<KodiAlbum> {
        struct Root: Decodable {
            var result: AlbumDetails
        }
        struct AlbumDetails: Decodable {
            var albumdetails: KodiAlbum
        }
        
        let parameters = ["jsonrpc": "2.0",
                          "method": "AudioLibrary.GetAlbumDetails",
                          "params": ["properties": KodiWrapper.albumProperties,
                                     "albumid": albumid],
                          "id": "getAlbumDetails"] as [String : Any]
        
        return dataPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, data) -> (KodiAlbum) in
                let root = try JSONDecoder().decode(Root.self, from: data)
                return root.result.albumdetails
            })
            .catchError({ (error) -> Observable<KodiAlbum> in
                print(error)
                return Observable.empty()
            })
    }
    
    private func getAlbumsWithFilter(_ filter: [String: Any], sort: [String: Any], limit: Int = 0) -> Observable<KodiAlbums> {
        struct Root: Decodable {
            var result: KodiAlbums
        }
        
        var params = ["properties": KodiWrapper.albumProperties,
                      "filter": filter,
                      "sort": sort] as [String: Any]
        if limit > 0 {
            params["limits"] = ["start": 0, "end": limit]
        }
        let parameters = ["jsonrpc": "2.0",
                          "method": "AudioLibrary.GetAlbums",
                          "params": params,
                          "id": "getAlbums"] as [String : Any]
        
        return dataPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, data) -> (KodiAlbums) in
                let root = try JSONDecoder().decode(Root.self, from: data)
                return root.result
            })
            .catchError({ (error) -> Observable<KodiAlbums> in
                print(error)
                return Observable.just(KodiAlbums(albums:[], limits: Limits(start: 0, end: 0, total: 0)))
            })
    }
    
    public func getAlbums(artistid: Int, sort: [String: Any]) -> Observable<KodiAlbums> {
        return getAlbumsWithFilter(["artistid": artistid],
                                    sort: sort)
    }

    public func getAlbums(genreid: Int, sort: [String: Any]) -> Observable<KodiAlbums> {
        return getAlbumsWithFilter(["genreid": genreid],
                                   sort: sort)
    }
    
    public func searchAlbums(_ search: String, limit: Int) -> Observable<[KodiAlbum]> {
        return getAlbumsWithFilter(["field": "album", "operator": "contains", "value": search],
                                   sort: ["order": "descending", "method": "playcount"],
                                   limit: limit)
            .map({ (kodiAlbums) -> [KodiAlbum] in
                kodiAlbums.albums
            })
    }
    
    public func allAlbumIds() -> Observable<[Int]> {
        struct Root: Decodable {
            var result: Result
        }
        struct Result: Decodable {
            var albums: [MinimalAlbum]
        }
        struct MinimalAlbum: Decodable {
            var albumid: Int
        }

        let params = [:] as [String: Any]
        let parameters = ["jsonrpc": "2.0",
                          "method": "AudioLibrary.GetAlbums",
                          "params": params,
                          "id": "getAllAlbums"] as [String : Any]
        
        return dataPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, data) -> ([Int]) in
                let json = try JSONDecoder().decode(Root.self, from: data)
                return json.result.albums
                    .map { (album) -> Int in
                        album.albumid
                    }
            })
            .catchError({ (error) -> Observable<[Int]> in
                print(error)
                return Observable.just([])
            })
    }
    
    public func playAlbum(_ albumid: Int, shuffle: Bool) -> Observable<Bool> {
        let parameters = ["jsonrpc": "2.0",
                          "method": "Player.Open",
                          "params": ["item": ["albumid": albumid],
                                     "options": ["shuffled": shuffle]],
                          "id": "playAlbum"] as [String : Any]
        
        return dataPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, data) -> (Bool) in
                return true
            })
            .catchError({ (error) -> Observable<(Bool)> in
                print(error)
                return Observable.just(false)
            })
    }
    
    public func addAlbum(_ albumid: Int) -> Observable<Bool> {
        let parameters = ["jsonrpc": "2.0",
                          "method": "Playlist.Add",
                          "params": ["playlistid": 0,
                                     "item": ["albumid": albumid]],
                          "id": "addAlbum"] as [String : Any]
        
        return dataPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, data) -> (Bool) in
                return true
            })
            .catchError({ (error) -> Observable<(Bool)> in
                print(error)
                return Observable.just(false)
            })

    }
    
    public func insertAlbum(_ albumid: Int, at: Int) -> Observable<Bool> {
        let parameters = ["jsonrpc": "2.0",
                          "method": "Playlist.Insert",
                          "params": ["playlistid": 0,
                                     "position": at,
                                     "item": ["albumid": albumid]],
                          "id": "insertAlbum"] as [String : Any]
        
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
