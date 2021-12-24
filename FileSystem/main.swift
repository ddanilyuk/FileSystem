//
//  main.swift
//  FileSystem
//
//  Created by Denys Danyliuk on 10.12.2021.
//

import Foundation


//MountCommand().execute(inputs: MountCommand.Input(name: "Hi every "))

FileSystemDriver.shared.mountFromMemory()
FileSystemDriver.shared.generateDescriptors(10)
let fileName1 = "Test file"
FileSystemDriver.shared.createFile(
    with: fileName1,
    in: FileSystemDriver.shared.rootDirectory
)
let fileName2 = "Second file"
FileSystemDriver.shared.createFile(
    with: fileName2,
    in: FileSystemDriver.shared.rootDirectory
)
FileSystemDriver.shared.createFile(
    with: "New file",
    in: FileSystemDriver.shared.rootDirectory
)
FileSystemDriver.shared.createFile(
    with: "Last file",
    in: FileSystemDriver.shared.rootDirectory
)

let ls = FileSystemDriver.shared.ls()
Logger.shared.logLSCommand(ls)

let openedFile1 = FileSystemDriver.shared.openFile(with: fileName1)
FileSystemDriver.shared.writeFile(to: openedFile1, offset: 0, data: "11111111112222222222111111111122222222221111111111222222222212345678")
print(FileSystemDriver.shared.readFile(from: openedFile1, size: nil) ?? "")

let openedFile2 = FileSystemDriver.shared.openFile(with: fileName2)
FileSystemDriver.shared.writeFile(to: openedFile2, offset: 0, data: "Test")
print(FileSystemDriver.shared.readFile(from: openedFile2, size: nil) ?? "")

Logger.shared.logLSCommand(FileSystemDriver.shared.ls())



extension Collection {
    
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}


extension String {
    
    func padding(_ length: Int) -> String {
        return padding(toLength: length, withPad: " ", startingAt: 0)
    }
}
