#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#define WALLPAPER_PATH @"/var/mobile/Library/Application Support/VibeTendies/wallpaper.png"

static UIView *gBgView = nil;

static void applyWallpaper(void) {
    UIImage *img = [UIImage imageWithContentsOfFile:WALLPAPER_PATH];
    if (!img) {
        NSLog(@"[VibeTendies] No image at %@", WALLPAPER_PATH);
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *w = nil;
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]]) {
                UIWindowScene *ws = (UIWindowScene *)scene;
                for (UIWindow *win in ws.windows) {
                    if (win.isKeyWindow) { w = win; break; }
                }
                if (!w && ws.windows.count > 0) w = ws.windows.firstObject;
            }
            if (w) break;
        }
        if (!w) {
            NSLog(@"[VibeTendies] No window");
            return;
        }
        
        if (gBgView) [gBgView removeFromSuperview];
        
        gBgView = [[UIView alloc] initWithFrame:w.bounds];
        gBgView.backgroundColor = [UIColor blackColor];
        gBgView.userInteractionEnabled = NO;
        gBgView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        UIImageView *iv = [[UIImageView alloc] initWithFrame:gBgView.bounds];
        iv.image = img;
        iv.contentMode = UIViewContentModeScaleAspectFill;
        iv.clipsToBounds = YES;
        iv.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [gBgView addSubview:iv];
        
        // Вставляем ПОД первый subview, чтобы иконки остались сверху
        [w insertSubview:gBgView atIndex:0];
        
        NSLog(@"[VibeTendies] Wallpaper applied to window %@", w);
    });
}

%hook SpringBoard
- (void)applicationDidFinishLaunching:(id)application {
    %orig;
    NSLog(@"[VibeTendies] SB launched");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        applyWallpaper();
    });
}

- (void)_menuButtonWasPressed:(id)arg {
    %orig;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        applyWallpaper();
    });
}
%end
