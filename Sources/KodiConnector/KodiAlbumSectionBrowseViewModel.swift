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
    public let albumSectionsObservable: Observable<AlbumSections>
    
    public private(set) var sort = SortType.artist
    public var availableSortOptions: [SortType] {
        return [.artist, .title, .year, .yearReverse]
    }

    private var bag = DisposeBag()
    private var kodi: KodiProtocol

    public init(kodi: KodiProtocol) {
        self.kodi = kodi
        
        albumSectionsObservable = albumSectionsSubject.share()
        loadProgress.onNext(.notStarted)
    }

    public func load(sort: SortType) {
        self.sort = sort
        
        // Clear the contents
        bag = DisposeBag()
        loadProgress.onNext(.loading)

        let albumObservable = kodi.getAlbums(start: 0, end: 100000, sort: sort.parameterArray)
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
                    if sort == .artist {
                        return (key, dict[key]!.sorted(by: { (lhs, rhs) -> Bool in
                            let artistCompare = lhs.sortArtist.caseInsensitiveCompare(rhs.sortArtist)
                            if artistCompare == .orderedSame {
                                return lhs.year < rhs.year
                            }
                            
                            return (artistCompare == .orderedAscending)
                        }))
                    }
                    return (key, dict[key]!)
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
