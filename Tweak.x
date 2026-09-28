#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#define WALLPAPER_PATH @"/var/mobile/Library/Application Support/VibeTendies/wallpaper.png"

// Правильные объявления классов SpringBoard
@interface UIView (VibeExtra)
@property (nonatomic, readonly) UIWindow *window;
@end

@interface SBFWallpaperView : UIView
@end

@interface SBIconController : UIViewController
- (UIView *)view;
@end

static UIImage *loadWallpaper(void) {
    if (![[NSFileManager defaultManager] fileExistsAtPath:WALLPAPER_PATH]) {
        NSLog(@"[VibeTendies] No file at %@", WALLPAPER_PATH);
        return nil;
    }
    UIImage *img = [UIImage imageWithContentsOfFile:WALLPAPER_PATH];
    NSLog(@"[VibeTendies] Loaded image: %@", img ? @"OK" : @"FAIL");
    return img;
}

static void attachImageToView(UIView *host, NSString *tag) {
    if (!host) return;
    UIImage *img = loadWallpaper();
    if (!img) return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        for (UIView *sub in host.subviews) {
            if (sub.tag == 999999) [sub removeFromSuperview];
        }
        
        UIImageView *iv = [[UIImageView alloc] initWithFrame:host.bounds];
        iv.image = img;
        iv.contentMode = UIViewContentModeScaleAspectFill;
        iv.clipsToBounds = YES;
        iv.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        iv.tag = 999999;
        iv.userInteractionEnabled = NO;
        
        [host insertSubview:iv atIndex:0];
        NSLog(@"[VibeTendies] Image attached (%@)", tag);
    });
}

%hook SBFWallpaperView
- (void)didMoveToWindow {
    %orig;
    NSLog(@"[VibeTendies] SBFWallpaperView didMoveToWindow");
    attachImageToView(self, @"wallpaper");
}
%end

%hook SBIconController
- (void)viewDidAppear:(BOOL)animated {
    %orig;
    NSLog(@"[VibeTendies] SBIconController viewDidAppear");
    attachImageToView([self view], @"icons");
}
%end
