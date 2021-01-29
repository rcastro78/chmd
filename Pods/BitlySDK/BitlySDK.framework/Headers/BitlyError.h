//
//  BitlyError.h
//  BitlySDK
//
//  Created by JC Tierney on 10/31/16.
//  Copyright © 2016 Bitly. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BitlyError : NSObject

@property (readonly) NSNumber *errorCode;
@property (readonly) NSString *errorMessage;
@property (readonly) NSString *originalUrl;
@property (readonly) NSString *originalBitlink;

@end
