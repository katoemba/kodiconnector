//
//  KodiWrapper+Genre.swift
//  KodiConnector
//
//  Created by Berrie Kremers on 20/08/2019.
//  Copyright © 2019 Katoemba Software. All rights reserved.
//

import Foundation
import RxSwift

extension KodiWrapper {
    public func getGenres() -> Observable<KodiGenres> {
        struct Root: Decodable {
            var result: KodiGenres
        }
        
        let parameters = ["jsonrpc": "2.0",
                          "method": "AudioLibrary.GetGenres",
                          "params": ["sort": ["order": "ascending", "method": "label"]],
                          "id": "getAlbums"] as [String : Any]
        
        return dataPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, data) -> (KodiGenres) in
                let root = try JSONDecoder().decode(Root.self, from: data)
                return root.result
            })
            .catchError({ (error) -> Observable<KodiGenres> in
                print(error)
                return Observable.empty()
            })
    }
    
    public func playGenre(_ genreid: Int, shuffle: Bool) -> Observable<Bool> {
        let parameters = ["jsonrpc": "2.0",
                          "method": "Player.Open",
                          "params": ["item": ["genreid": genreid],
                                     "options": ["shuffled": shuffle]],
                          "id": "playGenre"] as [String : Any]
        
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
