//
//  DebugCommand.swift
//  FileSystem
//
//  Created by Denys Danyliuk on 24.12.2021.
//

import Foundation

struct DebugCommand: Command {
    
    static func execute(_ inputs: Void = ()) {
        print("\n~$ debug")
        debugBlocks()
        debugDescriptors()
    }
    
    static func debugBlocks() {
        print("\nBlocks:")
        let number = "№:".padding(3)
        let isUsed = "Is used?"
        let dataDescription = "Data:"
        print("\(number) \(isUsed) \(dataDescription)")
        
        let data = FileSystem.blocks
            .enumerated()
            .filter { !$1.blockSpace.isClear }
            .map {
                let number = "#\($0.toString)".padding(3)
                let isUsed = FileSystem.blocksBitMap.test(position: $0) ? "Used    " : "Not Used"
                let dataDescription = $1.description
                return "\(number) \(isUsed) \(dataDescription)" }
            .joined(separator: "\n")
        print(data)
    }
    
    static func debugDescriptors() {
        print("\nDescriptors:")
        let descriptorNumber = "№:".padding(4)
        let descriptorMode = "Mode:".padding(16)
        let linkedBlocks = "Linked blocks:"
        print("\(descriptorNumber) \(descriptorMode) \(linkedBlocks)")
        
        let data = FileSystem.descriptors
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
