#import "RootListController.h"
#import <PhotosUI/PhotosUI.h>
#import <spawn.h>
#import <sys/wait.h>

extern char **environ;

@interface RootListController () <PHPickerViewControllerDelegate>
@end

@implementation RootListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        NSMutableArray *specs = [NSMutableArray new];
        
        PSSpecifier *g = [PSSpecifier groupSpecifierWithName:@"VibeTendies"];
        [g setProperty:@"Выберите фото из галереи или импортируйте .tendies" forKey:@"footerText"];
        [specs addObject:g];
        
        PSSpecifier *btn1 = [PSSpecifier preferenceSpecifierNamed:@"Выбрать фото из галереи"
                                                           target:self set:nil get:nil detail:nil
                                                             cell:PSButtonCell edit:nil];
        btn1->action = @selector(selectPhoto);
        [specs addObject:btn1];
        
        PSSpecifier *btn2 = [PSSpecifier preferenceSpecifierNamed:@"Импорт .tendies"
                                                           target:self set:nil get:nil detail:nil
                                                             cell:PSButtonCell edit:nil];
        btn2->action = @selector(selectTendies);
        [specs addObject:btn2];
        
        PSSpecifier *btn3 = [PSSpecifier preferenceSpecifierNamed:@"Перезапустить SpringBoard"
                                                           target:self set:nil get:nil detail:nil
                                                             cell:PSButtonCell edit:nil];
        btn3->action = @selector(doRespring);
        [specs addObject:btn3];
        
        _specifiers = specs;
    }
    return _specifiers;
}

#pragma mark - Photo Library

- (void)selectPhoto {
    PHPickerConfiguration *config = [[PHPickerConfiguration alloc] init];
    config.selectionLimit = 1;
    config.filter = [PHPickerFilter imagesFilter];
    
    PHPickerViewController *picker = [[PHPickerViewController alloc] initWithConfiguration:config];
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results {
    [picker dismissViewControllerAnimated:YES completion:nil];
    if (results.count == 0) return;
    
    PHPickerResult *result = results.firstObject;
    NSItemProvider *provider = result.itemProvider;
    
    [provider loadObjectOfClass:[UIImage class] completionHandler:^(UIImage *img, NSError *error) {
        if (!img) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showAlert:error.localizedDescription ?: @"Не удалось загрузить фото"];
            });
            return;
        }
        
        NSString *dir = @"/var/mobile/Library/Application Support/VibeTendies";
        [[NSFileManager defaultManager] createDirectoryAtPath:dir
                                  withIntermediateDirectories:YES attributes:nil error:nil];
        NSString *dst = [dir stringByAppendingPathComponent:@"wallpaper.png"];
        [[NSFileManager defaultManager] removeItemAtPath:dst error:nil];
        
        NSData *png = UIImagePNGRepresentation(img);
        [png writeToFile:dst atomically:YES];
        NSLog(@"[VibeTendies] Saved %lu bytes from photo library", (unsigned long)png.length);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showAlert:@"Фото сохранено! Жми Respring."];
        });
    }];
}

#pragma mark - .tendies

- (void)selectTendies {
    UIDocumentPickerViewController *p = [[UIDocumentPickerViewController alloc]
        initForOpeningContentTypes:@[[UTType typeWithIdentifier:@"public.data"]]];
    p.delegate = self;
    [self presentViewController:p animated:YES completion:nil];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller
    didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    NSURL *u = urls.firstObject;
    if (!u) return;
    [self importTendies:u.path];
}

- (void)importTendies:(NSString *)src {
    NSString *tmpDir = [NSTemporaryDirectory() stringByAppendingPathComponent:@"tendies_extract"];
    [[NSFileManager defaultManager] removeItemAtPath:tmpDir error:nil];
    [[NSFileManager defaultManager] createDirectoryAtPath:tmpDir
                              withIntermediateDirectories:YES attributes:nil error:nil];
    
    // Копируем .tendies во временный .zip
    NSString *tmpZip = [NSTemporaryDirectory() stringByAppendingPathComponent:@"tendies.zip"];
    [[NSFileManager defaultManager] removeItemAtPath:tmpZip error:nil];
    [[NSFileManager defaultManager] copyItemAtPath:src toPath:tmpZip error:nil];
    
    NSString *unzip = @"/var/jb/usr/bin/unzip";
    if (![[NSFileManager defaultManager] fileExistsAtPath:unzip]) unzip = @"/usr/bin/unzip";
    
    pid_t pid;
    const char *args[] = {"unzip", "-o", [tmpZip UTF8String], "-d", [tmpDir UTF8String], NULL};
    posix_spawn(&pid, [unzip UTF8String], NULL, NULL, (char *const *)args, environ);
    int status; waitpid(pid, &status, 0);
    
    if (status != 0) { [self showAlert:@"Не удалось распаковать"]; return; }
    
    NSString *found = nil;
    NSDirectoryEnumerator *en = [[NSFileManager defaultManager] enumeratorAtPath:tmpDir];
    for (NSString *f in en) {
        NSString *e = [[f pathExtension] lowercaseString];
        if ([e isEqualToString:@"png"] || [e isEqualToString:@"jpg"] || [e isEqualToString:@"jpeg"] || [e isEqualToString:@"heic"]) {
            found = [tmpDir stringByAppendingPathComponent:f];
            break;
        }
    }
    
    if (!found) {
        [self showAlert:@"В .tendies нет картинки. Это файл-дескриптор, а не обои. Используй PNG."];
        return;
    }
    
    UIImage *img = [UIImage imageWithContentsOfFile:found];
    if (!img) { [self showAlert:@"Не удалось прочитать картинку"]; return; }
    
    NSString *dir = @"/var/mobile/Library/Application Support/VibeTendies";
    [[NSFileManager defaultManager] createDirectoryAtPath:dir
                              withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *dst = [dir stringByAppendingPathComponent:@"wallpaper.png"];
    [[NSFileManager defaultManager] removeItemAtPath:dst error:nil];
    
    NSData *png = UIImagePNGRepresentation(img);
    [png writeToFile:dst atomically:YES];
    [self showAlert:@"Картинка из .tendies сохранена! Жми Respring."];
}

#pragma mark - Respring

- (void)doRespring {
    NSString *k = @"/var/jb/usr/bin/killall";
    if (![[NSFileManager defaultManager] fileExistsAtPath:k]) k = @"/usr/bin/killall";
    pid_t pid;
    const char *args[] = {"killall", "-9", "SpringBoard", NULL};
    posix_spawn(&pid, [k UTF8String], NULL, NULL, (char *const *)args, environ);
}

- (void)showAlert:(NSString *)msg {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *a = [UIAlertController alertControllerWithTitle:@"VibeTendies"
                                                                  message:msg
                                                           preferredStyle:UIAlertControllerStyleAlert];
        [a addAction:[UIAlertAction actionWithTitle:@"Ок" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:a animated:YES completion:nil];
    });
}

@end
