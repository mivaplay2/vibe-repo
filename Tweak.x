#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#define WALLPAPER_PATH @"/var/mobile/Library/Application Support/VibeTendies/wallpaper.png"
#define LOG_PATH @"/var/mobile/Documents/vibe.log"

@interface SBFWallpaperView : UIView
@end
@interface SBWallpaperController : UIViewController
@end
@interface SBIconController : UIViewController
@end
@interface SBLockScreenManager : NSObject
@end

static void vlog(NSString *s) {
    FILE *f = fopen([LOG_PATH UTF8String], "a");
    if (!f) return;
    NSString *line = [NSString stringWithFormat:@"%@\n", s];
    fwrite([line UTF8String], 1, [line lengthOfBytesUsingEncoding:NSUTF8StringEncoding], f);
    fclose(f);
}

static UIImage *loadImg(void) {
    if (![[NSFileManager defaultManager] fileExistsAtPath:WALLPAPER_PATH]) {
        vlog(@"no wallpaper file");
        return nil;
    }
    UIImage *img = [UIImage imageWithContentsOfFile:WALLPAPER_PATH];
    vlog(img ? @"image loaded" : @"image load failed");
    return img;
}

static void paint(UIView *host, NSString *who) {
    if (!host) { vlog([NSString stringWithFormat:@"%@: host nil", who]); return; }
    UIImage *img = loadImg();
    if (!img) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        for (UIView *v in host.subviews) {
            if (v.tag == 777777) [v removeFromSuperview];
        }
        UIImageView *iv = [[UIImageView alloc] initWithFrame:host.bounds];
        iv.image = img;
        iv.contentMode = UIViewContentModeScaleAspectFill;
        iv.clipsToBounds = YES;
        iv.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        iv.tag = 777777;
        iv.userInteractionEnabled = NO;
        [host insertSubview:iv atIndex:0];
        vlog([NSString stringWithFormat:@"painted in %@", who]);
    });
}

%hook SBFWallpaperView
- (void)didMoveToWindow {
    %orig;
    vlog(@"SBFWallpaperView didMoveToWindow");
    paint(self, @"SBFWallpaperView");
}
%end

%hook SBWallpaperController
- (void)viewDidAppear:(BOOL)a {
    %orig;
    vlog(@"SBWallpaperController viewDidAppear");
    paint([self view], @"SBWallpaperController");
}
%end

%hook SBIconController
- (void)viewDidAppear:(BOOL)a {
    %orig;
    vlog(@"SBIconController viewDidAppear");
    paint([self view], @"SBIconController");
}
%end

%ctor {
    vlog(@"=== constructor ===");
}
