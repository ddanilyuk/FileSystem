//
//  TruncateCommand.swift
//  FileSystem
//
//  Created by Denys Danyliuk on 25.12.2021.
//

import Foundation

struct TruncateCommand: Command {
    
    struct InputType {
        var path: String
        var size: Int
    }
    
    static func execute(_ inputs: InputType) {
        print("\n\(Path.currentPath)$ truncate \(inputs.path) \(inputs.size)")
        FileSystem.truncateFile(
            with: inputs.path,
            to: inputs.size
        )
        print("File truncated to \(inputs.size) data bytes")
    }
}
