//
//  Command.swift
//  FileSystem
//
//  Created by Denys Danyliuk on 10.12.2021.
//

import Foundation

//struct Input {
//
//}

protocol Command {
    
//    var inputs: A

    associatedtype InputType
    
    func execute(inputs: InputType)
}


struct MountCommand: Command {
    
    struct Input {
        var name: String
    }
    
    func execute(inputs: Input) {
        // Mount
        let some = ByteCountFormatter()
        print(inputs.name)
    }
}
