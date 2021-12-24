//
//  DebugCommand.swift
//  FileSystem
//
//  Created by Denys Danyliuk on 24.12.2021.
//

import Foundation

struct DebugCommand: Command {
    
    static func execute(_ inputs: Void = ()) {
        
        debugBlocks()
        debugDescriptors()
    }
    
    static func debugBlocks() {
        print("\n~$ Blocks")
        let number = "№:".padding(3)
        let isUsed = "Is used?"
        let dataDescription = "Data:"
        print("\(number) \(isUsed) \(dataDescription)")
        
        let data = FileSystemDriver.shared.blocks
            .enumerated()
            .filter { !$1.blockSpace.isClear }
            .map {
                let number = "#\($0.toString)".padding(3)
                let isUsed = FileSystemDriver.shared.blocksBitMap.test(position: $0) ? "Used    " : "Not Used"
                let dataDescription = $1.description
                return "\(number) \(isUsed) \(dataDescription)" }
            .joined(separator: "\n")
        print(data)
        print("")
    }
    
    static func debugDescriptors() {
        print("\n~$ Descriptors")
        let descriptorNumber = "№:".padding(4)
        let descriptorMode = "Mode:".padding(16)
        let linkedBlocks = "Linked blocks:"
        print("\(descriptorNumber) \(descriptorMode) \(linkedBlocks)")
        
        let data = FileSystemDriver.shared.descriptors
            .enumerated()
            .map {
                let descriptorNumber = "#\($0)".padding(4)
                let descriptorMode = $1.mode.description.padding(16)
                let linkedBlocks = $1.linksBlocks
                return "\(descriptorNumber) \(descriptorMode) \(linkedBlocks)"
            }
            .joined(separator: "\n")
        print(data)
    }
}
