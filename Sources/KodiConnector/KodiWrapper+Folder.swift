//
//  KodiWrapper+Folder.swift
//  KodiConnector
//
//  Created by Berrie Kremers on 20/08/2019.
//  Copyright © 2019 Katoemba Software. All rights reserved.
//

import Foundation
import RxSwift

extension KodiWrapper {
    public static let fileProperties = ["album", "displayartist", "duration", "thumbnail", "year", "albumartist", "genre", "track"]

    public func getSources() -> Observable<KodiSources> {

        struct Root: Decodable {
            var result: KodiSources
        }
        
        let parameters = ["jsonrpc": "2.0",
                          "method": "Files.GetSources",
                          "params": ["media": "music"],
                          "id": "getSources"] as [String : Any]
        
        return dataPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, data) -> (KodiSources) in
                let root = try JSONDecoder().decode(Root.self, from: data)
                return root.result
            })
            .catch({ (error) -> Observable<KodiSources> in
                print(error)
                return Observable.empty()
            })
    }

    public func getDirectory(_ path: String) -> Observable<KodiFiles> {
        struct Root: Decodable {
            var result: KodiFiles
        }
        
        let parameters = ["jsonrpc": "2.0",
                          "method": "Files.GetDirectory",
                          "params": ["directory": path,
                                     "media": "music",
                                     "properties": KodiWrapper.fileProperties],
                          "id": "getDirectory"] as [String : Any]
        
        return dataPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, data) -> (KodiFiles) in
                let root = try JSONDecoder().decode(Root.self, from: data)
                return root.result
            })
            .catch({ (error) -> Observable<KodiFiles> in
                print(error)
                return Observable.empty()
            })
    }
}
