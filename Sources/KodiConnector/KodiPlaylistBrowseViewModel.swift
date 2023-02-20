//
//  KodiPlaylistBrowseViewModel.swift
//  KodiConnector
//
//  Created by Berrie Kremers on 10/03/2019.
//  Copyright © 2019 Katoemba Software. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay
import ConnectorProtocol

public class KodiPlaylistBrowseViewModel: PlaylistBrowseViewModel {
    private var loadProgress = BehaviorRelay<LoadProgress>(value: .notStarted)
    public var loadProgressObservable: Observable<LoadProgress> {
        return loadProgress.asObservable()
    }

    private var playlistSubject = PublishSubject<[Playlist]>()
    public var playlistsObservable: Observable<[Playlist]> {
        return playlistSubject.asObservable()
    }
    
    private let kodi: KodiProtocol
    private let bag = DisposeBag()
    
    public init(kodi: KodiProtocol) {
        self.kodi = kodi
    }
    
    public func load() {
        loadProgress.accept(.loading)
        
        let playlistsObservable = kodi.getDirectory("special://profile/playlists/music")
            .map { (kodiFiles) -> [Playlist] in
                guard let files = kodiFiles.files else { return [] }
                return files.compactMap({ (kodiFile) -> Playlist? in
                    if kodiFile.filetype == "directory" {
                        return Playlist(id: kodiFile.file, source: .Local, name: kodiFile.label, lastModified: Date())
                    }
                    else {
                        return nil
                    }
                })
            }
            .share()
        
        playlistsObservable
            .bind(to: playlistSubject)
            .disposed(by: bag)
        
        playlistsObservable
            .filter { (playlists) -> Bool in
                playlists.count == 0
            }
            .map({ (_) -> LoadProgress in
                .noDataFound
            })
            .bind(to: loadProgress)
            .disposed(by: bag)
        
        playlistsObservable
            .filter { (playlists) -> Bool in
                playlists.count > 0
            }
            .map({ (_) -> LoadProgress in
                .allDataLoaded
            })
            .bind(to: loadProgress)
            .disposed(by: bag)
    }
    
    public func renamePlaylist(_ playlist: Playlist, to: String) -> Playlist {
        return Playlist()
    }
    
    public func deletePlaylist(_ playlist: Playlist) {
    }
    
}
