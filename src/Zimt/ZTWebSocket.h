//
//  ZTWebSocket.h
//  Zimt
//
//  Created by Esad Hajdarevic on 2/14/10.
//  Copyright 2010 OpenResearch Software Development OG. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ZimtAsyncSocket;
@class ZTWebSocket;

@protocol ZTWebSocketDelegate<NSObject>
@optional 
    - (void)webSocket:(ZTWebSocket*)webSocket didFailWithError:(NSError*)error;
    - (void)webSocketDidOpen:(ZTWebSocket*)webSocket;
    - (void)webSocketDidClose:(ZTWebSocket*)webSocket;
    - (void)webSocket:(ZTWebSocket*)webSocket didReceiveMessage:(NSString*)message;
    - (void)webSocketDidSendMessage:(ZTWebSocket*)webSocket;
@end

@interface ZTWebSocket : NSObject {
    id<ZTWebSocketDelegate> delegate;
    NSURL* url;
    ZimtAsyncSocket* socket;
    BOOL connected;
    NSString* origin;
    
    NSArray* runLoopModes;
    NSString* cookie;
@private
    u_char key3[8];
    NSData* expectedChallenge;
    BOOL handShakeHeaderReceived;
}

@property(nonatomic,assign) id<ZTWebSocketDelegate> delegate;
@property(nonatomic,readonly) NSURL* url;
@property(nonatomic,retain) NSString* origin;
@property(nonatomic,readonly) BOOL connected;
@property(nonatomic,retain) NSArray* runLoopModes;
@property(nonatomic,retain) NSString* cookie;

+ (id)webSocketWithURLString:(NSString*)urlString delegate:(id<ZTWebSocketDelegate>)delegate;
- (id)initWithURLString:(NSString*)urlString delegate:(id<ZTWebSocketDelegate>)delegate;

- (void)open;
- (void)close;
- (void)send:(NSString*)message;

@end

enum {
    ZTWebSocketErrorConnectionFailed = 1,
    ZTWebSocketErrorHandshakeFailed = 2
};

extern NSString *const ZTWebSocketException;
extern NSString* const ZTWebSocketErrorDomain;
