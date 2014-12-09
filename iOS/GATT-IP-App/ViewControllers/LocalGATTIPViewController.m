/* The MIT License
 
 Copyright (c) 2010-2014 Vensi, Inc. http://gatt-ip.org
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

#import "GATTIP.h"
#import "CoreWebSocket.h"
#import "LogViewController.h"
#import "LocalGATTIPViewController.h"
#import "RemoteGATTIPViewController.h"

@interface LocalGATTIPViewController() <GATTIPDelegate> {

    WebSocketRef webSocket;
}

@property(nonatomic, strong) GATTIP *gattip;

@end

@implementation LocalGATTIPViewController

- (void)viewDidLoad {
    [super viewDidLoad]; 
    
    webSocket = WebSocketCreate(NULL, (__bridge void *)(self));
    if (webSocket) {
        NSURL *indexURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"index" ofType:@"html" inDirectory:@"www"]];
        [self.webView loadRequest:[NSURLRequest requestWithURL:indexURL]];
        self.webView.delegate = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            webSocket->callbacks.didClientReadCallback = Callback;
        });
        
        _gattip = [[GATTIP alloc] init];
        [_gattip setDelegate:self];
    }
}

void Callback (WebSocketRef sockref, WebSocketClientRef client, CFStringRef value) {
    if (!value) {
        return;
    }
    
    NSLog(@"Request: %@",value);
    NSString *stringValue = (__bridge NSString *)value ;
    NSData *stringValueData = [stringValue dataUsingEncoding:NSUTF8StringEncoding];
    [(__bridge GATTIP *)sockref->userInfo request:stringValueData];
}

- (void)request:(NSData *)gattipMesg {
    [_gattip request:gattipMesg];
}

- (void)response:(NSData *)gattipMesg {
    NSString  *responseString = [[NSString alloc]initWithData:gattipMesg encoding:NSUTF8StringEncoding];
    NSLog(@"Response: %@",responseString);
    WebSocketWriteWithString(webSocket, (__bridge CFStringRef)(responseString));
}

-(void)gotoRemote {
    UIStoryboard *mystoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    RemoteGATTIPViewController *remoteVC = [mystoryboard instantiateViewControllerWithIdentifier:@"123"];
    remoteVC.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentViewController:remoteVC animated:YES completion:nil];
}

- (void)gotoLog {
    NSArray *listOfHumanReadableValues =  [_gattip listOFResponseAndRequests];
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    LogViewController *logViewController = (LogViewController *)[storyBoard instantiateViewControllerWithIdentifier:@"logVC"];
    logViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    logViewController.logList = listOfHumanReadableValues;
    [self showViewController:logViewController sender:self];
}

#pragma mark UIWebView Delegate Methods
- (void)webViewDidFinishLoad:(UIWebView *)webView {
    int port = WebSocketGetPort(webSocket);
    
    NSString *responseFromJS = [webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"connectWithPort(%d)", port]];
    NSLog(@"Response: %@", responseFromJS);
}

- (BOOL)webView:(UIWebView *)webView
shouldStartLoadWithRequest:(NSURLRequest *)request
 navigationType:(UIWebViewNavigationType)navigationType {
    
    if([[[request URL] host] isEqualToString:@"remoteview"]){
        [self gotoRemote];
    } else if([[[request URL] host] isEqualToString:@"logview"]){
        [self gotoLog];
    }
    
    return YES;
}

- (void)dealloc {
    WebSocketRelease(webSocket);
}

@end
