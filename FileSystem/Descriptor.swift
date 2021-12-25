//
//  Descriptor.swift
//  FileSystem
//
//  Created by Denys Danyliuk on 10.12.2021.
//

import Foundation

final class Descriptor {
    
    // MARK: - Mode
    
    enum Mode: CustomStringConvertible {
        case file
        case directory
        case none
        
        var description: String {
            switch self {
            case .file:
                return "File"
            case .directory:
                return "Directory"
            case .none:
                return "Not defined"
            }
        }
    }
    
    // MARK: - Propreties
    
    var isUsed: Bool
    var mode: Mode
    var referenceCount: Int
    // Size in bytes
    var size: Int
    // Contains ids of blocks with links. If its a file - the links is for other blocks of a file.
    // If its a directory - the mappings filename: descriptor id
    var linksBlocks: [Int]
    
    init(
        isUsed: Bool,
        mode: Descriptor.Mode,
        refCount: Int,
        size: Int,
        linksBlocks: [Int]
    ) {
        self.isUsed = isUsed
        self.mode = mode
        self.referenceCount = refCount
        self.size = size
        self.linksBlocks = linksBlocks
    }
    
    // MARK: - Public methods
    
    func updateSize() {
        size = linksBlocks.count * Constants.Block.dataSize
    }
    
    func initiateAsFile(_ blocks: [Int] = []) {
        isUsed = true
        mode = .file
        referenceCount = 0
        size = 0
        linksBlocks = blocks
    }
    
    func initiateAsDirectory(_ blocks: [Int] = []) {
        isUsed = true
        mode = .directory
        referenceCount = 1
        linksBlocks = blocks
        size = 0
    }
    
    func free() {
        isUsed = false
        mode = .none
        referenceCount = 0
        size = 0
        linksBlocks = []
    }
}
