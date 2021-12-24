//
//  Command.swift
//  FileSystem
//
//  Created by Denys Danyliuk on 10.12.2021.
//

import Foundation

protocol Command {
    
    associatedtype InputType
    associatedtype OutType
    
    static func execute(_ inputs: InputType) -> OutType
}
