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
}
