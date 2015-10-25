//
//  CSInputLibraryItem.h
//  CocoaSplit
//
//  Created by Zakk on 10/18/15.
//  Copyright © 2015 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CSInputLibraryItem : NSObject <NSPasteboardReading, NSPasteboardWriting, NSCoding>

@property (strong) NSString *name;
@property (strong) NSData *inputData;
@property (strong) NSImage *inputImage;

@end
