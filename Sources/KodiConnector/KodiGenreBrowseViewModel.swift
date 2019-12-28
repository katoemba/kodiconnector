//
//  KodiGenreBrowseViewModel.swift
//  KodiConnector
//
//  Created by Berrie Kremers on 10/03/2019.
//  Copyright © 2019 Katoemba Software. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import ConnectorProtocol

public class KodiGenreBrowseViewModel: GenreBrowseViewModel {
    private var loadProgress = BehaviorRelay<LoadProgress>(value: .notStarted)
    public var loadProgressObservable: Observable<LoadProgress> {
        return loadProgress.asObservable()
    }

    private var genresSubject = PublishSubject<[Genre]>()
    public var genresObservable: Observable<[Genre]> {
        return genresSubject.asObservable()
    }

    public private(set) var parentGenre = nil as Genre?
    
    private let kodi: KodiProtocol
    private let bag = DisposeBag()
    
    public init(kodi: KodiProtocol) {
        self.kodi = kodi
    }
    
    public func load() {
        loadProgress.accept(.loading)

        kodi.getGenres()
            .map { (kodiGenres) -> [Genre] in
                kodiGenres.genres.map({ (kodiGenre) -> Genre in
                    return kodiGenre.genre
                })
            }
            .do(onNext: { [weak self] (_) in
                self?.loadProgress.accept(.allDataLoaded)
            })
            .bind(to: genresSubject)
            .disposed(by: bag)
    }
    
    public func extend() {
    }    
}
