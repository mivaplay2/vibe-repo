#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#define TENDIES_PATH @"/var/mobile/Library/Application Support/VibeTendies"

static UIWindow *overlayWindow = nil;
static CALayer *camlLayer = nil;

// Загружаем CAML-файл через приватный фреймворк
static CALayer *loadCAMLLayer(NSString *camlPath) {
    if (![[NSFileManager defaultManager] fileExistsAtPath:camlPath]) return nil;
    
    // CAML загружается через CAAnimation
    NSData *data = [NSData dataWithContentsOfFile:camlPath];
    if (!data) return nil;
    
    // Пробуем создать слой из CAML через Core Animation
    // В iOS CAML-файлы рендерятся через CAStateController
    Class CAStateController = NSClassFromString(@"CAStateController");
    if (!CAStateController) return nil;
    
    CALayer *layer = [CALayer layer];
    layer.frame = [UIScreen mainScreen].bounds;
    
    id controller = [[CAStateController alloc] initWithLayer:layer];
    if (controller) {
        // Загружаем состояния из CAML
        [controller performSelector:@selector(setState:ofLayer:) withObject:data withObject:layer];
    }
    
    return layer;
}

// Показываем overlay с CAML-слоем
static void showOverlayWithCAMLLayer(CALayer *layer) {
    if (!layer) return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (overlayWindow) {
            [overlayWindow removeFromSuperview];
            overlayWindow = nil;
        }
        
        overlayWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        overlayWindow.windowLevel = UIWindowLevelAlert + 1;
        overlayWindow.backgroundColor = [UIColor clearColor];
        overlayWindow.userInteractionEnabled = NO;
        
        UIView *containerView = [[UIView alloc] initWithFrame:overlayWindow.bounds];
        containerView.backgroundColor = [UIColor clearColor];
        [containerView.layer addSublayer:layer];
        
        [overlayWindow addSubview:containerView];
        overlayWindow.hidden = NO;
    });
}

%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)application {
    %orig;
    
    // Ищем CAML-файл в папке твика
    NSString *camlPath = [TENDIES_PATH stringByAppendingPathComponent:@"wallpaper.caml"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:camlPath]) {
        CALayer *layer = loadCAMLLayer(camlPath);
        if (layer) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
                           dispatch_get_main_queue(), ^{
                showOverlayWithCAMLLayer(layer);
            });
        }
    }
}

%end
