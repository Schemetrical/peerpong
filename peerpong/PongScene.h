//
//  PongScene.h
//  peerpong
//
//  Created by Yichen Cao on 12/12/14.
//  Copyright (c) 2014 Schemetrical. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@protocol PongSceneDelegate <NSObject>

- (void)ready;
- (void)pointForPlayer;
- (void)startBall;
- (void)passThroughPosition:(CGFloat)x velocity:(CGVector)velocity;

@end

@interface PongScene : SKScene <SKPhysicsContactDelegate>

@property (weak, nonatomic) id <PongSceneDelegate> eventDelegate;
//ball node
@property(nonatomic) SKShapeNode *ballNode;

- (void)opponentReady;
- (void)pointForPlayer:(NSInteger)player;
- (void)startBall;

@end
