//
//  KodiPlaylistBrowseViewModel.swift
//  KodiConnector
//
//  Created by Berrie Kremers on 10/03/2019.
//  Copyright © 2019 Katoemba Software. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
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
    
    public func load() {
    }
    
    public func extend() {
    }
    
    public func renamePlaylist(_ playlist: Playlist, to: String) -> Playlist {
        return Playlist()
    }
    
    public func deletePlaylist(_ playlist: Playlist) {
    }
    
}
