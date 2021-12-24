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
    
    /// `[numericOpenedFileDescriptor : fileDescriptorId]`
    /// Call this number "numeric file descriptor". To work with an open file (this number is not the same as the descriptor number that identifies the file in the FS.
    var openedFiles: [Int: Int] = [:]
    
    var rootDirectory: Descriptor {
        return descriptors.first!
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
        let emptyBlockId = getEmptyBlockId()
        descriptor.isUsed = true
        descriptor.mode = .directory
        descriptor.referenceCount = 1
        blocks[emptyBlockId].mode = .mappings
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
    
    func ls() -> [LSDescription] {
        return blocks[rootDirectory.linksBlocks[0]].getFilesMappings().map { fileName, descriptorIndex in
            let descriptor = descriptors[descriptorIndex]
            return LSDescription(
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

    func createFile(with name: String, in directory: Descriptor) {
        let (descriptorIndex, descriptor) = getEmptyDescriptor()
        print("Find free descriptor with id: \(descriptorIndex)")
        initiateFileIn(descriptor: descriptor)
        addFileMapping(
            fileName: name,
            descriptorIndex: descriptorIndex,
            blockNumber: directory.linksBlocks[0]
        )
        descriptor.referenceCount = 1
    }
    
    @discardableResult
    func openFile(with name: String) -> Int {
        
        let descriptorIndex = getDescriptorId(with: name, for: rootDirectory.linksBlocks[0])
        let numericOpenedFileDescriptor = generateFD()
        openedFiles[numericOpenedFileDescriptor] = descriptorIndex
        return numericOpenedFileDescriptor
    }
    
    func closeFile(with numericOpenedFileDescriptor: Int) {
        guard openedFiles[numericOpenedFileDescriptor] != nil else {
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
        descriptor.size = getNumberOfAllocatedBlock(in: descriptor) * Constants.linkedBlockSize
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
            (0..<neededBlocksCount).forEach { _ in appendBlock(to: descriptor, blockNumber: getEmptyBlockId()) }
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
        // Read full if nil
        let size = size ?? descriptor.size
        
        guard offset + size <= descriptor.size else {
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
    
    private func getBlocks(
        from descriptor: Descriptor,
        with offset: Int,
        totalSize: Int
    ) -> [Block] {
        let firstBlockIndex = offset / Constants.linkedBlockSize
        let lastBlockIndex = CGFloat.roundUp(CGFloat(totalSize) / CGFloat(Constants.linkedBlockSize))
        return (firstBlockIndex..<lastBlockIndex).map { blocks[descriptor.linksBlocks[$0]] }
    }
    
    func truncateFile(with name: String, size: Int) {
        
        let descriptorIndex = getDescriptorId(with: name, for: rootDirectory.linksBlocks[0])
        let descriptor = descriptors[descriptorIndex]
        
        if size > descriptor.size {
            print("Increasing size")
            let delta = size - descriptor.size
            let neededBlocksCount = Int(ceil(CGFloat(delta) / CGFloat(Constants.linkedBlockSize)))
            for _ in 0..<neededBlocksCount {
                appendBlock(to: descriptor, blockNumber: getEmptyBlockId())
            }
            descriptor.size = getNumberOfAllocatedBlock(in: descriptor) * Constants.linkedBlockSize
        } else if size < descriptor.size {
            print("Decreasing size of a file")
            let neededBlocksCount = Int(ceil(CGFloat(size) / CGFloat(Constants.linkedBlockSize)))
            let blockDelta = getNumberOfAllocatedBlock(in: descriptor) - neededBlocksCount
            
            let deletedBlocks = descriptor.linksBlocks
                .removeLast(blockDelta)

            let blockTruncateOffset = size % Constants.linkedBlockSize
            deletedBlocks.forEach { blocksBitMap.reset(position: $0) }
            if let lastBlockId = descriptor.linksBlocks.last {
                let block = blocks[lastBlockId]
                block.setData(data: ByteArray(repeating: 0, count: Constants.linkedBlockSize - blockTruncateOffset), offset: blockTruncateOffset)
                block.setData(data: [0, 0], offset: Constants.linkedBlockSize)
            }
            descriptor.size = getNumberOfAllocatedBlock(in: descriptor) * Constants.linkedBlockSize
            
        } else {
            print("Size was not changed")
        }
    }
}

// MARK: - Links

extension FileSystemDriver {

    func link(to name: String, nameToLink: String) {
        
        let descriptorIndex = getDescriptorId(with: name, for: rootDirectory.linksBlocks[0])
        addFileMapping(fileName: nameToLink, descriptorIndex: descriptorIndex, blockNumber: rootDirectory.linksBlocks[0])
        let descriptor = descriptors[descriptorIndex]
        descriptor.referenceCount += 1
    }
    
    func unlink(name: String) {
        
        let descriptorIndex = getDescriptorId(with: name, for: rootDirectory.linksBlocks[0])
        let descriptor = descriptors[descriptorIndex]
        let block = blocks[rootDirectory.linksBlocks[0]]
        let result = block.deleteFileMapping(with: name)
        print(result)
        descriptor.referenceCount -= 1
        
        if descriptor.referenceCount == 0 {
            print("Removing descriptor")
            let blockIds = getBlockIds(from: descriptor)
            blockIds.forEach { id in
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
    
    private func getDescriptorId(
        with name: String,
        for blockNumber: Int
    ) -> Int {
        let block = blocks[blockNumber]
        return block.getDescriptorIndex(with: name)
    }
    
    private func getEmptyBlockId() -> Int {
        for index in 0..<Constants.numberOfBlocks {
            if !blocksBitMap.test(position: index) {
                blocksBitMap.set(position: index)
                return index
            }
        }
        fatalError("Out of blocks")
    }
    
    private func initiateFileIn(descriptor: Descriptor) {
        
        descriptor.isUsed = true
        descriptor.mode = .file
        descriptor.referenceCount = 0
        descriptor.size = 0
        descriptor.linksBlocks = []
    }
    
    private func addFileMapping(
        fileName: String,
        descriptorIndex: Int,
        blockNumber: Int
    ) {
        
        let block = blocks[blockNumber]
        block.createFileMapping(fileName: fileName, descriptorIndex: descriptorIndex)
    }
    
    private func generateFD() -> Int {
        
        var numericOpenedFileDescriptor: Int
        repeat {
            numericOpenedFileDescriptor = Int.random(in: 0..<Int(UInt16.max))
        } while openedFiles.keys.contains(numericOpenedFileDescriptor)
        return numericOpenedFileDescriptor
    }
    
    func getNumberOfAllocatedBlock(in descriptor: Descriptor) -> Int {
        
        descriptor.linksBlocks
            .filter { blocks[$0].mode == .dataAndLink }
            .count
    }
    
    func getBlockIds(from descriptor: Descriptor) -> [Int] {
        
        return descriptor.linksBlocks.filter { blocks[$0].mode == .dataAndLink }
    }
}

// MARK: - LSDescription

extension FileSystemDriver {
    
    struct LSDescription {
        var fileName: String
        var mode: Descriptor.Mode
        var referenceCount: Int
        var descriptorIndex: Int
        var size: Int
    }
}
