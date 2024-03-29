//
//  WriteCommand.swift
//  FileSystem
//
//  Created by Denys Danyliuk on 24.12.2021.
//

import Foundation

struct WriteCommand: Command {
    
    struct InputType {
        var numericOpenedFileDescriptor: Int
        var offset: Int
        var data: String
    }
    
    static func execute(_ inputs: InputType) {
        print("\n~$ write \(inputs.numericOpenedFileDescriptor)")
        FileSystem.writeFile(
            to: inputs.numericOpenedFileDescriptor,
            offset: inputs.offset,
            data: inputs.data
        )
        print("Data:\n\(inputs.data)\nWas successfully written")
    }
}
