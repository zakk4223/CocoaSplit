//
//  CSTransitionLayout.h
//  CocoaSplit
//
//  Created by Zakk on 3/19/18.
//

#import "CSTransitionInput.h"
#import "SourceLayout.h"


@protocol CSTransitionLayoutExport <JSExport>
@property (strong) SourceLayout *layout;

@end


@interface CSTransitionLayout : CSTransitionInput <CSTransitionLayoutExport>
{
    NSObject <CSInputSourceProtocol> *_realInput;
}


@property (strong) SourceLayout *layout;

@end


