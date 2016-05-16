//
//  GameViewController.m
//  peerpong
//
//  Created by Yichen Cao on 12/10/14.
//  Copyright (c) 2014 Schemetrical. All rights reserved.
//

#import "GameViewController.h"
#import "MultipeerSessionManager.h"

@implementation GameViewController {
    MultipeerSessionManager *sessionManager;
    PongScene *scene;
    CGSize preferredSize;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self startAdvertising];
    });
}

- (void)startAdvertising {
    sessionManager = [MultipeerSessionManager sharedManager];
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Connect"
                                                                             message:@"Enter display name"
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Host"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {
                                                          [self saveDisplayName:[alertController.textFields[0] text]];
                                                          [self host];
                                                      }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Join"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {
                                                          [self saveDisplayName:[alertController.textFields[0] text]];
                                                          [self join];
                                                      }]];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"User";
        textField.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"displayName"];
    }];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)saveDisplayName:(NSString *)displayName {
    sessionManager.displayName = displayName;
    [[NSUserDefaults standardUserDefaults] setObject:displayName forKey:@"displayName"];
    sessionManager.session.delegate = self;
}

#pragma mark - Host

- (void)host {
    MCBrowserViewController *browser = [[MCBrowserViewController alloc] initWithServiceType:SERVICE_TYPE session:sessionManager.session];
    browser.maximumNumberOfPeers = 1;
    browser.delegate = self;
    [self presentViewController:browser animated:YES completion:nil];
}

- (void)browserViewControllerDidFinish:(MCBrowserViewController *)browserViewController {
    [browserViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController {
    [browserViewController dismissViewControllerAnimated:YES completion:^{
        [self startAdvertising];
    }];
}

#pragma mark Join

- (void)join {
    MCAdvertiserAssistant *advertiser = sessionManager.advertiserAssistant;
    [advertiser start];
}

#pragma mark Session

- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state {
    if (sessionManager.session.connectedPeers.count > 0) {
        [self sendPreferredSize];
    }
}

- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID {
    NSString *sentData = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    if ([sentData isEqualToString:@"ready"]) {
        [scene opponentReady];
    } else if ([sentData isEqualToString:@"point"]) {
        [scene pointForPlayer:1];
    } else if ([sentData isEqualToString:@"ball"]) {
        [scene startBall];
    } else {
        NSArray *dataArray = [sentData componentsSeparatedByString:@","];
        if (dataArray.count == 2) {
            [self presentSceneWithSize:(CGSizeMake([dataArray[0] floatValue], [dataArray[1] floatValue]))];
        } else {
            scene.ballNode.position = CGPointMake(scene.size.width - [dataArray[0] floatValue], scene.ballNode.position.y);
            scene.ballNode.physicsBody.velocity = CGVectorMake(-[dataArray[1] floatValue], [dataArray[2] floatValue]);
        }
    }
}

- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID {
    
}

- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress {
    
}

- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error {
    
}

#pragma mark - Game

- (void)sendPreferredSize {
    CGFloat w = self.view.bounds.size.width;
    CGFloat h = self.view.bounds.size.height;
    CGSize sceneSize = CGSizeMake(w, h);
    //to make sure that scene size is made for landscape mode :)
    if (h > w) {
        sceneSize = CGSizeMake(h, w);
    }
    preferredSize = sceneSize;
    [self sendString:[NSString stringWithFormat:@"%f,%f", preferredSize.width, preferredSize.height]];
}

- (void)presentSceneWithSize:(CGSize)size {
    CGSize correctSize = CGSizeMake(MIN(size.width, preferredSize.width), MIN(size.height, preferredSize.height));
    SKView *skView = [[SKView alloc] initWithFrame:(CGRect){CGPointMake((self.view.frame.size.width - correctSize.width) / 2, 0), correctSize}];
    // Configure the view.
    //    skView.showsFPS = YES;
    //    skView.showsNodeCount = YES;
    /* Sprite Kit applies additional optimizations to improve rendering performance */
    skView.ignoresSiblingOrder = YES;
    
    scene = [PongScene sceneWithSize:correctSize];
    scene.scaleMode = SKSceneScaleModeAspectFit;
    
    // Present the scene.
    [skView presentScene:scene];
    scene.eventDelegate = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.view addSubview:skView];
    });
    self.view.backgroundColor = [UIColor blackColor];
}

- (void)ready {
    [self sendString:@"ready"];
}

- (void)pointForPlayer {
    [self sendString:@"point"];
}

- (void)startBall {
    [self sendString:@"ball"];
}

- (void)passThroughPosition:(CGFloat)x velocity:(CGVector)velocity {
    [self sendString:[NSString stringWithFormat:@"%f,%f,%f", x, velocity.dx, velocity.dy]];
}

- (void)sendString:(NSString *)string {
    [self sendData:[string dataUsingEncoding:NSASCIIStringEncoding]];
}

- (void)sendData:(NSData *)data {
    NSError *error;
    [sessionManager.session sendData:data
                             toPeers:sessionManager.session.connectedPeers
                            withMode:MCSessionSendDataReliable
                               error:&error];
    if (error) {
        NSLog(@"%@%@", error, error.localizedDescription);
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

@end
