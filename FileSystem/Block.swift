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
        
    var mode: Mode
    
    var blockSpace: ByteArray
    
    init(
        mode: Block.Mode,
        blockSpace: ByteArray
    ) {
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
                        
            let fileName = chunk[..<Constants.fileNameSize].toFileName
            let descriptorIndex = chunk[Constants.fileNameSize...].toInt
            return (fileName: fileName, descriptorIndex: descriptorIndex)
        }
    }
    
    func getDescriptorIndex(with name: String) -> Int {
        
        let index = mappingChunks()
            .first { chunk in
                guard !chunk.isClear else {
                    return false
                }
                let fileName = chunk[..<Constants.fileNameSize].toFileName
                return fileName == name
            }
            .map {
                $0[Constants.fileNameSize...].toInt
            }
        
        guard let index = index else {
            fatalError("Can't find descriptor with this name")
        }
        return index
    }
    
    // MARK: Delete methods
    
    @discardableResult
    func deleteFileMapping(with name: String) -> Bool {
        
        let chunk = mappingChunks().enumerated().first { index, chunk in
            guard !chunk.isClear else {
                return false
            }
            let fileName = chunk[..<Constants.fileNameSize].toFileName
            return fileName == name
        }
        
        if let chunk = chunk {
            setData(data: ByteArray(repeating: 0, count: Constants.mappingSize), offset: chunk.offset * Constants.mappingSize)
            return true
        } else {
            return false
        }
    }
    
    // MARK: - Private methods
    
    func setData(data: ByteArray, offset: Int) {
        
        guard
            data.count + offset <= Constants.blockSize
        else {
            fatalError("Out of space")
        }
        blockSpace.replaceSubrange(offset..<offset + data.count, with: data)
    }
    
    func mappingChunks() -> [ByteArray] {
        
        let mappingSize = Constants.mappingSize
        let availableNumberOfMappings = blockSpace.count / mappingSize
        
        return (0..<availableNumberOfMappings).map { index in
            let startIndex = index * mappingSize
            let endIndex = index * mappingSize + mappingSize
            return Array(blockSpace[startIndex..<endIndex])
        }
    }
    
    func linkChunk() -> ByteArray {
        Array(blockSpace[Constants.linkedBlockSize...])
    }
}

extension Block: CustomStringConvertible {
    
    var description: String {
        switch mode {
        case .link:
            let data = blockSpace[0..<Constants.linkedBlockSize].toFileName.padding(Constants.linkedBlockSize)
            let link = String(blockSpace[Constants.linkedBlockSize...].toInt)
                .padding(toLength: 2, withPad: " ", startingAt: 0)
            return data + "|" + link
        case .mappingsAndData:
            return getFilesMappings()
                .compactMap { fileName, descriptorIndex in
                    let fileName = fileName.padding(Constants.fileNameSize)
                    let descriptorIndex = String(descriptorIndex).padding(Constants.intSize)
                    return "\(fileName)\(descriptorIndex)"
                }
                .joined(separator: "|")
        default:
            return ""
        }
    }
}
