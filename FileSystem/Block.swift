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
        /// The block contain list of links to other blocks
        case dataAndLink
        /// The block contain mappings filename: descriptor id
        case mappings
        /// Mode was not set
        case none
    }
    
    // MARK: - Properties
        
    var mode: Mode
    
    var blockSpace: ByteArray
    
    // MARK: - Computed properties
    
    var mappingsChunks: [ByteArray] {
        
        guard
            mode == .mappings
        else {
            fatalError("Unable to get mapping chunks with mode != .mappingg")
        }
        
        let mappingSize = Constants.mappingSize
        let availableNumberOfMappings = blockSpace.count / mappingSize
        
        return (0..<availableNumberOfMappings).map { index in
            let startIndex = index * mappingSize
            let endIndex = index * mappingSize + mappingSize
            return Array(blockSpace[startIndex..<endIndex])
        }
    }
    
    var linkChunk: ByteArray {
        guard
            mode == .dataAndLink
        else {
            fatalError("Unable to get mapping chunks with mode != .mappingg")
        }
        
        return Array(blockSpace[Constants.linkedBlockSize...])
    }
    
    // MARK: - Lifecycle
    
    init(
        mode: Block.Mode,
        blockSpace: ByteArray
    ) {
        self.mode = mode
        self.blockSpace = blockSpace
    }
    
    // MARK: Mapping block methods
    
    func createFileMapping(
        fileName: String,
        descriptorIndex: Int
    ) {
        
        guard
            mode != .dataAndLink
        else {
            fatalError("Not able to add file link for this type of block")
        }
        
        guard
            let emptyMappingSlot = mappingsChunks.enumerated().first(where: { $1.isClear })?.offset
        else {
            fatalError("Was not able to find empty slot to add a link for a file")
        }
        
        let truncatedFileName = fileName.padding(Constants.fileNameSize)
        let fileNameBytes: ByteArray = Array(truncatedFileName.utf8)
        let descriptorIndexBytes: ByteArray = descriptorIndex.bytes
        let data = fileNameBytes + descriptorIndexBytes
        setData(data: data, offset: emptyMappingSlot * Constants.mappingSize)
    }
    
    func getFilesMappings() -> [(fileName: String, descriptorIndex: Int)] {
        
        guard
            mode != .dataAndLink
        else {
            fatalError("Not able to add file link for this type of block")
        }
        
        return mappingsChunks.compactMap { chunk in
            
            guard !chunk.isClear else {
                return nil
            }
                        
            let fileName = chunk[..<Constants.fileNameSize].toFileName
            let descriptorIndex = chunk[Constants.fileNameSize...].toInt
            return (fileName: fileName, descriptorIndex: descriptorIndex)
        }
    }
    
    func getDescriptorIndex(with name: String) -> Int {
        
        let index = mappingsChunks
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
        
        guard
            let index = index
        else {
            fatalError("Can't find descriptor with this name")
        }
        return index
    }
        
    @discardableResult
    func deleteFileMapping(with name: String) -> Bool {
        
        let chunk = mappingsChunks.enumerated().first { index, chunk in
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
    
    // MARK: - Common methods
    
    func setData(data: ByteArray, offset: Int) {
        
        guard
            data.count + offset <= Constants.blockSize
        else {
            fatalError("Out of space")
        }
        blockSpace.replaceSubrange(offset..<offset + data.count, with: data)
    }
}

// MARK: - CustomStringConvertible

extension Block: CustomStringConvertible {
    
    var description: String {
        switch mode {
        case .dataAndLink:
            let data = blockSpace[0..<Constants.linkedBlockSize]
                .toString
                .trim(.controlCharacters)
                .padding(Constants.linkedBlockSize)
            let linkNumber = linkChunk.toInt
            let link = linkNumber == 0 ? "-" : linkNumber.toString
                .padding(toLength: 2, withPad: " ", startingAt: 0)
            return data + "|" + link
            
        case .mappings:
            return getFilesMappings()
                .compactMap { fileName, descriptorIndex in
                    let fileName = fileName
                        .padding(Constants.fileNameSize)
                    let descriptorIndex = descriptorIndex
                        .toString
                        .padding(Constants.intSize)
                    return "\(fileName)\(descriptorIndex)"
                }
                .joined(separator: "|")
            
        case .none:
            return ""
        }
    }
}
