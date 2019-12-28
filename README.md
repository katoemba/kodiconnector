# README #

## What is this repository for? ##

* KodiConnector is an implementation of the generic ConnectorProtocol interface specification to control a kodi based music player.
* This framework is used the Rigelian music remote client, for more info see https://www.rigelian.net

## What are the building blocks of this Library? ##

* The implementation relies heavily on reactive constructs, using RxSwift.
* ConnectorProtocol consist of five sub-protocols, all of which are implemented in this framework:
	  * PlayerProtocol defines a basic player, access status, control and browse implementation, plus functions to maintain player-specific settings.
	  * PlayerBrowserProtocol is a generic protocol to detect players on the network.
	  * StatusProtocol is a protocol through which the connection status of a player, as well as the music-playing status can be monitored.
	  * ControlProtocol is a protocol through which commands can be sent to a player, like play, pause, add a song etc.
	  * BrowseProtocol is a protocol through which you can browse through the music on a player. It defines various ViewModels for artists, albums, genres etc.
* The protocol is meant to be independent of the target platform (iOS, MacOS, tvOS).

## Installation

KodiConnector depends on
* ConnectorProtocol, the generic music player protocol it implements
* RxSwift as the reactive framework
* Alamofire for making json-rpc requests to the player
* Starscream to receive status updates from the player via websockets

Build and usage via swift package manager is supported:

### [Swift Package Manager](https://github.com/apple/swift-package-manager)

The easiest way to add the library is directly from within XCode (11). Alternatively you can create a `Package.swift` file. 

```swift
// swift-tools-version:5.0

import PackageDescription

let package = Package(
  name: "MyProject",
  dependencies: [
  .package(url: "https://github.com/katoemba/kodiconnector.git", from: "1.7.0")
  ],
  targets: [
    .target(name: "MyProject", dependencies: ["kodiconnector"])
  ]
)
```
## Testing ##

* There are currently not tests :-(.

## Who do I talk to? ##

* In case of questions you can contact berrie at rigelian dot net
