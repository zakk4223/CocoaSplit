//
//  CSAdvancedAudioWindowController.m
//  CocoaSplit
//
//  Created by Zakk on 8/6/16.
//

#import "CSAdvancedAudioWindowController.h"

@interface CSAdvancedAudioWindowController ()

@end

@implementation CSAdvancedAudioWindowController



-(instancetype) init
{
    
    if (self = [self initWithWindowNibName:@"CSAdvancedAudioWindowController"])
    {
        NSSortDescriptor *nameSort = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES comparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            NSString *name1 = obj1;
            NSString *name2 = obj2;
            
            if ([name1 isEqualToString:@"Default"])
            {
                return (NSComparisonResult)NSOrderedAscending;
            }
            
            return [name1 compare:name2];
        }];
        
        _trackSortDescriptors = @[nameSort];
    }
    
    return self;
}


- (void)windowDidLoad {
    [super windowDidLoad];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}








- (IBAction)addAudioTrack:(id)sender
{
    [self.audioEngine addOutputTrack];
}
- (IBAction)removeAudioTrack:(id)sender
{
    NSArray *selectedTracks = self.outputTracksController.selectedObjects;
    for (CAMultiAudioOutputTrack *outTrack in selectedTracks)
    {
        [self.audioEngine removeOutputTrack:outTrack.uuid];
    }
}



@end
