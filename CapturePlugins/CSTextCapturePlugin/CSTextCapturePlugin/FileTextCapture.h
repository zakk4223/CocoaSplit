//
//  FileTextCapture.h
//  CSTextCapturePlugin
//
//  Created by Zakk on 12/31/14.
//

#import "CSTextCaptureBase.h"

@interface FileTextCapture : CSTextCaptureBase
{
    dispatch_source_t _fileSource;
    dispatch_queue_t _fileChangeQueue;
}

@property (assign) int startLine;
@property (assign) int lineLimit;
@property (assign) bool collapseLines;
@property (assign) bool readAsHTML;
@property (assign) int fontSizeAdjust;
@property (strong) NSString *currentFile;

-(void)openFile:(NSString *)filename;


@end
