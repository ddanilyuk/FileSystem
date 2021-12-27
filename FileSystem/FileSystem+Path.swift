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
        route: [String]? = nil
    ) -> (
        descriptor: Descriptor,
        route: [String]
    ) {
        switch path {
        case let currentPath where currentPath.starts(with: ".."):
            return resolveParent(path: path, descriptor: descriptor, route: route)
            
        case let currentPath where currentPath.starts(with: "."):
            return resolveCurrent(path: path, descriptor: descriptor, route: route)
            
        case let currentPath where currentPath.starts(with: "/"):
            return resolveRoot(path: path, descriptor: descriptor, route: route)

        default:
            return resolveDirectory(path: path, descriptor: descriptor, route: route)
        }
    }
    
    static func resolveParent(
        path: String,
        descriptor: Descriptor? = nil,
        route: [String]? = nil
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
                route: route
            )
        }
    }
    
    static func resolveCurrent(
        path: String,
        descriptor: Descriptor? = nil,
        route: [String]? = nil
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
                path: pathParts.joined(),
                descriptor: FileSystem.currentDirectory,
                route: route
            )
        }
    }
    
    static func resolveRoot(
        path: String,
        descriptor: Descriptor? = nil,
        route: [String]? = nil
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
                route: []
            )
        }
    }
    
    static func resolveDirectory(
        path: String,
        descriptor: Descriptor? = nil,
        route: [String]? = nil
    ) -> (
        descriptor: Descriptor,
        route: [String]
    ) {
        var route = route
        let descriptor: Descriptor! = descriptor ?? FileSystem.currentDirectory
        
        var pathParts = path.split(separator: "/", maxSplits: 1).map { String($0) }
        let directoryName = pathParts.removeFirst()
        route?.append(directoryName)
        
        let descriptorIndex = FileSystem.blocks[descriptor.linksBlocks[0]].getDescriptorIndex(with: directoryName)
        let newDescriptor = FileSystem.descriptors[descriptorIndex]
        guard newDescriptor.mode == .directory else {
            fatalError("This is not directory")
        }
        if pathParts.isEmpty {
            return (
                descriptor: newDescriptor,
                route: route ?? []
            )
        } else {
            return resolveV3(
                path: pathParts.joined(separator: "/"),
                descriptor: newDescriptor,
                route: route
            )
        }
    }
}
