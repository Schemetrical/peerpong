//
//  PongScene.m
//  peerpong
//
//  Created by Yichen Cao on 12/12/14.
//  Copyright (c) 2014 Schemetrical. All rights reserved.
//  Most of this code is taken from https://github.com/bozidarsevo/sprite-kit-pong
//

#import "PongScene.h"

#define ORIGINAL_PONG_BOUNCE

#define kPaddleWidth 80.0 //width of the paddles
#define kPaddleHeight 10.0 //height of the paddles
#define kBallRadius 7.0 //radius of the moving ball
#define kStartingVelocityX 200.0 //starting velocity x value for moving the ball
#define kStartingVelocityY -200.0 //starting velocity y value for moving the ball
#define kVelocityMultFactor 1.05 //multiply factor for speeding up the ball after some time
#define kSpeedupInterval 3.0 //interval after which the speedUpTheBall method is called
#define kScoreFontSize 30.0 //font size of score label nodes
#define kRestartGameWidthHeight 50.0 //width and height of restart node
#define kPaddleMoveMult 1.0 //multiply factor when moving fingers to move the paddles, by moving finger for N pt it will move it for N * kPaddleMoveMult

//categories for detecting contacts between nodes
static const uint32_t ballCategory  = 0x1 << 0;
static const uint32_t wallCategory = 0x1 << 1;
static const uint32_t paddleCategory = 0x1 << 2;

@interface PongScene ()

@property(nonatomic) BOOL playing;
//paddle nodes
@property(nonatomic) SKSpriteNode *playerPaddleNode;
//score label nodes
@property(nonatomic) SKLabelNode *playerOneScoreNode;
@property(nonatomic) SKLabelNode *playerTwoScoreNode;
//restart game node
@property(nonatomic) SKSpriteNode *restartGameNode;
//start game info node
@property(nonatomic) SKLabelNode *startGameInfoNode;
//touches
@property(nonatomic) UITouch *playerPaddleControlTouch;
//score
@property(nonatomic) NSInteger playerOneScore;
@property(nonatomic) NSInteger playerTwoScore;
//timer for speed-up
@property(nonatomic) NSTimer *speedupTimer;
//sounds
@property(nonatomic) SKAction *bounceSoundAction;
@property(nonatomic) SKAction *failSoundAction;

@end

@implementation PongScene {
    BOOL ready;
    BOOL opponentReady;
}

- (instancetype)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        self.backgroundColor = [SKColor whiteColor];
        
        self.physicsWorld.contactDelegate = self;
        self.physicsWorld.gravity = CGVectorMake(0, 0);
        
        //setup physics body for scene
        [self setPhysicsBody:[SKPhysicsBody bodyWithEdgeLoopFromRect:CGRectMake(0, -20, self.frame.size.width, self.frame.size.height + 40)]];
        self.physicsBody.categoryBitMask = wallCategory;
        self.physicsBody.dynamic = NO;
        self.physicsBody.friction = 0.0;
        self.physicsBody.restitution = 1.0;
        
        //dimensions etc.
        CGFloat paddleWidth = kPaddleWidth;
        CGFloat paddleHeight = kPaddleHeight;
        CGFloat scoreFontSize = kScoreFontSize;
        CGFloat restartNodeWidthHeight = kRestartGameWidthHeight;
        
        //paddles
        self.playerPaddleNode = [SKSpriteNode spriteNodeWithColor:[SKColor blackColor] size:CGSizeMake(paddleWidth, paddleHeight)];
        self.playerPaddleNode.position = CGPointMake(CGRectGetMidX(self.frame), self.playerPaddleNode.size.height);
        self.playerPaddleNode.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:self.playerPaddleNode.size];
        self.playerPaddleNode.physicsBody.categoryBitMask = paddleCategory;
        self.playerPaddleNode.physicsBody.dynamic = NO;
        [self addChild:self.playerPaddleNode];
        
        //score labels
        self.playerOneScoreNode = [SKLabelNode labelNodeWithFontNamed:@"Avenir-Light"];
        self.playerTwoScoreNode = [SKLabelNode labelNodeWithFontNamed:@"Avenir-Light"];
        self.playerOneScoreNode.fontColor = self.playerTwoScoreNode.fontColor = [SKColor blackColor];
        self.playerOneScoreNode.fontSize = self.playerTwoScoreNode.fontSize = scoreFontSize;
        self.playerOneScoreNode.position = CGPointMake(50, size.height - scoreFontSize * 2.0);
        self.playerTwoScoreNode.position = CGPointMake(size.width - 50, size.height - scoreFontSize * 2.0);
        [self addChild:self.playerOneScoreNode];
        [self addChild:self.playerTwoScoreNode];
        
        //restart node
        self.restartGameNode = [SKSpriteNode spriteNodeWithImageNamed:@"restartNode.png"];
        self.restartGameNode.size = CGSizeMake(restartNodeWidthHeight, restartNodeWidthHeight);
        self.restartGameNode.position = CGPointMake(size.width / 2.0, size.height - restartNodeWidthHeight);
        self.restartGameNode.hidden = YES;
//        [self addChild:self.restartGameNode];
        
        //start game info node
        self.startGameInfoNode = [SKLabelNode labelNodeWithFontNamed:@"Avenir-Light"];
        self.startGameInfoNode.fontColor = [SKColor blackColor];
        self.startGameInfoNode.fontSize = scoreFontSize;
        self.startGameInfoNode.position = CGPointMake(size.width / 2.0, size.height - scoreFontSize * 2.0);
        self.startGameInfoNode.text = @"start";
        [self addChild:self.startGameInfoNode];
        
        //set scores to 0
        self.playerOneScore = 0;
        self.playerTwoScore = 0;
        [self updateScoreLabels];
    }
    return self;
}

- (void)didMoveToView:(SKView *)view {
    /* Setup your scene here */
    
    //reset timer
    [self.speedupTimer invalidate];
    self.speedupTimer = nil;
}

- (void)ready {
    ready = YES;
    self.startGameInfoNode.text = @"ready";
    [self.eventDelegate ready];
    if (opponentReady) {
        [self start];
        ready = NO;
        opponentReady = NO;
        BOOL serve = arc4random_uniform(2);
        if (serve) {
            [self startBall];
        } else {
            [self.eventDelegate startBall];
        }
    }
}

- (void)opponentReady {
    opponentReady = YES;
    if (ready) {
        [self start];
        ready = NO;
        opponentReady = NO;
    }
}

- (void)start {
    self.playing = YES;
    self.startGameInfoNode.hidden = YES;
    self.restartGameNode.hidden = NO;
    [self addBall];
}

- (void)addBall {
    CGFloat ballRadius = kBallRadius;
    
    //make the ball
    self.ballNode = [SKShapeNode shapeNodeWithCircleOfRadius:ballRadius];
    self.ballNode.fillColor = [SKColor blackColor];
    self.ballNode.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:ballRadius];
    self.ballNode.physicsBody.categoryBitMask = ballCategory;
    self.ballNode.physicsBody.contactTestBitMask = wallCategory | paddleCategory;
    self.ballNode.physicsBody.linearDamping = 0.0;
    self.ballNode.physicsBody.angularDamping = 0.0;
    self.ballNode.physicsBody.restitution = 1.0;
    self.ballNode.physicsBody.dynamic = YES;
    self.ballNode.physicsBody.friction = 0.0;
//    self.ballNode.physicsBody.allowsRotation = NO;
    self.ballNode.position = CGPointMake(self.size.width / 2.0, self.size.height + ballRadius);
    
    [self addChild:self.ballNode];
    //start the timer for speed-up
    self.speedupTimer = [NSTimer scheduledTimerWithTimeInterval:kSpeedupInterval
                                                         target:self
                                                       selector:@selector(accelerate:)
                                                       userInfo:nil
                                                        repeats:YES];
}

- (void)startBall {
    CGFloat startingVelocityX = kStartingVelocityX;
    CGFloat startingVelocityY = kStartingVelocityY;
    if (self.playerOneScore > self.playerTwoScore) {
        startingVelocityX = -startingVelocityX;
    }
    self.ballNode.physicsBody.velocity = CGVectorMake(startingVelocityX, startingVelocityY);
}

- (void)restart {
    [self.ballNode removeFromParent];
    //reset timer
    [self.speedupTimer invalidate];
    self.speedupTimer = nil;
    self.playing = NO;
    self.startGameInfoNode.hidden = NO;
    self.startGameInfoNode.text = @"start";
    self.restartGameNode.hidden = YES;
    //set scores to 0
    self.playerOneScore = 0;
    self.playerTwoScore = 0;
    //update score labels
    [self updateScoreLabels];
}

- (void)updateScoreLabels {
    self.playerOneScoreNode.text = [NSString stringWithFormat:@"%ld",(long)self.playerOneScore];
    self.playerTwoScoreNode.text = [NSString stringWithFormat:@"%ld",(long)self.playerTwoScore];
}

- (void)pointForPlayer:(NSInteger)player {
    switch (player) {
        case 1:
            //point for player no 1
            self.playerOneScore++;
            break;
        case 2:
            //point for player no 2
            self.playerTwoScore++;
            break;
        default:
            break;
    }
    [self updateScoreLabels];
    self.startGameInfoNode.text = @"start";
    [self.ballNode removeFromParent];
    self.playing = NO;
    self.startGameInfoNode.hidden = NO;
    self.restartGameNode.hidden = YES;
    //reset timer
    [self.speedupTimer invalidate];
    self.speedupTimer = nil;
}

- (void)accelerate:(NSTimer *)timer {
    CGFloat velocityX = self.ballNode.physicsBody.velocity.dx * kVelocityMultFactor;
    CGFloat velocityY = self.ballNode.physicsBody.velocity.dy * kVelocityMultFactor;
    self.ballNode.physicsBody.velocity = CGVectorMake(velocityX, velocityY);
}

- (void)movePaddle {
    CGPoint previousLocation = [self.playerPaddleControlTouch previousLocationInNode:self];
    CGPoint newLocation = [self.playerPaddleControlTouch locationInNode:self];
    CGFloat x = self.playerPaddleNode.position.x + (newLocation.x - previousLocation.x) * kPaddleMoveMult;
    CGFloat y = self.playerPaddleNode.position.y;
    CGFloat xMax = self.size.width - self.playerPaddleNode.size.height / 2.0 - self.playerPaddleNode.size.width / 2.0;
    CGFloat xMin = self.playerPaddleNode.size.height / 2.0 + self.playerPaddleNode.size.width / 2.0;
    if (x > xMax) {
        x = xMax;
    } else if (x < xMin) {
        x = xMin;
    }
    self.playerPaddleNode.position = CGPointMake(x, y);
}

- (void)didBeginContact:(SKPhysicsContact *)contact {
    SKPhysicsBody *firstBody;
    SKPhysicsBody *secondBody;
    if (contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask) {
        firstBody = contact.bodyA;
        secondBody = contact.bodyB;
    } else {
        firstBody = contact.bodyB;
        secondBody = contact.bodyA;
    }
    // check if we have ball & corner contact
    if (firstBody.categoryBitMask == ballCategory && secondBody.categoryBitMask == wallCategory) {
        if (firstBody.node.position.y <= firstBody.node.frame.size.height) {
            [self pointForPlayer:2];
            [self.eventDelegate pointForPlayer];
            [self runAction:self.failSoundAction];
        } else if(firstBody.node.position.y >= (self.size.height)) {
            if (firstBody.node.position.x < 10 && firstBody.velocity.dx < 0) {
                firstBody.velocity = CGVectorMake(-firstBody.velocity.dx, firstBody.velocity.dy); // bugging out check
            }
            if (firstBody.node.position.x > self.frame.size.width - 10 && firstBody.velocity.dx > 0) {
                firstBody.velocity = CGVectorMake(-firstBody.velocity.dx, firstBody.velocity.dy); // bugging out check
            }
            [self.eventDelegate passThroughPosition:firstBody.node.position.x velocity:firstBody.velocity];
            NSLog(@"\nxpos: %f\nvel: %@", firstBody.node.position.x, NSStringFromCGVector(firstBody.velocity));
            firstBody.velocity = CGVectorMake(0, 0);
            firstBody.node.position = CGPointMake(firstBody.node.position.x, firstBody.node.position.y - 2);
        } else {
            [self runAction:self.bounceSoundAction];
        }
    }
    //check if we have ball & paddle contact
    else if (firstBody.categoryBitMask == ballCategory && secondBody.categoryBitMask == paddleCategory) {
        [self runAction:self.bounceSoundAction];
        //you can react here if you want to customize the ball movement or direction
        //in original pong direction of the ball after it hits the paddle depends on
        //what part of the paddle does it hit
        //so you can customize it as you want
#ifdef ORIGINAL_PONG_BOUNCE
        SKSpriteNode *paddleNode = (SKSpriteNode*)secondBody.node;
        CGPoint ballPosition = self.ballNode.position;
        CGPoint paddlePosition = paddleNode.position;
        CGFloat relativeIntersectX = ballPosition.x - paddlePosition.x;
        CGFloat normalizedRelativeIntersectionX = relativeIntersectX / (paddleNode.size.width / 2);
        CGFloat bounceAngle = normalizedRelativeIntersectionX * M_PI * 0.4;
        CGFloat speed = sqrtf(powf(self.ballNode.physicsBody.velocity.dx, 2) + powf(self.ballNode.physicsBody.velocity.dy, 2));
        self.ballNode.physicsBody.velocity = CGVectorMake(sinf(bounceAngle) * speed, cosf(bounceAngle) * speed);
//        CGFloat firstThird = (paddleNode.position.x - paddleNode.size.width / 2.0) + paddleNode.size.width * (1.0/3.0);
//        CGFloat secondThird = (paddleNode.position.x - paddleNode.size.width / 2.0) + paddleNode.size.width * (2.0/3.0);
//        CGFloat dx = self.ballNode.physicsBody.velocity.dx;
//        CGFloat dy = self.ballNode.physicsBody.velocity.dy;
//        if (ballPosition.x < firstThird) {
//            //ball hits the left part
//            if (dx > 0) {
//                self.ballNode.physicsBody.velocity = CGVectorMake(dy, -dx);
//            }
//        }
//        else if (ballPosition.x > secondThird) {
//            //ball hits the left part
//            if (dx < 0) {
//                self.ballNode.physicsBody.velocity = CGVectorMake(dy, -dx);
//            }
//        }
#endif
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if (self.playing) {
        //set touches to move paddles
        for (UITouch *touch in touches) {
            CGPoint location = [touch locationInNode:self];
            //first check if restart node is touched
            if (CGRectContainsPoint(self.restartGameNode.frame, location)) {
                [self restart];
                return;
            }
            if (self.playerPaddleControlTouch == nil) {
                self.playerPaddleControlTouch = touch;
            }
        }
        return;
    } else {
        // start playing
        [self ready];
        return;
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        if (touch == self.playerPaddleControlTouch) {
            [self movePaddle];
        }
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    //    NSLog(@"ended %d",touches.count);
    for (UITouch *touch in touches) {
        if (touch == self.playerPaddleControlTouch) {
            self.playerPaddleControlTouch = nil;
        }
    }
}

//- (void)update:(CFTimeInterval)currentTime {
//    /* Called before each frame is rendered */
//}

@end
