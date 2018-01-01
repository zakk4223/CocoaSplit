//
//  CAMultiAudioEffectsTableController.h
//  CocoaSplit
//
//  Created by Zakk on 12/31/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CAMultiAudioNode.h"
#import "CAMultiAudioEffect.h"


@interface CAMultiAudioEffectsTableController : NSObject <NSTableViewDelegate, NSTableViewDataSource, NSWindowDelegate, NSMenuDelegate>
{
    NSMenu *_effectsMenu;
}


@property (strong) CAMultiAudioNode *audioNode;
@property (weak) IBOutlet NSTableView *effectTable;
@property (weak) IBOutlet NSArrayController *effectArrayController;
@property (strong) NSMutableDictionary *configWindows;


-(IBAction)openAddEffect:(id)sender;
-(IBAction)removeEffects:(id)sender;

-(void)addEffect:(NSMenuItem *)item;
-(IBAction)effectTableDoubleClick:(NSTableView *)tableView;
-(IBAction)configureEffects:(id)sender;


@end
