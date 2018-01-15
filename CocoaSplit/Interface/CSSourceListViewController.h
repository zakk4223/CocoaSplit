//
//  CSSourceListViewController.h
//  CocoaSplit
//
//  Created by Zakk on 1/2/18.

#import <Cocoa/Cocoa.h>
#import "CSViewController.h"
@interface CSSourceListViewController : CSViewController <NSOutlineViewDelegate, NSOutlineViewDataSource, NSWindowDelegate>
{
    NSMenu *_inputsMenu;
    NSMutableDictionary *_activeConfigWindows;
    NSMutableDictionary *_activeConfigControllers;
}

//This is set by whatever instantiates us. Probably bound to something like activePreviewView.sourceLayout

@property (weak) IBOutlet NSObjectController *sourceLayoutController;
@property (strong) NSArray *sourceTreeSortDescriptors;
@property (strong) IBOutlet NSTreeController *sourceTreeController;
@property (weak) IBOutlet NSOutlineView *sourceOutlineView;
@property (strong) NSArray *selectedObjects;


-(IBAction)outlineViewDoubleClick:(NSOutlineView *)sender;
-(IBAction)sourceConfigClicked:(NSButton *)sender;
-(IBAction)sourceDeleteClicked:(NSButton *)sender;
-(IBAction)sourceAddClicked:(NSButton *)sender;

-(void)highlightSources:(NSArray *)sources;

@end
