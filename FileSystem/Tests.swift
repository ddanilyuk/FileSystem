//
//  Tests.swift
//  FileSystem
//
//  Created by Denys Danyliuk on 24.12.2021.
//

import Foundation

struct Tests {
    
    static func testCreateWriteReadFile() {
        
        print("\n\n\n****** TEST Create Write Read File ******")
        
        let fileName = "Test.txt"
        let data = "Here is test data."
        
        // Setup
        MountCommand.execute()
        MKFSCommand.execute(10)
        
        // Create
        CreateCommand.execute(fileName)
        LSCommand.execute()
        
        // Open
        let openedFileIndex = OpenCommand.execute(fileName)
        
        // Write
        WriteCommand.execute(
            WriteCommand.InputType(
                numericOpenedFileDescriptor: openedFileIndex,
                offset: 0,
                data: data
            )
        )
        
        // Read
        ReadCommand.execute(
            ReadCommand.InputType(
                numericOpenedFileDescriptor: openedFileIndex,
                offset: 0,
                size: data.count
            )
        )
        
        // Close
        CloseCommand.execute(openedFileIndex)
        
        // Umount
        UMountCommand.execute()
    }

    static func testCreate4Files() {
        
        print("\n\n\n****** TEST Create 4 Files ******")
        
        let fileName1 = "Test1"
        let fileName2 = "So very big file name"
        let fileName3 = "Test2.txt"
        let fileName4 = "Test3.txt"

        // Setup
        MountCommand.execute()
        MKFSCommand.execute(10)
        
        // Create
        CreateCommand.execute(fileName1)
        CreateCommand.execute(fileName2)
        CreateCommand.execute(fileName3)
        CreateCommand.execute(fileName4)
        
        // Check
        LSCommand.execute()

        // Umount
        UMountCommand.execute()
    }
    
    static func testBigFile() {
        
        print("\n\n\n****** TEST Create Big File ******")
        
        let fileName1 = "Big.file"
        let data = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Etiam in posuere tellus. Mauris non dui augue. Nullam eget maximusus odio. Donec finibus, leo vel placerat facilisis, libero orci pellentesque nisi, eu eleifend urna urna sed est. Mauris porttitor ex nec justo volutpat, in tincidunt orci euismod. Etiam rutrum dui eget fermentum malesuada. Nullam odio dolor, cursus sit amet tincidunt ac, suscipit at ligula. Praesent quis pellentesque risus, ac accumsan mi."
        
        // Setup
        MountCommand.execute()
        MKFSCommand.execute(10)
        
        // Create
        CreateCommand.execute(fileName1)
        
        // Check
        LSCommand.execute()
        
        // Open
        let openedFileIndex = OpenCommand.execute(fileName1)
        
        // Write
        WriteCommand.execute(
            WriteCommand.InputType(
                numericOpenedFileDescriptor: openedFileIndex,
                offset: 0,
                data: data
            )
        )
        
        // Read
        ReadCommand.execute(
            ReadCommand.InputType(
                numericOpenedFileDescriptor: openedFileIndex,
                offset: 0,
                size: data.count
            )
        )
        
        // Check blocks
        DebugCommand.execute()
        
        // Close
        CloseCommand.execute(openedFileIndex)
        
        // Umount
        UMountCommand.execute()
    }
    
    static func testOffset() {
        
        print("\n\n\n****** TEST Write With Offset ******")
        
        let fileName1 = "Big.file"
        let data1 = "Lorem ipsum dolor"
        let data2 = "test text"

        // Setup
        MountCommand.execute()
        MKFSCommand.execute(10)
        
        // Create
        CreateCommand.execute(fileName1)
        
        // Check
        LSCommand.execute()
        
        // Open
        let openedFileIndex = OpenCommand.execute(fileName1)
        
        // Write
        WriteCommand.execute(
            WriteCommand.InputType(
                numericOpenedFileDescriptor: openedFileIndex,
                offset: 0,
                data: data1
            )
        )
        
        WriteCommand.execute(
            WriteCommand.InputType(
                numericOpenedFileDescriptor: openedFileIndex,
                offset: 6,
                data: data2
            )
        )
        
        // Read
        ReadCommand.execute(
            ReadCommand.InputType(
                numericOpenedFileDescriptor: openedFileIndex,
                offset: 0,
                size: nil
            )
        )
        
        // Check blocks
        DebugCommand.execute()
        
        // Close
        CloseCommand.execute(openedFileIndex)
        
        // Umount
        UMountCommand.execute()
    }
    
    static func testTruncate() {
        
        print("\n\n\n****** TEST Truncate File ******")
        
        let fileName1 = "Big.file"
        let data = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Etiam in posuere tellus. Mauris non dui augue. Nullam eget maximusus odio. Donec finibus, leo vel placerat facilisis, libero orci pellentesque nisi, eu eleifend urna urna sed est. Mauris porttitor ex nec justo volutpat, in tincidunt orci euismod. Etiam rutrum dui eget fermentum malesuada. Nullam odio dolor, cursus sit amet tincidunt ac, suscipit at ligula. Praesent quis pellentesque risus, ac accumsan mi."
        let truncateSize = 40
        
        // Setup
        MountCommand.execute()
        MKFSCommand.execute(10)
        
        // Create
        CreateCommand.execute(fileName1)
        
        // Check
        LSCommand.execute()
        
        // Open
        let openedFileIndex = OpenCommand.execute(fileName1)
        
        // Write
        WriteCommand.execute(
            WriteCommand.InputType(
                numericOpenedFileDescriptor: openedFileIndex,
                offset: 0,
                data: data
            )
        )
        
        // Read before truncate
        ReadCommand.execute(
            ReadCommand.InputType(
                numericOpenedFileDescriptor: openedFileIndex,
                offset: 0,
                size: data.count
            )
        )
        
        // Truncate
        TruncateCommand.execute(
            TruncateCommand.InputType(
                name: fileName1,
                size: truncateSize
            )
        )
        
        // Read after truncate
        ReadCommand.execute(
            ReadCommand.InputType(
                numericOpenedFileDescriptor: openedFileIndex,
                offset: 0,
                size: truncateSize
            )
        )
        
        // Close
        CloseCommand.execute(openedFileIndex)
        
        // Umount
        UMountCommand.execute()
    }
    
    static func testLinks() {
        
        print("\n\n\n****** TEST Links ******")
        
        let fileName = "Test.txt"
        let data = "Here is test data."
        let link1 = "Link.link"
        let link2 = "Another link"
        
        // Setup
        MountCommand.execute()
        MKFSCommand.execute(10)
        
        // Create
        CreateCommand.execute(fileName)
        LSCommand.execute()
        
        // Open
        let openedFileIndex = OpenCommand.execute(fileName)
        
        // Write
        WriteCommand.execute(
            WriteCommand.InputType(
                numericOpenedFileDescriptor: openedFileIndex,
                offset: 0,
                data: data
            )
        )
        
        // Read
        ReadCommand.execute(
            ReadCommand.InputType(
                numericOpenedFileDescriptor: openedFileIndex,
                offset: 0,
                size: data.count
            )
        )
        
        // Close
        CloseCommand.execute(openedFileIndex)
        
        // Create first link and check it
        LinkCommand.execute(
            LinkCommand.InputType(
                name: fileName,
                linkName: link1
            )
        )
        LSCommand.execute()
        
        // Create second link and check it
        LinkCommand.execute(
            LinkCommand.InputType(
                name: fileName,
                linkName: link2
            )
        )
        LSCommand.execute()
        
        // Unlink first link
        UnlinkCommand.execute(link1)
        LSCommand.execute()
        
        // Open second link and read data
        let openedLinkIndex = OpenCommand.execute(link2)
        ReadCommand.execute(
            ReadCommand.InputType(
                numericOpenedFileDescriptor: openedLinkIndex,
                offset: 0,
                size: data.count
            )
        )
        LSCommand.execute()

        // Close
        CloseCommand.execute(openedLinkIndex)
        
        // Umount
        UMountCommand.execute()
    }
}
