//
//  FileSystem+Path.swift
//  FileSystem
//
//  Created by Denys Danyliuk on 28.12.2021.
//

import Foundation

class Path {
    
    static var currentPath: String {
        return "/" + pathRoute.joined(separator: "/")
    }
    
    static var pathRoute: [String] = []
    
    //    static func resolveV2(
    //        path: String,
    //        descriptor: Descriptor? = nil
    //    ) -> (Descriptor) {
    //        switch path {
    //        case let currentPath where currentPath.starts(with: ".."):
    //            var pathParts = path.split(separator: "/", maxSplits: 1).map { String($0) }
    //            pathParts.removeFirst()
    //            pathRoute.removeLast()
    //
    //            if pathParts.isEmpty {
    //                return descriptor ?? FileSystem.currentDirectory.parentDirectory
    //            } else {
    //                return resolveV2(
    //                    path: pathParts.joined(),
    //                    descriptor: FileSystem.currentDirectory.parentDirectory
    //                )
    //            }
    //
    //        case let currentPath where currentPath.starts(with: "."):
    //            var pathParts = path.split(separator: "/", maxSplits: 1).map { String($0) }
    //            pathParts.removeFirst()
    //            if pathParts.isEmpty {
    //                return descriptor ?? FileSystem.currentDirectory
    //            } else {
    //                return resolveV2(
    //                    path: pathParts.joined(),
    //                    descriptor: FileSystem.currentDirectory
    //                )
    //            }
    //
    //        case let currentPath where currentPath.starts(with: "/"):
    //            pathRoute = []
    //            return resolveV2(
    //                path: String(currentPath.dropFirst()),
    //                descriptor: FileSystem.rootDirectory
    //            )
    //
    //        default:
    //            let descriptor: Descriptor! = descriptor ?? FileSystem.currentDirectory
    //
    //            var pathParts = path.split(separator: "/", maxSplits: 1).map { String($0) }
    //            let directoryName = pathParts.removeFirst()
    //            pathRoute.append(directoryName)
    //
    //            let descriptorIndex = FileSystem.blocks[descriptor.linksBlocks[0]].getDescriptorIndex(with: directoryName)
    //            let newDescriptor = FileSystem.descriptors[descriptorIndex]
    //            guard newDescriptor.mode == .directory else {
    //                fatalError("This is not directory")
    //            }
    //            if pathParts.isEmpty {
    //                return newDescriptor
    //            } else {
    //                return resolveV2(
    //                    path: pathParts.joined(),
    //                    descriptor: newDescriptor
    //                )
    //            }
    //        }
    //    }
    
    static func resolveV3(
        path: String,
        descriptor: Descriptor? = nil,
        route: [String]? = nil,
        recursionCounter: Int = 0
    ) -> (
        descriptor: Descriptor,
        route: [String]
    ) {
        var recursionCounter = recursionCounter
        recursionCounter += 1
        
        guard recursionCounter < Constants.Common.maximumRecursionCounter else {
            fatalError("Reached maximum recursion")
        }
        
        switch path {
        case let currentPath where currentPath.starts(with: ".."):
            return resolveParent(path: path, descriptor: descriptor, route: route, recursionCounter: recursionCounter)
            
        case let currentPath where currentPath.starts(with: "."):
            return resolveCurrent(path: path, descriptor: descriptor, route: route, recursionCounter: recursionCounter)
            
        case let currentPath where currentPath.starts(with: "/"):
            return resolveRoot(path: path, descriptor: descriptor, route: route, recursionCounter: recursionCounter)
            
        default:
            return resolveDirectory(path: path, descriptor: descriptor, route: route, recursionCounter: recursionCounter)
        }
    }
    
    static func resolveParent(
        path: String,
        descriptor: Descriptor?,
        route: [String]?,
        recursionCounter: Int
    ) -> (
        descriptor: Descriptor,
        route: [String]
    ) {
        var route = route
        var pathParts = path.split(separator: "/", maxSplits: 1).map { String($0) }
        pathParts.removeFirst()
        route?.removeLast()
        
        if pathParts.isEmpty {
            return (
                descriptor: descriptor ?? FileSystem.currentDirectory.parentDirectory,
                route: route ?? []
            )
        } else {
            return resolveV3(
                path: pathParts.joined(separator: "/"),
                descriptor: FileSystem.currentDirectory.parentDirectory,
                route: route,
                recursionCounter: recursionCounter
            )
        }
    }
    
    static func resolveCurrent(
        path: String,
        descriptor: Descriptor?,
        route: [String]?,
        recursionCounter: Int
    ) -> (
        descriptor: Descriptor,
        route: [String]
    ) {
        var pathParts = path
            .split(separator: "/", maxSplits: 1)
            .map { String($0) }
        pathParts.removeFirst()
        if pathParts.isEmpty {
            return (
                descriptor: descriptor ?? FileSystem.currentDirectory,
                route: route ?? []
            )
        } else {
            return resolveV3(
                path: pathParts.joined(separator: "/"),
                descriptor: FileSystem.currentDirectory,
                route: route,
                recursionCounter: recursionCounter
            )
        }
    }
    
    static func resolveRoot(
        path: String,
        descriptor: Descriptor?,
        route: [String]?,
        recursionCounter: Int
    ) -> (
        descriptor: Descriptor,
        route: [String]
    ) {
        let pathParts = path
            .split(separator: "/", maxSplits: 1)
            .map { String($0) }
        if pathParts.isEmpty {
            return (
                descriptor: descriptor ?? FileSystem.rootDirectory,
                route: route ?? []
            )
        } else {
            return resolveV3(
                path: pathParts.joined(separator: "/"),
                descriptor: FileSystem.rootDirectory,
                route: [],
                recursionCounter: recursionCounter
            )
        }
    }
    
    static func resolveDirectory(
        path: String,
        descriptor: Descriptor?,
        route: [String]?,
        recursionCounter: Int
    ) -> (
        descriptor: Descriptor,
        route: [String]
    ) {
        var route = route
        let parentDirectory: Descriptor! = descriptor ?? FileSystem.currentDirectory
        
        var pathParts = path.split(separator: "/", maxSplits: 1).map { String($0) }
        let directoryName = pathParts.removeFirst()
        route?.append(directoryName)
        
        let descriptorIndex = FileSystem.blocks[parentDirectory.linksBlocks[0]].getDescriptorIndex(with: directoryName)
        let newDescriptor = FileSystem.descriptors[descriptorIndex]
        
        let resolve: ((String) -> (descriptor: Descriptor, route: [String])) = { pathParts in
            if pathParts.isEmpty {
                return (
                    descriptor: newDescriptor,
                    route: route ?? []
                )
            } else {
                return resolveV3(
                    path: pathParts,
                    descriptor: newDescriptor,
                    route: route,
                    recursionCounter: recursionCounter
                )
            }
        }
        
        switch newDescriptor.mode {
        case .directory:
            return resolve(pathParts.joined(separator: "/"))
            
        case .symlink:
            let data = FileSystem.blocks[newDescriptor.linksBlocks[0]].blockSpace.dataChunk
            let symlinkPath = data.toString.trim([.controlCharacters, .whitespaces])
            return resolve(symlinkPath + "/" + pathParts.joined(separator: "/"))
                        
        default:
            fatalError("Unable to find resolve path")
        }
    }
}
