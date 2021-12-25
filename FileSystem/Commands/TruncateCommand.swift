//
//  TruncateCommand.swift
//  FileSystem
//
//  Created by Denys Danyliuk on 25.12.2021.
//

import Foundation

struct TruncateCommand: Command {
    
    struct InputType {
        var name: String
        var size: Int
    }
    
    static func execute(_ inputs: InputType) {
        print("\n~$ truncate \(inputs.name) \(inputs.size)")
        FileSystem.truncateFile(
            with: inputs.name,
            to: inputs.size
        )
        print("File truncated to \(inputs.size) data bytes")
    }
}
