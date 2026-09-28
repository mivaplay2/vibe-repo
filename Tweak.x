#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#define WALLPAPER_PATH @"/var/mobile/Library/Application Support/VibeTendies/wallpaper.png"

static UIWindow *gOverlay = nil;

static NSArray *activeWindows(void) {
    for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
        if ([scene isKindOfClass:[UIWindowScene class]]) {
            NSArray *w = ((UIWindowScene *)scene).windows;
            if (w.count > 0) return w;
        }
    }
    return @[];
}

static void showOverlay(void) {
    if (![[NSFileManager defaultManager] fileExistsAtPath:WALLPAPER_PATH]) {
        NSLog(@"[VibeTendies] No wallpaper file");
        return;
    }
    
    UIImage *img = [UIImage imageWithContentsOfFile:WALLPAPER_PATH];
    if (!img) {
        NSLog(@"[VibeTendies] Failed to load image");
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (gOverlay) {
            [gOverlay removeFromSuperview];
            gOverlay = nil;
        }
        
        NSArray *windows = activeWindows();
        UIWindow *host = nil;
        for (UIWindow *w in windows) {
            if (w.bounds.size.width > 0) { host = w; break; }
        }
        if (!host) {
            NSLog(@"[VibeTendies] No host window");
            return;
        }
        
        gOverlay = [[UIWindow alloc] initWithFrame:host.bounds];
        gOverlay.windowLevel = UIWindowLevelAlert + 100;
        gOverlay.backgroundColor = [UIColor clearColor];
        gOverlay.userInteractionEnabled = NO;
        gOverlay.rootViewController = [[UIViewController alloc] init];
        gOverlay.rootViewController.view.backgroundColor = [UIColor clearColor];
        
        UIImageView *iv = [[UIImageView alloc] initWithFrame:gOverlay.bounds];
        iv.image = img;
        iv.contentMode = UIViewContentModeScaleAspectFill;
        iv.clipsToBounds = YES;
        iv.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        iv.userInteractionEnabled = NO;
        [gOverlay.rootViewController.view addSubview:iv];
        
        gOverlay.hidden = NO;
        NSLog(@"[VibeTendies] Overlay SHOWN");
    });
}

%ctor {
    NSLog(@"[VibeTendies] Constructor fired");
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        showOverlay();
    });
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"SBLockScreenDidUnlockNotification"
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            showOverlay();
        });
    }];
}
