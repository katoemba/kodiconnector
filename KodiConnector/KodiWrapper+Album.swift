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
                Observable.empty()
            })
    }
    
    public func getAlbums(start: Int, end: Int) -> Observable<KodiAlbums> {
        struct Root: Decodable {
            var result: KodiAlbums
        }

        let parameters = ["jsonrpc": "2.0",
                          "method": "AudioLibrary.GetAlbums",
                          "params": ["properties": KodiWrapper.albumProperties,
                                     "limits": ["start": start, "end": end],
                                     "sort": ["order": "ascending", "method": "artist"]],
                          "id": "getAlbums"] as [String : Any]
        
        return dataPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, data) -> (KodiAlbums) in
                let root = try JSONDecoder().decode(Root.self, from: data)
                return root.result
            })
            .catchError({ (error) -> Observable<KodiAlbums> in
                Observable.empty()
            })
    }
    
    public func getAlbums(artistid: Int) -> Observable<KodiAlbums> {
        struct Root: Decodable {
            var result: KodiAlbums
        }
        
        let parameters = ["jsonrpc": "2.0",
                          "method": "AudioLibrary.GetAlbums",
                          "params": ["properties": KodiWrapper.albumProperties,
                                     "filter": ["artistid": artistid],
                                     "sort": ["order": "ascending", "method": "year"]],
                          "id": "getArtistAlbums"] as [String : Any]
        
        return dataPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, data) -> (KodiAlbums) in
                let root = try JSONDecoder().decode(Root.self, from: data)
                return root.result
            })
            .catchError({ (error) -> Observable<KodiAlbums> in
                Observable.empty()
            })
    }

    public func getAlbums(genreid: Int) -> Observable<KodiAlbums> {
        struct Root: Decodable {
            var result: KodiAlbums
        }
        
        let parameters = ["jsonrpc": "2.0",
                          "method": "AudioLibrary.GetAlbums",
                          "params": ["properties": KodiWrapper.albumProperties,
                                     "filter": ["genreid": genreid],
                                     "sort": ["order": "ascending", "method": "artist"]],
                          "id": "getArtistAlbums"] as [String : Any]
        
        return dataPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, data) -> (KodiAlbums) in
                let root = try JSONDecoder().decode(Root.self, from: data)
                return root.result
            })
            .catchError({ (error) -> Observable<KodiAlbums> in
                Observable.empty()
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
                Observable.just(false)
            })
    }
}
