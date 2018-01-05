//
//  CAMultiAudioEngineInputsController.h
//  CocoaSplit
//
//  Created by Zakk on 1/4/18.
//

#import "CSViewController.h"

@interface CAMultiAudioEngineInputsController : CSViewController <NSWindowDelegate>
{
    NSMutableDictionary *_mixerWindows;
}


@property (strong) IBOutlet NSObjectController *multiAudioEngineController;
@property (strong) IBOutlet NSArrayController *audioInputsController;


@end
