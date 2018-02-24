//
//  ViewController.m
//  DemoWebKit
//
//  Created by Chris Hu on 30/01/2018.
//  Copyright © 2018 com.icetime. All rights reserved.
//

#import "ViewController.h"

#import <WebKit/WebKit.h>
#import <JavaScriptCore/JavaScriptCore.h>

#import <AVFoundation/AVFoundation.h>


/**
 只能自定义一个protocol继承JSExport协议, 规定属性和方法即可.
 其中的属性和方法都可以在JS代码中使用.
 */
@protocol PersonJSExport <JSExport>

@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) NSInteger age;
@property (nonatomic, copy) NSString *city;

+ (instancetype)personWithName:(NSString *)name;

+ (instancetype)personWithName:(NSString *)name
                           age:(NSInteger)age
                          city:(NSString *)city;

@end

@interface Person: NSObject <PersonJSExport>

@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) NSInteger age;
@property (nonatomic, copy) NSString *city;

+ (instancetype)personWithName:(NSString *)name;

+ (instancetype)personWithName:(NSString *)name
                           age:(NSInteger)age
                          city:(NSString *)city;

@end

@implementation Person

+ (instancetype)personWithName:(NSString *)name {
    Person *person = [[Person alloc] init];
    person.name = name;
    return person;
}

+ (instancetype)personWithName:(NSString *)name
                           age:(NSInteger)age
                          city:(NSString *)city
{
    Person *person = [[Person alloc] init];
    person.name = name;
    person.age = age;
    person.city = city;
    return person;
}

@end


@interface ViewController () <
    WKNavigationDelegate,
    WKUIDelegate
>

@property (nonatomic, strong) WKWebView *webView;

@property (weak, nonatomic) IBOutlet UIProgressView *progressView;


@end

@implementation ViewController

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)dealloc
{
    [self.webView removeObserver:self forKeyPath:@"loading" context:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.progressView.progressTintColor = [UIColor blueColor];
    self.progressView.trackTintColor = [UIColor whiteColor];
    
    [self.view insertSubview:self.webView atIndex:0];
    self.webView.navigationDelegate = self;
    self.webView.UIDelegate = self;
    
    [self.webView addObserver:self forKeyPath:@"loading" options:NSKeyValueObservingOptionNew context:nil];
    [self.webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
    
//    [self loadImg];
//    [self loadGif];
//    [self loadPDF];
//    [self loadHTML];
//    [self loadIndexHTML];
//    [self loadURL:@"https://www.apple.com"];

//    [self testJSConfirmAndAlert];
    
//    [self testJavaScriptCore_OC_JS];
    [self testJavaScriptCore_JS_OC];
}

- (WKWebView *)webView {
    if (!_webView) {
        WKPreferences *prefs = [[WKPreferences alloc] init];
        prefs.javaScriptEnabled = YES;
        prefs.javaScriptCanOpenWindowsAutomatically = YES;
        prefs.minimumFontSize = 30.f;
        
        WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
        config.userContentController = [[WKUserContentController alloc] init];
        config.preferences = prefs;
        
        CGRect frame = CGRectMake(0, 44, self.view.frame.size.width, self.view.frame.size.height - 44);
        _webView = [[WKWebView alloc] initWithFrame:frame configuration:config];
    }
    return _webView;
}

- (void)loadImg {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Model" ofType:@"jpg"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    [self.webView loadData:data MIMEType:@"image/jpg" characterEncodingName:@"UTF-8" baseURL:[[NSURL alloc] init]];
}

- (void)loadGif {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"demo" ofType:@"gif"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    [self.webView loadData:data MIMEType:@"image/gif" characterEncodingName:@"UTF-8" baseURL:[[NSURL alloc] init]];
}

- (void)loadPDF {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"isa" ofType:@"pdf"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    [self.webView loadData:data MIMEType:@"application/pdf" characterEncodingName:@"UTF-8" baseURL:[[NSURL alloc] init]];
}

- (void)loadHTML {
    [self.webView loadHTMLString:@"<html><body><p>this is HTML!</p></body></html>" baseURL: [NSURL URLWithString:@"https://www.apple.com"]];
}

- (void)loadIndexHTML {
    NSString *str = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html"];
    NSURL *url = [NSURL fileURLWithPath:str];
    [self.webView loadFileURL:url allowingReadAccessToURL:url];
}

- (void)loadURL:(NSString *)urlString {
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    [self.webView loadRequest:urlRequest];
}

// MARK: - OC --> JS

/**
 OC调用JS代码
 */

/**
 alert弹窗要实现WKUIDelegate协议的runJavaScriptAlertPanelWithMessage方法.
 conform弹窗要实现WKUIDelegate协议的runJavaScriptConfirmPanelWithMessage方法.
 */
- (void)testJSConfirmAndAlert {
    //    NSString *jsStr = [NSString stringWithFormat:@"setLocation('%@')",@"广东省深圳市南山区学府路XXXX号"];
    //    @"var hi = function() {alert('hi');$('.info').html('hi');}"
    
    //        NSString *jsStr = @"alert('hello')";
    NSString *jsStr = @"confirm('hello')";
    [self.webView evaluateJavaScript:jsStr completionHandler:^(id _Nullable info, NSError * _Nullable error) {
        NSLog(@"info: %@", info);
        NSLog(@"error: %@", error);
    }];
}

/**
 JavaScriptCore的关键在于JSContext和JSValue两个对象.
 http://nshipster.cn/javascriptcore/
 */
- (void)testJavaScriptCore_OC_JS {
    // JSContext可理解为运行js代码的环境, 可以执行js代码, 返回执行结果(使用JSValue包装结果值).
    JSContext *jsContext = [[JSContext alloc] init];
    jsContext.exceptionHandler = ^(JSContext *context, JSValue *exception) {
        NSLog(@"JS Error: %@", exception);
    };
    
    [jsContext evaluateScript:@"var num = 5 + 5"];
    [jsContext evaluateScript:@"var names = ['Grace', 'Ada', 'Margaret']"];
    [jsContext evaluateScript:@"var triple = function(value) { return value * 3 }"];
    // 错误的JS代码会触发JSContext的exceptionHandler.
//    [jsContext evaluateScript:@"var errorTriple = function(value) { return value *"];
    
    
    // JSContext是一个JS运行的上下文环境, 其中的变量都可以访问到.
    // 对于函数, 也可以取到. 通过callWithArguments:可以直接调用该JS函数, 返回值存于一个JSValue对象中.
//    [jsContext objectForKeyedSubscript:@"names"];
//    [jsContext objectForKeyedSubscript:@"names"][0];
//    [[jsContext objectForKeyedSubscript:@"names"] objectAtIndexedSubscript:0];
//    [jsContext objectForKeyedSubscript:@"triple"];
//    [[jsContext objectForKeyedSubscript:@"triple"] callWithArguments:@[@5]];
    
    
    // JSContext中的执行结果都被包在一个JSValue对象中. JS动态语言需要一个动态类型, JSValue中包装了每个可能的JS值.
    // string, int, array, object, method, 以及null和undefined.
    /**
     Objective-C type  |   JavaScript type
     --------------------+---------------------
     nil         |     undefined
     NSNull       |        null
     NSString      |       string
     NSNumber      |   number, boolean
     NSDictionary    |   Object object
     NSArray       |    Array object
     NSDate       |     Date object
     NSBlock (1)   |   Function object (1)
     id (2)     |   Wrapper object (2)
     Class (3)    | Constructor object (3)
     */
    JSValue *jsValue = [jsContext evaluateScript:@"triple(num)"];
//    jsValue.toString;
//    jsValue.toArray;
//    jsValue.toDictionary;
}

// MARK: - JS --> OC

/**
 JS调用OC代码
 */

/**
 使用JSContext访问OC代码中的对象和方法, 可以使用blocks和JSExport协议.
 */
- (void)testJavaScriptCore_JS_OC {
    JSContext *jsContext = [[JSContext alloc] init];
    jsContext.exceptionHandler = ^(JSContext *context, JSValue *exception) {
        NSLog(@"JS Error: %@", exception);
    };
    
    // blocks
    // 此simplifyString对应于一个__NSGlobalBlock__
    // 将block传入JSContext中, JSCore会自动将block封装成一个函数.
    // 注意循环引用, 避免持有JSContext或block中的任何JSValue.
    // [JSContext currentContext];
    jsContext[@"simplifyString"] = ^(NSString *input) {
        NSMutableString *mutableString = [input mutableCopy];
        CFStringTransform((__bridge CFMutableStringRef)mutableString, NULL, kCFStringTransformToLatin, NO);
        CFStringTransform((__bridge CFMutableStringRef)mutableString, NULL, kCFStringTransformStripCombiningMarks, NO);
        return mutableString;
    };
    
    JSValue *value1 = [jsContext evaluateScript:@"simplifyString('안녕하새요!')"];
//    value1.toString; // annyeonghasaeyo!
    
    
    // JSExport协议
    jsContext[@"Person"] = [Person class];
    [jsContext evaluateScript:@"var personWithName = function(name) { var person = Person.personWithName(name); return person;}"];
    JSValue *value2 = [[jsContext objectForKeyedSubscript:@"personWithName"] callWithArguments:@[@"Chris"]];
    
}

/**
 在decidePolicyForNavigationAction方法中,
 根据navigationAction的一些参数, 解析出对应的action和参数, 执行即可.
 
 对于这些action:
 若调用iOS系统的一些接口, 则over.
 若准备一些参数, 再传递给JS中的函数, 则依然需要调用evaluateJavaScript方法.
 */
- (void)routeJS_OC_Action:(NSString *)route {
    NSString *action = [route stringByReplacingOccurrencesOfString:@"actionOC_JS://" withString:@""];
    if ([action containsString:@"setColor"]) {
        NSString *paramStr = [action stringByReplacingOccurrencesOfString:@"setColor?" withString:@""];
        NSArray *params = [paramStr componentsSeparatedByString:@"&"];
        
        NSMutableDictionary *colorDic = [NSMutableDictionary dictionary];
        for (NSString *colorStr in params) {
            NSArray *key_value = [colorStr componentsSeparatedByString:@"="];
            [colorDic setObject:key_value[1] forKey:key_value[0]];
        }
        CGFloat r = [[colorDic objectForKey:@"r"] floatValue];
        CGFloat g = [[colorDic objectForKey:@"g"] floatValue];
        CGFloat b = [[colorDic objectForKey:@"b"] floatValue];
        CGFloat a = [[colorDic objectForKey:@"a"] floatValue];

        UIColor *color = [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a];
        [self p_actionSetColor:color];
    } else if ([action containsString:@"getLocation"]) {
        [self p_actionGetLocation];
    } else if ([action containsString:@"share"]) {
        [self p_actionShare];
    } else if ([action containsString:@"scan"]) {
        
    } else if ([action containsString:@"shake"]) {
        
    } else if ([action containsString:@"pay"]) {
    
    }
}

// MARK: private actions for JS->OC

- (void)p_actionSetColor:(UIColor *)color {
    self.webView.backgroundColor = color;
    self.view.backgroundColor = color;
}

- (void)p_actionGetLocation {
    // 获取真实的位置信息
    
    // 传入的JS代码中, 调用JS中的setLocation方法, 传入地址
    NSString *jsStr = [NSString stringWithFormat:@"setLocation('%@')", @"广东省深圳市南山区学府路XXXX号"];
    [self.webView evaluateJavaScript:jsStr completionHandler:^(id _Nullable info, NSError * _Nullable error) {
        NSLog(@"p_actionGetLocation : %@ %@", info, error);
    }];
}

- (void)p_actionShare {
    // 调用JS的shareResult方法, 传递参数
}

- (void)p_actionScan {
    
}

- (void)p_actionShake {
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}

- (void)p_actionPay {
    // 调用JS的payResult方法, 传递参数
}

// MARK: - actions

- (IBAction)actionBtnClose:(UIButton *)sender {
}

- (IBAction)actionBtnBackward:(id)sender {
    if ([self.webView canGoBack]) {
        [self.webView goBack];
    }
}

- (IBAction)actionBtnForward:(id)sender {
    if ([self.webView canGoForward]) {
        [self.webView goForward];
    }
}

- (IBAction)actionBtnRefresh:(UIButton *)sender {
    [self.webView reloadFromOrigin];
    
    self.webView.backgroundColor = [UIColor whiteColor];
    self.view.backgroundColor = [UIColor whiteColor];
}

// MARK: - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"loading"]) {
        NSLog(@"loading: %d", _webView.isLoading);
    } else if ([keyPath isEqualToString:@"estimatedProgress"]) {
        NSLog(@"estimatedProgress: %f", _webView.estimatedProgress);
        self.progressView.progress = _webView.estimatedProgress;
        if (self.progressView.progress >= 1.f) {
            self.progressView.progress = 0.f;
        }
    }
}

// MARK: - WKNavigationDelegate

/*! A class conforming to the WKNavigationDelegate protocol can provide
 methods for tracking progress for main frame navigations and for deciding
 policy for main frame and subframe navigations.
 */

// MARK: 拦截URL

/*! @abstract Decides whether to allow or cancel a navigation.
 @param webView The web view invoking the delegate method.
 @param navigationAction Descriptive information about the action
 triggering the navigation request.
 @param decisionHandler The decision handler to call to allow or cancel the
 navigation. The argument is one of the constants of the enumerated type WKNavigationActionPolicy.
 @discussion If you do not implement this method, the web view will load the request or, if appropriate, forward it to another application.
 */
// 接收到响应后, 如何处理(是否跳转, 是否拦截URL等)
// 调用decisionHandler(WKNavigationActionPolicyAllow);则允许跳转
// 调用decisionHandler(WKNavigationActionPolicyCancel);即不允许跳转
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSLog(@">>>>>>>>>> %s", __FUNCTION__);
    // 该方法实现了, 则必须调用decisionHandler.
    
    NSURL *url = navigationAction.request.URL;
    
    if ([url.absoluteString isEqualToString:@"about:blank"]) {
        decisionHandler(WKNavigationActionPolicyAllow);
        return;
    }
    
    NSString *scheme = [url scheme];
    
    NSURL *docUrl = navigationAction.request.mainDocumentURL;
    NSURL *urlOfBundleFilePrefix = [docUrl URLByDeletingLastPathComponent];
    NSString *route = [url.absoluteString stringByReplacingOccurrencesOfString:urlOfBundleFilePrefix.absoluteString withString:@""];
    
    
    if ([route containsString:@"actionOC_JS://"]) {
        [self routeJS_OC_Action:route];
        
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    
    NSString *host = [url host];
    
    NSLog(@"comes from %@ %@", scheme, host);
    
    if ([host containsString:@"baidu"]) {
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    
    decisionHandler(WKNavigationActionPolicyAllow);
}

/*! @abstract Decides whether to allow or cancel a navigation after its
 response is known.
 @param webView The web view invoking the delegate method.
 @param navigationResponse Descriptive information about the navigation
 response.
 @param decisionHandler The decision handler to call to allow or cancel the
 navigation. The argument is one of the constants of the enumerated type WKNavigationResponsePolicy.
 @discussion If you do not implement this method, the web view will allow the response, if the web view can show it.
 */
//- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
//    NSLog(@">>>>>>>>>> %s", __FUNCTION__);
//}

/*! @abstract Invoked when a main frame navigation starts.
 @param webView The web view invoking the delegate method.
 @param navigation The navigation.
 */
// 页面开始加载
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation {
    NSLog(@">>>>>>>>>> %s", __FUNCTION__);
}

/*! @abstract Invoked when a server redirect is received for the main
 frame.
 @param webView The web view invoking the delegate method.
 @param navigation The navigation.
 */
// 接收到服务器的重定向
- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(null_unspecified WKNavigation *)navigation {
    NSLog(@">>>>>>>>>> %s", __FUNCTION__);
}

/*! @abstract Invoked when an error occurs while starting to load data for
 the main frame.
 @param webView The web view invoking the delegate method.
 @param navigation The navigation.
 @param error The error that occurred.
 */
// 页面加载失败
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@">>>>>>>>>> %s", __FUNCTION__);
    NSLog(@"error: %@", error);
}

/*! @abstract Invoked when content starts arriving for the main frame.
 @param webView The web view invoking the delegate method.
 @param navigation The navigation.
 */
// 跳转以及完成, 页面内容开始到达并展示
- (void)webView:(WKWebView *)webView didCommitNavigation:(null_unspecified WKNavigation *)navigation {
    NSLog(@">>>>>>>>>> %s", __FUNCTION__);
}

/*! @abstract Invoked when a main frame navigation completes.
 @param webView The web view invoking the delegate method.
 @param navigation The navigation.
 */
// 页面跳转完成
- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation {
    NSLog(@">>>>>>>>>> %s", __FUNCTION__);
}

/*! @abstract Invoked when an error occurs during a committed main frame
 navigation.
 @param webView The web view invoking the delegate method.
 @param navigation The navigation.
 @param error The error that occurred.
 */
// 页面跳转失败
- (void)webView:(WKWebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@">>>>>>>>>> %s", __FUNCTION__);
}

/*! @abstract Invoked when the web view needs to respond to an authentication challenge.
 @param webView The web view that received the authentication challenge.
 @param challenge The authentication challenge.
 @param completionHandler The completion handler you must invoke to respond to the challenge. The
 disposition argument is one of the constants of the enumerated type
 NSURLSessionAuthChallengeDisposition. When disposition is NSURLSessionAuthChallengeUseCredential,
 the credential argument is the credential to use, or nil to indicate continuing without a
 credential.
 @discussion If you do not implement this method, the web view will respond to the authentication challenge with the NSURLSessionAuthChallengeRejectProtectionSpace disposition.
 */
//- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler {
//    NSLog(@">>>>>>>>>> %s", __FUNCTION__);
//}

/*! @abstract Invoked when the web view's web content process is terminated.
 @param webView The web view whose underlying web content process was terminated.
 */
- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView {
    NSLog(@">>>>>>>>>> %s", __FUNCTION__);
}

// MARK: - WKUIDelegate

/*! A class conforming to the WKUIDelegate protocol provides methods for
 presenting native UI on behalf of a webpage.
 */

/*! @abstract Creates a new web view.
 @param webView The web view invoking the delegate method.
 @param configuration The configuration to use when creating the new web
 view.
 @param navigationAction The navigation action causing the new web view to
 be created.
 @param windowFeatures Window features requested by the webpage.
 @result A new web view or nil.
 @discussion The web view returned must be created with the specified configuration. WebKit will load the request in the returned web view.
 
 If you do not implement this method, the web view will cancel the navigation.
 */
//- (nullable WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures;

/*! @abstract Notifies your app that the DOM window object's close() method completed successfully.
 @param webView The web view invoking the delegate method.
 @discussion Your app should remove the web view from the view hierarchy and update
 the UI as needed, such as by closing the containing browser tab or window.
 */
- (void)webViewDidClose:(WKWebView *)webView {
    NSLog(@">>>>>>>>>> %s", __FUNCTION__);
}

/*! @abstract Displays a JavaScript alert panel.
 @param webView The web view invoking the delegate method.
 @param message The message to display.
 @param frame Information about the frame whose JavaScript initiated this
 call.
 @param completionHandler The completion handler to call after the alert
 panel has been dismissed.
 @discussion For user security, your app should call attention to the fact
 that a specific website controls the content in this panel. A simple forumla
 for identifying the controlling website is frame.request.URL.host.
 The panel should have a single OK button.
 
 If you do not implement this method, the web view will behave as if the user selected the OK button.
 */
// 弹出警告框
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    NSLog(@">>>>>>>>>> %s", __FUNCTION__);
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Alert" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler();
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

/*! @abstract Displays a JavaScript confirm panel.
 @param webView The web view invoking the delegate method.
 @param message The message to display.
 @param frame Information about the frame whose JavaScript initiated this call.
 @param completionHandler The completion handler to call after the confirm
 panel has been dismissed. Pass YES if the user chose OK, NO if the user
 chose Cancel.
 @discussion For user security, your app should call attention to the fact
 that a specific website controls the content in this panel. A simple forumla
 for identifying the controlling website is frame.request.URL.host.
 The panel should have two buttons, such as OK and Cancel.
 
 If you do not implement this method, the web view will behave as if the user selected the Cancel button.
 */
// 弹出确认框
- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL result))completionHandler {
    NSLog(@">>>>>>>>>> %s", __FUNCTION__);
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Confirm" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(YES);
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

/*! @abstract Displays a JavaScript text input panel.
 @param webView The web view invoking the delegate method.
 @param message The message to display.
 @param defaultText The initial text to display in the text entry field.
 @param frame Information about the frame whose JavaScript initiated this call.
 @param completionHandler The completion handler to call after the text
 input panel has been dismissed. Pass the entered text if the user chose
 OK, otherwise nil.
 @discussion For user security, your app should call attention to the fact
 that a specific website controls the content in this panel. A simple forumla
 for identifying the controlling website is frame.request.URL.host.
 The panel should have two buttons, such as OK and Cancel, and a field in
 which to enter text.
 
 If you do not implement this method, the web view will behave as if the user selected the Cancel button.
 */
// 弹出输入框
- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(nullable NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable result))completionHandler {
    NSLog(@">>>>>>>>>> %s", __FUNCTION__);
}

#if TARGET_OS_IPHONE

/*! @abstract Allows your app to determine whether or not the given element should show a preview.
 @param webView The web view invoking the delegate method.
 @param elementInfo The elementInfo for the element the user has started touching.
 @discussion To disable previews entirely for the given element, return NO. Returning NO will prevent
 webView:previewingViewControllerForElement:defaultActions: and webView:commitPreviewingViewController:
 from being invoked.
 
 This method will only be invoked for elements that have default preview in WebKit, which is
 limited to links. In the future, it could be invoked for additional elements.
 */
// 是否预览
- (BOOL)webView:(WKWebView *)webView shouldPreviewElement:(WKPreviewElementInfo *)elementInfo {
    NSLog(@">>>>>>>>>> %s", __FUNCTION__);
    return YES;
}

/*! @abstract Allows your app to provide a custom view controller to show when the given element is peeked.
 @param webView The web view invoking the delegate method.
 @param elementInfo The elementInfo for the element the user is peeking.
 @param defaultActions An array of the actions that WebKit would use as previewActionItems for this element by
 default. These actions would be used if allowsLinkPreview is YES but these delegate methods have not been
 implemented, or if this delegate method returns nil.
 @discussion Returning a view controller will result in that view controller being displayed as a peek preview.
 To use the defaultActions, your app is responsible for returning whichever of those actions it wants in your
 view controller's implementation of -previewActionItems.
 
 Returning nil will result in WebKit's default preview behavior. webView:commitPreviewingViewController: will only be invoked
 if a non-nil view controller was returned.
 */
//- (nullable UIViewController *)webView:(WKWebView *)webView previewingViewControllerForElement:(WKPreviewElementInfo *)elementInfo defaultActions:(NSArray<id <WKPreviewActionItem>> *)previewActions API_AVAILABLE(ios(10.0))

/*! @abstract Allows your app to pop to the view controller it created.
 @param webView The web view invoking the delegate method.
 @param previewingViewController The view controller that is being popped.
 */
- (void)webView:(WKWebView *)webView commitPreviewingViewController:(UIViewController *)previewingViewController {
    NSLog(@">>>>>>>>>> %s", __FUNCTION__);
}

#endif // TARGET_OS_IPHONE

#if !TARGET_OS_IPHONE

/*! @abstract Displays a file upload panel.
 @param webView The web view invoking the delegate method.
 @param parameters Parameters describing the file upload control.
 @param frame Information about the frame whose file upload control initiated this call.
 @param completionHandler The completion handler to call after open panel has been dismissed. Pass the selected URLs if the user chose OK, otherwise nil.
 
 If you do not implement this method, the web view will behave as if the user selected the Cancel button.
 */
//- (void)webView:(WKWebView *)webView runOpenPanelWithParameters:(WKOpenPanelParameters *)parameters initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSArray<NSURL *> * _Nullable URLs))completionHandler API_AVAILABLE(macosx(10.12));

#endif

@end
