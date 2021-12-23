//
//  Block.swift
//  FileSystem
//
//  Created by Denys Danyliuk on 10.12.2021.
//

import Foundation

final class Block {
    
    // MARK: - Mode
    
    enum Mode {
        /// The block contain some data of a file
        case data
        /// The block contain list of links to other blocks
        case link
        /// The block contain mappings filename: descriptor id
        case mappingsAndData
        
        case none
        
        // TODO: Remove
        var isLinksBlock: Bool {
            switch self {
            case .data:
                return false
            case .link:
                return true
            case .mappingsAndData:
                return true
            case .none:
                return false
            }
        }
        
        // TODO: Remove
        var isMappingBlock: Bool {
            switch self {
            case .data:
                return false
            case .link:
                return false
            case .mappingsAndData:
                return true
            case .none:
                return false
            }
        }
    }
    
    // MARK: - Properties
    
//    var blockNumber: Int
    
    var mode: Mode
    
    var blockSpace: ByteArray
    
    init(
//        blockNumber: Int,
        mode: Block.Mode,
        blockSpace: ByteArray
    ) {
//        self.blockNumber = blockNumber
        self.mode = mode
        self.blockSpace = blockSpace
    }
    
    // MARK: Create methods
    
    func createFileMapping(fileName: String, descriptorIndex: Int) {
        
        guard
            mode != .data
        else {
            fatalError("Not able to add file link for this type of block")
        }
        
        guard
            let emptyMappingSlot = mappingChunks().enumerated().first(where: { $1.isClear })?.offset
        else {
            fatalError("Was not able to find empty slot to add a link for a file")
        }
        
        let truncatedFileName = fileName.padding(Constants.fileNameSize)
        let fileNameBytes: ByteArray = Array(truncatedFileName.utf8)
        let descriptorIndexBytes: ByteArray = descriptorIndex.bytes
        let data = fileNameBytes + descriptorIndexBytes
        setData(data: data, offset: emptyMappingSlot * Constants.mappingSize)
    }
    
    // MARK: Get methods

    func getFilesMappings() -> [(fileName: String, descriptorIndex: Int)] {
        
        guard
            mode != .data
        else {
            fatalError("Not able to add file link for this type of block")
        }
        
        return mappingChunks().compactMap { chunk in
            
            guard !chunk.isClear else {
                return nil
            }
            
            let chunkNameBytes = chunk[..<Constants.fileNameSize]
            let chunkDescriptorIndexBytes = chunk[Constants.fileNameSize...]
            
            let trimmedCharacterSet = CharacterSet.whitespaces.union(CharacterSet.controlCharacters)
            let fileName = chunkNameBytes.toString.trimmingCharacters(in: trimmedCharacterSet)
            let descriptorIndex = chunkDescriptorIndexBytes.toInt
            return (fileName: fileName, descriptorIndex: descriptorIndex)
        }
    }
    
    func getDescriptorIndex(with name: String) -> Int {
        
        return 0
    }
    
    // MARK: Delete methods
    
    func deleteFileMapping(with name: String) -> Bool {
        
        return false
    }
    
    // MARK: - Private methods
    
    private func setData(data: ByteArray, offset: Int) {
        
        guard
            data.count + offset < Constants.blockSize
        else {
            fatalError("Out of space")
        }
        blockSpace.replaceSubrange(offset..<offset + data.count, with: data)
    }
    
    private func mappingChunks() -> [ByteArray] {
        
        let mappingSize = Constants.mappingSize
        let availableNumberOfMappings = blockSpace.count / mappingSize
        
        return (0..<availableNumberOfMappings).map { index in
            let startIndex = index * mappingSize
            let endIndex = index * mappingSize + mappingSize
            return Array(blockSpace[startIndex..<endIndex])
        }
    }
}
