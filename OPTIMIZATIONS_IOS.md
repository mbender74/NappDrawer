# NappDrawer iOS — Optimierungsplan

Erstellt: 2026-05-22  
Basis: Titanium SDK 13.2.0.GA | Xcode 15.4+ | iOS Deployment Target 12.0+

---

## A. Titanium SDK API-Nutzung

### A1. `valueForUndefinedKey:` — korrekte Titanium-Eigenschaftsanfrage

**Problem:** `DkNappDrawerDrawer.m` verwendet `valueForUndefinedKey:` um Properties vom Proxy zu lesen (Zeilen 90, 99, 107, 113, 121, etc.). Intern ruft `TiProxy:valueForUndefinedKey:` auf `dynprops` zu — das funktioniert, ist aber ein indirekter Weg.

**Titanium SDK Pattern:** `TiProxy` speichert Properties in `dynprops` (NSMutableDictionary). `valueForUndefinedKey:` liest korrekt daraus. Allerdings gibt es keinen öffentlichen Getter wie `getProperty:`.

**Bewertung:** Der aktuelle Ansatz ist **funktional korrekt**, aber es gibt keine Typsicherheit.

**Empfehlung:** Beibehalten, aber mit Kommentar dokumentieren:
```objc
// Titanium SDK: TiProxy:valueForUndefinedKey: liest aus dynprops
id leftWindow = [self.proxy valueForUndefinedKey:@"leftWindow"];
```

### A2. `TiThreadPerformOnMainThread` — korrekte Verwendung

**Problem:** `DkNappDrawerDrawer.m` Zeilen 57–61 und 128–131:
```objc
TiThreadPerformOnMainThread(^{
    [proxy windowWillOpen];
    [proxy reposition];
    [proxy windowDidOpen];
}, YES);
```
Der `waitForFinish=YES` Parameter bedeutet, dass die Methode blockiert, bis der Block auf dem Main Thread ausgeführt wurde. Das ist in einem lazy-init Kontext problematisch, wenn der Aufruf bereits vom Main Thread kommt (deadlock!).

**Betroffen:** `DkNappDrawerDrawer.m` Zeilen 57, 128, 146, 165, 182

**Empfehlung:** `waitForFinish` auf `NO` setzen oder `NSThread.isMainThread` prüfen:
```objc
if ([NSThread isMainThread]) {
    [centerProxy windowWillOpen];
    [centerProxy windowDidOpen];
} else {
    TiThreadPerformOnMainThread(^{
        [centerProxy windowWillOpen];
        [centerProxy windowDidOpen];
    }, NO);
}
```

### A3. `ENSURE_UI_THREAD` Makro — korrekte Verwendung

**Problem:** Alle Setter-Methoden verwenden `ENSURE_UI_THREAD` korrekt (z.B. Zeile 224: `ENSURE_UI_THREAD(setCenterWindow_, args)`). Das Makro aus `TiThreading.h` leitet auf den Main Thread weiter und kehrt zurück, wenn nicht bereits dort.

**Beobachtung:** Die Verwendung ist **korrekt** gemäß Titanium SDK Pattern.

### A4. `windowWillOpen`/`windowDidOpen` — Doppel-Feuern bei 3-Panel-Setup

**Problem:** In `DkNappDrawerDrawer.m` wird `windowWillOpen`/`windowDidOpen` zweimal gefeuert:
1. Einmal in `ControllerForViewProxy` (Zeilen 57–61) — für das Center-Window
2. Nochmal in der `controller`-Methode bei 3-Panel-Setup (Zeilen 128–131)

**Betroffen:** Zeilen 128–131, 146–148, 165–167, 182–184

**Empfehlung:** Die zweiten Feuers in den `if`-Blöcken entfernen, da `ControllerForViewProxy` sie bereits feuert. Oder: `ControllerForViewProxy` das Feuern unterdrücken und nur an zentraler Stelle feuern.

### A5. `reposition` fehlt

**Problem:** `DkNappDrawerDrawerProxy.windowDidOpen` (Zeile 18) ruft `[self reposition]` auf. `TiUIWindowProxy` hat keine `reposition`-Methode — sie kommt von `TiViewProxy`. Das funktioniert, ist aber nicht dokumentiert.

**Bewertung:** Funktioniert, da `TiUIWindowProxy` von `TiViewProxy` erbt.

---

## B. Veraltete APIs & Deprecations

### B1. `UIApplicationDidChangeStatusBarOrientationNotification`

**Problem:** Die Notification ist seit iOS 13 veraltet.

**Betroffen:** `DkNappDrawerDrawer.m` Zeilen 268–275

```objc
[[NSNotificationCenter defaultCenter] addObserver:self
                                         selector:@selector(orientationDidChange:)
                                             name:UIApplicationDidChangeStatusBarOrientationNotification
                                           object:nil];
```

**Empfehlung:** Auf `viewWillTransitionToSize:withTransitionCoordinator:` umstellen:
```objc
- (void)viewWillTransition(toSize size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    [super viewWillTransition(toSize: size, with: coordinator)];
    [coordinator animate(alongside: { [self updateOrientation]; }, completion: nil)];
}
```

### B2. `setStatusBarStyle:` und `setStatusBarHidden:withAnimation:`

**Problem:** Beide sind seit iOS 13 veraltet.

**Betroffen:** `DkNappDrawerModule.m` Zeilen 63–78

**Empfehlung:** Abwärtskompatible Implementierung:
```objc
- (void)setStatusBarStyle:(id)args {
    ENSURE_UI_THREAD(setStatusBarStyle, args);
    UIStatusBarStyle style = (UIStatusBarStyle)[[args class] isEqual:[NSNumber numberWithInt:0].class] ? [args intValue] : [[args stringValue] intValue];
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000
    UIWindowScene *scene = UIApplication.sharedApplication.connectedScenes.firstObject;
    if (scene) {
        scene.statusBarManager?.desiredStatusBarStyle = style;
    }
#else
    [[UIApplication sharedApplication] setStatusBarStyle:style];
#endif
}
```

### B3. `class` description String-Vergleich für Typ-Prüfung

**Problem:** `DkNappDrawerDrawer.m` Zeilen 91, 114, 149, 228, 266:
```objc
if ([[[[self.proxy valueForUndefinedKey:@"centerWindow"] class] description] isEqualToString:@"TiUINavigationWindowProxy"]) {
```

**Empfehlung:** `isKindOfClass:` verwenden:
```objc
if ([centerWindowProxy isKindOfClass:[TiUINavigationWindowProxy class]]) {
```

### B4. `preferredStatusBarStyle` über Navigation Bar

**Problem:** `DkNappDrawerDrawer.m` Zeilen 320–322:
```objc
controller.navigationController.navigationBar.barStyle = [style intValue];
```
Das setzt die `barStyle` der Navigation Bar, nicht den `UIStatusBarStyle`. `barStyle` und `statusBarStyle` sind unterschiedlich.

**Empfehlung:** `preferredStatusBarStyle` des `CustomMMDrawerController` verwenden oder `UIViewController.preferredStatusBarUpdateAnimation` nutzen.

---

## C. Code-Qualität & Modernisierung

### C1. `navProxy` ivar nicht initialisiert

**Problem:** `DkNappDrawerDrawer.h`:
```objc
TiUINavigationWindowProxy *navProxy;
```

**Empfehlung:**
```objc
TiUINavigationWindowProxy *navProxy = nil;
```

### C2. `setAnimationMode_:` — missing break bei Case 100

**Problem:** `DkNappDrawerDrawer.m` Zeilen 340–359:
```objc
case 100:
    [controller setDrawerVisualStateBlock:[NappDrawerVisualState noneVisualStateBlock]];
    // FEHLT: break;
default:
    [controller setDrawerVisualStateBlock:[NappDrawerVisualState noneVisualStateBlock]];
    break;
```
Funktioniert korrekt (beide tun dasselbe), aber `break` fehlt.

**Empfehlung:** `break` hinzufügen oder Case 100 und default zusammenlegen.

### C3. `setBackGroundColor:` — inkonsistente Signatur

**Problem:** `DkNappDrawerDrawerProxy.m` Zeilen 90–97:
```objc
- (NSNumber *)setBackGroundColor:(id)args {
    [(DkNappDrawerDrawer *)[self view] setBackgroundColor:...];
}
// Kein return-Wert, Return-Typ NSNumber
```

**Empfehlung:** Return-Typ auf `void` ändern:
```objc
- (void)setBackGroundColor:(id)args { ... }
```

### C4. Redundante Visual State Methoden

**Problem:** `NappDrawerVisualState.m` hat 6 fast identische Methoden. Das bundled `MMDrawerController/MMDrawerController/MMDrawerVisualState.m` hat bereits eine generische `parallaxVisualStateBlockWithParallaxFactor:` Methode.

**Empfehlung:** `NappDrawerVisualState` vereinfachen:
```objc
@implementation NappDrawerVisualState

+ (MMDrawerControllerDrawerVisualStateBlock)slideAndScaleVisualStateBlock {
    // ... wie bisher
}

+ (MMDrawerControllerDrawerVisualStateBlock)slideVisualStateBlock {
    return [MMDrawerVisualState slideVisualStateBlock]; // aus bundled MMDrawerController
}

+ (MMDrawerControllerDrawerVisualStateBlock)parallax3VisualStateBlock {
    return [MMDrawerVisualState parallaxVisualStateBlockWithParallaxFactor:3.0];
}

+ (MMDrawerControllerDrawerVisualStateBlock)parallax5VisualStateBlock {
    return [MMDrawerVisualState parallaxVisualStateBlockWithParallaxFactor:5.0];
}

+ (MMDrawerControllerDrawerVisualStateBlock)parallax7VisualStateBlock {
    return [MMDrawerVisualState parallaxVisualStateBlockWithParallaxFactor:7.0];
}

+ (MMDrawerControllerDrawerVisualStateBlock)noneVisualStateBlock {
    return [MMDrawerVisualState noneVisualStateBlock];
}

+ (MMDrawerControllerDrawerVisualStateBlock)fadeVisualStateBlock {
    return [MMDrawerVisualState fadeVisualStateBlock];
}

@end
```

### C5. `_accessibleElements` Thread-Safety

**Problem:** `DkNappDrawerDrawer.m` Zeilen 41–51:
```objc
- (NSArray *)accessibleElements {
    if (_accessibleElements != nil) {
        [_accessibleElements removeAllObjects];
    } else {
        _accessibleElements = [[NSMutableArray alloc] init];
    }
    // ...
}
```
`_accessibleElements` wird ohne Synchronisation modifiziert.

**Empfehlung:** Mit `@synchronized` oder `dispatch_barrier_sync` schützen.

---

## D. Architektur & Lifecycle

### D1. `controller` lazy init — kein `dispatch_once`

**Problem:** `DkNappDrawerDrawer.m` Zeilen 87–265: Die `controller` Property lazy-init ohne `dispatch_once`. Bei parallelem Zugriff könnte `controller` mehrfach initialisiert werden.

**Empfehlung:**
```objc
- (MMDrawerController *)controller {
    static MMDrawerController *_controller = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _controller = // ... init code ...
    });
    return _controller;
}
```

### D2. `windowAppearanceCallback` retain cycle

**Problem:** `DkNappDrawerDrawer.m` Zeilen 240–254:
```objc
[controller setWindowAppearanceCallback:^(NSString *state) {
    __typeof__(self) weakSelf = self;
    // ... uses strongSelf ...
}];
```
Der Block verwendet `weakSelf`/`strongSelf` Pattern — das ist **korrekt**.

**Aber:** Der Block wird nie auf nil gesetzt, wenn der Drawer geschlossen wird.

**Empfehlung:** In `windowWillClose`-ähnlichem Kontext den Callback auf nil setzen.

### D3. Orientation-Handler — frame-basiert statt Auto Layout

**Problem:** `DkNappDrawerDrawer.m` Zeilen 269–278:
```objc
bar.frame = CGRectMake(0, 0, self.controller.view.bounds.size.width, 64);
```
Manuelles Frame-Seting funktioniert nicht bei Dynamic Type, Notch, iPad Split View.

**Empfehlung:** Auto Layout Constraints oder `viewWillTransitionToSize:withTransitionCoordinator:`.

### D4. `CustomMMDrawerController` — Block-Typ Definition

**Problem:** `CustomMMDrawerController.h`:
```objc
typedef void windowAppearanceChange;  // FEHLT ^ und Parameter
```
Die Typ-Definition ist unvollständig.

**Empfehlung:**
```objc
typedef void (^WindowAppearanceChangeBlock)(NSString *state);
```

### D5. `addChildViewController:` ohne `didAddViewController`

**Problem:** `DkNappDrawerDrawer.m` Zeilen 260–262:
```objc
[TiApp.controller.topPresentedController addChildViewController:controller];
```
Es fehlt `[controller didMoveToParentViewController:]` nach `addChildViewController:`.

**Empfehlung:**
```objc
[TiApp.controller.topPresentedController addChildViewController:controller];
[controller didMoveToParentViewController:TiApp.controller.topPresentedController];
```

---

## E. Build-Konfiguration

### E1. `module.xcconfig` — `$(USER)` vs `$(HOME)`

**Problem:** `ios/module.xcconfig`:
```
TITANIUM_SDK = /Users/$(USER)/Library/Application Support/Titanium/...
```
`$(USER)` funktioniert nur lokal, nicht in CI/CD.

**Empfehlung:**
```
TITANIUM_SDK = $(HOME)/Library/Application Support/Titanium/mobilesdk/osx/$(TITANIUM_SDK_VERSION)
```

### E2. iOS Deployment Target

**Problem:** `ios/manifest`:
```
minsdk: 13.2.0.GA
```
Das referenziert die Titanium SDK Version, nicht die iOS Deployment Target. Das Xcode-Projekt targetet iOS 12.0 (`-fobjc-runtime=ios-12.0.0` im Build-Output).

**Empfehlung:** iOS Deployment Target auf mindestens iOS 13 setzen (wegen veralteter Status Bar APIs ab iOS 13).

### E3. `archs` — `arm64 x86_64` für Simulator

**Problem:** `ios/manifest`:
```
architectures: arm64 x86_64
```
Xcode 15+ verwendet nur `arm64` für den iOS Simulator (Apple Silicon). `x86_64` ist noch enthalten für Intel-Macs.

**Empfehlung:** Beibehalten für Abwärtskompatibilität, aber dokumentieren.

### E4. Prefix Header `DkNappDrawer_Prefix.pch`

**Problem:** Der Prefix Header importiert nur `Foundation` und `UIKit`. Keine `Availability`-Defines.

**Empfehlung:**
```objc
#ifdef __OBJC__
    #import <Foundation/Foundation.h>
    #import <UIKit/UIKit.h>
#endif

#ifndef NS_DESIGNATED_INITIALIZER
#define NS_DESIGNATED_INITIALIZER
#endif
```

---

## F. MMDrawerController Bundle

### F1. MMDrawerVisualState — bereits modernisiert

**Beobachtung:** Das bundled `MMDrawerController/MMDrawerController/MMDrawerVisualState.m` wurde bereits modernisiert und verwendet eine generische `parallaxVisualStateBlockWithParallaxFactor:` Methode.

**Empfehlung:** `NappDrawerVisualState.m` (die NappDrawer-eigene Kopie) sollte die generische Methode des bundled MMDrawerController verwenden, um Redundanz zu vermeiden (siehe C4).

### F2. `bounceKeyFrameAnimationForDistanceOnView` — hardcodierte Faktoren

**Problem:** `MMDrawerController.m` Zeile 56:
```objc
CGFloat factors[32] = {0, 32, 60, 83, 100, 114, 124, 128, 128, 124, 114, 100, 83, 60, 32, 0, ...};
```
Hardcodierte Bounce-Faktoren.

**Bewertung:** Akzeptabel für ein bundled Third-Party-Library.

---

## G. Prioritäten

| # | Priorität | Issue | Datei | Aufwand | Impact |
|---|-----------|-------|-------|---------|--------|
| G1 | **P0** | `dispatch_once` für `controller` init | `DkNappDrawerDrawer.m` | Klein | Hoch (Thread-Safety) |
| G2 | **P0** | `isKindOfClass:` statt String-Vergleich | `DkNappDrawerDrawer.m` | Klein | Hoch (Korrektheit) |
| G3 | **P0** | `didMoveToParentViewController:` fehlt | `DkNappDrawerDrawer.m` | Klein | Hoch (UIViewController Lifecycle) |
| G4 | **P1** | `TiThreadPerformOnMainThread` deadlock Risiko | `DkNappDrawerDrawer.m` | Klein | Mittel |
| G5 | **P1** | `navProxy` init mit `= nil` | `DkNappDrawerDrawer.h` | Winzig | Niedrig |
| G6 | **P1** | `setAnimationMode_:` break hinzufügen | `DkNappDrawerDrawer.m` | Winzig | Niedrig |
| G7 | **P1** | `setBackGroundColor:` Return-Typ korrigieren | `DkNappDrawerDrawerProxy.m` | Winzig | Niedrig |
| G8 | **P1** | Visual State Redundanz beheben | `NappDrawerVisualState.m` | Mittel | Mittel (Wartbarkeit) |
| G9 | **P1** | Status Bar API Modernisierung | `DkNappDrawerModule.m` | Mittel | Mittel |
| G10 | **P2** | Orientation Handler modernisieren | `DkNappDrawerDrawer.m` | Mittel | Mittel |
| G11 | **P2** | `windowAppearanceCallback` auf nil setzen | `DkNappDrawerDrawer.m` | Klein | Mittel (Memory) |
| G12 | **P2** | `_accessibleElements` Thread-Safety | `DkNappDrawerDrawer.m` | Klein | Niedrig |
| G13 | **P2** | `windowWillOpen` Doppel-Feuern bereinigen | `DkNappDrawerDrawer.m` | Mittel | Mittel |
| G14 | **P2** | `windowAppearanceChange` Typ korrigieren | `CustomMMDrawerController.h` | Winzig | Niedrig |
| G15 | **P3** | `module.xcconfig` `$(HOME)` verwenden | `module.xcconfig` | Winzig | Niedrig |
| G16 | **P3** | iOS Deployment Target auf 13+ erhöhen | `manifest` | Winzig | Mittel |

---

## Zusammenfassung

**Kritisch (sofort fixen):**
1. `dispatch_once` für `controller` lazy init (D1)
2. `isKindOfClass:` für Typ-Prüfung (B3)
3. `didMoveToParentViewController:` nach `addChildViewController:` (D5)

**Wichtig (nächste Iteration):**
4. `TiThreadPerformOnMainThread` deadlock vermeiden (A2)
5. Visual State Redundanz beheben (C4)
6. Status Bar APIs modernisieren (B2)

**Schönheit (zeit permitting):**
7. `navProxy` initialisieren (C1)
8. `setAnimationMode_:` break (C2)
9. `setBackGroundColor:` Return-Typ (C3)
10. Orientation Handler modernisieren (D3)
