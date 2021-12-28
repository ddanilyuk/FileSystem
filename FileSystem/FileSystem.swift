//
//  FileSystem.swift
//  FileSystem
//
//  Created by Denys Danyliuk on 10.12.2021.
//

import Foundation

final class FileSystem {
    
    // MARK: - Properties
    
    /// Bit for blocks
    static var blocksBitMap: BitMap!

    /// All blocks
    static var blocks: [Block]!
    
    /// All descriptors
    static var descriptors: [Descriptor] = []
    
    /// `[numericOpenedFileDescriptor : fileDescriptorIndex]`
    /// Call this number "numeric file descriptor". To work with an open file (this number is not the same as the descriptor number that identifies the file in the FS.
    static var openedFiles: [Int: Int] = [:]
    
    // MARK: - Computed property
    
    static var rootDirectory: Descriptor {
        descriptors.first!
    }
    
    static var currentDirectory: Descriptor!
    
    static var currentDirectoryBlock: Block {
        blocks[currentDirectory.linksBlocks[0]]
    }
    
    // MARK: - Lifecycle
        
    private init() { }    
    
    static func generateDescriptors(
        _ numberOfDescriptors: Int
    ) {
        descriptors = (0..<numberOfDescriptors).map { _ in
            Descriptor(
                isUsed: false,
                mode: .none,
                refCount: 0,
                size: 0,
                linksBlocks: []
            )
        }
        generateRootDirectory()
    }
    
    static func generateRootDirectory() {
        let emptyBlockId = blocksBitMap.firstEmpty()
        blocks[emptyBlockId].mode = .mappings
        descriptors[0].initiateAsDirectory([emptyBlockId])
        currentDirectory = rootDirectory
        rootDirectory.parentDirectory = rootDirectory
    }
    
    static func generateBlocksBitMap() -> BitMap {
        BitMap(size: Constants.Block.amount)
    }
    
    static func generateBlocks() -> [Block] {
        let byteArray = ByteArray(
            size: Constants.Block.amount * Constants.Block.size
        )
        return (0..<Constants.Block.amount)
            .map { index in
                let startBlockSpace = Constants.Block.size * index
                let endBlockSpace = Constants.Block.size * index + Constants.Block.size
                return Block(
                    mode: .none,
                    blockSpace: Array(byteArray[startBlockSpace..<endBlockSpace])
                )
            }
    }
}

// MARK: - Console commands

extension FileSystem {
    
    static func mountFromMemory() {
        blocksBitMap = generateBlocksBitMap()
        blocks = generateBlocks()
    }
    
    static func umount() {
        openedFiles = [:]
        descriptors = []
        blocksBitMap = nil
        blocks = nil
    }
    
    static func fstab(
        descriptorIndex: Int
    ) -> Descriptor {
        if let descriptor = descriptors[safe: descriptorIndex] {
            return descriptor
        } else {
            fatalError("Not found")
        }
    }
    
    static func ls() -> [LSCommand.LineModel] {
        currentDirectoryBlock
            .filesMappings
            .map { fileName, descriptorIndex in
                let descriptor = descriptors[descriptorIndex]
                return LSCommand.LineModel(
                    fileName: fileName,
                    mode: descriptor.mode,
                    referenceCount: descriptor.referenceCount,
                    descriptorIndex: descriptorIndex,
                    size: descriptor.size
                )
            }
    }
    
    static func mappingBlock(
        for descriptor: Descriptor
    ) -> Block {
        return blocks[descriptor.linksBlocks[0]]
    }
}

// MARK: - Directories

extension FileSystem {
    
    static func mkdir(
        _ path: String
    ) {
        let (dirName, pathToDirectory) = path.withoutLastPathComponent
        let pathResolver = Path.resolveV3(path: pathToDirectory)
        let (descriptorIndex, descriptor) = findFreeDescriptor()
        let emptyBlockId = blocksBitMap.firstEmpty()
        blocks[emptyBlockId].mode = .mappings
        descriptor.initiateAsDirectory([emptyBlockId])
        descriptor.parentDirectory = pathResolver.descriptor
        mappingBlock(for: pathResolver.descriptor).createFileMapping(
            fileName: dirName,
            descriptorIndex: descriptorIndex
        )
    }
    
    static func rmdir(
        _ path: String
    ) {
        let (dirName, pathToDirectory) = path.withoutLastPathComponent
        let pathResolver = Path.resolveV3(path: pathToDirectory)
        let (_, descriptor) = getDescriptor(
            with: dirName,
            from: pathResolver.descriptor
        )
        
        guard blocks[descriptor.linksBlocks[0]].blockSpace.isClear else {
            fatalError("This directory is not clear")
        }
        blocks[descriptor.parentDirectory.linksBlocks[0]].deleteFileMapping(with: dirName)
        descriptor.linksBlocks.forEach { blocksBitMap.reset(position: $0) }
        descriptor.free()
    }
    
    static func cd(
        _ path: String
    ) {
        let pathResolver = Path.resolveV3(path: path)
        Path.pathRoute = pathResolver.route
        currentDirectory = pathResolver.descriptor
    }
    
    static func simlink(
        str: String,
        path: String
    ) {
        let (fileName, pathToDirectory) = path.withoutLastPathComponent
        let pathResolver = Path.resolveV3(path: pathToDirectory)
        let (descriptorIndex, descriptor) = findFreeDescriptor()
        let emptyBlockId = blocksBitMap.firstEmpty()
        let newBlock = blocks[emptyBlockId]
        newBlock.mode = .symlink
        descriptor.initiateAsSymlink([emptyBlockId])
        descriptor.parentDirectory = pathResolver.descriptor
        mappingBlock(for: pathResolver.descriptor).createFileMapping(
            fileName: fileName,
            descriptorIndex: descriptorIndex
        )
        guard str.count <= Constants.Block.size else {
            fatalError("Symlink is too large")
        }
        newBlock.setData(data: str.toBytes, offset: 0)
    }
}

// MARK: - Create

extension FileSystem {

    static func createFile(
        with path: String
    ) {
        let (fileName, pathToDirectory) = path.withoutLastPathComponent
        let pathResolver = Path.resolveV3(path: pathToDirectory)
        
        let (descriptorIndex, descriptor) = findFreeDescriptor()
        print("Find free descriptor with index: \(descriptorIndex)")
        descriptor.initiateAsFile()
        descriptor.referenceCount += 1
        mappingBlock(for: pathResolver.descriptor).createFileMapping(
            fileName: fileName,
            descriptorIndex: descriptorIndex
        )
    }
}

// MARK: - Open/Close

extension FileSystem {
    
    @discardableResult
    static func openFile(
        with path: String
    ) -> Int {
        let (fileName, pathToDirectory) = path.withoutLastPathComponent
        let pathResolver = Path.resolveV3(path: pathToDirectory)
        
        let numericOpenedFileDescriptor = openedFiles.uniqueKey
        openedFiles[numericOpenedFileDescriptor] = getDescriptor(
            with: fileName,
            from: pathResolver.descriptor
        ).descriptorIndex
        return numericOpenedFileDescriptor
    }
    
    static func closeFile(
        with numericOpenedFileDescriptor: Int
    ) {
        guard
            openedFiles[numericOpenedFileDescriptor] != nil
        else {
            fatalError("File is closed")
        }
        openedFiles.removeValue(forKey: numericOpenedFileDescriptor)
    }
}

// MARK: - Write

extension FileSystem {
    
    static func writeFile(
        to numericOpenedFileDescriptor: Int,
        offset: Int,
        data: String
    ) {
        guard
            let descriptorIndex = openedFiles[numericOpenedFileDescriptor]
        else {
            fatalError("File is closed")
        }
        let descriptor = descriptors[descriptorIndex]
        writeData(to: descriptor, offset: offset, data: data)
        descriptor.updateSize()
    }
    
    static private func writeData(
        to descriptor: Descriptor,
        offset: Int,
        data: String
    ) {
        switch descriptor.mode {
        case .file:
            let totalSize = offset + data.count
            
            // Allocate enough blocks
            if totalSize > descriptor.size {
                let delta = totalSize - descriptor.size
                let numberOfNeededBlocksToAllocate = CGFloat.roundUp(CGFloat(delta) / CGFloat(Constants.Block.dataSize))
                (0..<numberOfNeededBlocksToAllocate).forEach { _ in allocateNewBlock(for: descriptor, newBlockIndex: blocksBitMap.firstEmpty()) }
            }
            
            var blocksToWrite = getBlocks(
                from: descriptor,
                with: offset,
                totalSize: totalSize
            )
            var dataChunks = data.toBytes.chunked(into: Constants.Block.dataSize)
            
            // Set data
            blocksToWrite.removeFirst().setData(data: dataChunks.removeFirst(), offset: offset)
            zip(blocksToWrite, dataChunks).forEach { $0.setData(data: $1, offset: 0) }
            
        default:
            fatalError("Unable to write not for file")
        }
    }
}

// MARK: - Read

extension FileSystem {
    
    static func readFile(
        from numericOpenedFileDescriptor: Int,
        offset: Int = 0,
        size: Int?
    ) -> String? {
        guard
            let descriptorIndex = openedFiles[numericOpenedFileDescriptor]
        else {
            fatalError("File is closed")
        }
        
        let descriptor = descriptors[descriptorIndex]
        
        switch descriptor.mode {
        case .file:
            // Read all if nil
            let size = size ?? descriptor.size
            guard
                offset + size <= descriptor.size
            else {
                fatalError("Offset is bigger than size")
            }
            return readFrom(descriptor, offset: offset, size: size).toString
            
        default:
            fatalError("Unable to read not a file")
        }
    }
    
    static private func readFrom(
        _ descriptor: Descriptor,
        offset: Int,
        size: Int
    ) -> ByteArray {
        let blocksToRead = getBlocks(
            from: descriptor,
            with: offset,
            totalSize: offset + size
        )
        let blocksSpaces = blocksToRead
            .map { $0.blockSpace.dataChunk }
            .joined()
        return Array(Array(blocksSpaces)[offset..<offset + size])
    }
}

// MARK: - Truncate

extension FileSystem {
    
    static func truncateFile(with path: String, to size: Int) {
        
        let (fileName, pathToDirectory) = path.withoutLastPathComponent
        let pathResolver = Path.resolveV3(path: pathToDirectory)

        let descriptor = getDescriptor(with: fileName, from: pathResolver.descriptor).descriptor
        
        switch descriptor.size {
        case let currentSize where currentSize < size:
            let neededBlocksCount = CGFloat.roundUp(CGFloat(size - descriptor.size) / CGFloat(Constants.Block.dataSize))
            (0..<neededBlocksCount).forEach { _ in allocateNewBlock(for: descriptor, newBlockIndex: blocksBitMap.firstEmpty()) }
            descriptor.updateSize()
            
        case let currentSize where currentSize > size:
            // Delete blocks
            let neededBlocksCount = CGFloat.roundUp(CGFloat(size) / CGFloat(Constants.Block.dataSize))
            let deletedBlocks = descriptor.linksBlocks.removeLast(descriptor.linksBlocks.count - neededBlocksCount)
            deletedBlocks.forEach { blocksBitMap.reset(position: $0) }
            // Clean last block
            if let lastBlockIndex = descriptor.linksBlocks.last {
                let lastBlock = blocks[lastBlockIndex]
                let lastBlockTruncateOffset = size % Constants.Block.dataSize
                // Remove data
                lastBlock.setData(
                    data: ByteArray(size: Constants.Block.dataSize - lastBlockTruncateOffset),
                    offset: lastBlockTruncateOffset
                )
                // Remove link
                lastBlock.setData(
                    data: ByteArray(size: Constants.Common.intSize),
                    offset: Constants.Block.dataSize
                )
            }
            descriptor.updateSize()
            
        default:
            print("Size remains the same")
        }
    }
}

// MARK: - Links

extension FileSystem {

    static func link(
        to path: String,
        linkName: String
    ) {
        let (fileName, pathToDirectory) = path.withoutLastPathComponent
        let route = Path.resolveV3(path: pathToDirectory)

        let descriptorIndex = getDescriptor(with: fileName, from: route.descriptor).descriptorIndex
        currentDirectoryBlock.createFileMapping(
            fileName: linkName,
            descriptorIndex: descriptorIndex
        )
        descriptors[descriptorIndex].referenceCount += 1
    }
    
    static func unlink(
        name: String
    ) {
        let descriptor = descriptors[currentDirectoryBlock.getDescriptorIndex(with: name)]
        currentDirectoryBlock.deleteFileMapping(with: name)
        descriptor.referenceCount -= 1
        
        if descriptor.referenceCount == 0 {
            print("Removing descriptor because it has no references")
            descriptor.linksBlocks.forEach { blocksBitMap.reset(position: $0) }
            descriptor.free()
        }
    }
}

// MARK: - Private methods

extension FileSystem {
    
    static private func findFreeDescriptor() -> (
        descriptorIndex: Int,
        descriptor: Descriptor
    ) {
        guard
            let (descriptorIndex, descriptor) = descriptors.enumerated().first(where: { !$1.isUsed })
        else {
            fatalError("No available descriptors")
        }
        return (descriptorIndex: descriptorIndex, descriptor: descriptor)
    }
    
    static private func getDescriptor(
        with name: String,
        from directory: Descriptor
    ) -> (
        descriptorIndex: Int,
        descriptor: Descriptor
    ) {
        let descriptorIndex = mappingBlock(for: directory).getDescriptorIndex(with: name)
        return (
            descriptorIndex: descriptorIndex,
            descriptor: descriptors[descriptorIndex]
        )
    }
    
    static private func getBlocks(
        from descriptor: Descriptor,
        with offset: Int,
        totalSize: Int
    ) -> [Block] {
        let firstBlockIndex = offset / Constants.Block.dataSize
        let lastBlockIndex = CGFloat.roundUp(CGFloat(totalSize) / CGFloat(Constants.Block.dataSize))
        return (firstBlockIndex..<lastBlockIndex).map { blocks[descriptor.linksBlocks[$0]] }
    }
    
    static private func allocateNewBlock(
        for descriptor: Descriptor,
        newBlockIndex: Int
    ) {
        if let lastBlockIndex = descriptor.linksBlocks.last {
            blocks[lastBlockIndex].blockSpace.replaceSubrange(
                (Constants.Block.dataSize..<Constants.Block.size),
                with: newBlockIndex.toBytes
            )
        }
        blocks[newBlockIndex].mode = .dataAndLink
        descriptor.linksBlocks.append(newBlockIndex)
    }
}
