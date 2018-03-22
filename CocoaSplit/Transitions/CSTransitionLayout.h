//
//  CSTransitionLayout.h
//  CocoaSplit
//
//  Created by Zakk on 3/19/18.
//

#import "CSTransitionBase.h"
#import "SourceLayout.h"


@protocol CSTransitionLayoutExport <JSExport>
@property (strong) SourceLayout *layout;
@property (strong) NSObject<CSInputSourceProtocol> *layoutSource;
@property (assign) float holdDuration;
@property (assign) bool waitForMedia;

@end


@interface CSTransitionLayout : CSTransitionBase <CSTransitionLayoutExport>
{
    CSTransitionBase *_savedTransition;
}


@property (strong) SourceLayout *layout;
@property (assign) float holdDuration;
@property (assign) bool doMerge;
@property (strong) NSObject<CSInputSourceProtocol> *layoutSource;
@property (assign) bool waitForMedia;
@end


