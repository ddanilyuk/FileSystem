//
//  FileSystemDriver.swift
//  FileSystem
//
//  Created by Denys Danyliuk on 10.12.2021.
//

import Foundation


typealias OFDN = Int

final class FileSystemDriver {
    
    // MARK: - Properties
    
    var globalByteArray: ByteArray!
    
    var blocksBitMap: BitMap!
    
    // We need somewhere to store all blocks.
    var blocks: [Block]!
    
    var descriptors: [Descriptor] = []
    
    /// `[numericOpenFileDescriptor : fileDescriptorId]`
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
        descriptor.linksBlocks = [emptyBlockId]
        descriptor.size = 0
    }
    
    func generateGlobalByteArray() -> ByteArray {
        ByteArray(
            repeating: 0,
            count: Constants.numberOfBlocks * Constants.blockSize
        )
    }
    
    func generateBlocksBitMap() -> BitMap {
        BitMap(size: Constants.numberOfBlocks)
    }
    
    func generateBlocks() -> [Block] {
        (0..<Constants.numberOfBlocks).map { index in
            let startBlockSpace = Constants.blockSize * index
            let endBlockSpace = Constants.blockSize * index + Constants.blockSize
            return Block(
                mode: .none,
                blockSpace: Array(globalByteArray[startBlockSpace..<endBlockSpace])
            )
        }
    }
}

// MARK: - Console commands

extension FileSystemDriver {
    
    func mountFromMemory() {
        
        globalByteArray = generateGlobalByteArray()
        blocksBitMap = generateBlocksBitMap()
        blocks = generateBlocks()
    }
    
    func unmount() {
        
        globalByteArray = nil
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
                referenceCount: descriptor.size,
                descriptorIndex: descriptorIndex
            )
        }
    }
}

// MARK: - Files

extension FileSystemDriver {

    func createFile(with name: String, in directory: Descriptor) {
        let (descriptorIndex, descriptor) = getEmptyDescriptor()
        Logger.shared.log("Find free descriptor with id: \(descriptorIndex)")
        initiateFileIn(descriptor: descriptor)
        addFileMapping(
            fileName: name,
            descriptorIndex: descriptorIndex,
            blockNumber: directory.linksBlocks[0]
        )
        descriptor.referenceCount = 1
    }
    
    func openFile(with name: String) {
        
    }
    
    func closeFile(with descriptorId: Int) {
        
    }
    
    func readFile(with descriptorId: Int, offset: Int, size: Int) -> String? {
        
        return nil
    }
    
    func truncateFile(with name: String, size: Int) {
        
    }
}

// MARK: - Links

extension FileSystemDriver {

    func link(to name: String, nameToLink: String) {
        
    }
    
    func unlink(name: String) {
        
    }
}

// MARK: - Private methods

extension FileSystemDriver {
    
    private func getEmptyDescriptor() -> (descriptorIndex: Int, descriptor: Descriptor) {
        
        if let (descriptorIndex, descriptor) = descriptors.enumerated().first(where: { !$1.isUsed }) {
            return (descriptorIndex: descriptorIndex, descriptor: descriptor)
        } else {
            fatalError("No available descriptors")
        }
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
        descriptor.linksBlocks = [getEmptyBlockId()]
    }
    
    private func addFileMapping(
        fileName: String,
        descriptorIndex: Int,
        blockNumber: Int
    ) {
        
        let block = blocks[blockNumber]
        block.createFileMapping(fileName: fileName, descriptorIndex: descriptorIndex)
    }
    
    private func free(descriptor: Descriptor) {
        
    }
}

extension FileSystemDriver {
    
    struct LSDescription {
        var fileName: String
        var mode: Descriptor.Mode
        var referenceCount: Int
        var descriptorIndex: Int
    }
}
