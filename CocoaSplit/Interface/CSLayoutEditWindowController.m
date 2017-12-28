//
//  CSLayoutEditWindowController.m
//  CocoaSplit
//
//  Created by Zakk on 10/12/15.
//  Copyright © 2015 Zakk. All rights reserved.
//

#import "CSLayoutEditWindowController.h"
#import "CSInputSourceProtocol.h"
#import "CSAudioInputSource.h"


@interface CSLayoutEditWindowController ()

@end

@implementation CSLayoutEditWindowController


-(instancetype) init
{
    _inputViewSortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"depth" ascending:NO]];

    return [self initWithWindowNibName:@"CSLayoutEditWindowController"];
}


- (void)windowDidLoad {
    [super windowDidLoad];
    self.window.delegate = self;
    [self.inputOutlineView registerForDraggedTypes:@[NSSoundPboardType,NSFilenamesPboardType, NSFilesPromisePboardType, NSFileContentsPboardType, @"cocoasplit.input.item", @"cocoasplit.audio.item"]];

    if (self.previewView.sourceLayout.recorder)
    {
        [self.previewView disablePrimaryRender];
    }
    [self.previewView addObserver:self forKeyPath:@"sourceLayout.recorder" options:NSKeyValueObservingOptionNew context:NULL];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}


-(NSString *)windowTitle
{
    return [NSString stringWithFormat:@"Layout - %@", self.previewView.sourceLayout.name];
}


-(void)windowWillClose:(NSNotification *)notification
{
    
    [self.previewView removeObserver:self forKeyPath:@"sourceLayout.recorder"];
    if (self.layoutController)
    {
        [self.layoutController discardEditing];
    }
    
    if (self.previewView.sourceLayout && !self.previewView.sourceLayout.recordingLayout)
    {
        [self.previewView.sourceLayout clearSourceList];
    }
    
    if (self.delegate)
    {
        [self.delegate layoutWindowWillClose:self];
    }
}



- (IBAction)cancelEdit:(id)sender
{
    [self close];
}



- (IBAction)editOK:(id)sender
{
    if (self.layoutController)
    {
        [self.layoutController commitEditing];
    }
        
    if (self.previewView.sourceLayout)
    {
        [self.previewView.sourceLayout saveSourceList];
        [self.previewView.sourceLayout clearSourceList];
    }
    [self close];
}



-(BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pasteboard
{
    
    NSPasteboardItem *pItem = [[NSPasteboardItem alloc] init];
    
    NSMutableArray *sourceIDS = [NSMutableArray array];
    for (NSTreeNode *node in items)
    {
        NSObject<CSInputSourceProtocol> *iSrc = node.representedObject;
        NSString *iUUID = iSrc.uuid;
        [sourceIDS addObject:iUUID];
        
    }
    [pItem setPropertyList:sourceIDS forType:@"cocoasplit.input.item"];
    [pasteboard writeObjects:@[pItem]];
    return YES;
}

-(NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id<NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)index
{
    
    NSTreeNode *nodeItem = (NSTreeNode *)item;
    InputSource *nodeInput = nil;
    if (nodeItem)
    {
        nodeInput = nodeItem.representedObject;
    }
    
    
    
    
    NSPasteboard *pb = [info draggingPasteboard];
    
    
    
    if ([pb.types containsObject:@"cocoasplit.audio.item" ])
    {
        if (item)
        {
            return NSDragOperationNone;
        } else {
            return NSDragOperationMove;
        }
    }
    
    NSArray *draggedUUIDS = [pb propertyListForType:@"cocoasplit.input.item"];
    if (draggedUUIDS && draggedUUIDS.lastObject)
    {
        NSString *draggedUUID = draggedUUIDS.lastObject;
        NSObject<CSInputSourceProtocol> *pdraggedSource = [self.previewView.sourceLayout inputForUUID:draggedUUID];
        
        
        
        if (!pdraggedSource || !pdraggedSource.layer)
        {
            return NSDragOperationNone;
        }
        
        InputSource *draggedSource = (InputSource *)pdraggedSource;
        
        if (nodeInput && nodeInput == draggedSource)
        {
            return NSDragOperationNone;
        }
        
        if (nodeInput && draggedSource.parentInput == nodeInput)
        {
            return NSDragOperationNone;
        }
        
        
        if (draggedSource.parentInput && nodeInput && nodeInput != draggedSource.parentInput)
        {
            return NSDragOperationMove;
        }
        
        
        if (draggedSource.parentInput && !nodeInput)
        {
            return NSDragOperationMove;
        }
        
        
        if (item && index == -1)
        {
            return NSDragOperationMove;
        }
    }
    return NSDragOperationMove;
}


-(CAMultiAudioNode *)findNodeForUUID:(NSString *)uuid
{
    CAMultiAudioEngine *useEngine = nil;
    if (self.previewView.sourceLayout.recorder && self.previewView.sourceLayout.recorder.audioEngine)
    {
        useEngine = self.previewView.sourceLayout.recorder.audioEngine;
    } else {
        useEngine = [CaptureController sharedCaptureController].multiAudioEngine;
    }
    
    return [useEngine inputForUUID:uuid];
}

-(IBAction)inputOutlineViewDoubleClick:(NSOutlineView *)outlineView
{
    NSTreeNode *node = [outlineView itemAtRow:outlineView.clickedRow];
    if (node)
    {
        NSObject<CSInputSourceProtocol> *src = node.representedObject;
        [self.previewView openInputConfigWindow:src.uuid];
    }
}


-(BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id<NSDraggingInfo>)info item:(id)item childIndex:(NSInteger)index
{
    
    NSPasteboard *pb = [info draggingPasteboard];
    
    NSArray *audioUUIDS = [pb propertyListForType:@"cocoasplit.audio.item"];
    if (audioUUIDS)
    {
        for(NSString *aUID in audioUUIDS)
        {
            CAMultiAudioNode *audioNode = [CaptureController.sharedCaptureController.multiAudioEngine inputForUUID:aUID];
            if (audioNode)
            {
                CSAudioInputSource *newSource = [[CSAudioInputSource alloc] initWithAudioNode:audioNode];
                [self.previewView addInputSourceWithInput:newSource];
                
            }
        }
        return YES;
    }
    
    NSArray *draggedUUIDS = [pb propertyListForType:@"cocoasplit.input.item"];
    
    NSTreeNode *parentNode = (NSTreeNode *)item;
    InputSource *parentSource = nil;
    
    
    NSIndexPath *droppedIdxPath = nil;
    
    if (parentNode)
    {
        parentSource = parentNode.representedObject;
        droppedIdxPath = [[parentNode indexPath] indexPathByAddingIndex:index];
    } else {
        droppedIdxPath = [NSIndexPath indexPathWithIndex:index];
    }
    
    
    NSTreeNode *idxNode = nil;
    float newDepth = 1;
    
    if (index == -1)
    {
        newDepth = -FLT_MAX;
    } else {
        idxNode = [self.inputTreeController.arrangedObjects descendantNodeAtIndexPath:droppedIdxPath];
        
    }
    
    
    if (idxNode)
    {
        NSObject<CSInputSourceProtocol> *iSrc = idxNode.representedObject;
        if (iSrc.layer)
        {
            InputSource *dSrc = (InputSource *)iSrc;
            newDepth = dSrc.depth + 1;
        } else {
            newDepth = -FLT_MAX;
        }
    }
    
    
    if (draggedUUIDS)
    {
        
        for (NSString *srcID in draggedUUIDS.reverseObjectEnumerator)
        {
            
            NSObject <CSInputSourceProtocol> *pSrc = [self.previewView.sourceLayout inputForUUID:srcID];
            if (!pSrc || !pSrc.layer)
            {
                continue;
            }
            
            InputSource *iSrc = (InputSource *)pSrc;
            if (iSrc.parentInput)
            {
                if ([draggedUUIDS containsObject:iSrc.parentInput.uuid])
                {
                    continue;
                }
                
                [iSrc.parentInput detachInput:iSrc];
                
            }
            if (parentSource)
            {
                [parentSource attachInput:iSrc];
            }
            iSrc.depth = newDepth++;
        }
        
        
        [self.previewView.sourceLayout generateTopLevelSourceList];
        return YES;
    }
    
    bool retVal = NO;
    
    
    for(NSPasteboardItem *item in pb.pasteboardItems)
    {
        
        NSString *urlString = [item stringForType:@"public.file-url"];
        if (urlString)
        {
            NSURL *fileURL = [NSURL URLWithString:urlString];
            if ([CaptureController.sharedCaptureController fileURLIsAudio:fileURL])
            {
                CSAudioInputSource *audioSrc = [[CSAudioInputSource alloc] initWithPath:fileURL.path];
                [self.previewView addInputSourceWithInput:audioSrc];
                retVal = YES;
                continue;
            }
            
        }
        
        NSObject<CSInputSourceProtocol> *itemSrc = [CaptureController.sharedCaptureController inputSourceForPasteboardItem:item];
        if (itemSrc)
        {
            
            [self.previewView addInputSourceWithInput:itemSrc];
            if (itemSrc.layer)
            {
                InputSource *lsrc = (InputSource *)itemSrc;
                
                [lsrc autoCenter];
                if (parentSource)
                {
                    [parentSource attachInput:lsrc];
                }
                lsrc.depth = newDepth++;
            }
            retVal = YES;
        }
    }
    
    if (retVal)
    {
        [self.previewView.sourceLayout generateTopLevelSourceList];
        
    }
    return retVal;
}


-(void) resetInputTableHighlights
{
    [self.previewView stopHighlightingAllSources];
    if (self.inputOutlineView && self.inputOutlineView.selectedRowIndexes)
    {
        [self.inputOutlineView.selectedRowIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
            NSTreeNode *node = [self.inputOutlineView itemAtRow:idx];
            NSObject<CSInputSourceProtocol> *src = node.representedObject;
            if (src.layer)
            {
                [self.previewView highlightSource:(InputSource *)src];
            }
        }];
    }
}


-(void)outlineView:(NSOutlineView *)outlineView didAddRowView:(NSTableRowView *)rowView forRow:(NSInteger)row
{
    NSTreeNode *node = [outlineView itemAtRow:row];
    NSObject<CSInputSourceProtocol> *src = node.representedObject;
    if (!src.layer || !((InputSource *)src).parentInput)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [outlineView expandItem:nil expandChildren:YES];
        });
    }
}


-(void) outlineViewSelectionDidChange:(NSNotification *)notification
{
    [self resetInputTableHighlights];
}

-(void)menuEndedTracking:(NSNotification *)notification
{
    NSMenu *menu = notification.object;
    
    if (menu == _inputsMenu)
    {
        _inputsMenu = nil;
    }
}


- (void)topLevelInputClicked:(NSMenuItem *)item
{
    
    
    NSObject *clickedItem = item.representedObject;
    if ([[clickedItem valueForKey:@"instanceLabel"] isEqualToString:@"Script"])
    {
        CSScriptInputSource *newScript = [[CSScriptInputSource alloc] init];
        [self.previewView addInputSourceWithInput:newScript];
        [self.previewView openInputConfigWindow:newScript.uuid];
        return;
    }
    
    NSObject <CSCaptureSourceProtocol> *clickedCapture = (NSObject <CSCaptureSourceProtocol> *)clickedItem;
    
    
    
    InputSource *newSrc = [[InputSource alloc] init];
    newSrc.selectedVideoType = clickedCapture.instanceLabel;
    newSrc.depth = FLT_MAX;
    [self.previewView addInputSourceWithInput:newSrc];
    [self.previewView openInputConfigWindow:newSrc.uuid];
    
}

- (void)videoInputItemClicked:(NSMenuItem *)item
{
    CSAbstractCaptureDevice *clickedDevice;
    clickedDevice = item.representedObject;
    if (clickedDevice)
    {
        InputSource *newSrc =  [[InputSource alloc] init];
        NSObject <CSCaptureSourceProtocol> *clickedCapture = (NSObject <CSCaptureSourceProtocol> *)item.parentItem.representedObject;
        
        newSrc.selectedVideoType = clickedCapture.instanceLabel;
        newSrc.videoInput.activeVideoDevice = clickedDevice;
        newSrc.depth = FLT_MAX;
        [self.previewView addInputSourceWithInput:newSrc];
        [newSrc autoCenter];
        
    }
    
}

-(void)audioInputItemClicked:(NSMenuItem *)item
{
    
    CAMultiAudioNode *audioNode = item.representedObject;
    
    CSAudioInputSource *newSource = [[CSAudioInputSource alloc] initWithAudioNode:audioNode];
    [self.previewView addInputSourceWithInput:newSource];
}

-(void)buildInputSubMenu:(NSMenuItem *)forItem
{
    NSObject <CSCaptureSourceProtocol> *captureObj = forItem.representedObject;
    
    for (CSAbstractCaptureDevice *dev in captureObj.availableVideoDevices)
    {
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:dev.captureName action:nil keyEquivalent:@""];
        item.representedObject = dev;
        item.target = self;
        item.action = @selector(videoInputItemClicked:);
        [forItem.submenu addItem:item];
    }
}


-(void)buildInputMenu
{
    _inputsMenu = [[NSMenu alloc] init];
    
    NSMutableDictionary *pluginMap = [[CSPluginLoader sharedPluginLoader] sourcePlugins];
    
    NSArray *sortedKeys = [pluginMap.allKeys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    
    NSMenuItem *item = nil;
    NSSize iconSize;
    iconSize.width = [[NSFont menuFontOfSize:0] pointSize];
    iconSize.height = iconSize.width;
    for (NSString *inputName in sortedKeys)
    {
        Class captureClass = pluginMap[inputName];
        
        NSObject <CSCaptureSourceProtocol> *newCapture = [[captureClass alloc] init];
        
        item = [[NSMenuItem alloc] initWithTitle:inputName action:nil keyEquivalent:@""];
        item.image = newCapture.libraryImage;
        item.image.size = iconSize;
        item.representedObject = newCapture;
        item.target = self;
        [_inputsMenu addItem:item];
        
        if (newCapture.availableVideoDevices && newCapture.availableVideoDevices.count > 0)
        {
            item.submenu = [[NSMenu alloc] init];
            [self buildInputSubMenu:item];
        } else {
            item.action = @selector(topLevelInputClicked:);
            item.target = self;
        }
    }
    
    item = [[NSMenuItem alloc] initWithTitle:@"Script" action:nil keyEquivalent:@""];
    NSImage *scriptImage  = [NSImage imageNamed:@"NSScriptTemplate"];
    scriptImage.template = NO;
    item.image = scriptImage;
    item.image.size = iconSize;
    item.representedObject = @{@"instanceLabel":@"Script"};
    item.action = @selector(topLevelInputClicked:);
    item.target = self;
    
    [_inputsMenu addItem:item];
    
    item = [[NSMenuItem alloc] initWithTitle:@"Audio" action:nil keyEquivalent:@""];
    NSImage *audioImage = [NSImage imageNamed:@"NSAudioOutputVolumeMedTemplate"];
    audioImage.template = NO;
    item.image = audioImage;
    item.image.size = iconSize;
    item.submenu = [[NSMenu alloc] init];
    
    for(CAMultiAudioInput *input in [CaptureController sharedCaptureController].multiAudioEngine.audioInputs)
    {
        if (input.systemDevice)
        {
            NSMenuItem *audioItem = [[NSMenuItem alloc] initWithTitle:input.name action:nil keyEquivalent:@""];
            audioItem.representedObject = input;
            audioItem.target = self;
            audioItem.action = @selector(audioInputItemClicked:);
            [item.submenu addItem:audioItem];
        }
    }
    
    [_inputsMenu addItem:item];
    
}


-(void)openAddInputPopover:(id)sender sourceRect:(NSRect)sourceRect
{
    [self buildInputMenu];
    
    NSInteger midItem = _inputsMenu.itemArray.count/2;
    NSPoint popupPoint = NSMakePoint(NSMaxY(sourceRect), NSMidY(sourceRect));
    [_inputsMenu popUpMenuPositioningItem:[_inputsMenu itemAtIndex:midItem] atLocation:popupPoint inView:sender];
    
}





- (IBAction)inputTableControlClick:(NSButton *)sender
{
    NSInteger clicked = sender.tag;
    
    NSRect sbounds;
    switch (clicked) {
        case 0:
            sbounds = sender.bounds;
            [self openAddInputPopover:sender sourceRect:sbounds];
            break;
        case 1:
            if (self.inputOutlineView && self.inputOutlineView.selectedRowIndexes)
            {
                [self.inputOutlineView.selectedRowIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
                    NSTreeNode *node = [self.inputOutlineView itemAtRow:idx];
                    InputSource *src = node.representedObject;
                    
                    if (src)
                    {
                        NSString *uuid = src.uuid;
                        NSObject<CSInputSourceProtocol> *realInput = [self.previewView.sourceLayout inputForUUID:uuid];
                        [self.previewView deleteInput:realInput];
                    }
                    
                }];

            }
            break;
        case 2:
            
            if (self.inputOutlineView && self.inputOutlineView.selectedRowIndexes)
            {
                
                [self.inputOutlineView.selectedRowIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
                    NSTreeNode *node = [self.inputOutlineView itemAtRow:idx];
                    NSObject<CSInputSourceProtocol> *src = node.representedObject;
                    
                    if (src)
                    {
                        [self.previewView openInputConfigWindow:src.uuid];
                    }
                    
                }];
            }
            break;
        default:
            break;
    }
}

- (IBAction)layoutGoLive:(id)sender
{
    
    CaptureController *controller = [CaptureController sharedCaptureController];
    SourceLayout *useLayout = controller.activePreviewView.sourceLayout;
    [self.previewView.sourceLayout saveSourceList];
    
    [controller switchToLayout:self.previewView.sourceLayout usingLayout:useLayout];
}


-(NSString *)resolutionDescription
{
    return [NSString stringWithFormat:@"%dx%d@%.2f", self.previewView.sourceLayout.canvas_width, self.previewView.sourceLayout.canvas_height, self.previewView.sourceLayout.frameRate];
}

+(NSSet *)keyPathsForValuesAffectingResolutionDescription
{
    return [NSSet setWithObjects:@"previewView.sourceLayout.canvas_height", @"previewView.sourceLayout.canvas_width", @"previewView.sourceLayout.frameRate", nil];
}


+(NSSet *)keyPathsForValuesAffectingWindowTitle
{
    return [NSSet setWithObjects:@"previewView.sourceLayout.name", nil];
}


-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"sourceLayout.recorder"])
    {
        if (self.previewView.sourceLayout.recorder)
        {
            [self.previewView disablePrimaryRender];
        } else {
            [self.previewView enablePrimaryRender];
        }
    }
}


@end
