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
                                     "sort": ["order": "ascending", "method": "artist"]],
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

    public func getArtistId(_ name: String) -> Observable<Int> {
        struct Root: Decodable {
            var result: KodiArtists
        }
        enum MyError: Error {
            case artistNotFound
        }

        let parameters = ["jsonrpc": "2.0",
                          "method": "AudioLibrary.GetArtists",
                          "params": ["properties": KodiWrapper.artistProperties,
                                     "filter": ["field": "artist", "operator": "is", "value": name]],
                          "id": "getArtist"] as [String : Any]
        
        return dataPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, data) -> (Int) in
                let root = try JSONDecoder().decode(Root.self, from: data)
                
                guard root.result.artists.count > 0, let artistid = root.result.artists[0].artistid else {
                    throw MyError.artistNotFound
                }
                return artistid
            })
            .catchError({ (error) -> Observable<Int> in
                Observable.empty()
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
