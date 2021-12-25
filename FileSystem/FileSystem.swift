//
//  FileSystem.swift
//  FileSystem
//
//  Created by Denys Danyliuk on 10.12.2021.
//

import Foundation

final class FileSystem {
    
    // MARK: - Properties
        
    static var blocksBitMap: BitMap!
    
    static var blocks: [Block]!
    
    static var descriptors: [Descriptor] = []
    
    /// `[numericOpenedFileDescriptor : fileDescriptorIndex]`
    /// Call this number "numeric file descriptor". To work with an open file (this number is not the same as the descriptor number that identifies the file in the FS.
    static var openedFiles: [Int: Int] = [:]
    
    // MARK: - Computed property
    
    static var rootDirectory: Descriptor {
        descriptors.first!
    }
    static var rootBlock: Block {
        blocks[rootDirectory.linksBlocks[0]]
    }
    
    // MARK: - Lifecycle
        
    private init() { }    
    
    static func generateDescriptors(_ numberOfDescriptors: Int) {
        
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
        
        let descriptor = descriptors[0]
        let emptyBlockId = blocksBitMap.firstEmpty()
        blocks[emptyBlockId].mode = .mappings
        descriptor.isUsed = true
        descriptor.mode = .directory
        descriptor.referenceCount = 1
        descriptor.linksBlocks = [emptyBlockId]
        descriptor.size = 0
    }
    
    static func generateBlocksBitMap() -> BitMap {
        BitMap(size: Constants.numberOfBlocks)
    }
    
    static func generateBlocks() -> [Block] {
        let byteArray = ByteArray(
            repeating: 0,
            count: Constants.numberOfBlocks * Constants.blockSize
        )
        return (0..<Constants.numberOfBlocks).map { index in
            let startBlockSpace = Constants.blockSize * index
            let endBlockSpace = Constants.blockSize * index + Constants.blockSize
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
    
    static func fstab(descriptorIndex: Int) -> Descriptor {
        if let descriptor = descriptors[safe: descriptorIndex] {
            return descriptor
        } else {
            fatalError("Not found")
        }
    }
    
    static func ls() -> [LSCommand.LineModel] {
        rootBlock
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
}

// MARK: - Create

extension FileSystem {

    static func createFile(with name: String) {
        let (descriptorIndex, descriptor) = getEmptyDescriptor()
        print("Find free descriptor with id: \(descriptorIndex)")
        descriptor.initiateAsFile()
        rootBlock.createFileMapping(
            fileName: name,
            descriptorIndex: descriptorIndex
        )
        descriptor.referenceCount = 1
    }
    
    @discardableResult
    static func openFile(with name: String) -> Int {
        let numericOpenedFileDescriptor = openedFiles.uniqueKey
        openedFiles[numericOpenedFileDescriptor] = getDescriptor(with: name).descriptorIndex
        return numericOpenedFileDescriptor
    }
    
    static func closeFile(with numericOpenedFileDescriptor: Int) {
        guard
            openedFiles[numericOpenedFileDescriptor] != nil
        else {
            fatalError("File was not opened")
        }
        openedFiles.removeValue(forKey: numericOpenedFileDescriptor)
        print("File closed")
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
            fatalError("File was not opened")
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
        guard
            descriptor.mode == .file
        else {
            fatalError("Unable to write not for file")
        }
        let totalSize = offset + data.count
        
        // Allocate enough blocks for write if needed
        if totalSize > descriptor.size {
            let delta = totalSize - descriptor.size
            let numberOfNeededBlocksToAllocate = CGFloat.roundUp(CGFloat(delta) / CGFloat(Constants.linkedBlockSize))
            (0..<numberOfNeededBlocksToAllocate).forEach { _ in allocateNewBlock(for: descriptor, newBlockIndex: blocksBitMap.firstEmpty()) }
        }
        
        var blocksToWrite = getBlocks(
            from: descriptor,
            with: offset,
            totalSize: totalSize
        )
        var dataChunks = Array(data.utf8).chunked(into: Constants.linkedBlockSize)
        
        // Set data
        blocksToWrite.removeFirst().setData(data: dataChunks.removeFirst(), offset: offset)
        zip(blocksToWrite, dataChunks).forEach { $0.setData(data: $1, offset: 0) }
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
            fatalError("File was not opened")
        }
        
        let descriptor = descriptors[descriptorIndex]
        
        // Read all if nil
        let size = size ?? descriptor.size
        
        guard
            offset + size <= descriptor.size
        else {
            fatalError("Offset is bigger than size")
        }
                
        return readFrom(descriptor, offset: offset, size: size).toString
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
            .map { $0.blockSpace[..<Constants.linkedBlockSize] }
            .joined()
        return Array(Array(blocksSpaces)[offset..<offset + size])
    }
}

// MARK: - Truncate

extension FileSystem {
    
    static func truncateFile(with name: String, to size: Int) {
        
        let descriptor = getDescriptor(with: name).descriptor
        
        if size > descriptor.size {
            let neededBlocksCount = CGFloat.roundUp(CGFloat(size - descriptor.size) / CGFloat(Constants.linkedBlockSize))
            (0..<neededBlocksCount).forEach { _ in allocateNewBlock(for: descriptor, newBlockIndex: blocksBitMap.firstEmpty()) }
            descriptor.updateSize()
            
        } else if size < descriptor.size {
            // Delete blocks
            let neededBlocksCount = CGFloat.roundUp(CGFloat(size) / CGFloat(Constants.linkedBlockSize))
            let deletedBlocks = descriptor.linksBlocks.removeLast(descriptor.linksBlocks.count - neededBlocksCount)
            deletedBlocks.forEach { blocksBitMap.reset(position: $0) }
            // Clean last block
            if let lastBlockIndex = descriptor.linksBlocks.last {
                let lasBlock = blocks[lastBlockIndex]
                let lastBlockTruncateOffset = size % Constants.linkedBlockSize
                // Remove data
                lasBlock.setData(
                    data: ByteArray(size: Constants.linkedBlockSize - lastBlockTruncateOffset),
                    offset: lastBlockTruncateOffset
                )
                // Remove link
                lasBlock.setData(
                    data: ByteArray(size: Constants.intSize),
                    offset: Constants.linkedBlockSize
                )
            }
            descriptor.updateSize()
            
        } else {
            print("Size remains the same")
        }
    }
}

// MARK: - Links

extension FileSystem {

    static func link(to name: String, nameToLink: String) {
        
        let descriptorIndex = getDescriptor(with: name).descriptorIndex
        rootBlock.createFileMapping(
            fileName: nameToLink,
            descriptorIndex: descriptorIndex
        )
        descriptors[descriptorIndex].referenceCount += 1
    }
    
    static func unlink(name: String) {
        
        let descriptorIndex = rootBlock.getDescriptorIndex(with: name)
        let descriptor = descriptors[descriptorIndex]
        let block = blocks[rootDirectory.linksBlocks[0]]
        block.deleteFileMapping(with: name)
        descriptor.referenceCount -= 1
        
        if descriptor.referenceCount == 0 {
            print("Removing descriptor")
            descriptor.linksBlocks.forEach { id in
                blocksBitMap.reset(position: id)
            }
            descriptor.free()
        }
    }
}

// MARK: - Private methods

extension FileSystem {
    
    static private func getEmptyDescriptor() -> (descriptorIndex: Int,
                                          descriptor: Descriptor) {
        
        if let (descriptorIndex, descriptor) = descriptors.enumerated().first(where: { !$1.isUsed }) {
            return (descriptorIndex: descriptorIndex, descriptor: descriptor)
        } else {
            fatalError("No available descriptors")
        }
    }
    
    static private func getDescriptor(with name: String) -> (descriptorIndex: Int,
                                                      descriptor: Descriptor) {
        let descriptorIndex = rootBlock.getDescriptorIndex(with: name)
        return (descriptorIndex: descriptorIndex,
                descriptor: descriptors[descriptorIndex])
    }
    
    static private func getBlocks(
        from descriptor: Descriptor,
        with offset: Int,
        totalSize: Int
    ) -> [Block] {
        let firstBlockIndex = offset / Constants.linkedBlockSize
        let lastBlockIndex = CGFloat.roundUp(CGFloat(totalSize) / CGFloat(Constants.linkedBlockSize))
        return (firstBlockIndex..<lastBlockIndex).map { blocks[descriptor.linksBlocks[$0]] }
    }
    
    static private func allocateNewBlock(
        for descriptor: Descriptor,
        newBlockIndex: Int
    ) {
        
        if let lastBlockIndex = descriptor.linksBlocks.last {
            blocks[lastBlockIndex].blockSpace.replaceSubrange(
                (Constants.linkedBlockSize..<Constants.blockSize),
                with: newBlockIndex.bytes
            )
        }
        
        blocks[newBlockIndex].mode = .dataAndLink
        descriptor.linksBlocks.append(newBlockIndex)
    }
}
