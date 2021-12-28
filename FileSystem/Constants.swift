//
//  Constants.swift
//  FileSystem
//
//  Created by Denys Danyliuk on 10.12.2021.
//

import Foundation

struct Constants {
    
    struct Block {
        
        // Number of blocks in file system
        static let amount = 20
        
        // Size in bytes
        static let size = 64
        
        // Size for data in linked block
        static var dataSize: Int {
            return size - Common.intSize
        }
    }
    
    struct Common {
        
        // All file names are truncated to that size in bytes
        static let fileNameSize = 14
        
        // All integers stored in FS are truncated to that size in bytes
        static let intSize = 2
        
        // Dividing a bytes in block into a chunks of MAPPING_SIZE bytes, this chunks will store
        // filename: descriptor_id mappings
        static var mappingSize: Int {
            fileNameSize + intSize
        }
        
        static var maximumRecursionCounter: Int {
            return 50
        }
    }
}
