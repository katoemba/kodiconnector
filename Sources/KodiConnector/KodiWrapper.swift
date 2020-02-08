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
    public var kodiAddress: KodiAddress {
        return kodi
    }

    public var playerId = 0
    public var stream: KodiStream {
        return KodiStream(rawValue: playerId) ?? .audio
    }
    
    private var bag = DisposeBag()
    
    private func jsonPostRequest(_ url: URL, parameters: [String: Any]) -> Observable<(HTTPURLResponse, Any)> {
        return RxAlamofire.requestJSON(.post, url, parameters: parameters, encoding: encoding, headers: headers)
    }
    public func dataPostRequest(_ url: URL, parameters: [String: Any]) -> Observable<(HTTPURLResponse, Data)> {
        return RxAlamofire.requestData(.post, url, parameters: parameters, encoding: encoding, headers: headers)
            .flatMapFirst { (arg) -> Observable<(HTTPURLResponse, Data)> in
                let (response, data) = arg
                guard response.statusCode == 200, (response.mimeType ?? "").contains("json") else {
                    return Observable.empty()
                }
                return Observable.just((response, data))
            }
    }
    
    public init(kodi: KodiAddress) {
        self.kodi = kodi
        self.getActivePlayers()
            .subscribe(onNext: { [weak self] (playerId, isAudio) in
                guard let weakSelf = self else { return }
                weakSelf.playerId = playerId
            })
            .disposed(by: bag)
    }
}
