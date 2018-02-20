//
//  CSSourceLayoutSettingsWindowController.m
//  CocoaSplit
//
//  Created by Zakk on 2/17/18.
//

#import "CSSourceLayoutSettingsWindowController.h"

@interface CSSourceLayoutSettingsWindowController ()

@end

@implementation CSSourceLayoutSettingsWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

-(instancetype)init
{
    if (self = [self initWithWindowNibName:@"CSSourceLayoutSettingsWindowController"])
    {

    }
    
    return self;
}
-(void)awakeFromNib
{
    self.window.title = [NSString stringWithFormat:@"%@ Settings", self.layout.name];
    
    self.filterListViewController.baseLayer = self.layout.rootLayer;
    self.filterListViewController.filterArrayName = @"backgroundFilters";
    self.layoutObjectController.undoDelegate = self;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(colorWellActivate:) name:@"CSColorWellActivated" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(colorWellDeactivate:) name:@"CSColorWellDeactivated" object:nil];

    
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


-(NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
{
    if (self.layout && self.layout.undoManager)
    {
        return self.layout.undoManager;
    }
    return [[NSUndoManager alloc] init];
}


-(void)colorWellActivate:(NSNotification *)notification
{
    NSColorWell *well = notification.object;
    
    if (well.window != self.window)
    {
        return;
    }
    
    NSDictionary *bindInfo = [well infoForBinding:@"value"];
    NSString *keyPath = bindInfo[NSObservedKeyPathKey];
    [self.layoutObjectController setValue:well.color forKeyPath:keyPath];
    [self.layoutObjectController pauseUndoForKeyPath:keyPath];
}

-(void)performUndoForKeyPath:(NSString *)keyPath usingValue:(id)usingValue
{
    NSString *propName = [[keyPath componentsSeparatedByString:@"."] lastObject];
    [[self.window.undoManager prepareWithInvocationTarget:self.layout] setValue:usingValue forKey:propName];
    NSString *actionName = [self.layout undoNameForKeyPath:propName usingValue:usingValue];
    if (actionName)
    {
        [self.window.undoManager setActionName:actionName];
    }
}


-(void)colorWellDeactivate:(NSNotification *)notification
{
    
    
    NSColorWell *well = notification.object;
    
    if (well.window != self.window)
    {
        return;
    }
    
    NSDictionary *bindInfo = [well infoForBinding:@"value"];
    NSString *keyPath = bindInfo[NSObservedKeyPathKey];
    [self.layoutObjectController resumeUndoForKeyPath:keyPath];
    [self.layoutObjectController setValue:well.color forKeyPath:keyPath];
}



- (IBAction)clearGradient:(id)sender
{
    [self.layout clearGradient];
    
}
@end
