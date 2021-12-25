//
//  LSCommand.swift
//  FileSystem
//
//  Created by Denys Danyliuk on 24.12.2021.
//

import Foundation

struct LSCommand: Command {
    
    struct LineModel {
        var fileName: String
        var mode: Descriptor.Mode
        var referenceCount: Int
        var descriptorIndex: Int
        var size: Int
    }
    
    static func execute(_ inputs: Void = ()) {
        print("\n~$ ls")
        let fileName = "File name:".padding(Constants.fileNameSize)
        let descriptorMode = "Mode:".padding(10)
        let referenceCount = "References:".padding(12)
        let descriptorIndex = "Index:".padding(7)
        let descriptorSize = "Size:".padding(6)
        print("\(fileName) \(descriptorMode) \(referenceCount) \(descriptorIndex) \(descriptorSize)")
        
        let data = FileSystemDriver.shared.ls()
            .map { line in
                let fileName = line.fileName.padding(Constants.fileNameSize)
                let descriptorMode = line.mode.description.padding(10)
                let referenceCount = line.referenceCount.toString.padding(12)
                let descriptorIndex = line.descriptorIndex.toString.padding(7)
                let descriptorSize = line.size.toString.padding(6)
                return "\(fileName) \(descriptorMode) \(referenceCount) \(descriptorIndex) \(descriptorSize)"
            }
            .joined(separator: "\n")
        print(data)
    }
}
