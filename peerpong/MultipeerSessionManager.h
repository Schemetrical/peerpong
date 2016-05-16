//
//  MultipeerSessionManager.h
//
//  Created by Yichen Cao on 11/20/14.
//  Copyright (c) 2014 Schemetrical. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>

// Change this to desired service name.
#define SERVICE_TYPE @"peerpong"
// Peer ID prefix used for NSUserDefaults Saving of the PeerID.
#define PEER_ID_KEY @"PeerPongKey"

@protocol MultipeerSessionManagerDelegate <NSObject>

/*!
 * @method didSetDisplayName:
 * @abstract
 * Delegate method notifying the new displayName being set
 * @discussion
 * Called from the setter of displayName, either manually set or from promptForNewDisplayNameWithCompletionHandler:sender:
 */
- (void)didSetDisplayName:(NSString *)displayName;

@end

@interface MultipeerSessionManager : NSObject

/*!
 * @property displayName
 * @abstract
 * The display name for the MCPeerID
 * @discussion
 * Please set this manually or with promptForNewDisplayNameWithCompletionHandler:sender: before using any other properties.
 */
@property (strong, nonatomic) NSString *displayName;

/*!
 * @property session
 * @abstract
 * The MCSession configured with the peerID.
 * @discussion
 * Use the session and set the session's delegate for sending and receiving data.
 */
@property (strong, nonatomic) MCSession *session;

/*!
 * @property advertiserAssistant
 * @abstract
 * The MCAdvertiserAssistant configured with the session.
 * @discussion
 * Use the advertiserAssistant and set the assistant's delegate for advertising the device.
 */
@property (strong, nonatomic) MCAdvertiserAssistant *advertiserAssistant;

/*!
 * @property delegate
 * @abstract
 * The delegate class receiving the delegate methods.
 */
@property (weak, nonatomic) id <MultipeerSessionManagerDelegate> delegate;

/*!
 * @property sharedManager
 * @abstract
 * Gets the shared sessionManager.
 * @discussion
 * Use [MultipeerSessionManager sharedManager] to retrieve the shared instance.
 */
+ (instancetype)sharedManager;

- (instancetype)init NS_UNAVAILABLE;

/*!
 * @method promptForNewDisplayNameWithCompletionHandler:sender:
 * @abstract
 * Displays an alert prompting the user for a new display name.
 * @param completionHandler
 * The completionHandler for the prompt. Use [MultipeerSessionManager sharedManager].displayName or the delegate method didSetDisplayName: to retrieve new display name.
 * @param sender
 * A view controller sender which will display the alert prompt
 * @discussion
 * Call this method before using any of the properties to ensure you have the correct display name
 */
- (void)promptForNewDisplayNameWithCompletionHandler:(void (^)())completionHandler sender:(id)sender;

@end
