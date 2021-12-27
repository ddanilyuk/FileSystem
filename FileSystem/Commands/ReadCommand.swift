//
//  ReadCommand.swift
//  FileSystem
//
//  Created by Denys Danyliuk on 24.12.2021.
//

import Foundation

struct ReadCommand: Command {
    
    struct InputType {
        var numericOpenedFileDescriptor: Int
        var offset: Int
        var size: Int? = nil
    }
    
    static func execute(_ inputs: InputType) {
        print("\n\(Path.currentPath)$ read \(inputs.numericOpenedFileDescriptor)")
        let result = FileSystem.readFile(
            from: inputs.numericOpenedFileDescriptor,
            offset: inputs.offset,
            size: inputs.size
        )
        print("Data:\n\(result ?? "")")
    }
}
