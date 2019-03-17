//
//  KodiBrowse.swift
//  KodiConnector
//
//  Created by Berrie Kremers on 10/03/2019.
//  Copyright © 2019 Katoemba Software. All rights reserved.
//

import Foundation
import ConnectorProtocol
import RxSwift
import RxCocoa

public class KodiBrowse: BrowseProtocol {
    private var kodi: KodiProtocol
    
    public init(kodi: KodiProtocol) {
        self.kodi = kodi
    }
    
    public func songsByArtist(_ artist: Artist) -> Observable<[Song]> {
        return Observable.empty()
    }
    
    public func albumsByArtist(_ artist: Artist, sort: SortType) -> Observable<[Album]> {
        return Observable.empty()
    }
    
    public func songsOnAlbum(_ album: Album) -> Observable<[Song]> {
        return Observable.empty()
    }
    
    public func songsInPlaylist(_ playlist: Playlist) -> Observable<[Song]> {
        return Observable.empty()
    }
    
    public func search(_ search: String, limit: Int, filter: [SourceType]) -> Observable<SearchResult> {
        return Observable.empty()
    }
    
    public func albumSectionBrowseViewModel() -> AlbumSectionBrowseViewModel {
        return KodiAlbumSectionBrowseViewModel()
    }
    
    public func albumBrowseViewModel() -> AlbumBrowseViewModel {
        return KodiAlbumBrowseViewModel(kodi: kodi)
    }
    
    public func albumBrowseViewModel(_ artist: Artist) -> AlbumBrowseViewModel {
        return KodiAlbumBrowseViewModel(kodi: kodi)
    }
    
    public func albumBrowseViewModel(_ genre: String) -> AlbumBrowseViewModel {
        return KodiAlbumBrowseViewModel(kodi: kodi)
    }
    
    public func albumBrowseViewModel(_ albums: [Album]) -> AlbumBrowseViewModel {
        return KodiAlbumBrowseViewModel(kodi: kodi)
    }
    
    public func artistBrowseViewModel(type: ArtistType) -> ArtistBrowseViewModel {
        return KodiArtistBrowseViewModel()
    }
    
    public func artistBrowseViewModel(_ genre: String, type: ArtistType) -> ArtistBrowseViewModel {
        return KodiArtistBrowseViewModel()
    }
    
    public func artistBrowseViewModel(_ artists: [Artist]) -> ArtistBrowseViewModel {
        return KodiArtistBrowseViewModel()
    }
    
    public func playlistBrowseViewModel() -> PlaylistBrowseViewModel {
        return KodiPlaylistBrowseViewModel()
    }
    
    public func playlistBrowseViewModel(_ playlists: [Playlist]) -> PlaylistBrowseViewModel {
        return KodiPlaylistBrowseViewModel()
    }
    
    public func songBrowseViewModel(_ songs: [Song]) -> SongBrowseViewModel {
        return KodiSongBrowseViewModel(kodi: kodi, songs: songs)
    }
    
    public func songBrowseViewModel(_ album: Album) -> SongBrowseViewModel {
        return KodiSongBrowseViewModel(kodi: kodi, filters: [.album(album)])
    }
    
    public func songBrowseViewModel(_ playlist: Playlist) -> SongBrowseViewModel {
        return KodiSongBrowseViewModel(kodi: kodi, filters: [.playlist(playlist)])
    }
    
    public func genreBrowseViewModel() -> GenreBrowseViewModel {
        return KodiGenreBrowseViewModel()
    }
    
    public func folderContentsBrowseViewModel() -> FolderBrowseViewModel {
        return KodiFolderBrowseViewModel()
    }
    
    public func folderContentsBrowseViewModel(_ parentFolder: Folder) -> FolderBrowseViewModel {
        return KodiFolderBrowseViewModel()
    }
    
    public func artistFromSong(_ song: Song) -> Observable<Artist> {
        return Observable.empty()
    }
    
    public func albumFromSong(_ song: Song) -> Observable<Album> {
        return Observable.empty()
    }
    
    public func preprocessCoverURI(_ coverURI: CoverURI) -> Observable<CoverURI> {
        return Observable.just(coverURI)
    }
    
    public func diagnostics(album: Album) -> Observable<String> {
        return Observable.empty()
    }
    
}
