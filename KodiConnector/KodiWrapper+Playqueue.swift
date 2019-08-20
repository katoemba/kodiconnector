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
    public func getPlayQueue(start: Int, end: Int) -> Observable<[KodiSong]> {
        struct Root: Decodable {
            var result: Result
        }
        struct Result: Decodable {
            var items: [KodiSong]
            var limits: Limits
        }
        struct Limits: Decodable {
            var start: Int
            var end: Int
            var total: Int
        }

        let parameters = ["jsonrpc": "2.0",
                          "method": "Playlist.GetItems",
                          "params": ["playlistid": 0,
                                     "properties": KodiWrapper.songParams,
                                     "limits": ["start": start, "end": end]],
                          "id": "getPlaylistItems"] as [String : Any]
        
        return dataPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, data) -> ([KodiSong]) in
                let json = try JSONDecoder().decode(Root.self, from: data)

                return json.result.items
            })
            .catchError({ (error) -> Observable<[KodiSong]> in
                Observable.just([])
            })
    }
    
    // MARK: - Player control functions
    
    public func clearPlayqueue(_ playlistId: Int) -> Observable<Bool> {
        let parameters = ["jsonrpc": "2.0",
                          "method": "Playlist.Clear",
                          "params": ["playlistid": playlistId],
                          "id": "playlistClear"] as [String : Any]
        
        return dataPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, data) -> (Bool) in
                return true
            })
            .catchError({ (error) -> Observable<(Bool)> in
                Observable.just(false)
            })
    }
}
