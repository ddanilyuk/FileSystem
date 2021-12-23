//
//  Constants.swift
//  FileSystem
//
//  Created by Denys Danyliuk on 10.12.2021.
//

import Foundation

struct Constants {
    
    // Number of blocks in `?file?`
    static let numberOfBlocks = 20
    
    // Number of blocks in `?FS?`
    static let numberOfDescriptors = 100
    
    // Size in bytes
    static let blockSize = 64
    
    // All file names are truncated to that size in bytes
    static let fileNameSize = 14
    
    // All integers stored in FS are truncated to that size in bytes
    static let intSize = 2
    
    // dividing a bytes in block into a chunks of MAPPING_SIZE bytes, this chunks will store
    // filename: descriptor_id mappings
    static var mappingSize: Int {
        fileNameSize + intSize
    }
}
