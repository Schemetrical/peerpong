//
//  MultipeerSessionManager.m
//  MultipeerBuzz
//
//  Created by Yichen Cao on 11/20/14.
//  Copyright (c) 2014 Schemetrical. All rights reserved.
//

#import "MultipeerSessionManager.h"

@interface MultipeerSessionManager ()

@end

@implementation MultipeerSessionManager

@synthesize displayName = _displayName;

+ (instancetype)sharedManager {
    static MultipeerSessionManager *_sharedManager = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        _sharedManager = [MultipeerSessionManager new];
    });
    return _sharedManager;
}

- (MCPeerID *)peerIDForDisplayName:(NSString *)displayName {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *peerIDs = [[defaults objectForKey:PEER_ID_KEY] mutableCopy];
    NSData *peerIDData = peerIDs[displayName]; // peerID or nil if none
    if (!peerIDs) {
        peerIDs = [NSMutableDictionary new]; // no need to save here because guarenteed no key here
    }
    if (!peerIDData) {
        peerIDData = [NSKeyedArchiver archivedDataWithRootObject:[[MCPeerID alloc] initWithDisplayName:displayName]];
        [peerIDs setObject:peerIDData forKey:displayName];
        [defaults setObject:peerIDs forKey:PEER_ID_KEY];
    }
    return [NSKeyedUnarchiver unarchiveObjectWithData:peerIDData];
}

- (NSString *)displayName {
    if (!_displayName) {
        _displayName = @"User";
    }
    return _displayName;
}

- (MCSession *)session {
    if (!_session) {
        _session = [[MCSession alloc] initWithPeer:[self peerIDForDisplayName:self.displayName]];
    }
    return _session;
}

- (MCAdvertiserAssistant *)advertiserAssistant {
    if (!_advertiserAssistant) {
        _advertiserAssistant = [[MCAdvertiserAssistant alloc] initWithServiceType:SERVICE_TYPE
                                                                    discoveryInfo:nil
                                                                          session:self.session];
    }
    return _advertiserAssistant;
}

- (void)setDisplayName:(NSString *)displayName {
    _displayName = displayName;
    [self.delegate didSetDisplayName:displayName];
}

- (void)promptForNewDisplayNameWithCompletionHandler:(void (^)())completionHandler sender:(id)sender {
    UIAlertController *changeNameController = [UIAlertController alertControllerWithTitle:@"Change Name"
                                                                                  message:@"Enter a Display Name"
                                                                           preferredStyle:UIAlertControllerStyleAlert];
    [changeNameController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"Display Name";
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel"
                                                     style:UIAlertActionStyleCancel
                                                   handler:^(UIAlertAction *action) {
                                                       if (completionHandler) completionHandler();
                                                   }];
    [changeNameController addAction:cancel];
    UIAlertAction *done = [UIAlertAction actionWithTitle:@"Done"
                                                   style:UIAlertActionStyleDefault
                                                 handler:^(UIAlertAction *action) {
                                                     self.displayName = ((UITextField *)changeNameController.textFields[0]).text;
                                                     if (completionHandler) completionHandler();
                                                 }];
    [changeNameController addAction:done];
    [sender presentViewController:changeNameController
                         animated:YES
                       completion:nil];
}

@end
