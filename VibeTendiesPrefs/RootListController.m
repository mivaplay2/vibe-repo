#import "RootListController.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import <spawn.h>

extern char **environ;

@implementation RootListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        NSMutableArray *specs = [NSMutableArray new];
        
        PSSpecifier *g1 = [PSSpecifier groupSpecifierWithName:@"VibeTendies"];
        [g1 setProperty:@"Выберите картинку — она наложится поверх обоев. После выбора нажмите «Перезапустить SpringBoard»." forKey:@"footerText"];
        [specs addObject:g1];
        
        PSSpecifier *sel = [PSSpecifier preferenceSpecifierNamed:@"Выбрать картинку"
                                                         target:self
                                                            set:nil
                                                            get:nil
                                                         detail:nil
                                                           cell:PSButtonCell
                                                           edit:nil];
        [sel setProperty:NSStringFromSelector(@selector(selectFile)) forKey:@"action"];
        [specs addObject:sel];
        
        PSSpecifier *g2 = [PSSpecifier groupSpecifierWithName:@""];
        [specs addObject:g2];
        
        PSSpecifier *res = [PSSpecifier preferenceSpecifierNamed:@"Перезапустить SpringBoard"
                                                         target:self
                                                            set:nil
                                                            get:nil
                                                         detail:nil
                                                           cell:PSButtonCell
                                                           edit:nil];
        [res setProperty:NSStringFromSelector(@selector(doRespring)) forKey:@"action"];
        [specs addObject:res];
        
        _specifiers = specs;
    }
    return _specifiers;
}

- (void)selectFile {
    UIDocumentPickerViewController *p = [[UIDocumentPickerViewController alloc]
        initForOpeningContentTypes:@[UTTypeImage]];
    p.delegate = self;
    [self presentViewController:p animated:YES completion:nil];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller
    didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    NSURL *u = urls.firstObject;
    if (!u) return;
    
    NSString *dir = @"/var/mobile/Library/Application Support/VibeTendies";
    [[NSFileManager defaultManager] createDirectoryAtPath:dir
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];
    
    NSString *dst = [dir stringByAppendingPathComponent:@"wallpaper.png"];
    [[NSFileManager defaultManager] removeItemAtPath:dst error:nil];
    NSError *err = nil;
    [[NSFileManager defaultManager] copyItemAtPath:u.path toPath:dst error:&err];
    
    NSString *msg = err ? [NSString stringWithFormat:@"Ошибка: %@", err.localizedDescription]
                        : @"Сохранено! Нажмите «Перезапустить SpringBoard».";
    
    UIAlertController *a = [UIAlertController alertControllerWithTitle:@"VibeTendies"
                                                              message:msg
                                                       preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"Ок" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:a animated:YES completion:nil];
}

- (void)doRespring {
    NSString *killall = @"/var/jb/usr/bin/killall";
    if (![[NSFileManager defaultManager] fileExistsAtPath:killall]) {
        killall = @"/usr/bin/killall";
    }
    pid_t pid;
    const char *args[] = {"killall", "-9", "SpringBoard", NULL};
    posix_spawn(&pid, [killall UTF8String], NULL, NULL, (char *const *)args, environ);
}

@end
