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
@synthesize readAsHTML = _readAsHTML;

-(instancetype)init
{
    if (self = [super init])
    {
        self.lineLimit = 0;
        self.startLine = 0;
        self.collapseLines = NO;
        _fileChangeQueue = dispatch_queue_create("File Watch Queue", DISPATCH_QUEUE_SERIAL);
    }
    
    return self;
}


-(void)saveWithCoder:(NSCoder *)aCoder
{
    [super saveWithCoder:aCoder];
    [aCoder encodeObject:self.currentFile forKey:@"currentFile"];
    [aCoder encodeInt:self.startLine forKey:@"startLine"];
    [aCoder encodeInt:self.lineLimit forKey:@"lineLimit"];
    [aCoder encodeBool:self.readAsHTML forKey:@"readAsHTML"];
}

-(void)restoreWithCoder:(NSCoder *)aDecoder
{
    [super restoreWithCoder:aDecoder];
    
    _lineLimit = [aDecoder decodeIntForKey:@"lineLimit"];
    _startLine = [aDecoder decodeIntForKey:@"startLine"];
    _readAsHTML = [aDecoder decodeBoolForKey:@"readAsHTML"];
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

-(void)setReadAsHTML:(bool)readAsHTML
{
    _readAsHTML = readAsHTML;
    [self openFile:self.currentFile];
}

-(bool)readAsHTML
{
    return _readAsHTML;
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
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0
                                             ), ^{
        NSData *fileData = [NSData dataWithContentsOfFile:filename];
        [self watchPath:filename];
        [self processFileData:fileData];
    });
}


-(void)processFileData:(NSData *)fileData
{
    
    if (self.readAsHTML)
    {
        self.text = nil;
        
        NSAttributedString *fileText = [[NSAttributedString alloc] initWithHTML:fileData documentAttributes:nil];
        if (fileText)
        {
            self.attributedText = fileText;
        }
    } else {
        self.attributedText = nil;
        //self.currentFile = filename;
        NSString *fileText = [[NSString alloc] initWithData:fileData encoding:NSUTF8StringEncoding];
        
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
    }
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
    if (_fileSource)
    {
        return;
    }
    
    
    int fd = open([filePath UTF8String], O_EVTONLY);
    NSLog(@"FD IS %d", fd);
    __block typeof(self) blockSelf = self;
    
    _fileSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE, fd, DISPATCH_VNODE_DELETE | DISPATCH_VNODE_WRITE | DISPATCH_VNODE_EXTEND | DISPATCH_VNODE_ATTRIB | DISPATCH_VNODE_LINK | DISPATCH_VNODE_RENAME | DISPATCH_VNODE_REVOKE, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
    
    dispatch_source_set_event_handler(_fileSource, ^{
        unsigned long flags = dispatch_source_get_data(blockSelf->_fileSource);
        
        if (flags & DISPATCH_VNODE_DELETE)
        {
            dispatch_source_cancel(blockSelf->_fileSource);
            blockSelf->_fileSource = NULL;
            [blockSelf watchPath:filePath];
        } else {
            dispatch_async(self->_fileChangeQueue, ^{
                [self openFile:filePath];
            });
        }
        
    });
    
    dispatch_source_set_cancel_handler(_fileSource, ^{
        close(fd);
    });
    
    dispatch_resume(_fileSource);
}


@end
