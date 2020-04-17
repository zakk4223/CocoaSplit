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
@synthesize fontSizeAdjust = _fontSizeAdjust;

-(instancetype)init
{
    if (self = [super init])
    {
        _lineLimit = 0;
        _startLine = 0;
        _collapseLines = NO;
        _fontSizeAdjust = 0;
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
    [aCoder encodeInt:self.fontSizeAdjust forKey:@"fontSizeAdjust"];
}

-(void)restoreWithCoder:(NSCoder *)aDecoder
{
    [super restoreWithCoder:aDecoder];
    
    _lineLimit = [aDecoder decodeIntForKey:@"lineLimit"];
    _startLine = [aDecoder decodeIntForKey:@"startLine"];
    if ([aDecoder containsValueForKey:@"fontSizeAdjust"])
    {
        _fontSizeAdjust = [aDecoder decodeIntForKey:@"fontSizeAdjust"];
    }
    
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

-(void)setFontSizeAdjust:(int)fontSizeAdjust
{
    _fontSizeAdjust = fontSizeAdjust;
    [self openFile:self.currentFile];
}

-(int)fontSizeAdjust
{
    return _fontSizeAdjust;
}


-(void)setCurrentFile:(NSString *)currentFile
{
    [self openFile:currentFile];
    _currentFile = currentFile;

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
    
    

    if (!filename)
    {
        [self cancelWatch];
        return;
    }
    
    if (self.currentFile && ![self.currentFile isEqualToString:filename])
    {
        [self cancelWatch];
    }

    dispatch_async(_fileChangeQueue, ^{
        NSData *fileData = [NSData dataWithContentsOfFile:filename];
        [self watchPath:filename];
        [self processFileData:fileData];
    });

}


-(void)processFileData:(NSData *)fileData
{
    
    NSDictionary *documentAttributes = nil;
    
    NSMutableAttributedString *fileAttributedString = [[NSMutableAttributedString alloc] initWithData:fileData options:@{NSCharacterEncodingDocumentOption:@(NSUTF8StringEncoding)} documentAttributes:&documentAttributes error:nil];
    
    
    

   if (fileAttributedString && [documentAttributes[NSDocumentTypeDocumentAttribute] isEqualToString:NSPlainTextDocumentType])
   {
        //self.currentFile = filename;
        NSString *fileText = fileAttributedString.string;
        
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
        

       self.attributedText = [[NSAttributedString alloc] initWithString:fileText attributes:self.defaultAttributes];
   } else if (fileAttributedString) {
       [fileAttributedString beginEditing];
       [fileAttributedString enumerateAttribute:NSFontAttributeName inRange:NSMakeRange(0, fileAttributedString.length) options:0 usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
           NSFont *fontAttribute = value;
           NSFont *newFont = [NSFont fontWithDescriptor:fontAttribute.fontDescriptor size:fontAttribute.pointSize+self.fontSizeAdjust];
           [fileAttributedString removeAttribute:NSFontAttributeName range:range];
           [fileAttributedString addAttribute:NSFontAttributeName value:newFont range:range];
       }];
       [fileAttributedString endEditing];
       //self.text = nil;
       self.attributedText = fileAttributedString;
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
    __block typeof(self) blockSelf = self;
    
    _fileSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE, fd, DISPATCH_VNODE_DELETE | DISPATCH_VNODE_WRITE | DISPATCH_VNODE_RENAME | DISPATCH_VNODE_REVOKE, _fileChangeQueue);
    
    dispatch_source_set_event_handler(_fileSource, ^{
        unsigned long flags = dispatch_source_get_data(blockSelf->_fileSource);
        //NSLog(@"FLAGS %lu", flags);
        if (flags & DISPATCH_VNODE_DELETE)
        {
            dispatch_source_cancel(blockSelf->_fileSource);
            blockSelf->_fileSource = NULL;
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
