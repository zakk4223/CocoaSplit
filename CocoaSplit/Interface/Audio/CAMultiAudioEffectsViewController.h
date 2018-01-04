//
//  CAMultiAudioEffectsViewController.h
//  CocoaSplit
//
//  Created by Zakk on 1/3/18.

#import <Cocoa/Cocoa.h>
#import "CAMultiAudioEffect.h"
#import "CAMultiAudioEffectWindow.h"
#import "CSViewController.h"

@interface CAMultiAudioEffectsViewController : CSViewController <NSTableViewDelegate, NSTableViewDataSource, NSWindowDelegate, NSMenuDelegate>
{
    NSMenu *_effectsMenu;
}




@property (weak) IBOutlet NSObjectController *audioNodeController;

@property (weak) IBOutlet NSTableView *effectTable;
@property (weak) IBOutlet NSArrayController *effectArrayController;
@property (strong) NSMutableDictionary *configWindows;


-(IBAction)openAddEffect:(id)sender;
-(IBAction)removeEffects:(id)sender;

-(void)addEffect:(NSMenuItem *)item;
-(IBAction)effectTableDoubleClick:(NSTableView *)tableView;
-(IBAction)configureEffects:(id)sender;
@end
