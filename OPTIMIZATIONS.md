# NappDrawer — Optimierungsplan

Erstellt: 2026-05-22
Basis: Titanium SDK 13.2.0.GA | Xcode 26.2 (iOS 26.2 SDK) | Android SDK 23

---

## 1. iOS — Veraltete APIs & Deprecations

### 1.1 Status Bar APIs (iOS 13+)

**Problem:** `setStatusBarHidden:withAnimation:` und `setStatusBarStyle:` sind seit iOS 13 veraltet. Die Module verwenden noch die alte `UIApplication`-basierte API.

**Betroffen:** `DkNappDrawerModule.m` Zeilen 63–78

**Empfehlung:**
- `hideStatusBar:` / `showStatusBar:` beibehalten für Abwärtskompatibilität, aber mit `#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000` eine moderne Implementierung über `UIWindowScene`-`statusBarManager` hinzufügen
- `setStatusBarStyle:` in der Drawer-Implementierung über `preferredStatusBarStyle` des ViewControllers auflösen (bereits teilweise vorhanden in `DkNappDrawerDrawer.m`)

### 1.2 `UIApplicationDidChangeStatusBarOrientationNotification`

**Problem:** Die Notification `UIApplicationDidChangeStatusBarOrientationNotification` ist seit iOS 13 veraltet.

**Betroffen:** `DkNappDrawerDrawer.m` Zeilen 270–275

**Empfehlung:**
- Auf `viewWillTransitionToSize:withTransitionCoordinator:` umstellen
- Oder: `UIViewController.viewWillTransition(toSize:with:)` für Orientation-Changes nutzen

### 1.3 `class` description Vergleich

**Problem:** In `DkNappDrawerDrawer.m` wird der Typ über `[[proxy class] description]` String-Vergleich geprüft (`@"TiUINavigationWindowProxy"`). Das ist fragil.

**Betroffen:** `DkNappDrawerDrawer.m` Zeilen 91, 114, 149, 228, 266

**Empfehlung:**
- `isKindOfClass:` verwenden statt String-Vergleich:
  ```objc
  if ([proxy isKindOfClass:[TiUINavigationWindowProxy class]]) {
  ```

### 1.4 `valueForUndefinedKey:` Missbrauch

**Problem:** `valueForUndefinedKey:` wird verwendet, um Properties lesend zu accessen (Zeilen 90, 99, 107, etc.). Das ist ein Hack für das Titanium Proxy-System, aber untypisiert und fehleranfällig.

**Empfehlung:**
- `getProperty:` oder `valueForProperty:` verwenden, falls in der Titanium SDK Version verfügbar
- Alternativ: `valueForUndefinedKey:` beibehalten, aber mit Typcast und nil-Check dokumentieren

### 1.5 `navProxy` ivar nicht initialisiert

**Problem:** Die ivar `navProxy` in `DkNappDrawerDrawer.h` ist nicht mit `= nil` initialisiert.

**Betroffen:** `DkNappDrawerDrawer.h`

**Empfehlung:**
```objc
TiUINavigationWindowProxy *navProxy = nil;
```

---

## 2. iOS — Code-Qualität & Modernisierung

### 2.1 Nullability Annotations

**Problem:** Die Header-Dateien enthalten keine Nullability-Annotations (`_Nullable`, `_Nonnull`).

**Betroffen:** `DkNappDrawerDrawer.h`, `DkNappDrawerDrawerProxy.h`, `DkNappDrawerModule.h`

**Empfehlung:** Nullability hinzufügen:
```objc
- (void)setCenterWindow_:(id _Nonnull)args;
- (void)setLeftWindow_:(id _Nullable)args;
```

### 2.2 `instancetype` statt `id`

**Problem:** `newView` in `DkNappDrawerDrawerProxy.m` gibt `id` zurück.

**Empfehlung:**
```objc
- (instancetype)newView {
    return [[DkNappDrawerDrawer alloc] init];
}
```

### 2.3 Redundanter Code in Visual States

**Problem:** `NappDrawerVisualState.m` hat 6 fast identische Methoden (`slideAndScale`, `slide`, `parallax3`, `parallax5`, `parallax7`), die sich nur in `parallaxFactor` und `minScale` unterscheiden.

**Empfehlung:** Eine generische Factory-Methode:
```objc
+ (MMDrawerControllerDrawerVisualStateBlock)visualStateBlockWithParallaxFactor:(CGFloat)factor minScale:(CGFloat)minScale;
```

### 2.4 `setAnimationMode_:` — switch/case ohne break

**Problem:** Case 100 (`ANIMATION_NONE`) hat kein `break`, fällt durch zu default.

**Betroffen:** `DkNappDrawerDrawer.m` Zeilen 340–359

**Empfehlung:** `break` nach Case 100 hinzufügen oder `default` in einen separaten `if` auslagern.

### 2.5 `setBackGroundColor:` — kein Return-Wert

**Problem:** `DkNappDrawerDrawerProxy.m` Zeile 90–97: Methode heißt `setBackGroundColor:` (Großschreibung), hat `NSNumber` Return-Typ, gibt aber keinen Wert zurück.

**Empfehlung:** Entweder `-(void)` Return-Typ oder korrekten Return-Wert liefern.

---

## 3. iOS — Architektur & Lifecycle

### 3.1 `controller` lazy init — Thread-Safety

**Problem:** Die `controller` Property in `DkNappDrawerDrawer.m` verwendet lazy initialization ohne Lock/Synchronization. Bei parallelem Zugriff könnte `controller` mehrfach initialisiert werden.

**Empfehlung:** `dispatch_once` für die Initialisierung verwenden:
```objc
static dispatch_once_t onceToken;
dispatch_once(&onceToken, ^{
    // init controller
});
```

### 3.2 `windowWillOpen`/`windowDidOpen` Doppel-Feuern

**Problem:** In `ControllerForViewProxy` werden `windowWillOpen` und `windowDidOpen` gefeuert. Zusätzlich werden sie in der `controller`-Methode bei 3-Panel-Setup nochmal gefeuert (Zeilen 130-132).

**Empfehlung:** Prüfen, ob das beabsichtigt ist. Falls nicht, nur einmal feuern.

### 3.3 Orientation-Handler frame-basiert

**Problem:** `orientationDidChange:` setzt die NavigationBar frame manuell auf `CGRectMake(0, 0, width, 64)`. Das funktioniert nicht bei Dynamic Type, Notch, oder iPad Split View.

**Empfehlung:** Auto Layout Constraints oder `viewWillTransitionToSize:withTransitionCoordinator:` verwenden.

### 3.4 `CustomMMDrawerController` — `windowAppearanceCallback` Block nicht nil-ed

**Problem:** Der Block wird gesetzt, aber nie auf nil gesetzt, wenn der Drawer geschlossen wird. Kann zu retain cycles führen.

**Empfehlung:** Block in `windowWillClose`/`handleClose` auf nil setzen oder `weak` Referenz im Block verwenden (bereits teilweise mit `weakSelf` gemacht).

---

## 4. Android — Veraltete APIs & Target SDK

### 4.1 Target SDK veraltet

**Problem:** `android/manifest` hat `minsdk: 7.1.1` (API 23). Aktuelle Android-Entwicklung zielt auf API 34+.

**Empfehlung:**
- `minsdk` auf mindestens API 26 (Android 8.0) erhöhen
- `android.platform` in `build.properties` auf `android-34` aktualisieren
- `targetSdkVersion` im `timodule.xml` setzen

### 4.2 `TiActivity` statt `TiActivityWindow`

**Problem:** `DrawerProxy.handleOpen()` startet eine neue `TiActivity` über Intent. Das ist der alte Titanium 7.x/8.x Pattern. Neuere SDKs verwenden `TiActivityWindow` mit `TiActivityWindows.addWindow()`.

**Beobachtung:** `DrawerProxy` implementiert bereits `TiActivityWindow` und verwendet `TiActivityWindows.addWindow()` in `handleOpen()` — das ist korrekt.

### 4.3 `SlidingMenu` Library — kein AndroidX

**Problem:** Die bundled `SlidingMenu` Library (`com.slidingmenu.lib`) verwendet die alte Support Library, nicht AndroidX.

**Empfehlung:**
- Für kurzfristig: Beibehalten, da SlidingMenu stabil funktioniert
- Für langfristig: Migration zu `MaterialDrawer` (Mike Penz) oder `DrawerLayout` (AndroidX)

### 4.4 `SlidingMenu.SLIDING_WINDOW` veraltet

**Problem:** `SlidingMenu.SLIDING_WINDOW` ist deprecated. `SlidingMenu.SLIDING_CONTENT` sollte verwendet werden.

**Betroffen:** `Drawer.java` Zeile ~145

**Empfehlung:**
```java
slidingMenu.attachToActivity(activity, SlidingMenu.SLIDING_CONTENT);
```

---

## 5. Android — Code-Qualität

### 5.1 `leftMenuOffset` Typ-Inkonsistenz

**Problem:** `leftMenuOffset` ist `float`, aber in `onScrolled` wird `scroll` (int) durch `leftMenuWidth` (int) geteilt. Die Division erfolgt in int-Arithmetik.

**Betroffen:** `Drawer.java` Zeilen 183-186

**Empfehlung:**
```java
leftMenuOffset = (float) scroll / (float) leftMenuWidth;
```

### 5.2 `getRealRightViewWidth()` falsche Methode

**Problem:** `DrawerProxy.getRealRightViewWidth()` ruft `getBehindOffset()` auf, nicht `getRightBehindOffset()`.

**Betroffen:** `DrawerProxy.java` Zeilen 324-327

**Empfehlung:**
```java
public int getRealRightViewWidth() {
    return getSlidingMenu().getRightBehindOffset();
}
```

### 5.3 `getDevicePixels` nur für Strings

**Problem:** `Drawer.getDevicePixels()` verwendet `TiConvert.toTiDimension()`, wird aber auch mit numerischen Werten aufgerufen (in `propertyChanged`).

**Empfehlung:** Typ-Check vor `getDevicePixels`-Aufruf:
```java
if (value instanceof String) {
    leftMenuWidth = getDevicePixels(value);
} else {
    leftMenuWidth = TiConvert.toInt(value);
}
```

### 5.4 `Interpolator` Lambda statt anonymous class

**Problem:** Die `interp` Interpolator-Instanz ist eine anonyme Klasse.

**Empfehlung:** Modernere写法 (ab Java 8):
```java
private static final Interpolator interp = t -> {
    t -= 1.0f;
    return t * t * t + 1.0f;
};
```

---

## 6. Build-Konfiguration

### 6.1 iOS — `module.xcconfig` SDK-Pfad hartkodiert

**Problem:** `TITANIUM_SDK` verwendet `$(USER)` im Pfad, was in CI/CD-Umgebungen problematisch sein kann.

**Empfehlung:**
```
TITANIUM_SDK = $(HOME)/Library/Application Support/Titanium/mobilesdk/osx/$(TITANIUM_SDK_VERSION)
```

### 6.2 Android — Ant Build System

**Problem:** `android/build.xml` verwendet Ant, welches seit Jahren von Gradle abgelöst wurde.

**Empfehlung (langfristig):**
- Migration zu Gradle-basiertem Build
- `build.gradle` mit `com.android.library`
- Abhängigkeiten über Maven/Central statt bundled JAR

### 6.3 `package.json` — Versionen inkonsistent

**Problem:** `package.json` referenziert `dk.napp.drawer-iphone-2.0.0.zip` und `dk.napp.drawer-android-2.0.2.zip`, während die tatsächlichen Builds `3.1.0` (iOS) und `2.0.3` (Android) sind.

**Empfehlung:** `package.json` aktualisieren mit den korrekten Versionsnummern.

### 6.4 iOS — KitchenSink-Beispieldateien im Build

**Problem:** Die `MMDrawerController/KitchenSink/`-Verzeichnis-Dateien (`MMTableViewCell.m`, `MMExampleViewController.m`, etc.) werden im Xcode-Projekt mitgebaut, sind aber Beispielcode für die MMDrawerController-Demo.

**Empfehlung:** KitchenSink-Dateien aus dem NappDrawer Xcode-Projekt entfernen oder als separate Target-Dependency auslagern.

---

## 7. Module-Architektur

### 7.1 Event-System Inkonsistenz zwischen iOS und Android

**Problem:**
- iOS feuert `windowDidOpen` ohne `window`-Property
- Android feuert `windowDidOpen` MIT `window`-Property (`LEFT_WINDOW` oder `RIGHT_WINDOW`)
- iOS feuert `centerWindowDidFocus`/`centerWindowDidBlur`
- Android feuert `focus`/`blur`

**Empfehlung:** Event-Namen und Payloads zwischen Plattformen angleichen.

### 7.2 `autoCloseWindows` Property — Titanium-Intern

**Problem:** `autoCloseWindows` wird über `valueForUndefinedKey:` gelesen, ist aber keine offizielle Titanium-Property.

**Empfehlung:** Als explizite Module-Property definieren:
```objc
// iOS
@Kroll.getProperty / @Kroll.setProperty (oder legacy: -setAutoCloseWindows:)
```

### 7.3 Android — `releaseViews()` ist leer

**Problem:** `DrawerProxy.releaseViews()` ruft nur `super.releaseViews()` auf, ohne die SlidingMenu-Referenzen zu bereinigen.

**Empfehlung:**
```java
@Override
public void releaseViews() {
    super.releaseViews();
    slidingMenu = null;
    slideMenuActivity = null;
}
```

---

## 8. Dokumentation

### 8.1 README.md — veraltete Installationsmethoden

**Problem:** README erwähnt `gittio` (deprecated), keine Erwähnung von `ti module` CLI.

**Empfehlung:** Aktualisieren mit aktuellen Installationswegen.

### 8.2 iOS `README.md` — fehlende API-Dokumentation für neue Properties

**Problem:** Die iOS-Dokumentation (`ios/README.md`) dokumentiert nicht alle Properties und Methoden.

**Empfehlung:** Alle Properties, Methoden und Events dokumentieren, inklusive platform-spezifischer Unterschiede.

---

## Prioritäten

| Priorität | Bereich | Aufwand | Impact |
|-----------|---------|---------|--------|
| **P0** | Android `getRealRightViewWidth()` Bug | Klein | Hoch |
| **P0** | iOS `isKindOfClass:` statt String-Vergleich | Klein | Hoch |
| **P1** | Android Target SDK aktualisieren | Mittel | Hoch |
| **P1** | iOS `dispatch_once` für Thread-Safety | Klein | Mittel |
| **P1** | `autoCloseWindows` als offizielle Property | Klein | Mittel |
| **P1** | Event-Inkonsistenz iOS/Android angleichen | Mittel | Hoch |
| **P2** | Visual State Refactoring | Mittel | Niedrig |
| **P2** | AndroidX Migration | Groß | Mittel |
| **P2** | Gradle Build Migration | Groß | Mittel |
| **P3** | KitchenSink aus Build entfernen | Klein | Niedrig |
| **P3** | Nullability Annotations | Mittel | Niedrig |
