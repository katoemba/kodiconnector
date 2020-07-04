//
//  KodiWrapper.swift
//  KodiConnector_iOS
//
//  Created by Berrie Kremers on 12/03/2019.
//  Copyright © 2019 Katoemba Software. All rights reserved.
//

import Foundation
import RxSwift

public class KodiWrapper: KodiProtocol {
    enum ResponseError: Error {
        case responseError
    }

    private(set) var kodi: KodiAddress
    public var kodiAddress: KodiAddress {
        return kodi
    }
    private var sessionManager: URLSession

    public var playerId = 0
    public var stream: KodiStream {
        return KodiStream(rawValue: playerId) ?? .audio
    }
    
    private var bag = DisposeBag()
        
    public init(kodi: KodiAddress, getPlayerId: Bool, sessionManager: URLSession? = nil) {
        self.kodi = kodi
        self.sessionManager = sessionManager ?? URLSession.shared
        if getPlayerId {
            self.getActivePlayers()
                .subscribe(onNext: { [weak self] (playerId, isAudio) in
                    guard let weakSelf = self else { return }
                    weakSelf.playerId = playerId
                })
                .disposed(by: bag)
        }
    }

    public func dataPostRequest(_ url: URL?, parameters: [String: Any], timeoutInterval: TimeInterval = 15.0) -> Observable<(HTTPURLResponse, Data)> {
        guard let url = url else { return Observable.empty() }
        
        return Observable.create { (observer) in
            var request = URLRequest(url: url, timeoutInterval: timeoutInterval)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")

            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted) // pass dictionary to nsdata object and set it as request body
            } catch let error {
                print(error.localizedDescription)
            }

            let task = self.sessionManager.dataTask(with: request) { data, response, error in
                if let response = response as? HTTPURLResponse, response.statusCode == 200, (response.mimeType ?? "").contains("json"),
                    let data = data {
                    observer.onNext((response, data))
                    observer.onCompleted()
                }
                else {
                    observer.onError(ResponseError.responseError)
                }
            }

            task.resume()
            return Disposables.create()
        }
        .observeOn(MainScheduler.instance)
    }
}
