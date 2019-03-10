//
//  KodiAlbumBrwoseViewModel.swift
//  KodiConnector
//
//  Created by Berrie Kremers on 10/03/2019.
//  Copyright © 2019 Katoemba Software. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import ConnectorProtocol

public class KodiAlbumBrowseViewModel: AlbumBrowseViewModel {
    private var loadProgress = BehaviorRelay<LoadProgress>(value: .notStarted)
    public var loadProgressObservable: Observable<LoadProgress> {
        return loadProgress.asObservable()
    }

    private var albumsSubject = PublishSubject<[Album]>()
    public var albumsObservable: Observable<[Album]> {
        return albumsSubject.asObservable()
    }

    public private(set) var filters = [BrowseFilter]()

    public private(set) var sort = SortType.artist
    
    public private(set) var availableSortOptions = [SortType]()
    
    public func load(sort: SortType) {
    }
    
    public func load(filters: [BrowseFilter]) {
    }
    
    public func extend() {
    }
    
    public func extend(to: Int) {
    }
    
}
