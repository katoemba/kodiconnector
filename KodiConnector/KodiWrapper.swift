//
//  KodiWrapper.swift
//  KodiConnector_iOS
//
//  Created by Berrie Kremers on 12/03/2019.
//  Copyright © 2019 Katoemba Software. All rights reserved.
//

import Foundation
import RxSwift
import RxAlamofire
import Alamofire

public class KodiWrapper: KodiProtocol {
    private let encoding = JSONEncoding.default
    private let headers = ["Content-Type": "application/json"]
    private(set) var kodi: KodiAddress
    private(set) var playerId = -1
    
    private var bag = DisposeBag()
    
    private func jsonPostRequest(_ url: URL, parameters: [String: Any]) -> Observable<(HTTPURLResponse, Any)> {
        return RxAlamofire.requestJSON(.post, url, parameters: parameters, encoding: encoding, headers: headers)
    }
    public func dataPostRequest(_ url: URL, parameters: [String: Any]) -> Observable<(HTTPURLResponse, Data)> {
        return RxAlamofire.requestData(.post, url, parameters: parameters, encoding: encoding, headers: headers)
    }
    
    public init(kodi: KodiAddress) {
        self.kodi = kodi
        getActivePlayers()
            .filter({ (_, found) -> Bool in
                found == true
            })
            .subscribe(onNext: { [weak self] (playerId, found) in
                self?.playerId = playerId
            })
            .disposed(by: bag)
    }
}
