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
        
        print("$ ls:")
        description.forEach { description in
            print("File name: \(description.fileName.padding(Constants.fileNameSize)) | Mode: \(description.mode.description.padding(10)) | ref \(description.referenceCount) | index: \(description.descriptorIndex)")
        }
        print("\n")
    }
    
    func logBlocks() {
        print("\n$ Blocks:")
        print(Array(repeating: "*", count: 72).joined())
        let data = FileSystemDriver.shared.blocks
            .enumerated()
            .filter { !$1.blockSpace.isClear }
            .map { "#\(String($0).padding(3)) \($1.description)" }
            .joined(separator: "\n")
        print(data)
        print(Array(repeating: "*", count: 72).joined())
        print("")
    }
    
    func logDescriptors() {
        
        print("\n$ Descriptors:")
        print(FileSystemDriver.shared.descriptors.map { $0.mode })
        print("")
    }
}

