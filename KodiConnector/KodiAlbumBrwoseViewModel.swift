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
    
    private var kodi: KodiProtocol
    private var bag = DisposeBag()

    public init(kodi: KodiProtocol) {
        self.kodi = kodi
    }
    
    public func load(sort: SortType) {
        self.sort = sort
        load()
    }
    
    public func load(filters: [BrowseFilter]) {
        self.filters = filters
        load()
    }
    
    public func load() {
        if filters.count > 0 {
            switch filters[0] {
            case let .genre(genre):
                reload(genre: genre, sort: sort)
            case let .artist(artist):
                reload(artist: artist, sort: sort)
            case let .recent(duration):
                reload(recent: duration, sort: sort)
            case let .random(count):
                reload(random: count, sort: sort)
            default:
                fatalError("MPDAlbumBrowseViewModel: unsupported filter type")
            }
        }
        else {
            reload(sort: sort)
        }
    }
    
    private func reload(genre: String? = nil, artist: Artist? = nil, recent: Int? = nil, random: Int? = nil, sort: SortType) {
        loadProgress.accept(.loading)

        if let recent = recent {
            kodi.getRecentAlbums(count: recent)
                .do() { [weak self] in
                    self?.loadProgress.accept(.dataAvailable)
                }
                .bind(to: albumsSubject)
                .disposed(by: bag)
            return
        }
        
        kodi.getAlbums(start: 0, end: 100)
            .do() { [weak self] in
                self?.loadProgress.accept(.dataAvailable)
            }
            .bind(to: albumsSubject)
            .disposed(by: bag)
    }
    
    public func extend() {
    }
    
    public func extend(to: Int) {
    }
    
}
