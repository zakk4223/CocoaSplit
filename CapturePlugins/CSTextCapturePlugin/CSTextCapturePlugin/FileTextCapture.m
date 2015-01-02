//
//  FileTextCapture.m
//  CSTextCapturePlugin
//
//  Created by Zakk on 12/31/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "FileTextCapture.h"

@implementation FileTextCapture


-(instancetype)init
{
    if (self = [super init])
    {
        self.lineLimit = 0;
        self.collapseLines = NO;
    }
    
    return self;
}


-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.currentFile forKey:@"currentFile"];
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        NSString *fileName = [aDecoder decodeObjectForKey:@"currentFile"];
        [self openFile:fileName];
    }
    return self;
}


+(NSString *)label
{
    return @"Text File";
}


-(void)openFile:(NSString *)filename
{
    [self cancelWatch];
    
    self.currentFile = filename;
    NSString *fileText = [[NSString alloc] initWithContentsOfFile:filename encoding:NSUTF8StringEncoding error:nil];
    
    if (self.lineLimit > 0)
    {
        NSArray *lines = [fileText componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        long useLimit = self.lineLimit;
        
        if (useLimit > lines.count)
        {
            useLimit = lines.count;
        }
        
        NSArray *lineSlice = [lines subarrayWithRange:NSMakeRange(0, useLimit)];
        fileText = [lineSlice componentsJoinedByString:@"\n"];
    }
    
    if (self.collapseLines)
    {
        fileText = [fileText stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
    }
    
    self.text = fileText;
    [self watchPath:filename];
}



-(void)cancelWatch
{
    if (_fileSource)
    {
        dispatch_source_cancel(_fileSource);
    }
    
    _fileSource = nil;
}


-(void)watchPath:(NSString *)filePath
{
    int fd = open([filePath UTF8String], O_EVTONLY);
    
    __block typeof(self) blockSelf = self;
    
    _fileSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE, fd, DISPATCH_VNODE_DELETE | DISPATCH_VNODE_WRITE | DISPATCH_VNODE_EXTEND | DISPATCH_VNODE_ATTRIB | DISPATCH_VNODE_LINK | DISPATCH_VNODE_RENAME | DISPATCH_VNODE_REVOKE, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
    
    dispatch_source_set_event_handler(_fileSource, ^{
        unsigned long flags = dispatch_source_get_data(blockSelf->_fileSource);
        
        if (flags & DISPATCH_VNODE_DELETE)
        {
            dispatch_source_cancel(blockSelf->_fileSource);
            [blockSelf watchPath:filePath];
        } else {
            [self openFile:filePath];
        }
        
    });
    
    dispatch_source_set_cancel_handler(_fileSource, ^{
        close(fd);
    });
    
    dispatch_resume(_fileSource);
}


@end
