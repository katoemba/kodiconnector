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
        guard let albumId = Int(album.id) else {
            return Observable.empty()
        }
        
        return kodi.getSongsOnAlbum(albumId)
            .map({ [weak self] (kodiSongs) -> [Song] in
                guard let weakSelf = self else { return [] }

                return kodiSongs.map({ (kodiSong) -> Song in
                    kodiSong.song(kodiAddress: weakSelf.kodi.kodiAddress)
                })
            })
    }
    
    public func songsInPlaylist(_ playlist: Playlist) -> Observable<[Song]> {
//        return kodi.getSongsInPlaylist(playlist)
//            .map({ (kodiSongs) -> [Song] in
//                kodiSongs.map({ (kodiSong) -> Song in
//                    kodiSong.song
//                })
//            })
        return Observable.empty()
    }
    
    public func search(_ search: String, limit: Int, filter: [SourceType]) -> Observable<SearchResult> {
        return Observable.empty()
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
        return KodiArtistBrowseViewModel(kodi: kodi)
    }
    
    public func artistBrowseViewModel(_ artists: [Artist]) -> ArtistBrowseViewModel {
        return KodiArtistBrowseViewModel(kodi: kodi)
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

extension KodiSong {
    public func song(kodiAddress: KodiAddress) -> Song {
        var song = Song(id: "\(uniqueId)",
            source: .Local,
            location: file,
            title: label,
            album: album,
            artist: displayartist,
            albumartist: albumartist.count > 0 ? albumartist[0] : displayartist,
            composer: "",
            year: year,
            genre: genre,
            length: duration,
            quality: QualityStatus(samplerate: "", encoding: "", channels: "", filetype: ""),
            position: 0,
            track: track)
        if thumbnail != "" {
            song.coverURI = CoverURI.fullPathURI("\(kodiAddress.baseUrl)image/\(thumbnail.addingPercentEncoding(withAllowedCharacters: .letters)!)")
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
        if thumbnail != "" {
            album.coverURI = CoverURI.fullPathURI("\(kodiAddress.baseUrl)image/\(thumbnail.addingPercentEncoding(withAllowedCharacters: .letters)!)")
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
                quality: QualityStatus(samplerate: "", encoding: "", channels: "", filetype: ""),
                position: 0,
                track: track ?? 0)
            if thumbnail != "" {
                song.coverURI = CoverURI.fullPathURI("\(kodiAddress.baseUrl)image/\(thumbnail.addingPercentEncoding(withAllowedCharacters: .letters)!)")
            }

            return .song(song)
        }
        
        return nil
    }
}
