//
//  KodiAlbumSectionBrowseViewModel.swift
//  KodiConnector
//
//  Created by Berrie Kremers on 10/03/2019.
//  Copyright © 2019 Katoemba Software. All rights reserved.
//

import Foundation
import RxSwift
import ConnectorProtocol

public class KodiAlbumSectionBrowseViewModel: AlbumSectionBrowseViewModel {
    private var loadProgress = ReplaySubject<LoadProgress>.create(bufferSize: 1)
    public var loadProgressObservable: Observable<LoadProgress> {
        return loadProgress.asObservable()
    }
    
    private var albumSectionsSubject = ReplaySubject<AlbumSections>.create(bufferSize: 1)
    public var albumSectionsObservable: Observable<AlbumSections> {
        return albumSectionsSubject.asObservable()
    }
    
    public private(set) var sort = SortType.artist
    public var availableSortOptions: [SortType] {
        return [.artist, .title, .year, .yearReverse]
    }

    private var bag = DisposeBag()
    private var kodi: KodiProtocol

    public init(kodi: KodiProtocol) {
        self.kodi = kodi
        
        loadProgress.onNext(.notStarted)
    }

    public func load(sort: SortType) {
        self.sort = sort
        
        // Clear the contents
        bag = DisposeBag()
        loadProgress.onNext(.loading)

        var sortString = "title"
        var sortDirection = "ascending"
        switch sort {
        case .artist:
        sortString = "artist"
        sortDirection = "ascending"
        case .title:
        sortString = "label"
        sortDirection = "ascending"
        case .year:
        sortString = "year"
        sortDirection = "ascending"
        case .yearReverse:
        sortString = "year"
        sortDirection = "descending"
        }
        let albumObservable = kodi.getAlbums(start: 0, end: 100000, sort: sortString, sortDirection: sortDirection)
            .map({ [weak self] (kodiAlbums) -> [Album] in
                guard let weakSelf = self else { return [] }
                
                return kodiAlbums.albums.map({ (kodiAlbum) -> Album in
                    kodiAlbum.album(kodiAddress: weakSelf.kodi.kodiAddress)
                })
            })
            .observeOn(MainScheduler.instance)
            .share(replay: 1)

        albumObservable
            .filter({ (albums) -> Bool in
                albums.count > 0
            })
            .map({ (albums) -> [(String, [Album])] in
                let dict = Dictionary(grouping: albums, by: { album -> String in
                    var firstLetter: String
                    
                    if sort == .year || sort == .yearReverse {
                        return "\(album.year)"
                    }
                    if sort == .artist {
                        firstLetter = String(album.sortArtist.prefix(1)).uppercased()
                    }
                    else {
                        firstLetter = String(album.title.prefix(1)).uppercased()
                    }
                    if "ABCDEFGHIJKLMNOPQRSTUVWXYZ".contains(firstLetter) == false {
                        firstLetter = "•"
                    }
                    return firstLetter
                })
                
                // Create an ordered array of LibraryItemsSections from the dictionary
                var sortedKeys = dict.keys.sorted()
                if sort == .yearReverse {
                    sortedKeys = sortedKeys.reversed()
                }
                return sortedKeys.map({ (key) -> (String, [Album]) in
                        (key, dict[key]!)
                    })
            })
            .map({ (sectionDictionary) -> AlbumSections in
                AlbumSections(sectionDictionary, completeObjects: { (albums) -> Observable<[Album]> in
                    return Observable.just(albums)
                })
            })
            .subscribe(onNext: { [weak self] (objectSections) in
                self?.albumSectionsSubject.onNext(objectSections)
            })
            .disposed(by: bag)
        
        albumObservable
            .map { (albums) -> LoadProgress in
                albums.count == 0 ? .noDataFound : .allDataLoaded
            }
            .bind(to: loadProgress)
            .disposed(by: bag)
    }
}
