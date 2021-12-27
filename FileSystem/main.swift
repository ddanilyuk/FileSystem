//
//  main.swift
//  FileSystem
//
//  Created by Denys Danyliuk on 10.12.2021.
//

import Foundation


FileSystem.mountFromMemory()
FileSystem.generateDescriptors(10)

MountCommand.execute()

MKFSCommand.execute(10)

MKDirCommand.execute("test")
MKDirCommand.execute("hello")
MKDirCommand.execute("hello/testSimlink")
MKDirCommand.execute("world")
CDCommand.execute("/test")
MKDirCommand.execute("dirInsideTest")
CDCommand.execute("..")
MKDirCommand.execute("/test/dirInsideTest/newDir")
CDCommand.execute("/test/dirInsideTest/newDir")

LSCommand.execute()

CDCommand.execute("/")
SymlinkCommand.execute(
    SymlinkCommand.InputType(
        str: "/hello",
        path: "/test/dirInsideTest/symlink"
    )
)

//
//MKDirCommand.execute("foo")
//MKDirCommand.execute("foo2")
//
CDCommand.execute("/test/dirInsideTest/symlink")
LSCommand.execute()

CDCommand.execute("..")
LSCommand.execute()

DebugCommand.execute()

//let path1 = Path.resolve("/test")
////print(FileSystem.descriptors.firstIndex(where: { $0.linksBlocks == some.linksBlocks }))
//FileSystem.currentDirectory = path1
//
//LSCommand.execute()
//
//let path2 = Path.resolve("foo")
////print(FileSystem.descriptors.firstIndex(where: { $0.linksBlocks == some.linksBlocks }))
//FileSystem.currentDirectory = path2
//
//LSCommand.execute()
//DebugCommand.execute()


//print(some.)

//
//Tests.testCreateWriteReadFile()
//
//Tests.testCreate4Files()
//
//Tests.testBigFile()
//
//Tests.testOffset()
//
//Tests.testTruncate()
//
//Tests.testLinks()
