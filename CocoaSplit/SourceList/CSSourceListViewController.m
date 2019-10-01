//
//  CSSourceListViewController.m
//  CocoaSplit
//
//  Created by Zakk on 1/2/18.

#import "CSSourceListViewController.h"
#import "CSInputSourceProtocol.h"
#import "SourceLayout.h"
#import "CaptureController.h"
#import "CSAudioInputSource.h"
#import "CSScriptInputSource.h"
#import "CSLayoutRecorder.h"
#import "SourceCache.h"

//Thanks stack overflow user "Rob Keniger"

@implementation NSTreeController (CSSearchAddition)

- (NSIndexPath*)indexPathOfObject:(id)anObject
{
    return [self indexPathOfObject:anObject inNodes:[[self arrangedObjects] childNodes]];
}

- (NSIndexPath*)indexPathOfObject:(id)anObject inNodes:(NSArray*)nodes
{
    for(NSTreeNode* node in nodes)
    {
        if([[node representedObject] isEqual:anObject])
            return [node indexPath];
        if([[node childNodes] count])
        {
            NSIndexPath* path = [self indexPathOfObject:anObject inNodes:[node childNodes]];
            if(path)
                return path;
        }
    }
    return nil;
}
@end


@interface CSSourceListViewController ()

@end

@implementation CSSourceListViewController


-(NSMenu *)menuForItem:(id)item
{
    if (item)
    {
        NSObject <CSInputSourceProtocol>*input = item;
        NSInteger idx = 0;
        
        NSMenu *itemMenu = [[NSMenu alloc] initWithTitle:input.name];
        NSMenuItem *menuEntry = [itemMenu insertItemWithTitle:@"Settings" action:@selector(itemSettingsMenu:) keyEquivalent:@"" atIndex:idx++];
        menuEntry.representedObject = item;
        NSString *pinStr = nil;
        if (input.persistent)
        {
            pinStr = @"Unpin";
        } else {
            pinStr = @"Pin";
        }
        
        menuEntry = [itemMenu insertItemWithTitle:pinStr action:@selector(itemPinMenu:) keyEquivalent:@"" atIndex:idx++];
        menuEntry.representedObject = item;
        
        if (input.isVideo)
        {
            InputSource *vidSrc = (InputSource *)input;
            
            menuEntry = [itemMenu insertItemWithTitle:@"Clone" action:@selector(cloneInputSourceMenu:) keyEquivalent:@"" atIndex:idx++];
            menuEntry.representedObject = item;
            
            menuEntry = [itemMenu insertItemWithTitle:@"Clone Without Cache" action:@selector(cloneInputSourceNoCache:) keyEquivalent:@"" atIndex:idx++];
            menuEntry.representedObject = item;
            menuEntry.alternate = YES;
            menuEntry.keyEquivalentModifierMask = NSAlternateKeyMask;
            
            menuEntry = [itemMenu insertItemWithTitle:@"Make Source Private" action:@selector(privatizeSource:) keyEquivalent:@"" atIndex:idx++];
            menuEntry.representedObject = item;
            menuEntry.alternate = YES;
            menuEntry.keyEquivalentModifierMask = NSControlKeyMask;
            
            NSString *freezeStr = nil;
            if (vidSrc.isFrozen)
            {
                freezeStr = @"Unfreeze";
            } else {
                freezeStr = @"Freeze";
            }
            menuEntry = [itemMenu insertItemWithTitle:freezeStr action:@selector(itemFreezeMenu:) keyEquivalent:@"" atIndex:idx++];
            menuEntry.representedObject = item;
        }
        
        menuEntry = [itemMenu insertItemWithTitle:@"Midi Mapping" action:@selector(midiMapInputMenu:) keyEquivalent:@"" atIndex:idx++];
        menuEntry.representedObject = item;
        
        menuEntry = [itemMenu insertItemWithTitle:@"Delete" action:@selector(itemDeleteMenu:) keyEquivalent:@"" atIndex:idx++];
        menuEntry.representedObject = item;
        return itemMenu;
    }
    return nil;
}

-(void)midiMapInputMenu:(NSMenuItem *)menuItem
{
    if (menuItem.representedObject)
    {
        
        [CaptureController.sharedCaptureController openMidiLearnerForResponders:@[menuItem.representedObject]];
    }
}


-(void)itemFreezeMenu:(NSMenuItem *)menuItem
{
    InputSource *input = menuItem.representedObject;
    input.isFrozen = !input.isFrozen;
}


-(void)itemDeleteMenu:(NSMenuItem *)menuItem
{
    NSObject <CSInputSourceProtocol>*input = menuItem.representedObject;
    [self deleteSourcesByUUID:@[input.uuid]];
}


-(void)itemPinMenu:(NSMenuItem *)menuItem
{
    NSObject <CSInputSourceProtocol>*input = menuItem.representedObject;
    input.persistent = !input.persistent;
}


-(void)itemSettingsMenu:(NSMenuItem *)menuItem
{
    [self openInputConfigWindows:@[menuItem.representedObject]];
}

-(void)cloneInputSourceByUUID:(NSString *)uuid
{
    SourceLayout *sourceLayout = self.sourceLayoutController.content;

    InputSource *src = (InputSource *)[sourceLayout inputForUUID:uuid];
    if (src)
    {
        [self cloneInputSource:src];
    }
}



-(void) privatizeSource:(NSMenuItem *)menuItem

{
    InputSource *toClone = nil;
    toClone = (InputSource *)menuItem.representedObject;

    if (toClone)
    {
        [toClone makeSourcePrivate];
    }
}

-(void)undoCloneInput:(NSString *)inputUUID parentUUID:(NSString *)parentUUID
{
    
    SourceLayout *sourceLayout = self.sourceLayoutController.content;

    if (inputUUID)
    {
        NSObject<CSInputSourceProtocol> *clonedSource = [sourceLayout inputForUUID:inputUUID];
        if (clonedSource)
        {
            [sourceLayout deleteSource:clonedSource];
            
        }
    }
    if (parentUUID)
    {
        NSObject<CSInputSourceProtocol> *parentSource = [sourceLayout inputForUUID:parentUUID];
        if (parentSource)
        {
            [[self.undoManager prepareWithInvocationTarget:self] cloneInputSourceByUUID:parentUUID];
        }
    }
}



-(IBAction)cloneInputSourceNoCache:(NSMenuItem *)menuItem
{
    InputSource *toClone = nil;
    toClone = (InputSource *)menuItem.representedObject;
    SourceLayout *sourceLayout = self.sourceLayoutController.content;

    if (toClone)
    {
        InputSource *newSource = [toClone cloneInputNoCache];
        [sourceLayout addSource:newSource];
        
        [[self.undoManager prepareWithInvocationTarget:self] undoCloneInput:newSource.uuid parentUUID:toClone.uuid];
    }
}


-(void)cloneInputSource:(InputSource *)toClone
{
    SourceLayout *sourceLayout = self.sourceLayoutController.content;
    
    if (toClone)
    {
        InputSource *newSource = [toClone cloneInput];
        [sourceLayout addSource:newSource];
        
        [[self.undoManager prepareWithInvocationTarget:self] undoCloneInput:newSource.uuid parentUUID:toClone.uuid];
    }
}
- (IBAction)cloneInputSourceMenu:(NSMenuItem *)menuItem
{
    
    InputSource *toClone = nil;
    toClone = (InputSource *)menuItem.representedObject;
    [self cloneInputSource:toClone];
}



-(void)outlineViewDoubleClick:(NSOutlineView *)sender
{
    NSObject<CSInputSourceProtocol>*src = [sender itemAtRow:sender.clickedRow];
    if (src)
    {
        [self openInputConfigWindows:@[src]];
    }
}

-(id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    
    if (!item)
    {
        SourceLayout *layout = self.sourceLayoutController.content;
        NSArray *sourceList = layout.topLevelSourceList.copy;
        
        if (index < sourceList.count)
        {
            return [sourceList objectAtIndex:index];
        }
    }
    
    
    NSObject<CSInputSourceProtocol> *useItem = item;
    if (useItem.isVideo)
    {
        InputSource *vItem = (InputSource *)useItem;
        return [vItem.attachedInputs objectAtIndex:index];
    }
    
    return nil;
}

-(BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    
    if (!item)
    {
        return YES;
    }
    
    
    NSObject<CSInputSourceProtocol> *useItem = item;
    if (!useItem.isVideo)
    {
        return NO;
    }
    InputSource *vSrc = item;
    return vSrc.attachedInputs.count > 0;
}

-(NSInteger) outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if (!item)
    {
        SourceLayout *layout = self.sourceLayoutController.content;
        return layout.topLevelSourceList.count;
    }
    
    NSObject<CSInputSourceProtocol> *useItem = item;
    if (useItem.isVideo)
    {
        InputSource *vItem = item;
        return vItem.attachedInputs.count;
    }
    
    return 0;
}
-(void)outlineView:(NSOutlineView *)outlineView didAddRowView:(NSTableRowView *)rowView forRow:(NSInteger)row
{
    
    NSObject<CSInputSourceProtocol> *src = [outlineView itemAtRow:row];
    if (!src.isVideo || !((InputSource *)src).parentInput)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [outlineView expandItem:nil expandChildren:YES];
        });
    }
    
}

-(NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    
    NSTableCellView *ret = [outlineView makeViewWithIdentifier:@"defaultView" owner:self];
    ret.objectValue = item;
    return ret;
}


-(BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pasteboard
{
    
    NSPasteboardItem *pItem = [[NSPasteboardItem alloc] init];
    
    NSMutableArray *sourceIDS = [NSMutableArray array];
    NSMutableArray *savedSources = [NSMutableArray array];
    for (NSObject<CSInputSourceProtocol>*iSrc in items)
    {
        NSString *iUUID = iSrc.uuid;
        [sourceIDS addObject:iUUID];
        NSData *saveData = [NSKeyedArchiver archivedDataWithRootObject:iSrc];
        [savedSources addObject:saveData];
        
    }
    [pItem setPropertyList:sourceIDS forType:@"cocoasplit.input.uuids"];
    [pItem setPropertyList:savedSources forType:@"cocoasplit.input.data"];
    [pasteboard writeObjects:@[pItem]];
    return YES;
}

-(NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id<NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)index
{
    
    InputSource *nodeInput = item;
    
    
    
    
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
    
    NSArray *draggedUUIDS = [pb propertyListForType:@"cocoasplit.input.uuids"];
    if (draggedUUIDS && draggedUUIDS.lastObject)
    {
        NSString *draggedUUID = draggedUUIDS.lastObject;
        SourceLayout *sourceLayout = self.sourceLayoutController.content;
        
        NSObject<CSInputSourceProtocol> *pdraggedSource = [sourceLayout inputForUUID:draggedUUID];
        
        
        
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


-(void)addInputSourceWithInput:(NSObject<CSInputSourceProtocol> *)source
{
    SourceLayout *sourceLayout = self.sourceLayoutController.content;
    
    if (sourceLayout)
    {
        if (source.isVideo)
        {
            InputSource *vSrc = (InputSource *)source;
            vSrc.autoPlaceOnFrameUpdate = YES;
        }
        
        [sourceLayout addSource:source];
        NSUndoManager *undoManager = self.view.window.undoManager;
        [[undoManager prepareWithInvocationTarget:self] deleteSourcesByUUID:@[source.uuid]];
    }
}

-(void)attachByUUUID:(NSString *)srcUUID toUUID:(NSString *)toUUID
{
    SourceLayout *sourceLayout = self.sourceLayoutController.content;
    if (!srcUUID || !toUUID) //??
    {
        return;
    }
    
    InputSource *src = (InputSource *)[sourceLayout inputForUUID:srcUUID];
    InputSource *parent = (InputSource *)[sourceLayout inputForUUID:toUUID];
    if (src && parent)
    {
        [parent attachInput:src];
        [[self.view.window.undoManager prepareWithInvocationTarget:self] detachSourcesByUUID:@[src.uuid]];
    }
}



-(void)detachSourcesByUUID:(NSArray *)uuids
{
    SourceLayout *sourceLayout = self.sourceLayoutController.content;
    
    for (NSString *uuid in uuids)
    {
        InputSource *src = (InputSource *)[sourceLayout inputForUUID:uuid];
        InputSource *parent = src.parentInput;
        if (parent)
        {
            [parent detachInput:src];
            [[self.view.window.undoManager prepareWithInvocationTarget:self] attachByUUUID:src.uuid toUUID:parent.uuid];
        }
    }
}


-(void)restoreDepths:(NSDictionary *)depthMap
{
    SourceLayout *sourceLayout = self.sourceLayoutController.content;
    
    NSUndoManager *undoManager = self.view.window.undoManager;
    
    NSMutableDictionary *currentDepths = [NSMutableDictionary dictionary];
    
    for (NSObject <CSInputSourceProtocol> *src in sourceLayout.sourceList)
    {
        [currentDepths setObject:[NSNumber numberWithFloat:src.depth] forKey:src.uuid];
    }
    
    for (NSString *uuid in depthMap)
    {
        NSObject <CSInputSourceProtocol> *src = [sourceLayout inputForUUID:uuid];
        NSNumber *depth = depthMap[uuid];
        float fDepth = depth.floatValue;
        src.depth = fDepth;
    }
    
    [sourceLayout generateTopLevelSourceList];
    [[undoManager prepareWithInvocationTarget:self] restoreDepths:currentDepths];
}


-(void)undoDepthForUUID:(NSString *)uuid oldDepth:(float)oldDepth
{
    SourceLayout *sourceLayout = self.sourceLayoutController.content;
    
    NSUndoManager *undoManager = self.view.window.undoManager;
    
    NSObject <CSInputSourceProtocol> *src = [sourceLayout inputForUUID:uuid];
    if (!src)
    {
        return;
    }
    
    float cDepth = src.depth;
    src.depth = oldDepth;
    if (cDepth != oldDepth)
    {
        [[undoManager prepareWithInvocationTarget:self] undoDepthForUUID:uuid oldDepth:cDepth];
    }
    
    [sourceLayout generateTopLevelSourceList];
}


-(BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id<NSDraggingInfo>)info item:(id)item childIndex:(NSInteger)index
{
    
    NSUndoManager *undoManager = self.view.window.undoManager;
    
    [undoManager beginUndoGrouping];
    NSPasteboard *pb = [info draggingPasteboard];
    SourceLayout *sourceLayout = self.sourceLayoutController.content;
    
    CAMultiAudioEngine *audioEngine;
    if (sourceLayout.recorder && sourceLayout.recorder.audioEngine)
    {
        audioEngine = sourceLayout.recorder.audioEngine;
    } else {
        audioEngine = [CaptureController sharedCaptureController].multiAudioEngine;
    }
    
    
    NSArray *audioUUIDS = [pb propertyListForType:@"cocoasplit.audio.item"];
    if (audioUUIDS)
    {
        for(NSString *aUID in audioUUIDS)
        {
            CAMultiAudioNode *audioNode = [audioEngine inputForUUID:aUID];
            if (audioNode)
            {
                CSAudioInputSource *newSource = [[CSAudioInputSource alloc] initWithAudioNode:audioNode];
                [self addInputSourceWithInput:newSource];
                
            }
        }
        [undoManager endUndoGrouping];
        return YES;
    }
    
    NSArray *draggedUUIDS = [pb propertyListForType:@"cocoasplit.input.uuids"];
    
    InputSource *parentSource = item;
    
    NSMutableDictionary *currentDepths = [NSMutableDictionary dictionary];
    
    for (NSObject <CSInputSourceProtocol> *src in sourceLayout.sourceList)
    {
        [currentDepths setObject:[NSNumber numberWithFloat:src.depth] forKey:src.uuid];
    }
    
    
    

    
    
    NSObject <CSInputSourceProtocol> *iSrc = nil;
    float newDepth = 1.0f;
    
    
    if (index == -1)
    {
        newDepth = -FLT_MAX;
    } else {
        if (index < [outlineView numberOfChildrenOfItem:item])
        {
            iSrc = [outlineView child:index ofItem:item];
        }
    }
    
    
    if (iSrc)
    {
        if (iSrc.isVideo)
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
            
            NSObject <CSInputSourceProtocol> *pSrc = [sourceLayout inputForUUID:srcID];
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
                [[undoManager prepareWithInvocationTarget:self] attachByUUUID:iSrc.uuid toUUID:iSrc.parentInput.uuid];
                
            }
            if (parentSource)
            {
                [parentSource attachInput:iSrc];
                [[undoManager prepareWithInvocationTarget:self] detachSourcesByUUID:@[iSrc.uuid]];
            }
            
            iSrc.depth = newDepth++;
        }
        
        [[undoManager prepareWithInvocationTarget:self] restoreDepths:currentDepths];
        [sourceLayout generateTopLevelSourceList];
        [undoManager endUndoGrouping];
        return YES;
    }
    
    bool retVal = NO;
    
    if ([pb canReadItemWithDataConformingToTypes:@[@"cocoasplit.library.item"]])
    {
        NSArray *classes = @[[CSInputLibraryItem class]];
        NSArray *draggedObjects = [pb readObjectsForClasses:classes options:@{}];
        
        for (CSInputLibraryItem *item in draggedObjects)
        {
            InputSource *iSrc = [item makeInput];
            [iSrc createUUID];
            if (item.autoFit)
            {
                iSrc.autoPlaceOnFrameUpdate = YES;
            }
            [self addInputSourceWithInput:iSrc];
            if (parentSource)
            {
                [parentSource attachInput:iSrc];
            }
            iSrc.depth = newDepth++;
            retVal = YES;
        }
    }
    
    
    for(NSPasteboardItem *item in pb.pasteboardItems)
    {
        
        NSString *urlString = [item stringForType:@"public.file-url"];
        if (urlString)
        {
            NSURL *fileURL = [NSURL URLWithString:urlString];
            if ([self fileURLIsAudio:fileURL])
            {
                CSAudioInputSource *audioSrc = [[CSAudioInputSource alloc] initWithPath:fileURL.path];
                [self addInputSourceWithInput:audioSrc];
                retVal = YES;
                continue;
            }
            
        }
        
        NSObject<CSInputSourceProtocol> *itemSrc = [self inputSourceForPasteboardItem:item];
        if (itemSrc)
        {
            
            [self addInputSourceWithInput:itemSrc];
            
            if (itemSrc.isVideo)
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
        [sourceLayout generateTopLevelSourceList];
        
    }
    return retVal;
}


-(NSString *)primaryTypeForURL:(NSURL *)url
{
    NSString *dType;
    [url getResourceValue:&dType forKey:NSURLTypeIdentifierKey error:nil];
    return dType;
}


-(NSObject<CSInputSourceProtocol>*)inputSourceForPasteboardItem:(NSPasteboardItem *)item
{
    return [CaptureController.sharedCaptureController inputSourceForPasteboardItem:item];
}


-(NSArray *)captureSourcesForPasteboardItem:(NSPasteboardItem *)item
{
    
    NSMutableArray *candidates = [NSMutableArray array];
    
    CSPluginLoader *loader = [CSPluginLoader sharedPluginLoader];
    
    
    NSString *urlString = [item stringForType:@"public.file-url"];
    if (urlString)
    {
        NSURL *fileURL = [NSURL URLWithString:urlString];
        NSString *realPath = [fileURL path];
        
        MDItemRef mditem = MDItemCreate(NULL, (__bridge CFStringRef)realPath);
        if (mditem)
        {
            NSArray *attrs = @[(__bridge NSString *)kMDItemContentTypeTree];
            NSDictionary *attrMap = CFBridgingRelease(MDItemCopyAttributes(mditem, (__bridge CFArrayRef)attrs));
            NSArray *fileTypes = attrMap[(__bridge NSString *)kMDItemContentTypeTree];
            if (fileTypes)
            {
                NSSet *typeSet = [NSSet setWithArray:fileTypes];
                for (NSString *key in loader.sourcePlugins)
                {
                    Class<CSCaptureSourceProtocol> captureClass = loader.sourcePlugins[key];
                    NSSet *captureSet = [captureClass mediaUTIs];
                    if (captureSet)
                    {
                        if([typeSet intersectsSet:captureSet])
                        {
                            [candidates addObject:captureClass];
                        }
                    }
                    
                }
            }
        }
        
    }

    return candidates;
}

-(bool)fileURLIsAudio:(NSURL *)url
{
    NSString *dType = [self primaryTypeForURL:url];
    if (dType && [[CaptureController sharedCaptureController].audioFileUTIs containsObject:dType])
    {
        return YES;
    }
    return NO;
}

-(void)sourceDeleted:(NSNotification *)notification
{
    id <CSInputSourceProtocol> dSrc = notification.object;
    
    NSString *uuid = dSrc.uuid;
    
    NSWindow *configWindow = _activeConfigWindows[uuid];
    if (configWindow)
    {
        [configWindow close];
    }
}


-(void)awakeFromNib
{
    [super awakeFromNib];
    if (!self.sourceTreeSortDescriptors)
    {
        self.sourceTreeSortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"depth" ascending:NO]];
        [self.sourceOutlineView registerForDraggedTypes:@[NSSoundPboardType,NSFilenamesPboardType, NSFilesPromisePboardType, NSFileContentsPboardType, @"cocoasplit.input.uuids", @"cocoasplit.audio.item", @"cocoasplit.layout", @"cocoasplit.library.item"]];

        _activeConfigWindows = [NSMutableDictionary dictionary];
        _activeConfigControllers = [NSMutableDictionary dictionary];
        

    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sourceDeleted:) name:CSNotificationInputDeleted object:nil];

}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    
    if ([keyPath isEqualToString:@"content.topLevelSourceList"])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.sourceOutlineView reloadData];
        });
    }
}
- (void)viewDidLoad {
    [super viewDidLoad];
    if (self.sourceLayoutController)
    {
        [self.sourceLayoutController addObserver:self forKeyPath:@"content.topLevelSourceList" options:NSKeyValueObservingOptionNew context:NULL];
    }
    // Do view setup here.
}


-(void)deleteSourcesByUUID:(NSArray *)uuids
{
    
    NSUndoManager *undoManager = self.view.window.undoManager;
    
    NSMutableArray *undoMap = [NSMutableArray array];
    
    for (NSString *uuid in uuids)
    {
        SourceLayout *srcLayout = self.sourceLayoutController.content;
        
        NSObject <CSInputSourceProtocol> *obj = [srcLayout inputForUUID:uuid];
        if (!obj)
        {
            continue;
        }
        [srcLayout deleteSource:obj];
        NSDictionary *undoEntry = nil;
        if (obj.isVideo)
        {
            InputSource *vsrc = (InputSource *)obj;
            if (vsrc.parentInput)
            {
                undoEntry = @{@"parentUUID": vsrc.parentInput.uuid, @"source": obj};
            }
        }
        
        if (!undoEntry)
        {
            undoEntry = @{@"source": obj};
        }
        
        [undoMap addObject:undoEntry];
    }
    
    NSData *undoData = [NSKeyedArchiver archivedDataWithRootObject:undoMap];
    [[undoManager prepareWithInvocationTarget:self]  undoDeleteSources:undoData];
}


-(void)undoDeleteSources:(NSData *)withData
{
    NSArray *undoList = [NSKeyedUnarchiver unarchiveObjectWithData:withData];
    NSMutableArray *uuids = [NSMutableArray array];
    
    SourceLayout *sourceLayout = self.sourceLayoutController.content;
    for (NSDictionary *undoMap in undoList)
    {
        NSObject <CSInputSourceProtocol> *obj = undoMap[@"source"];
        [sourceLayout addSource:obj];
        [uuids addObject:obj.uuid];
        NSString *parentUUID = [undoMap objectForKey:@"parentUUID"];
        if (obj.isVideo && parentUUID)
        {
            InputSource *vParent = (InputSource *)[sourceLayout inputForUUID:parentUUID];
            [vParent attachInput:(InputSource *)obj];
        }
    }
    NSUndoManager *undoManager = self.view.window.undoManager;
    [[undoManager prepareWithInvocationTarget:self] deleteSourcesByUUID:uuids];
    
}




-(NSArray *)getSelectedItems
{
    NSIndexSet *selectedRows = [self.sourceOutlineView selectedRowIndexes];
    NSMutableArray *selectedItems = [NSMutableArray array];
    
    [selectedRows enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        id item = [self.sourceOutlineView itemAtRow:idx];
        if (item)
        {
            [selectedItems addObject:item];
        }
    }];
    
    return selectedItems;
}

-(IBAction)sourceDeleteClicked:(NSButton *)sender
{
    
    NSArray *selectedSources = [self getSelectedItems];
    
    NSUndoManager *undoManager = self.view.window.undoManager;

    NSMutableArray *undoMap = [NSMutableArray array];
    
    for (NSObject<CSInputSourceProtocol> *obj in selectedSources)
    {
        SourceLayout *srcLayout = self.sourceLayoutController.content;
        
        [srcLayout deleteSource:obj];
        NSDictionary *undoEntry = nil;
        if (obj.isVideo)
        {
            InputSource *vsrc = (InputSource *)obj;
            if (vsrc.parentInput)
            {
                undoEntry = @{@"parentUUID": vsrc.parentInput.uuid, @"source": obj};
            }
        }
        
        if (!undoEntry)
        {
            undoEntry = @{@"source": obj};
        }
        
        [undoMap addObject:undoEntry];
    }
    
    self.selectedObjects  = @[];
    
    NSData *undoData = [NSKeyedArchiver archivedDataWithRootObject:undoMap];
    [[undoManager prepareWithInvocationTarget:self]  undoDeleteSources:undoData];
}


-(IBAction)sourceConfigClicked:(NSButton *)sender
{
    NSArray *selectedSources = [self getSelectedItems];
    [self openInputConfigWindows:selectedSources];
}

-(IBAction)sourceAddClicked:(NSButton *)sender
{
    NSRect sbounds = sender.bounds;
    
    [self openAddInputPopover:sender sourceRect:sbounds];
}


-(void)highlightSources:(NSArray *)sources
{
    NSMutableIndexSet *selectedRows = [[NSMutableIndexSet alloc] init];
    
    for (NSObject *src in sources)
    {
        NSInteger idx = [self.sourceOutlineView rowForItem:src];
        
        [selectedRows addIndex:idx];
    }
    
    [self.sourceOutlineView selectRowIndexes:selectedRows byExtendingSelection:NO];
}

-(void)outlineViewSelectionDidChange:(NSNotification *)notification
{
    
    self.selectedObjects = [self getSelectedItems];

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
        
        
        [self addInputSourceWithInput:newScript];
        [self openInputConfigWindows:@[newScript]];
        return;
    }
    
    NSObject <CSCaptureSourceProtocol> *clickedCapture = (NSObject <CSCaptureSourceProtocol> *)clickedItem;
    
    
    
    InputSource *newSrc = [[InputSource alloc] init];
    newSrc.selectedVideoType = clickedCapture.instanceLabel;
    newSrc.depth = FLT_MAX;
    [self addInputSourceWithInput:newSrc];
    [self openInputConfigWindows:@[newSrc]];

}

- (void)videoInputItemClicked:(NSMenuItem *)item
{
    CSAbstractCaptureDevice *clickedDevice;
    clickedDevice = item.representedObject;
    if (clickedDevice)
    {
        InputSource *newSrc =  [[InputSource alloc] init];
        NSObject <CSCaptureSourceProtocol> *clickedCapture = (NSObject <CSCaptureSourceProtocol> *)item.parentItem.representedObject;
        [self addInputSourceWithInput:newSrc];

        newSrc.selectedVideoType = clickedCapture.instanceLabel;
        newSrc.activeVideoDevice = clickedDevice;
        newSrc.depth = FLT_MAX;
        [newSrc autoCenter];
        
    }
    
}

-(void)audioInputItemClicked:(NSMenuItem *)item
{
    
    NSString *audioUUID = item.representedObject;
    
    SourceLayout *sourceLayout = self.sourceLayoutController.content;
    CAMultiAudioEngine *useEngine = [sourceLayout findAudioEngine];
    if (!useEngine)
    {
        useEngine = CaptureController.sharedCaptureController.multiAudioEngine;
    }
    CAMultiAudioInput *audioNode = [useEngine inputForSystemUUID:audioUUID];
    
    CSAudioInputSource *newSource = [[CSAudioInputSource alloc] initWithAudioNode:audioNode];
    [self addInputSourceWithInput:newSource];
}

-(void)buildInputSubMenu:(NSMenuItem *)forItem
{
    NSObject <CSCaptureSourceProtocol> *captureObj = forItem.representedObject;
    
    for (CSAbstractCaptureDevice *dev in captureObj.availableVideoDevices)
    {
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:dev.captureName action:nil keyEquivalent:@""];
        item.representedObject = dev;
        if (dev.uniqueID)
        {
            item.target = self;
            item.action = @selector(videoInputItemClicked:);
        }
        [forItem.submenu addItem:item];
    }
}


-(void)menuNeedsUpdate:(NSMenu *)menu
{
    NSMenu *parentMenu = menu.supermenu;
    NSInteger itemIdx = [parentMenu indexOfItemWithSubmenu:menu];
    if (itemIdx > -1)
    {
        NSMenuItem *parentItem = [parentMenu itemAtIndex:itemIdx];
        if (parentItem)
        {
            [menu removeAllItems];
            [self buildInputSubMenu:parentItem];
        }
    }
}

-(void)libraryItemMenuClicked:(NSMenuItem *)menuItem
{
    CSInputLibraryItem *libraryItem = menuItem.representedObject;
    if (libraryItem)
    {
        InputSource *iSrc = [libraryItem makeInput];
        [self addInputSourceWithInput:iSrc];
    }
}


-(NSMenuItem *)buildCustomInputMenu
{
    NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"Custom Inputs" action:nil keyEquivalent:@""];
    menuItem.submenu = [[NSMenu alloc] init];
    for (CSInputLibraryItem *libraryItem in CaptureController.sharedCaptureController.inputLibrary)
    {
        NSMenuItem *lItem = [[NSMenuItem alloc] initWithTitle:libraryItem.name action:@selector(libraryItemMenuClicked:) keyEquivalent:@""];
        lItem.representedObject = libraryItem;
        lItem.target = self;
        [menuItem.submenu addItem:lItem];
    }
    return menuItem;
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
    
    if (CaptureController.sharedCaptureController.inputLibrary && CaptureController.sharedCaptureController.inputLibrary.count > 0)
    {
        item = [self buildCustomInputMenu];
        [_inputsMenu addItem:item];
    }

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
            item.submenu.delegate = self;
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
    
    SourceLayout *sourceLayout = self.sourceLayoutController.content;

    CAMultiAudioEngine *useEngine = [sourceLayout findAudioEngine];
    if (!useEngine)
    {
        useEngine = CaptureController.sharedCaptureController.multiAudioEngine;
    }
    NSDictionary *systemInputs = [useEngine systemAudioInputs];
    for(NSString *inputUUID in systemInputs)
    {
        NSString *inputName = systemInputs[inputUUID];
        NSMenuItem *audioItem = [[NSMenuItem alloc] initWithTitle:inputName action:nil keyEquivalent:@""];
        audioItem.representedObject = inputUUID;
        audioItem.target = self;
        audioItem.action = @selector(audioInputItemClicked:);
        [item.submenu addItem:audioItem];
        
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

-(void)openInputConfigWindows:(NSArray *)sources
{
    
    NSPoint cascadePoint = NSZeroPoint;
    for (NSObject <CSInputSourceProtocol> *src in sources)
    {
        cascadePoint = [self openInputConfigWindow:src withCascade:cascadePoint];
    }

}



-(NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
{
    if (!window.identifier)
    {
        return nil;
    }
    
    InputPopupControllerViewController *inputController = [_activeConfigControllers objectForKey:window.identifier];
    
    if (!inputController || !inputController.inputSource)
    {
        return nil;
    }
    
    return inputController.inputSource.sourceLayout.undoManager;
}


-(NSPoint)openInputConfigWindow:(NSObject <CSInputSourceProtocol>*)configSrc withCascade:(NSPoint)cascadePoint
{
    
    NSPoint retPoint = cascadePoint;
    
    if (!configSrc)
    {
        return retPoint;
    }
    
    
    NSString *uuid = configSrc.uuid;
    NSViewController *newViewController = [configSrc configurationViewController];
    
    
    
    NSWindow *configWindow = [[NSWindow alloc] init];
    NSRect newFrame = [configWindow frameRectForContentRect:NSMakeRect(0.0f, 0.0f, newViewController.view.frame.size.width, newViewController.view.frame.size.height)];
    
    
    
    [configWindow setFrame:newFrame display:NO];
    [configWindow center];
    retPoint = [configWindow cascadeTopLeftFromPoint:cascadePoint];
    
    [configWindow setReleasedWhenClosed:NO];
    
    
    [configWindow.contentView addSubview:newViewController.view];
    configWindow.title = [NSString stringWithFormat:@"CocoaSplit Input (%@)", configSrc.name];
    configWindow.delegate = self;
    
    configWindow.styleMask =  NSTitledWindowMask|NSClosableWindowMask|NSMiniaturizableWindowMask;
    
    NSWindow *cWindow = [_activeConfigWindows objectForKey:uuid];
    NSViewController *cController = [_activeConfigControllers objectForKey:uuid];
    
    if (cController)
    {
        //cController.inputSource = nil;
        [_activeConfigControllers removeObjectForKey:uuid];
    }
    
    if (cWindow)
    {
        [_activeConfigWindows removeObjectForKey:uuid];
    }
    
    
    [_activeConfigWindows setObject:configWindow forKey:uuid];
    [_activeConfigControllers setObject:newViewController forKey:uuid];
    
    configWindow.identifier = uuid;
    
    [configWindow makeKeyAndOrderFront:nil];
    return retPoint;
}

-(void)windowWillClose:(NSNotification *)notification
{

    NSWindow *toClose = notification.object;
    
    if (toClose)
    {
        NSString *wId = toClose.identifier;
        [_activeConfigWindows removeObjectForKey:wId];
        [_activeConfigControllers removeObjectForKey:wId];
    }
}

-(void)dealloc
{
    if (self.sourceLayoutController)
    {
        [self.sourceLayoutController removeObserver:self forKeyPath:@"content.topLevelSourceList"];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
