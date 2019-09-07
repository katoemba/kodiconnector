//
//  KodiWrapper+Artist.swift
//  KodiConnector
//
//  Created by Berrie Kremers on 19/08/2019.
//  Copyright © 2019 Katoemba Software. All rights reserved.
//

import Foundation
import RxSwift

extension KodiWrapper {
    public static let artistProperties = ["thumbnail"]
    
    public func getArtists(start: Int, end: Int, albumartistsonly: Bool) -> Observable<KodiArtists> {
        struct Root: Decodable {
            var result: KodiArtists
        }
        
        let parameters = ["jsonrpc": "2.0",
                          "method": "AudioLibrary.GetArtists",
                          "params": ["albumartistsonly": albumartistsonly,
                                     "properties": KodiWrapper.artistProperties,
                                     "limits": ["start": start, "end": end],
                                     "sort": ["order": "ascending", "method": "artist", "ignorearticle": true]],
                          "id": "getArtists"] as [String : Any]
        
        return dataPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, data) -> (KodiArtists) in
                let root = try JSONDecoder().decode(Root.self, from: data)
                return root.result
            })
            .catchError({ (error) -> Observable<KodiArtists> in
                Observable.empty()
            })
    }

    private func getArtistsWithFilter(_ filter: [String: Any], sort: [String: Any], limit: Int = 0) -> Observable<KodiArtists> {
        struct Root: Decodable {
            var result: KodiArtists
        }
        
        var params = ["properties": KodiWrapper.artistProperties,
                      "filter": filter,
                      "sort": sort] as [String: Any]
        if limit > 0 {
            params["limits"] = ["start": 0, "end": limit]
        }
        let parameters = ["jsonrpc": "2.0",
                          "method": "AudioLibrary.GetArtists",
                          "params": params,
                          "id": "getArtist"] as [String : Any]
        
        return dataPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, data) -> (KodiArtists) in
                let root = try JSONDecoder().decode(Root.self, from: data)
                
                return root.result
            })
            .catchError({ (error) -> Observable<KodiArtists> in
                Observable.just(KodiArtists(artists:[], limits: Limits(start: 0, end: 0, total: 0)))
            })
    }
    
    public func getArtistId(_ name: String) -> Observable<Int> {
        enum MyError: Error {
            case artistNotFound
        }

        return getArtistsWithFilter(["field": "artist", "operator": "is", "value": name],
                                    sort: ["order": "ascending", "method": "name", "ignorearticle": true])
            .map({ (kodiArtists) -> Int in
                guard kodiArtists.artists.count > 0, let artistid = kodiArtists.artists[0].artistid else {
                    throw MyError.artistNotFound
                }
                return artistid
            })
            .catchError({ (error) -> Observable<Int> in
                Observable.empty()
            })
    }

    public func searchArtists(_ search: String, limit: Int) -> Observable<[KodiArtist]> {
        return getArtistsWithFilter(["field": "artist", "operator": "contains", "value": search],
                                    sort: ["order": "ascending", "method": "artist", "ignorearticle": true],
                                    limit: limit)
            .map({ (kodiArtists) -> [KodiArtist] in
                kodiArtists.artists
            })
    }

    public func playArtist(_ artistid: Int, shuffle: Bool) -> Observable<Bool> {
        let parameters = ["jsonrpc": "2.0",
                          "method": "Player.Open",
                          "params": ["item": ["artistid": artistid],
                                     "options": ["shuffled": shuffle]],
                          "id": "playArtist"] as [String : Any]
        
        return dataPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, data) -> (Bool) in
                return true
            })
            .catchError({ (error) -> Observable<(Bool)> in
                Observable.just(false)
            })
    }
    
}
