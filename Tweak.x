#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#define TENDIES_DIR @"/var/mobile/Library/Application Support/VibeTendies"
#define WALLPAPER_PATH @"/var/mobile/Library/Application Support/VibeTendies/wallpaper.png"

static UIWindow *gOverlay = nil;

static void createTendiesDir(void) {
    if (![[NSFileManager defaultManager] fileExistsAtPath:TENDIES_DIR]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:TENDIES_DIR
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
    }
}

static void showWallpaperOverlay(void) {
    NSLog(@"[VibeTendies] showWallpaperOverlay called");
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:WALLPAPER_PATH]) {
        NSLog(@"[VibeTendies] No wallpaper at %@", WALLPAPER_PATH);
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
        
        // Ищем активный UIWindowScene
        UIWindowScene *targetScene = nil;
        for (UIScene *s in [UIApplication sharedApplication].connectedScenes) {
            if ([s isKindOfClass:[UIWindowScene class]]) {
                UIWindowScene *ws = (UIWindowScene *)s;
                if (ws.activationState == UISceneActivationStateForegroundActive) {
                    targetScene = ws;
                    break;
                }
                if (!targetScene) targetScene = ws;
            }
        }
        
        if (!targetScene) {
            NSLog(@"[VibeTendies] No UIWindowScene found");
            return;
        }
        
        gOverlay = [[UIWindow alloc] initWithWindowScene:targetScene];
        gOverlay.frame = targetScene.coordinateSpace.bounds;
        gOverlay.windowLevel = 10000;
        gOverlay.backgroundColor = [UIColor clearColor];
        gOverlay.userInteractionEnabled = NO;
        gOverlay.rootViewController = [[UIViewController alloc] init];
        gOverlay.rootViewController.view.backgroundColor = [UIColor clearColor];
        gOverlay.hidden = NO;
        
        UIImageView *iv = [[UIImageView alloc] initWithFrame:gOverlay.bounds];
        iv.image = img;
        iv.contentMode = UIViewContentModeScaleAspectFill;
        iv.clipsToBounds = YES;
        iv.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        iv.userInteractionEnabled = NO;
        
        [gOverlay.rootViewController.view addSubview:iv];
        
        NSLog(@"[VibeTendies] Overlay shown successfully");
    });
}

%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)application {
    %orig;
    NSLog(@"[VibeTendies] SpringBoard didFinishLaunching");
    createTendiesDir();
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(vibe_onUnlock)
                                                 name:@"SBLockScreenDidUnlockNotification"
                                               object:nil];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        showWallpaperOverlay();
    });
}

- (void)vibe_onUnlock {
    NSLog(@"[VibeTendies] Unlock detected, refreshing overlay");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        showWallpaperOverlay();
    });
}

%end

// Резервный хук — на случай, если didFinishLaunching не сработает
%hook SBUIController
- (void)finishLaunching {
    %orig;
    NSLog(@"[VibeTendies] SBUIController finishLaunching");
    createTendiesDir();
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        showWallpaperOverlay();
    });
}
%end
