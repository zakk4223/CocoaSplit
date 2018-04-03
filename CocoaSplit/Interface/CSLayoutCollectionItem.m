//
//  CSLayoutCollectionItem.m
//  CocoaSplit
//
//  Created by Zakk on 10/4/15.
//

#import "CSLayoutCollectionItem.h"
#import "AppDelegate.h"
#import "CSLayoutRecorder.h"
#import "PreviewView.h"

@interface CSLayoutCollectionItem ()

@end

@implementation CSLayoutCollectionItem



-(void)setRepresentedObject:(id)representedObject
{
    [super setRepresentedObject:representedObject];


    [self.layoutButton setNeedsDisplay:YES];

    [self setButtonLabelName];
    if (self.representedObject)
    {
        [self.representedObject addObserver:self forKeyPath:@"in_live" options:NSKeyValueObservingOptionNew context:NULL];
        [self.representedObject addObserver:self forKeyPath:@"in_staging" options:NSKeyValueObservingOptionNew context:NULL];
        [self.representedObject addObserver:self forKeyPath:@"recorder.defaultRecordingActive" options:NSKeyValueObservingOptionNew context:NULL];
        [self.representedObject addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionNew context:NULL];


    }
}


-(void) awakeFromNib
{
    [super awakeFromNib];
    AppDelegate *appDel = [NSApp delegate];
    self.captureController = appDel.captureController;
    [self setButtonLabelName];
    [self.upImage rotateByAngle:90.0f];
    [self.downImage rotateByAngle:-90.0f];
    self.upImage.hidden = YES;
    self.downImage.hidden = YES;

}


-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"name"] || [keyPath isEqualToString:@"recorder.defaultRecordingActive"])
    {
        [self setButtonLabelName];
    } else {
        [self.layoutButton setNeedsDisplay:YES];
    }
}


- (void)viewDidLoad {
    [super viewDidLoad];
    

    //self.view.layer.backgroundColor = [[NSColor blackColor] CGColor];

    // Do view setup here.
}
-(void)controlTextDidEndEditing:(NSNotification *)obj
{
    [self.view.window makeFirstResponder:self.buttonLabel.superview];
    [self.buttonLabel setEditable:NO];
}


-(BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector
{
    NSString *selectorName = NSStringFromSelector(commandSelector);
    if ([selectorName isEqualToString:@"cancel:"])
    {
        [self.view.window makeFirstResponder:nil];
        [self.buttonLabel setEditable:NO];
        return YES;
    }
    return NO;
}

-(void)setButtonLabelName
{
    SourceLayout *layout = self.representedObject;
    NSString *name = layout.name;
    NSString *recString;
    if (layout.recorder && layout.recorder.defaultRecordingActive)
    {
        recString = @"(R) ";
    } else {
        recString = @"";
    }
    
    NSString *labelString = [NSString stringWithFormat:@"%@%@", recString, name];
    self.buttonLabel.stringValue = labelString;
}

- (IBAction)layoutButtonPushed:(id)sender
{
    SourceLayout *useLayout = self.captureController.activePreviewView.sourceLayout;
    
    if ([NSEvent modifierFlags]& NSCommandKeyMask)
    {
        useLayout = self.captureController.selectedLayout;
    }
    
    if ([NSEvent modifierFlags] & NSShiftKeyMask)
    {
        if (!self.upImage.hidden)
        {
            useLayout.sourceAddOrder = kCSSourceAddOrderTop;
        } else if (!self.downImage.hidden) {
            useLayout.sourceAddOrder = kCSSourceAddOrderBottom;
        } else {
            useLayout.sourceAddOrder = kCSSourceAddOrderTop;
        }
        
        [self.captureController toggleLayout:self.representedObject usingLayout:useLayout];
    } else {
        [self.captureController switchToLayout:self.representedObject usingLayout:useLayout];
    }
}

-(void)mouseDragged:(NSEvent *)theEvent
{
    [self.nextResponder mouseDragged:theEvent];
}


-(void)saveToLayout:(id) sender
{
    [self.captureController saveToLayout:self.representedObject];
}


-(void)editLayout:(id) sender
{
    SourceLayout *toEdit = self.representedObject;
    [self.captureController openLayoutWindow:toEdit];
    
    //[self.captureController openLayoutPopover:self.layoutButton forLayout:toEdit];
}

-(void)editLayoutName:(id) sender
{
    [self.buttonLabel setEditable:YES];
    [self.view.window makeFirstResponder:self.buttonLabel];
}


-(void)deleteLayout:(id) sender
{
    SourceLayout *toDelete = self.representedObject;
    
    if ([self.captureController deleteLayout:self.representedObject])
    {
        [toDelete removeObserver:self forKeyPath:@"in_live"];
        [toDelete removeObserver:self forKeyPath:@"in_staging"];
        [toDelete removeObserver:self forKeyPath:@"recorder.defaultRecordingActive"];
        [toDelete removeObserver:self forKeyPath:@"name"];

    }
}


-(void) startRecordingLayout:(NSMenuItem *)sender
{
    [[CaptureController sharedCaptureController] startRecordingLayout:sender.representedObject];
}


-(void) stopRecordingLayout:(NSMenuItem *)sender
{
    [[CaptureController sharedCaptureController] stopRecordingLayout:sender.representedObject];
}



-(void)buildLayoutMenu
{

    NSInteger idx = 0;
    
    NSMenuItem *tmp;
    SourceLayout *forLayout = self.representedObject;
    
    self.layoutMenu = [[NSMenu alloc] init];
    tmp = [self.layoutMenu insertItemWithTitle:@"Save To" action:@selector(saveToLayout:) keyEquivalent:@"" atIndex:idx++];
    tmp.target = self;
    tmp.representedObject = forLayout;
    
    if (forLayout.recordingLayout)
    {
        tmp = [self.layoutMenu insertItemWithTitle:@"Stop Recording" action:@selector(stopRecordingLayout:) keyEquivalent:@"" atIndex:idx++];
        tmp.target = self;
        tmp.representedObject = forLayout;
        
    } else {
        tmp = [self.layoutMenu insertItemWithTitle:@"Start Recording" action:@selector(startRecordingLayout:) keyEquivalent:@"" atIndex:idx++];
        tmp.target = self;
        tmp.representedObject = forLayout;
        
    }
    
    tmp = [self.layoutMenu insertItemWithTitle:@"Change Name" action:@selector(editLayoutName:) keyEquivalent:@"" atIndex:idx++];
    tmp.target = self;
    tmp.representedObject = forLayout;
    
    tmp = [self.layoutMenu insertItemWithTitle:@"Edit" action:@selector(editLayout:) keyEquivalent:@"" atIndex:idx++];
    tmp.target = self;
    tmp.representedObject = forLayout;
    

    
    tmp = [self.layoutMenu insertItemWithTitle:@"Delete" action:@selector(deleteLayout:) keyEquivalent:@"" atIndex:idx++];
    tmp.target = self;
    tmp.representedObject = forLayout;

}

-(void)showLayoutMenu:(NSEvent *)clickEvent
{
    NSPoint tmp = [self.view convertPoint:clickEvent.locationInWindow fromView:nil];
    [self buildLayoutMenu];
    [self.layoutMenu popUpMenuPositioningItem:self.layoutMenu.itemArray.firstObject atLocation:tmp inView:self.view];
}

@end
