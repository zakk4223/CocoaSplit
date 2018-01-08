//
//  CAMultiAudioEngineInputsController.m
//  CocoaSplit
//
//  Created by Zakk on 1/4/18.

#import "CAMultiAudioEngineInputsController.h"
#import "CAMultiAudioNode.h"
#import "CAMultiAudioMatrixMixerWindowController.h"
#import "CAMultiAudioFile.h"
#import "CAMultiAudioEngine.h"
#import "CaptureController.h"

@interface CAMultiAudioEngineInputsController ()

@end

@implementation CAMultiAudioEngineInputsController

-(void)awakeFromNib
{
    if (!_mixerWindows)
    {
        _mixerWindows = [NSMutableDictionary dictionary];
        _viewOnly = NO;
        [self.audioTableView registerForDraggedTypes:@[@"cocoasplit.audio.item", NSFilenamesPboardType]];

    }
    [super awakeFromNib];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}


-(void)openMixerWindow:(CAMultiAudioNode *)node
{
    
    
    if (node)
    {
        CAMultiAudioMatrixMixerWindowController *mixerWindow = [[CAMultiAudioMatrixMixerWindowController alloc] initWithAudioMixer:node];
        [mixerWindow showWindow:nil];

        mixerWindow.window.title = node.name;
        mixerWindow.window.identifier = node.nodeUID;
        mixerWindow.window.delegate = self;
        
        [_mixerWindows setObject:mixerWindow forKey:node.nodeUID];
    }
    
}

-(void)windowWillClose:(NSNotification *)notification
{
    NSWindow *closedWindow = notification.object;
    
    if (closedWindow.identifier)
    {
        [_mixerWindows removeObjectForKey:closedWindow.identifier];
    }
}

-(void)removeFileAudio:(CAMultiAudioFile *)toDelete
{
    CAMultiAudioEngine *engine = self.multiAudioEngineController.content;
    
    [engine removeFileInput:toDelete];
}

-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    CAMultiAudioNode *audioNode = [self.audioInputsController.arrangedObjects objectAtIndex:row];
    if ([audioNode isKindOfClass:CAMultiAudioFile.class])
    {
        return [tableView makeViewWithIdentifier:@"fileAudioView" owner:self];
    } else {
        return [tableView makeViewWithIdentifier:@"standardAudioView" owner:self];
    }
}

-(BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
    
    
    NSArray *audioNodes = [self.audioInputsController.arrangedObjects objectsAtIndexes:rowIndexes];
    
    NSPasteboardItem *pItem = [[NSPasteboardItem alloc] init];
    
    NSArray *audioUIDS = [audioNodes valueForKey:@"nodeUID"];
    
    
    [pItem setPropertyList:audioUIDS forType:@"cocoasplit.audio.item"];
    [pboard writeObjects:@[pItem]];
    
    return YES;
}

-(NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation
{
    NSPasteboard *pb = [info draggingPasteboard];
    
    if (self.viewOnly)
    {
        return NSDragOperationNone;
    }
    
    
    if ([pb.types containsObject:NSFilenamesPboardType])
    {
        return NSDragOperationCopy;
    }
    
    return NSDragOperationNone;
}

-(BOOL)tableView:(NSTableView *)tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation
{
    NSPasteboard *pb = [info draggingPasteboard];
    
    bool retVal = NO;
    for(NSPasteboardItem *item in pb.pasteboardItems)
    {
        
        if ([item.types containsObject:@"public.file-url"])
        {
            NSString *dragPath = [item stringForType:@"public.file-url"];
            if (dragPath)
            {
                NSURL *fileURL = [NSURL URLWithString:dragPath];
                
                if ([[CaptureController sharedCaptureController] fileURLIsAudio:fileURL])
                {
                    NSString *realPath = [fileURL path];
                    
                    [self.multiAudioEngineController.content createFileInput:realPath];
                    retVal = YES;
                }
            }
        }
        
    }
    
    return retVal;
}



@end
