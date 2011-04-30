//
//  ZTWebSocket.m
//  Zimt
//
//  Created by Esad Hajdarevic on 2/14/10.
//  Copyright 2010 OpenResearch Software Development OG. All rights reserved.
//

#import "ZTLog.h"
#import "ZTWebSocket.h"
#import "AsyncSocket.h"


NSString* const ZTWebSocketErrorDomain = @"ZTWebSocketErrorDomain";
NSString* const ZTWebSocketException = @"ZTWebSocketException";

enum {
    ZTWebSocketTagHandshake = 0,
    ZTWebSocketTagMessage = 1
};

@implementation ZTWebSocket

@synthesize delegate, url, origin, connected, runLoopModes;

#pragma mark Initializers

+ (id)webSocketWithURLString:(NSString*)urlString delegate:(id<ZTWebSocketDelegate>)aDelegate {
    return [[[ZTWebSocket alloc] initWithURLString:urlString delegate:aDelegate] autorelease];
}

-(id)initWithURLString:(NSString *)urlString delegate:(id<ZTWebSocketDelegate>)aDelegate {
    if ((self=[super init])) {
        self.delegate = aDelegate;
        url = [[NSURL URLWithString:urlString] retain];
        if (![url.scheme isEqualToString:@"ws"]) {
            [NSException raise:ZTWebSocketException format:[NSString stringWithFormat:@"Unsupported protocol %@",url.scheme]];
        }
        socket = [[AsyncSocket alloc] initWithDelegate:self];
        self.runLoopModes = [NSArray arrayWithObjects:NSRunLoopCommonModes, nil]; 
    }
    return self;
}

#pragma mark Delegate dispatch methods

-(void)_dispatchFailure:(NSNumber*)code {
    if(delegate && [delegate respondsToSelector:@selector(webSocket:didFailWithError:)]) {
        [delegate webSocket:self didFailWithError:[NSError errorWithDomain:ZTWebSocketErrorDomain code:[code intValue] userInfo:nil]];
    }
}

-(void)_dispatchClosed {
    if (delegate && [delegate respondsToSelector:@selector(webSocketDidClose:)]) {
        [delegate webSocketDidClose:self];
    }
}

-(void)_dispatchOpened {
    if (delegate && [delegate respondsToSelector:@selector(webSocketDidOpen:)]) {
        [delegate webSocketDidOpen:self];
    }
}

-(void)_dispatchMessageReceived:(NSString*)message {
    if (delegate && [delegate respondsToSelector:@selector(webSocket:didReceiveMessage:)]) {
        [delegate webSocket:self didReceiveMessage:message];
    }
}

-(void)_dispatchMessageSent {
    if (delegate && [delegate respondsToSelector:@selector(webSocketDidSendMessage:)]) {
        [delegate webSocketDidSendMessage:self];
    }
}

#pragma mark Private

-(void)_readNextMessage {
    [socket readDataToData:[NSData dataWithBytes:"\xFF" length:1] withTimeout:-1 tag:ZTWebSocketTagMessage];
}

#pragma mark Public interface

-(void)close {
    [socket disconnectAfterReadingAndWriting];
}

-(void)open {
    if (!connected) {
        [socket connectToHost:url.host onPort:[url.port intValue] withTimeout:5 error:nil];
        if (runLoopModes) [socket setRunLoopModes:runLoopModes];
    }
}

-(void)send:(NSString*)message {
    NSMutableData* data = [NSMutableData data];
    [data appendBytes:"\x00" length:1];
    [data appendData:[message dataUsingEncoding:NSUTF8StringEncoding]];
    [data appendBytes:"\xFF" length:1];
    [socket writeData:data withTimeout:-1 tag:ZTWebSocketTagMessage];
}




#pragma mark AsyncSocket delegate methods

-(void)onSocketDidDisconnect:(AsyncSocket *)sock {
    connected = NO;
}

-(void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err {
    if (!connected) {
        [self _dispatchFailure:[NSNumber numberWithInt:ZTWebSocketErrorConnectionFailed]];
    } else {
        [self _dispatchClosed];
    }
}

- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port {
    NSString* requestOrigin = self.origin;
    if (!requestOrigin) requestOrigin = [NSString stringWithFormat:@"http://%@",url.host];
        
    NSString *requestPath = url.path;
    if (url.query) {
      requestPath = [requestPath stringByAppendingFormat:@"?%@", url.query];
    } else {
      requestPath = @"/";
    }
    
    // Compose Security Keys
    // TODO Clean up the code
    int _spaces = ((arc4random() % (12 - 1)) + 1); // from 1 to 12
    int _spaces2 = ((arc4random() % (12 - 1)) + 1);
    int max_1 = (arc4random() % 4294967295) / _spaces;
    int max_2 = (arc4random() % 4294967295) / _spaces2;
    
    int number_1 = (arc4random() % (max_1 - 1)) +1;
    int number_2 = (arc4random() % (max_2 - 1)) +1;
    
    int product_1 = number_1 * _spaces;
    int product_2 = number_2 * _spaces2;
    
    NSMutableString *key1 = [NSMutableString stringWithFormat:@"%i", product_1];
    NSMutableString *key2 = [NSMutableString stringWithFormat:@"%i", product_2];
    
    int numberOfSymbols = (arc4random() % (12 - 1)) + 1;
    
    for (int i=0;i<numberOfSymbols;i++) {
        // Get random symbol from U+0021 to U+002F and U+003A to U+007E
        // Insert the symbol into key1 at a random position
        // 33-47,58-126 - According to specification
        // There is some problem with U-055 (45):"-"
        int randSymbol = (arc4random() % (126 - 33)) + 33;
        NSLog(@"Random symbol is %i", randSymbol);
        while ((randSymbol > 0 && randSymbol < 33) || (randSymbol > 47 && randSymbol < 58) || randSymbol > 126) {
            NSLog(@"Refuse %i", randSymbol);
            randSymbol = (arc4random() % (126 - 33)) + 33;
            NSLog(@"New number is %i", randSymbol);
        }
        int position = arc4random() % [key1 length];
        [key1 insertString:[NSString stringWithFormat:@"%C",randSymbol] atIndex:position];
    }
    
    numberOfSymbols = (arc4random() % (12 - 1)) +1;
    
    for (int i=0;i<numberOfSymbols;i++) {
        // Get random symbol from U+0021 to U+002F and U+003A to U+007E
        // Insert the symbol into key2 at a random position
        // 33-47,58-126
        int randSymbol = (arc4random() % (126 - 33)) + 33;
        NSLog(@"Random symbol 2 is %i", randSymbol);
        while ((randSymbol >0 && randSymbol < 33) || (randSymbol > 47 && randSymbol < 58) || randSymbol > 126) {
            randSymbol = (arc4random() % (126 -33)) + 33;
            NSLog(@"Random symbol 2 is %i", randSymbol);
        }
        int position = arc4random() % [key2 length];
        [key2 insertString:[NSString stringWithFormat:@"%C",randSymbol] atIndex:position];
    }

    
    NSLog(@"%i, %i", _spaces, _spaces2);
    
    for (int i=0;i<_spaces;i++) {
        int position = (arc4random() % ([key1 length]-1)) + 1;
        [key1 insertString:@" " atIndex:position];
    }
    
    for (int i=0;i<_spaces2;i++) {
        int position = (arc4random() % ([key2 length]-1)) + 1;
        [key2 insertString:@" " atIndex:position];
    }
    
    NSLog(@"Key1: %@ Key2:%@", key1, key2);
    
    secKey1 = key1;
    secKey2 = key2;

    
    NSError *error;
    
    NSRegularExpression *spaces = [NSRegularExpression regularExpressionWithPattern:@" " options:NSRegularExpressionCaseInsensitive error:&error];
    
    NSUInteger sp1 = [spaces numberOfMatchesInString:secKey1
                                                        options:0
                                                        range:NSMakeRange(0, [secKey1 length])];
    NSUInteger sp2 = [spaces numberOfMatchesInString:secKey2
                                                         options:0
                                                           range:NSMakeRange(0, [secKey2 length])];

    NSRegularExpression *regEx = [NSRegularExpression regularExpressionWithPattern:@"[^0-9]" options:NSRegularExpressionCaseInsensitive error:&error];

    
    //NSCharacterSet *removeCharSet = [NSCharacterSet characterSetWithRange:charRange];
    NSString *key1Sum = [regEx stringByReplacingMatchesInString:secKey1 options:0 range:NSMakeRange(0, [secKey1 length]) withTemplate:@""];
    NSString *key2Sum = [regEx stringByReplacingMatchesInString:secKey2 options:0 range:NSMakeRange(0, [secKey2 length]) withTemplate:@""];
    
    NSNumber *number1 = [NSNumber numberWithInt:[key1Sum integerValue]/sp1];
    NSNumber *number2 = [NSNumber numberWithInt:[key2Sum integerValue]/sp2];

    NSLog(@"Key1 sum is %@, %@. Spaces %d, %d; Numbers: %@, %@", key1Sum, key2Sum, sp1, sp2, number1, number2);
    
    uint32_t res32 = CFSwapInt32HostToBig([number1 intValue]);
    
    NSMutableString *str = [NSMutableString stringWithFormat:@""];
    for(uint32_t numberCopy = res32; numberCopy > 0; numberCopy >>= 1)
    {
        // Prepend "0" or "1", depending on the bit
        [str insertString:((numberCopy & 1) ? @"1" : @"0") atIndex:0];
    }
    
    uint32_t res32_2 = CFSwapInt32HostToBig([number2 intValue]);
    
    NSMutableString *str2 = [NSMutableString stringWithFormat:@""];
    for(uint32_t numberCopy2 = res32_2; numberCopy2 > 0; numberCopy2 >>= 1)
    {
        // Prepend "0" or "1", depending on the bit
        [str2 insertString:((numberCopy2 & 1) ? @"1" : @"0") atIndex:0];
    }
    
    NSString *uint32String = [NSString stringWithFormat:@"%@%@", str, str2];
    
    NSLog(@"Binary string is %@", uint32String);
    
    NSMutableString *key3 = [NSMutableString stringWithFormat:@""];
    NSMutableString *key3bin = [NSMutableString stringWithFormat:@""];
    for (int i=0; i < 8; i++) {
        int randByte = arc4random() % 128;
        for (int numberCopy = randByte; numberCopy > 0; numberCopy >>=1) {
            [key3bin insertString:((numberCopy & 1) ? @"1" : @"0") atIndex:0];
        }
        
        NSString *randStr = [NSString stringWithFormat:@"%c", randByte];
        NSLog(@"Random byte: %i, %@, %@", randByte, randStr, key3bin);
        [key3 insertString:randStr atIndex:0];
    }
    
    secKey3 = key3;
    
    handshakeMd5 = [self md5:[NSString stringWithFormat:@"%@%@", uint32String, key3bin]];
    
    
    NSString* getRequest = [NSString stringWithFormat:@"GET %@ HTTP/1.1\r\n"
                                                       "Upgrade: WebSocket\r\n"
                                                       "Connection: Upgrade\r\n"
                                                       "Host: %@:%@\r\n"
                                                       "Origin: %@\r\n"
                                                       "Sec-WebSocket-Key1: %@\r\n"
                                                       "Sec-WebSocket-Key2: %@\r\n"
                                                       "\r\n%@",
                                                        requestPath,url.host,url.port,requestOrigin
                                                        ,secKey1, secKey2, secKey3
                                                        ];
    NSLog(@"%@", getRequest);
    [socket writeData:[getRequest dataUsingEncoding:NSASCIIStringEncoding] withTimeout:-1 tag:ZTWebSocketTagHandshake];
}

- (NSString*)md5:(NSString *)str {
    const char *cStr = [str UTF8String];
    unsigned char result[32];
    CC_MD5( cStr, strlen(cStr), result );
    return [NSString 
            stringWithFormat: @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
            result[0], result[1],
            result[2], result[3],
            result[4], result[5],
            result[6], result[7],
            result[8], result[9],
            result[10], result[11],
            result[12], result[13],
            result[14], result[15]
            ];
}

-(void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag {
    if (tag == ZTWebSocketTagHandshake) {
        [sock readDataToData:[@"\r\n\r\n" dataUsingEncoding:NSASCIIStringEncoding] withTimeout:-1 tag:ZTWebSocketTagHandshake];
    } else if (tag == ZTWebSocketTagMessage) {
        [self _dispatchMessageSent];
    }
}

-(void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    if (tag == ZTWebSocketTagHandshake) {
        NSString* response = [[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] autorelease];
        
        //TODO - Compare handshakeMd5 to value received with handshake
        if ([response hasPrefix:@"HTTP/1.1 101 WebSocket Protocol Handshake\r\nUpgrade: WebSocket\r\nConnection: Upgrade\r\nSec-WebSocket-Location:"]) {
            connected = YES;
            [self _dispatchOpened];
            
            [self _readNextMessage];
        } else {
            [self _dispatchFailure:[NSNumber numberWithInt:ZTWebSocketErrorHandshakeFailed]];
        }
    } else if (tag == ZTWebSocketTagMessage) {
        unsigned char firstByte = 0xFF;
        //unsigned char firstByte[1];
        [data getBytes:&firstByte length:1];
        //firstByte = CFSwapInt32BigToHost(firstByte);
        NSLog(@"First byte %x", firstByte);
        //if (firstByte != 0x00) return; // Discard message - Strange behaviour.
        NSString* message = [[[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(1, [data length]-2)] encoding:NSUTF8StringEncoding] autorelease];
        
        NSLog(@"Message received %@", message);
    
        [self _dispatchMessageReceived:message];
        [self _readNextMessage];
    }
}

#pragma mark Destructor

-(void)dealloc {
    socket.delegate = nil;
    [socket disconnect];
    [socket release];
    [runLoopModes release];
    [url release];
    [super dealloc];
}

@end

