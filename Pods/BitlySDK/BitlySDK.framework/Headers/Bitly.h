//
//  Bitly.h
//  BitlySDK
//
//  Created by JC Tierney on 10/31/16.
//  Copyright © 2016 Bitly. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BitlyResponse.h"
#import "BitlyError.h"

@interface Bitly : NSObject

+ (void) initialize:(nonnull NSString *)appId supportedDomains:(nonnull NSArray *)supportedDomains supportedSchemes:(nonnull NSArray *)supportedSchemes handler:(nonnull void (^)(BitlyResponse * _Nullable response, BitlyError * _Nullable error))handler;
+ (void) initialize:(nonnull NSString *)appId accessToken:(nonnull NSString *)accessToken supportedDomains:(nonnull NSArray *)supportedDomains supportedSchemes:(nonnull NSArray *)supportedSchemes handler:(nonnull void (^)(BitlyResponse * _Nullable response, BitlyError * _Nullable error))handler;
+ (void) initialize:(nonnull NSString *)appId deviceId:(nonnull NSUUID *)deviceId supportedDomains:(nonnull NSArray *)supportedDomains supportedSchemes:(nonnull NSArray *)supportedSchemes handler:(nonnull void (^)(BitlyResponse * _Nullable response, BitlyError * _Nullable error))handler;
+ (void) initialize:(nonnull NSString *)appId accessToken:(nonnull NSString *)accessToken deviceId:(nonnull NSUUID *)deviceId supportedDomains:(nonnull NSArray *)supportedDomains supportedSchemes:(nonnull NSArray *)supportedSchemes handler:(nonnull void (^)(BitlyResponse * _Nullable response, BitlyError * _Nullable error))handler;
+ (void) initialize:(nonnull NSString *) accessToken;

+ (BOOL) handleUserActivity:(nonnull NSUserActivity *)userActivity;
+ (BOOL) handleOpenUrl:(nonnull NSURL *)url;
+ (BOOL) retryError:(nonnull BitlyError *)error;
+ (void) shorten:(nonnull NSString *)link handler:(nonnull void (^)(BitlyResponse * _Nullable response, BitlyError * _Nullable error))handler;

@end
