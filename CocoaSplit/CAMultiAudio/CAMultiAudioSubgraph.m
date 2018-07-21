//
//  CAMultiAudioSubgraph.m
//  CocoaSplit
//
//  Created by Zakk on 12/29/17.
//

#import "CAMultiAudioSubgraph.h"

@implementation CAMultiAudioSubgraph


-(instancetype) initWithParent:(CAMultiAudioGraph *)parent
{
    if (self = [self init])
    {
        AUGraphNewNodeSubGraph(parent.graphInst, &_subgraphNode);
        AUGraphGetNodeInfoSubGraph(parent.graphInst, _subgraphNode, &_graphInst);
        self.parentGraph = parent;
        self.sampleRate = parent.sampleRate;
        self.graphAsbd = malloc(sizeof(AudioStreamBasicDescription));
        memcpy(_graphAsbd, parent.graphAsbd, sizeof(AudioStreamBasicDescription));
        //AUGraphOpen(_graphInst);
        AUGraphInitialize(_graphInst);
        self.outputNode = [[CAMultiAudioGenericOutput alloc] init];

        [self addNode:self.outputNode];

        [self graphUpdate];
        [self startGraph];
        //AUGraphConnectNodeInput(self.graphInst, self.outputNode.node, 0, _subgraphNode, 0);
        //[self graphUpdate];
    }
    
    return self;
}


-(void)dealloc
{
    if (self.graphAsbd)
    {
        free(self.graphAsbd);
    }
}


@end
