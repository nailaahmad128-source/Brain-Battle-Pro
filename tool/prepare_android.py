"""Patches the freshly generated Flutter android/ folder (run from repo root).
Idempotent. Fails loudly if anything required for Play is not in place.

env: ADMOB_APP_ID   AdMob *app* id (ca-app-pub-...~...)
     REQUIRE_PROD   'true' for release builds: needs real AdMob app id + signing key
"""
import os, pathlib, re, sys

APP_ID_EXPECTED = 'com.midostudio.brainbattlepro'
TEST_APP_ID = 'ca-app-pub-3940256099942544~3347511713'  # Google's sample app id (CI test builds only)
SDK = 36      # compileSdk / targetSdk (Android 16)
MIN_SDK = 24  # Android 7.0+

def die(msg):
    print(f'::error::{msg}'); sys.exit(1)

prod = os.environ.get('REQUIRE_PROD', 'false').lower() == 'true'
app_id = os.environ.get('ADMOB_APP_ID', '').strip()
root = pathlib.Path('android')
has_key = (root / 'key.properties').exists()

if prod:
    if not re.fullmatch(r'ca-app-pub-\d{16}~\d{10}', app_id) or app_id == TEST_APP_ID:
        die('Release build needs a real ADMOB_APP_ID (format ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY).')
    if not has_key:
        die('Release build needs android/key.properties (signing secrets missing).')
else:
    app_id = app_id if re.fullmatch(r'ca-app-pub-\d{16}~\d{10}', app_id) else TEST_APP_ID

# ---- AndroidManifest ----
man = root / 'app/src/main/AndroidManifest.xml'
s = man.read_text()
s = re.sub(r'android:label="[^"]*"', 'android:label="Brain Battle Pro"', s, count=1)
app_attrs = ''
if 'android:allowBackup' not in s:
    app_attrs += ' android:allowBackup="false"'
if 'usesCleartextTraffic' not in s:
    app_attrs += ' android:usesCleartextTraffic="false"'
if app_attrs:
    s = s.replace('<application', '<application' + app_attrs, 1)
s = re.sub(r'(<meta-data android:name="com\.google\.android\.gms\.ads\.APPLICATION_ID"[^>]*/>)', '', s)
meta = f'\n        <meta-data android:name="com.google.android.gms.ads.APPLICATION_ID" android:value="{app_id}"/>'
s = re.sub(r'(<application[^>]*>)', lambda m: m.group(1) + meta, s, count=1)
if 'screenOrientation' not in s:
    s = s.replace('<activity', '<activity android:screenOrientation="portrait"', 1)
man.write_text(s)

# ---- Gradle (kts or groovy) ----
kts = root / 'app/build.gradle.kts'
g = kts if kts.exists() else root / 'app/build.gradle'
t = g.read_text()
t = re.sub(r'compileSdk(?:Version)?\s*=?\s*flutter\.compileSdkVersion', f'compileSdk = {SDK}', t)
t = re.sub(r'targetSdk(?:Version)?\s*=?\s*flutter\.targetSdkVersion', f'targetSdk = {SDK}', t)
t = re.sub(r'minSdk(?:Version)?\s*=?\s*flutter\.minSdkVersion', f'minSdk = {MIN_SDK}', t)

if has_key and 'keystoreProperties' not in t:
    if g == kts:
        t = 'import java.util.Properties\nimport java.io.FileInputStream\n\n' + t
        t = t.replace('android {', '''val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {''', 1)
        t = t.replace('buildTypes {', '''signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {''', 1)
        t = t.replace('signingConfigs.getByName("debug")', 'signingConfigs.getByName("release")')
    else:
        t = 'def keystoreProperties = new Properties()\ndef keystorePropertiesFile = rootProject.file("key.properties")\nif (keystorePropertiesFile.exists()) { keystoreProperties.load(new FileInputStream(keystorePropertiesFile)) }\n' + t
        t = t.replace('buildTypes {', '''signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }

    buildTypes {''', 1)
        t = t.replace('signingConfig signingConfigs.debug', 'signingConfig signingConfigs.release')
g.write_text(t)

# ---- verify (exact matches: a prefix match once let a wrong applicationId through) ----
checks = [(rf'compileSdk\s*=?\s*{SDK}\b', f'compileSdk {SDK}'),
          (rf'targetSdk\s*=?\s*{SDK}\b', f'targetSdk {SDK}'),
          (rf'minSdk\s*=?\s*{MIN_SDK}\b', f'minSdk {MIN_SDK}'),
          (rf'namespace\s*=?\s*["\']{re.escape(APP_ID_EXPECTED)}["\']', f'namespace == {APP_ID_EXPECTED}'),
          (rf'applicationId\s*=?\s*["\']{re.escape(APP_ID_EXPECTED)}["\']', f'applicationId == {APP_ID_EXPECTED}')]
for pat, what in checks:
    if not re.search(pat, t):
        die(f'{g} does not contain {what} after patching.')
pkg_dir = root / 'app/src/main' / 'kotlin' / pathlib.Path(*APP_ID_EXPECTED.split('.'))
java_dir = root / 'app/src/main' / 'java' / pathlib.Path(*APP_ID_EXPECTED.split('.'))
act = [f for d in (pkg_dir, java_dir) for f in (d / 'MainActivity.kt', d / 'MainActivity.java') if f.exists()]
if not act:
    die(f'MainActivity not found under {pkg_dir} - package/directory mismatch would crash at launch (ClassNotFoundException).')
if f'package {APP_ID_EXPECTED}' not in act[0].read_text():
    die(f'{act[0]} has the wrong package declaration.')
m = man.read_text()
if m.count('com.google.android.gms.ads.APPLICATION_ID') != 1 or 'android.intent.action.MAIN' not in m or 'android.intent.category.LAUNCHER' not in m:
    die('AndroidManifest is missing the launcher intent-filter or has a wrong AdMob APPLICATION_ID entry.')
if 'flutterEmbedding' not in m:
    die('AndroidManifest has no flutterEmbedding=2 meta-data.')
if prod and 'signingConfigs.getByName("release")' not in t and 'signingConfig signingConfigs.release' not in t:
    die('Release signing config was not applied to the release build type.')
print(f'android patched OK: {g.name} | id {APP_ID_EXPECTED} | MainActivity {act[0].name} | SDK {SDK}/min {MIN_SDK} | prod={prod} | signed={has_key}')
