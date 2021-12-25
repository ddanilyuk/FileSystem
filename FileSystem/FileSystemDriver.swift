//
//  FileSystemDriver.swift
//  FileSystem
//
//  Created by Denys Danyliuk on 10.12.2021.
//

import Foundation

final class FileSystemDriver {
    
    // MARK: - Properties
        
    var blocksBitMap: BitMap!
    
    var blocks: [Block]!
    
    var descriptors: [Descriptor] = []
    
    /// `[numericOpenedFileDescriptor : fileDescriptorIndex]`
    /// Call this number "numeric file descriptor". To work with an open file (this number is not the same as the descriptor number that identifies the file in the FS.
    var openedFiles: [Int: Int] = [:]
    
    // MARK: - Computed property
    
    var rootDirectory: Descriptor {
        descriptors.first!
    }
    var rootBlock: Block {
        blocks[rootDirectory.linksBlocks[0]]
    }
    
    // MARK: - Singleton
    
    static let shared = FileSystemDriver()
    
    private init() { }
    
    // MARK: - Lifecycle
    
    func generateDescriptors(_ numberOfDescriptors: Int) {
        
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
    
    func generateRootDirectory() {
        
        let descriptor = descriptors[0]
        let emptyBlockId = blocksBitMap.firstEmpty()
        blocks[emptyBlockId].mode = .mappings
        descriptor.isUsed = true
        descriptor.mode = .directory
        descriptor.referenceCount = 1
        descriptor.linksBlocks = [emptyBlockId]
        descriptor.size = 0
    }
    
    func generateBlocksBitMap() -> BitMap {
        BitMap(size: Constants.numberOfBlocks)
    }
    
    func generateBlocks() -> [Block] {
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

extension FileSystemDriver {
    
    func mountFromMemory() {
        
        blocksBitMap = generateBlocksBitMap()
        blocks = generateBlocks()
    }
    
    func umount() {
        
        openedFiles = [:]
        descriptors = []
        blocksBitMap = nil
        blocks = nil
    }
    
    func fstab(descriptorIndex: Int) -> Descriptor {
        if let descriptor = descriptors[safe: descriptorIndex] {
            return descriptor
        } else {
            fatalError("Not found")
        }
    }
    
    func ls() -> [LSCommand.LineModel] {
        rootBlock
            .getFilesMappings()
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

extension FileSystemDriver {

    func createFile(with name: String) {
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
    func openFile(with name: String) -> Int {
        let numericOpenedFileDescriptor = openedFiles.uniqueKey
        openedFiles[numericOpenedFileDescriptor] = getDescriptor(with: name).descriptorIndex
        return numericOpenedFileDescriptor
    }
    
    func closeFile(with numericOpenedFileDescriptor: Int) {
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

extension FileSystemDriver {
    
    func writeFile(
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
    
    private func writeData(
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
            let neededBlocksCount = CGFloat.roundUp(CGFloat(delta) / CGFloat(Constants.linkedBlockSize))
            (0..<neededBlocksCount).forEach { _ in appendBlock(to: descriptor, blockNumber: blocksBitMap.firstEmpty()) }
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

extension FileSystemDriver {
    
    func readFile(
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
    
    private func readFrom(
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

extension FileSystemDriver {
    
    func truncateFile(with name: String, to size: Int) {
        
        let descriptor = getDescriptor(with: name).descriptor
        
        if size > descriptor.size {
            let neededBlocksCount = CGFloat.roundUp(CGFloat(size - descriptor.size) / CGFloat(Constants.linkedBlockSize))
            (0..<neededBlocksCount).forEach { _ in appendBlock(to: descriptor, blockNumber: blocksBitMap.firstEmpty()) }
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

extension FileSystemDriver {

    func link(to name: String, nameToLink: String) {
        
        let descriptorIndex = getDescriptor(with: name).descriptorIndex
        rootBlock.createFileMapping(
            fileName: nameToLink,
            descriptorIndex: descriptorIndex
        )
        descriptors[descriptorIndex].referenceCount += 1
    }
    
    func unlink(name: String) {
        
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

extension FileSystemDriver {
    
    private func getEmptyDescriptor() -> (descriptorIndex: Int,
                                          descriptor: Descriptor) {
        
        if let (descriptorIndex, descriptor) = descriptors.enumerated().first(where: { !$1.isUsed }) {
            return (descriptorIndex: descriptorIndex, descriptor: descriptor)
        } else {
            fatalError("No available descriptors")
        }
    }
    
    private func getDescriptor(with name: String) -> (descriptorIndex: Int,
                                              descriptor: Descriptor) {
        
        let descriptorIndex = rootBlock.getDescriptorIndex(with: name)
        return (descriptorIndex: descriptorIndex,
                descriptor: descriptors[descriptorIndex])
    }
    
    private func getBlocks(
        from descriptor: Descriptor,
        with offset: Int,
        totalSize: Int
    ) -> [Block] {
        let firstBlockIndex = offset / Constants.linkedBlockSize
        let lastBlockIndex = CGFloat.roundUp(CGFloat(totalSize) / CGFloat(Constants.linkedBlockSize))
        return (firstBlockIndex..<lastBlockIndex).map { blocks[descriptor.linksBlocks[$0]] }
    }
    
    private func appendBlock(
        to descriptor: Descriptor,
        blockNumber: Int
    ) {
        
        if let lastBlockId = descriptor.linksBlocks.last {
            let lastBlock = blocks[lastBlockId]
            let blockNumberBytes = blockNumber.bytes
            lastBlock.mode = .dataAndLink
            lastBlock.blockSpace.replaceSubrange(
                (Constants.linkedBlockSize..<Constants.blockSize),
                with: blockNumberBytes
            )
        }
        
        blocks[blockNumber].mode = .dataAndLink
        descriptor.linksBlocks.append(blockNumber)
    }
}
