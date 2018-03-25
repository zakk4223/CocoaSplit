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
@property (strong) NSNumber *holdDuration;
@property (assign) bool waitForMedia;
@property (assign) float realHoldDuration;
@property (strong) CATransition *transitionInputTransition;

@end


@interface CSTransitionLayout : CSTransitionBase <CSTransitionLayoutExport>
{
    CSTransitionBase *_savedTransition;
}


@property (strong) SourceLayout *layout;
@property (strong) NSNumber *holdDuration;
@property (assign) float realHoldDuration;
@property (strong) CATransition *transitionInputTransition;
@property (strong) NSObject<CSInputSourceProtocol> *layoutSource;
@property (assign) bool waitForMedia;
@end


