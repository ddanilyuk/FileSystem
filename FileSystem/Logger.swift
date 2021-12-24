//
//  Logger.swift
//  FileSystem
//
//  Created by Denys Danyliuk on 10.12.2021.
//

import Foundation

final class Logger {
    
    // MARK: - Properties
    
    
    // MARK: - Singleton
    
    static let shared = Logger()
    
    private init() { }
    
    // MARK: - Public methods
    
    func log(_ text: String) {
        
        print(text)
    }
    
    func logLSCommand(_ description: [FileSystemDriver.LSDescription]) {
        
        print("~$ ls")
        description.forEach { description in
            print("File name: \(description.fileName.padding(Constants.fileNameSize)) | Mode: \(description.mode.description.padding(10)) | ref \(description.referenceCount) | index: \(description.descriptorIndex) | size: \(description.size)")
        }
        print("\n")
    }
    
    func debug() {
        
        logDescriptors()
        logBlocks()
    }
    
    func logBlocks() {
        print("\n~$ Blocks")
//        print(Array(repeating: "*", count: 80).joined())
        let data = FileSystemDriver.shared.blocks
            .enumerated()
            .filter { !$1.blockSpace.isClear }
            .map { "#\(String($0).padding(2)) \(FileSystemDriver.shared.blocksBitMap.test(position: $0) ? "Used    " : "Not Used") \($1.description)" }
            .joined(separator: "\n")
        print(data)
//        print(Array(repeating: "*", count: 80).joined())
        print("")
    }
    
    func logDescriptors() {
        
        print("\n~$ Descriptors")
        let data = FileSystemDriver.shared.descriptors
            .enumerated()
            .map { "#\($0) \($1.mode.description.padding(16)) \($1.linksBlocks)" }
            .joined(separator: "\n")
        print(data)
        print("")
    }
}

