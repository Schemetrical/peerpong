//
//  GameViewController.h
//  peerpong
//

//  Copyright (c) 2014 Schemetrical. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SpriteKit/SpriteKit.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import "PongScene.h"

@interface GameViewController : UIViewController <MCBrowserViewControllerDelegate, MCSessionDelegate, PongSceneDelegate>

@end
