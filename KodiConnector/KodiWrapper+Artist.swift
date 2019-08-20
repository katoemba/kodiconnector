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
                          "id": "getAlbums"] as [String : Any]
        
        return dataPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, data) -> (KodiArtists) in
                let root = try JSONDecoder().decode(Root.self, from: data)
                return root.result
            })
            .catchError({ (error) -> Observable<KodiArtists> in
                Observable.empty()
            })
    }
}
