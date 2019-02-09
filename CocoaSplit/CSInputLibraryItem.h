//
//  CSInputLibraryItem.h
//  CocoaSplit
//
//  Created by Zakk on 10/18/15.
//

#import <Foundation/Foundation.h>
#import "InputSource.h"


@interface CSInputLibraryItem : NSObject <NSPasteboardReading, NSPasteboardWriting, NSCoding>

@property (strong) NSString *name;
@property (strong) NSData *inputData;
@property (strong) NSImage *inputImage;
@property (assign) bool autoFit;
@property (assign) bool transient;
@property (strong) InputSource *editInput;


-(instancetype) initWithInput:(NSObject<CSInputSourceProtocol> *)input;
-(void)makeDataFromInput:(NSObject<CSInputSourceProtocol> *)input;
-(InputSource *)makeInput;

@end
