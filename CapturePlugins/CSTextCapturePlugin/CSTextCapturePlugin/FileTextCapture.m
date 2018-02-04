//
//  FileTextCapture.m
//  CSTextCapturePlugin
//
//  Created by Zakk on 12/31/14.
//

#import "FileTextCapture.h"

@implementation FileTextCapture

@synthesize currentFile = _currentFile;
@synthesize startLine = _startLine;
@synthesize lineLimit = _lineLimit;

-(instancetype)init
{
    if (self = [super init])
    {
        self.lineLimit = 0;
        self.startLine = 0;
        self.collapseLines = NO;
    }
    
    return self;
}


-(void)saveWithCoder:(NSCoder *)aCoder
{
    [super saveWithCoder:aCoder];
    [aCoder encodeObject:self.currentFile forKey:@"currentFile"];
    [aCoder encodeInt:self.startLine forKey:@"startLine"];
    [aCoder encodeInt:self.lineLimit forKey:@"lineLimit"];
}

-(void)restoreWithCoder:(NSCoder *)aDecoder
{
    [super restoreWithCoder:aDecoder];
    
    _lineLimit = [aDecoder decodeIntForKey:@"lineLimit"];
    _startLine = [aDecoder decodeIntForKey:@"startLine"];
    self.currentFile = [aDecoder decodeObjectForKey:@"currentFile"];
}


+(NSSet *)mediaUTIs
{
    return [NSSet setWithArray:@[@"public.plain-text"]];
}


+(NSObject<CSCaptureSourceProtocol> *)createSourceFromPasteboardItem:(NSPasteboardItem *)item
{
    
    FileTextCapture *ret = nil;
    
    NSString *textPath = [item stringForType:@"public.file-url"];
    if (textPath)
    {
        NSURL *fileURL = [NSURL URLWithString:textPath];
        NSString *realPath = [fileURL path];
        ret = [[FileTextCapture alloc] init];
        ret.currentFile = realPath;
    }
    return ret;
}


-(void)setStartLine:(int)startLine
{
    _startLine = startLine;
    [self openFile:self.currentFile];
}

-(int)startLine
{
    return _startLine;
}

-(void)setLineLimit:(int)lineLimit
{
    _lineLimit = lineLimit;
    [self openFile:self.currentFile];
}

-(int)lineLimit
{
    return _lineLimit;
}


-(void)setCurrentFile:(NSString *)currentFile
{
    _currentFile = currentFile;
    [self openFile:self.currentFile];
}

-(NSString *)currentFile
{
    return _currentFile;
}


+(NSString *)label
{
    return @"Text File";
}


-(void)openFile:(NSString *)filename
{
    if (!self.currentFile)
    {
        return;
    }
    [self cancelWatch];
    
    //self.currentFile = filename;
    NSString *fileText = [[NSString alloc] initWithContentsOfFile:filename encoding:NSUTF8StringEncoding error:nil];
    
    long lineCount = self.lineLimit;
    long startLine = self.startLine;
    
    
    if (lineCount || startLine)
    {
        NSArray *lines = [fileText componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        if (startLine > lines.count)
        {
            startLine = 0;
        }
        
        long totalLength = lines.count - startLine;
        
        if (lineCount > totalLength)
        {
            lineCount = totalLength;
        }
        
        NSArray *lineSlice = [lines subarrayWithRange:NSMakeRange(startLine, lineCount)];
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
