//
//  main.swift
//  FileSystem
//
//  Created by Denys Danyliuk on 10.12.2021.
//

import Foundation


MountCommand.execute()

MKFSCommand.execute(10)

MKDirCommand.execute("test")
MKDirCommand.execute("hello")
//MKDirCommand.execute("hello/testSimlink")
CDCommand.execute("/test")
MKDirCommand.execute("dirInsideTest")
CDCommand.execute("..")
MKDirCommand.execute("/test/dirInsideTest/newDir")
CDCommand.execute("/test/dirInsideTest/newDir")

LSCommand.execute()

CDCommand.execute("/")

MKDirCommand.execute("world")
MKDirCommand.execute("world/test")
LSCommand.execute()
RMDirCommand.execute("world")
LSCommand.execute()


//SymlinkCommand.execute(
//    SymlinkCommand.InputType(
//        str: "/hello/recursion",
//        path: "/test/dirInsideTest/symlink"
//    )
//)
//SymlinkCommand.execute(
//    SymlinkCommand.InputType(
//        str: "/test/dirInsideTest/symlink",
//        path: "hello/recursion"
//    )
//)

DebugCommand.execute()


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
//
//Tests.testSymlinkRecursion()
