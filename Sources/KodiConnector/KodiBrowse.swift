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
        guard let albumId = Int(album.id) else {
            return Observable.just([])
        }
        
        return kodi.getSongsOnAlbum(albumId)
            .map({ [weak self] (kodiSongs) -> [Song] in
                guard let weakSelf = self else { return [] }
                
                return kodiSongs.map({ (kodiSong) -> Song in
                    kodiSong.song(kodiAddress: weakSelf.kodi.kodiAddress)
                })
            })
            .catchAndReturn([])
    }
    
    public func songsInPlaylist(_ playlist: Playlist) -> Observable<[Song]> {
        return kodi.getDirectory(playlist.id)
            .map { [weak self] (kodiFiles) -> [Song] in
                guard let weakSelf = self else { return [] }
                guard let files = kodiFiles.files else { return [] }
                
                return files.compactMap({ (kodiFile) -> Song? in
                    let folderContent = kodiFile.folderContent(kodiAddress: weakSelf.kodi.kodiAddress)
                    
                    if case let .song(song)? = folderContent {
                        return song
                    }
                    return nil
                })
        }
            .catchAndReturn([])
    }
    
    public func search(_ search: String, limit: Int, filter: [SourceType]) -> Observable<SearchResult> {
        let songSearch = kodi.searchSongs(search, limit: limit)
            .map { (songs) -> ([Song]) in
                songs.map({ (kodiSong) -> Song in
                    kodiSong.song(kodiAddress: self.kodi.kodiAddress)
                })
        }
        let albumSearch = kodi.searchAlbums(search, limit: limit)
            .map { (albums) -> ([Album]) in
                albums.map({ (kodiAlbum) -> Album in
                    kodiAlbum.album(kodiAddress: self.kodi.kodiAddress)
                })
        }
        let artistSearch = kodi.searchArtists(search, limit: limit)
            .map { (artists) -> ([Artist]) in
                artists.map({ (kodiArtist) -> Artist in
                    kodiArtist.artist
                })
        }
        
        return Observable.combineLatest(songSearch, albumSearch, artistSearch)
            .map { (songs, albums,artists) -> SearchResult in
                var result = SearchResult()
                result.songs = songs
                result.albums = albums
                result.artists = artists
                return result
        }
            .catchAndReturn(SearchResult())
    }
    
    public func albumSectionBrowseViewModel() -> AlbumSectionBrowseViewModel {
        return KodiAlbumSectionBrowseViewModel(kodi: kodi)
    }
    
    public func albumBrowseViewModel() -> AlbumBrowseViewModel {
        return KodiAlbumBrowseViewModel(kodi: kodi)
    }
    
    public func albumBrowseViewModel(_ artist: Artist) -> AlbumBrowseViewModel {
        return KodiAlbumBrowseViewModel(kodi: kodi, filters: [.artist(artist)])
    }
    
    public func albumBrowseViewModel(_ genre: Genre) -> AlbumBrowseViewModel {
        return KodiAlbumBrowseViewModel(kodi: kodi, filters: [.genre(genre)])
    }
    
    public func albumBrowseViewModel(_ albums: [Album]) -> AlbumBrowseViewModel {
        return KodiAlbumBrowseViewModel(kodi: kodi, albums: albums)
    }
    
    public func artistBrowseViewModel(type: ArtistType) -> ArtistBrowseViewModel {
        return KodiArtistBrowseViewModel(kodi: kodi)
    }
    
    public func artistBrowseViewModel(_ genre: Genre, type: ArtistType) -> ArtistBrowseViewModel {
        return KodiArtistBrowseViewModel(kodi: kodi, filters: [.genre(genre)])
    }
    
    public func artistBrowseViewModel(_ artists: [Artist]) -> ArtistBrowseViewModel {
        return KodiArtistBrowseViewModel(kodi: kodi, artists: artists)
    }
    
    public func playlistBrowseViewModel() -> PlaylistBrowseViewModel {
        return KodiPlaylistBrowseViewModel(kodi: kodi)
    }
    
    public func playlistBrowseViewModel(_ playlists: [Playlist]) -> PlaylistBrowseViewModel {
        return KodiPlaylistBrowseViewModel(kodi: kodi)
    }
    
    public func songBrowseViewModel(_ songs: [Song]) -> SongBrowseViewModel {
        return KodiSongBrowseViewModel(kodi: kodi, songs: songs)
    }
    
    public func songBrowseViewModel(_ album: Album, artist: Artist?) -> SongBrowseViewModel {
        if let artist = artist {
            return KodiSongBrowseViewModel(kodi: kodi, filter: .album(album), subFilter: .artist(artist))
        }
        else {
            return KodiSongBrowseViewModel(kodi: kodi, filter: .album(album))
        }
    }
    
    public func songBrowseViewModel(_ playlist: Playlist) -> SongBrowseViewModel {
        return KodiSongBrowseViewModel(kodi: kodi, filter: .playlist(playlist))
    }
    
    public func songBrowseViewModel(random: Int) -> SongBrowseViewModel {
        return KodiSongBrowseViewModel(kodi: kodi, filter: .random(random))
    }
    
    public func genreBrowseViewModel() -> GenreBrowseViewModel {
        return KodiGenreBrowseViewModel(kodi: kodi)
    }
    
    public func folderContentsBrowseViewModel() -> FolderBrowseViewModel {
        return KodiFolderBrowseViewModel(kodi: kodi)
    }
    
    public func folderContentsBrowseViewModel(_ parentFolder: Folder) -> FolderBrowseViewModel {
        return KodiFolderBrowseViewModel(kodi: kodi, parentFolder: parentFolder)
    }
    
    public func artistFromSong(_ song: Song) -> Observable<Artist> {
        guard let songId = Int(song.id) else { return Observable.empty() }
        
        return kodi.getSong(songId)
            .flatMap({ (kodiSong) -> Observable<KodiArtist> in
                guard let artistIds = kodiSong.artistid, artistIds.count > 0 else { return Observable.empty() }
                return self.kodi.getArtist(artistIds[0])
            })
            .map({ (kodiArtist) -> Artist in
                kodiArtist.artist
            })
    }
    
    public func albumFromSong(_ song: Song) -> Observable<Album> {
        guard let songId = Int(song.id) else { return Observable.empty() }
        
        return kodi.getSong(songId)
            .flatMap({ (kodiSong) -> Observable<KodiAlbum> in
                self.kodi.getAlbum(kodiSong.albumid)
            })
            .map({ (kodiAlbum) -> Album in
                kodiAlbum.album(kodiAddress: self.kodi.kodiAddress)
            })
    }
    
    /// Filter artists that exist in the library
    /// - Parameter artist: the set of artists to check
    /// - Returns: an observable of the filtered array of artists
    public func existingArtists(artists: [Artist]) -> Observable<[Artist]> {
        return Observable.just(artists)
    }
    
    public func diagnostics(album: Album) -> Observable<String> {
        return Observable.empty()
    }
    
    /// Search for the existance a certain item
    /// - Parameter searchItem: what to search for
    /// - Returns: an observable array of results
    public func search(searchItem: SearchItem) -> Observable<[FoundItem]> {
        let kodi = self.kodi
        switch searchItem {
        case let .artist(name):
            return kodi.getArtistId(name)
                .map { (id) -> [FoundItem] in
                    [FoundItem.artist(Artist(id: "\(id)", source: .Local, name: name))]
                }
        case let .artistAlbum(artist, sort):
            return kodi.getArtistId(artist)
                .flatMapFirst({ (id) -> Observable<[FoundItem]> in
                    return self.kodi.getAlbums(artistid: id, sort: ["order": sort == .yearReverse ? "descending" : "ascending", "method": "date"])
                        .map { (kodiAlbums) -> [FoundItem] in
                            kodiAlbums.albums.map { (kodiAlbum) -> FoundItem in
                                .album(kodiAlbum.album(kodiAddress: kodi.kodiAddress))
                            }
                        }
                })
        case let .album(album, artist):
            return kodi.searchAlbums(album, limit: 10)
                .map { (kodiAlbums) -> [FoundItem] in
                    kodiAlbums.compactMap { (kodiAlbum) -> FoundItem? in
                        if let artist = artist {
                            if kodiAlbum.displayartist == artist {
                                return .album(kodiAlbum.album(kodiAddress: kodi.kodiAddress))
                            }
                            return nil
                        }
                        return .album(kodiAlbum.album(kodiAddress: kodi.kodiAddress))
                    }
            }
        case let .genre(name):
            return kodi.getGenres()
                .map { (kodiGenres) -> [FoundItem] in
                    kodiGenres.genres.compactMap { (kodiGenre) -> FoundItem? in
                        kodiGenre.label.lowercased() == name.lowercased() ? .genre(kodiGenre.genre) : nil
                    }
            }
        case let .song(title, artist):
            return kodi.searchSongs(title, limit: 5)
                .map { (kodiSongs) -> [FoundItem] in
                    kodiSongs.compactMap { (kodiSong) -> FoundItem? in
                        if let artist = artist {
                            if kodiSong.albumartist.map({ $0.lowercased() }).contains(artist.lowercased()) {
                                return .song(kodiSong.song(kodiAddress: kodi.kodiAddress))
                            }
                            else {
                                return nil
                            }
                        }
                        else {
                            return .song(kodiSong.song(kodiAddress: kodi.kodiAddress))
                        }
                    }
            }
        default:
            return Observable.just([])
        }
    }
}

extension KodiSong {
    public func song(kodiAddress: KodiAddress) -> Song {
        var song = Song(id: "\(uniqueId)",
            source: .Local,
            location: file,
            title: label,
            album: album,
            artist: displayartist ?? "",
            albumartist: albumartist.count > 0 ? albumartist[0] : (displayartist ?? ""),
            composer: "",
            year: year,
            genre: genre,
            length: duration,
            quality: QualityStatus(),
            position: 0,
            track: track)
        if thumbnail != "", let url = kodiAddress.baseUrl {
            song.coverURI = CoverURI.fullPathURI("\(url)image/\(thumbnail.addingPercentEncoding(withAllowedCharacters: .letters)!)")
        }
        
        return song
    }
}

extension KodiAlbum {
    public func album(kodiAddress: KodiAddress) -> Album {
        var album = Album(id: "\(uniqueId)",
            source: .Local,
            location: "",
            title: label,
            artist: displayartist,
            year: year,
            genre: genre,
            length: 0,
            sortTitle: label,
            sortArtist: displayartist)
        if thumbnail != "", let url = kodiAddress.baseUrl {
            album.coverURI = CoverURI.fullPathURI("\(url)image/\(thumbnail.addingPercentEncoding(withAllowedCharacters: .letters)!)")
        }
        
        return album
    }
}

extension KodiArtist {
    var artist: Artist {
        return Artist(id: "\(uniqueId)", type: .artist, source: .Local, name: label, sortName: label)
    }
}

extension KodiGenre {
    var genre: Genre {
        return Genre(id: "\(uniqueId)", source: .Local, name: label)
    }
}

extension KodiSource {
    var folder: Folder {
        return Folder(id: file, source: .Local, path: file, name: label)
    }
}

extension KodiFile {
    public func folderContent(kodiAddress: KodiAddress) -> FolderContent? {
        if filetype == "directory" {
            return .folder(Folder(id: file, source: .Local, path: file, name: label))
        }
        else if filetype == "file" && type == "song" {
            guard let id = id else { return nil }
            
            let albumartistToUse: String
            if let albumartist = albumartist, albumartist.count > 0 {
                albumartistToUse = albumartist[0]
            }
            else {
                albumartistToUse = displayartist ?? ""
            }
            var song = Song(id: "\(id)",
                source: .Local,
                location: file,
                title: label,
                album: album ?? "",
                artist: displayartist ?? "",
                albumartist: albumartistToUse,
                composer: "",
                year: year ?? 0,
                genre: genre ?? [],
                length: duration ?? 0,
                quality: QualityStatus(),
                position: 0,
                track: track ?? 0)
            if thumbnail != "", let url = kodiAddress.baseUrl {
                song.coverURI = CoverURI.fullPathURI("\(url)image/\(thumbnail.addingPercentEncoding(withAllowedCharacters: .letters)!)")
            }
            
            return .song(song)
        }
        
        return nil
    }
}

extension SortType {
    var parameterArray: [String: Any] {
        switch self {
        case .artist:
            return ["method": "artist",
                    "order": "ascending",
                    "ignorearticle": true]
        case .title:
            return ["method": "title",
                    "order": "ascending"]
        case .year:
            return ["method": "year",
                    "order": "ascending"]
        case .yearReverse:
            return ["method": "year",
                    "order": "descending"]
        }
    }
}
