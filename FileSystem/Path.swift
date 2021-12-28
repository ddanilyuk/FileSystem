//
//  FileSystem+Path.swift
//  FileSystem
//
//  Created by Denys Danyliuk on 28.12.2021.
//

import Foundation

typealias ResolvedPath = (descriptor: Descriptor, route: [String])

final class Path {
    
    static var currentPath: String {
        return "/" + pathRoute.joined(separator: "/")
    }
    
    static var pathRoute: [String] = []
    
    static func resolve(
        path: String,
        descriptor: Descriptor? = nil,
        route: [String]? = nil,
        recursionCounter: Int =  0
    ) -> ResolvedPath {
        var recursionCounter = recursionCounter
        recursionCounter += 1
        
        guard recursionCounter < Constants.Common.maximumRecursionCounter else {
            fatalError("Reached maximum recursion")
        }
        
        switch path {
        case let currentPath where currentPath.starts(with: ".."):
            return resolveParent(
                path: path,
                descriptor: descriptor,
                route: route,
                recursionCounter: recursionCounter
            )
            
        case let currentPath where currentPath.starts(with: "."):
            return resolveCurrent(
                path: path,
                descriptor: descriptor,
                route: route,
                recursionCounter: recursionCounter
            )
            
        case let currentPath where currentPath.starts(with: "/"):
            return resolveRoot(
                path: path,
                descriptor: descriptor,
                route: route,
                recursionCounter: recursionCounter
            )
            
        default:
            return resolveDescriptor(
                path: path,
                descriptor: descriptor,
                route: route,
                recursionCounter: recursionCounter
            )
        }
    }
    
    static private func resolveParent(
        path: String,
        descriptor: Descriptor?,
        route: [String]?,
        recursionCounter: Int
    ) -> ResolvedPath {
        var route: [String] = route == nil ? Path.pathRoute : route!
        var pathParts = path.split(separator: "/", maxSplits: 1).map { String($0) }
        pathParts.removeFirst()
        route.removeLast()
        
        if pathParts.isEmpty {
            return (
                descriptor: descriptor?.parentDirectory ?? FileSystem.currentDirectory.parentDirectory,
                route: route
            )
        } else {
            return resolve(
                path: pathParts.joined(separator: "/"),
                descriptor: descriptor?.parentDirectory ?? FileSystem.currentDirectory.parentDirectory,
                route: route,
                recursionCounter: recursionCounter
            )
        }
    }
    
    static private func resolveCurrent(
        path: String,
        descriptor: Descriptor?,
        route: [String]?,
        recursionCounter: Int
    ) -> ResolvedPath {
        let route: [String] = route == nil ? Path.pathRoute : route!
        var pathParts = path
            .split(separator: "/", maxSplits: 1)
            .map { String($0) }
        pathParts.removeFirst()
        if pathParts.isEmpty {
            return (
                descriptor: descriptor ?? FileSystem.currentDirectory,
                route: route
            )
        } else {
            return resolve(
                path: pathParts.joined(separator: "/"),
                descriptor: descriptor ?? FileSystem.currentDirectory,
                route: route,
                recursionCounter: recursionCounter
            )
        }
    }
    
    static private func resolveRoot(
        path: String,
        descriptor: Descriptor?,
        route: [String]?,
        recursionCounter: Int
    ) -> ResolvedPath {
        let pathParts = path
            .split(separator: "/", maxSplits: 1)
            .map { String($0) }
        if pathParts.isEmpty {
            return (
                descriptor: FileSystem.rootDirectory,
                route: route ?? []
            )
        } else {
            return resolve(
                path: pathParts.joined(separator: "/"),
                descriptor: FileSystem.rootDirectory,
                route: [],
                recursionCounter: recursionCounter
            )
        }
    }
    
    static private func resolveDescriptor(
        path: String,
        descriptor: Descriptor?,
        route: [String]?,
        recursionCounter: Int
    ) -> ResolvedPath {
        var route: [String] = route == nil ? Path.pathRoute : route!
        let parentDirectory: Descriptor! = descriptor ?? FileSystem.currentDirectory
        
        var pathParts = path.split(separator: "/", maxSplits: 1).map { String($0) }
        let directoryName = pathParts.removeFirst()
        route.append(directoryName)
        
        let descriptorIndex = FileSystem.blocks[parentDirectory.linksBlocks[0]].getDescriptorIndex(with: directoryName)
        let newDescriptor = FileSystem.descriptors[descriptorIndex]
        
        let resolveWith: ((_ pathParts: String) -> ResolvedPath) = { pathParts in
            if pathParts.isEmpty {
                return (
                    descriptor: newDescriptor,
                    route: route
                )
            } else {
                return resolve(
                    path: pathParts,
                    descriptor: newDescriptor,
                    route: route,
                    recursionCounter: recursionCounter
                )
            }
        }
        
        switch newDescriptor.mode {
        case .directory:
            return resolveWith(pathParts.joined(separator: "/"))
            
        case .symlink:
            let data = FileSystem.blocks[newDescriptor.linksBlocks[0]].blockSpace.dataChunk
            let symlinkPath = data.toString.trim([.controlCharacters, .whitespaces])
            return resolveWith(symlinkPath + "/" + pathParts.joined(separator: "/"))
                        
        default:
            fatalError("Unable to find resolve path")
        }
    }
}
