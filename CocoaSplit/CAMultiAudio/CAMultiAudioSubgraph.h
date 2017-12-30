//
//  CAMultiAudioSubgraph.h
//  CocoaSplit
//
//  Created by Zakk on 12/29/17.
//

#import "CAMultiAudioGraph.h"
#import "CAMultiAudioGenericOutput.h"

@interface CAMultiAudioSubgraph : CAMultiAudioGraph

@property (assign) AUNode subgraphNode;
@property (strong) CAMultiAudioGenericOutput *outputNode;
@property (strong) CAMultiAudioGraph *parentGraph;

-(instancetype) initWithParent:(CAMultiAudioGraph *)parent;


@end
