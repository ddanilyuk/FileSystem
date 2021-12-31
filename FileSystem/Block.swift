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
        // Symbolic link
        case symlink
        /// Mode was not set
        case none
    }
    
    // MARK: - Properties
        
    var mode: Mode
    
    var blockSpace: ByteArray
    
    // MARK: - Computed properties
    
    var mappingsChunks: [ByteArray] {
        (0..<(blockSpace.count / Constants.Common.mappingSize)).map { index in
            let startIndex = index * Constants.Common.mappingSize
            let endIndex = index * Constants.Common.mappingSize + Constants.Common.mappingSize
            return ByteArray(blockSpace[startIndex..<endIndex])
        }
    }
    
    var filesMappings: [(fileName: String, descriptorIndex: Int)] {
        mappingsChunks.compactMap { chunk in
            guard !chunk.isClear else { return nil }
            let fileName = chunk.fileNameChunk.toFileName
            let descriptorIndex = chunk.descriptorIndexChunk.toInt
            return (fileName: fileName, descriptorIndex: descriptorIndex)
        }
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
            let emptyFileMappingSlot = mappingsChunks.enumerated().first(where: { $1.isClear })?.offset
        else {
            fatalError("Was not able to find empty slot to add a link for a file")
        }
        setData(
            data: fileName.padding(Constants.Common.fileNameSize).toBytes + descriptorIndex.toBytes,
            offset: emptyFileMappingSlot * Constants.Common.mappingSize
        )
    }
    
    func getDescriptorIndex(
        with name: String
    ) -> Int {
        if let chunkWithNeededName = mappingsChunks.first(where: { $0.isClear ? false : $0.fileNameChunk.toFileName == name }) {
            return chunkWithNeededName.descriptorIndexChunk.toInt
        } else {
            fatalError("Can't find descriptor with this name")
        }
    }
    
    @discardableResult
    func deleteFileMapping(
        with name: String
    ) -> Bool {
        let chunk = mappingsChunks.enumerated().first { index, chunk in
            guard
                !chunk.isClear
            else {
                return false
            }
            return chunk.fileNameChunk.toFileName == name
        }
        
        if let chunk = chunk {
            setData(data: ByteArray(size: Constants.Common.mappingSize), offset: chunk.offset * Constants.Common.mappingSize)
            return true
        } else {
            return false
        }
    }
    
    // MARK: - Common methods
    
    func setData(
        data: ByteArray,
        offset: Int
    ) {
        guard
            data.count + offset <= Constants.Block.size
        else {
            fatalError("Out of space")
        }
        blockSpace.replaceSubrange(
            offset..<offset + data.count,
            with: data
        )
    }
}

// MARK: - CustomStringConvertible

extension Block: CustomStringConvertible {
    
    var description: String {
        switch mode {
        case .dataAndLink:
            let data = blockSpace
                .dataChunk
                .toString
                .trim(.controlCharacters)
                .padding(Constants.Block.dataSize)
            let linkNumber = blockSpace
                .linkChunk
                .toInt
            let link = linkNumber == 0 ? "-" : linkNumber.toString
                .padding(toLength: 2, withPad: " ", startingAt: 0)
            return data + "|" + link
            
        case .mappings:
            return filesMappings
                .compactMap { fileName, descriptorIndex in
                    let fileName = fileName
                        .padding(Constants.Common.fileNameSize)
                    let descriptorIndex = descriptorIndex
                        .toString
                        .padding(Constants.Common.intSize)
                    return "\(fileName)\(descriptorIndex)"
                }
                .joined(separator: "|")
            
        case .symlink:
            let data = blockSpace
                .dataChunk
                .toString
                .trim(.controlCharacters)
                .padding(Constants.Block.dataSize)
            return data
            
        case .none:
            return ""
        }
    }
}
