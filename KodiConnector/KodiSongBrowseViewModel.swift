//
//  KodiSongBrowseViewModel.swift
//  KodiConnector
//
//  Created by Berrie Kremers on 10/03/2019.
//  Copyright © 2019 Katoemba Software. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import ConnectorProtocol

public class KodiSongBrowseViewModel: SongBrowseViewModel {
    private var loadProgress = BehaviorRelay<LoadProgress>(value: .notStarted)
    public var loadProgressObservable: Observable<LoadProgress> {
        return loadProgress.asObservable()
    }

    private var songsSubject = PublishSubject<[Song]>()
    public var songsObservable: Observable<[Song]> {
        return songsSubject.asObservable()
    }
    
    public private(set) var filters = [BrowseFilter]()

    public func load() {
    }
    
    public func extend() {
    }
    
    public func removeSong(at: Int) {
    }
    
}
