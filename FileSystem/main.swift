//
//  main.swift
//  FileSystem
//
//  Created by Denys Danyliuk on 10.12.2021.
//

import Foundation



class Path {
    
    static var currentPath: String {
        return "/" + pathRoute.joined(separator: "/")
    }
    
    static var pathRoute: [String] = []
    
    static func resolveV2(
        path: String,
        descriptor: Descriptor? = nil
    ) -> Descriptor {
        switch path {
        case let currentPath where currentPath.starts(with: ".."):
            var pathParts = path.split(separator: "/", maxSplits: 1).map { String($0) }
            pathParts.removeFirst()
            pathRoute.removeLast()
            
            if pathParts.isEmpty {
                return descriptor ?? FileSystem.currentDirectory.parentDirectory
            } else {
                return resolveV2(
                    path: pathParts.joined(),
                    descriptor: FileSystem.currentDirectory.parentDirectory
                )
            }
            
        case let currentPath where currentPath.starts(with: "."):
            var pathParts = path.split(separator: "/", maxSplits: 1).map { String($0) }
            pathParts.removeFirst()
            if pathParts.isEmpty {
                return descriptor ?? FileSystem.currentDirectory
            } else {
                return resolveV2(
                    path: pathParts.joined(),
                    descriptor: FileSystem.currentDirectory
                )
            }
            
        case let currentPath where currentPath.starts(with: "/"):
            pathRoute = []
            return resolveV2(
                path: String(currentPath.dropFirst()),
                descriptor: FileSystem.rootDirectory
            )
            
        default:
            let descriptor: Descriptor! = descriptor ?? FileSystem.currentDirectory
            
            var pathParts = path.split(separator: "/", maxSplits: 1).map { String($0) }
            let directoryName = pathParts.removeFirst()
            pathRoute.append(directoryName)
            
            let descriptorIndex = FileSystem.blocks[descriptor.linksBlocks[0]].getDescriptorIndex(with: directoryName)
            let newDescriptor = FileSystem.descriptors[descriptorIndex]
            guard newDescriptor.mode == .directory else {
                fatalError("This is not directory")
            }
            if pathParts.isEmpty {
                return newDescriptor
            } else {
                return resolveV2(
                    path: pathParts.joined(),
                    descriptor: newDescriptor
                )
            }
        }
    }
    
    
    static func resolve(_ path: String) -> Descriptor {
        
        var currentDescriptor = FileSystem.rootDirectory
        
        if path.starts(with: "..") {
            // Resolve from parent directory
            let parts = path.dropFirst(2).split(separator: "/").map { String($0) }
            pathRoute.removeLast()
            pathRoute.append(contentsOf: parts)
            return getNewDescriptor(from: FileSystem.currentDirectory.parentDirectory, parts: parts)
            
        } else if path.starts(with: ".") {
            // Resolve from current directory
            let parts = path.dropFirst(2).split(separator: "/").map { String($0) }
            pathRoute.append(contentsOf: parts)
            return getNewDescriptor(from: FileSystem.currentDirectory, parts: parts)

        } else if path.first == "/" {
            // Resolve absolute path
            let parts = path.dropFirst().split(separator: "/").map { String($0) }
            pathRoute = parts
            return getNewDescriptor(from: FileSystem.rootDirectory, parts: parts)
            
        } else {
            // Resolve relative path
            let parts = path.split(separator: "/").map { String($0) }
            pathRoute.append(contentsOf: parts)
            return getNewDescriptor(from: FileSystem.currentDirectory, parts: parts)
        }
    }
    

    
    static private func getNewDescriptor(
        from currentDescriptor: Descriptor,
        parts: [String]
    ) -> Descriptor {
        var newDescriptor = currentDescriptor
        for part in parts {
            let descriptorIndex = FileSystem.blocks[currentDescriptor.linksBlocks[0]]
                .getDescriptorIndex(with: String(part))
            let descriptor = FileSystem.descriptors[descriptorIndex]
            if descriptor.mode == .directory {
                newDescriptor = descriptor
            }
        }
        return newDescriptor
    }
}




FileSystem.mountFromMemory()
FileSystem.generateDescriptors(10)

MountCommand.execute()

MKFSCommand.execute(10)

MKDirCommand.execute("test")
MKDirCommand.execute("hello")
MKDirCommand.execute("world")

CDCommand.execute("/test")

MKDirCommand.execute("foo")
MKDirCommand.execute("foo2")

CDCommand.execute("foo")
CDCommand.execute("./..")


LSCommand.execute()

DebugCommand.execute()

//let path1 = Path.resolve("/test")
////print(FileSystem.descriptors.firstIndex(where: { $0.linksBlocks == some.linksBlocks }))
//FileSystem.currentDirectory = path1
//
//LSCommand.execute()
//
//let path2 = Path.resolve("foo")
////print(FileSystem.descriptors.firstIndex(where: { $0.linksBlocks == some.linksBlocks }))
//FileSystem.currentDirectory = path2
//
//LSCommand.execute()
//DebugCommand.execute()


//print(some.)

//
//Tests.testCreateWriteReadFile()
//
//Tests.testCreate4Files()
//
//Tests.testBigFile()
//
//Tests.testOffset()
//
//Tests.testTruncate()
//
//Tests.testLinks()
