//
//  BitlyResponse.h
//  BitlySDK
//
//  Created by JC Tierney on 10/31/16.
//  Copyright © 2016 Bitly. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BitlyResponse : NSObject

@property (readonly) NSNumber *statusCode;
@property (readonly) NSString *statusText;
@property (readonly) NSString *bitlink;
@property (readonly) NSString *url;
@property (readonly) NSString *applink;

@end
