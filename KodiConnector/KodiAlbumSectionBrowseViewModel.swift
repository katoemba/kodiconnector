//
//  KodiAlbumSectionBrowseViewModel.swift
//  KodiConnector
//
//  Created by Berrie Kremers on 10/03/2019.
//  Copyright © 2019 Katoemba Software. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import ConnectorProtocol

public class KodiAlbumSectionBrowseViewModel: AlbumSectionBrowseViewModel {
    private var loadProgress = BehaviorRelay<LoadProgress>(value: .notStarted)
    public var loadProgressObservable: Observable<LoadProgress> {
        return loadProgress.asObservable()
    }
    
    private var albumSectionsSubject = PublishSubject<AlbumSections>()
    public var albumSectionsObservable: Observable<AlbumSections> {
        return albumSectionsSubject.asObservable()
    }
    
    public private(set) var sort = SortType.artist

    public private(set) var availableSortOptions = [SortType]()

    public func load(sort: SortType) {
    }
}
