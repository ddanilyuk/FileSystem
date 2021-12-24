//
//  LSCommand.swift
//  FileSystem
//
//  Created by Denys Danyliuk on 24.12.2021.
//

import Foundation

struct LSCommand: Command {
    
    static func execute(_ inputs: Void = ()) {
        
        print("\n~$ ls")
        let fileName = "File name:".padding(Constants.fileNameSize)
        let descriptorMode = "Mode:".padding(10)
        let referenceCount = "References:".padding(12)
        let descriptorIndex = "Index:".padding(7)
        let descriptorSize = "Size:".padding(6)
        print("\(fileName) \(descriptorMode) \(referenceCount) \(descriptorIndex) \(descriptorSize)")
        
        let data = FileSystemDriver.shared.ls()
            .map { description in
                let fileName = description.fileName.padding(Constants.fileNameSize)
                let descriptorMode = description.mode.description.padding(10)
                let referenceCount = description.referenceCount.toString.padding(12)
                let descriptorIndex = description.descriptorIndex.toString.padding(7)
                let descriptorSize = description.size.toString.padding(6)
                return "\(fileName) \(descriptorMode) \(referenceCount) \(descriptorIndex) \(descriptorSize)"
            }
            .joined(separator: "\n")
        print(data)
    }
}
