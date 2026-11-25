"""flutter create sonrası Android ayarlarını otomatik yapar:
- core library desugaring (flutter_local_notifications için)
- bildirim / internet / açılışta alarm izinleri ve alıcılar
- release derlemede bildirim sınıflarının küçültülmemesi (proguard)
- uygulama adı "Green Life"
"""
import pathlib
import re
import shutil
import sys

root = pathlib.Path("android/app")
kts = root / "build.gradle.kts"
groovy = root / "build.gradle"
manifest = root / "src/main/AndroidManifest.xml"

DESUGAR = "com.android.tools:desugar_jdk_libs:2.1.4"


SIGN_GROOVY = """    signingConfigs {
        debug {
            storeFile file('greenlife-test.keystore')
            storePassword 'android'
            keyAlias 'androiddebugkey'
            keyPassword 'android'
        }
    }

    buildTypes {"""

SIGN_KTS = """    signingConfigs {
        getByName("debug") {
            storeFile = file("greenlife-test.keystore")
            storePassword = "android"
            keyAlias = "androiddebugkey"
            keyPassword = "android"
        }
    }

    buildTypes {"""


def patch_signing(p, s):
    """Sabit test anahtarı: her derlemede aynı SHA-1 (Google girişi için gerekli)."""
    shutil.copy("tool/debug.keystore", root / "greenlife-test.keystore")
    if "greenlife-test.keystore" in s:
        return s
    sign = SIGN_KTS if p.suffix == ".kts" else SIGN_GROOVY
    if "buildTypes {" not in s:
        sys.exit("buildTypes bulunamadı")
    return s.replace("    buildTypes {", sign, 1)


def patch_gradle():
    if kts.exists():
        p, s = kts, kts.read_text()
        if "isCoreLibraryDesugaringEnabled" not in s:
            s = re.sub(r"compileOptions\s*\{", "compileOptions {\n        isCoreLibraryDesugaringEnabled = true", s, count=1)
            s = re.sub(
                r'(signingConfig\s*=\s*signingConfigs\.getByName\("debug"\))',
                r'\1\n            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")',
                s,
                count=1,
            )
            s += f'\ndependencies {{\n    coreLibraryDesugaring("{DESUGAR}")\n}}\n'
    elif groovy.exists():
        p, s = groovy, groovy.read_text()
        if "coreLibraryDesugaringEnabled" not in s:
            s = re.sub(r"compileOptions\s*\{", "compileOptions {\n        coreLibraryDesugaringEnabled true", s, count=1)
            s = re.sub(
                r"(signingConfig\s*=?\s*signingConfigs\.debug)",
                r"\1\n            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'",
                s,
                count=1,
            )
            s += f"\ndependencies {{\n    coreLibraryDesugaring '{DESUGAR}'\n}}\n"
    else:
        sys.exit("build.gradle bulunamadı")
    if "desugaring" not in s.lower():
        sys.exit("desugaring eklenemedi")
    s = patch_signing(p, s)
    p.write_text(s)
    print("gradle düzenlendi:", p)


def patch_manifest():
    s = manifest.read_text()
    perms = (
        '\n    <uses-permission android:name="android.permission.INTERNET"/>'
        '\n    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>'
        '\n    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>'
    )
    if "POST_NOTIFICATIONS" not in s:
        s = re.sub(r"(<manifest[^>]*>)", r"\1" + perms, s, count=1)
    receivers = """
        <receiver android:exported="false"
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:exported="false"
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
            </intent-filter>
        </receiver>
    """
    if "ScheduledNotificationReceiver" not in s:
        s = s.replace("</application>", receivers + "</application>", 1)
    s = s.replace('android:label="green_life"', 'android:label="Green Life"')
    manifest.write_text(s)
    print("manifest düzenlendi")


def write_proguard():
    (root / "proguard-rules.pro").write_text(
        "-keep class com.dexterous.** { *; }\n"
        "-keep class com.google.gson.** { *; }\n"
        "-keepattributes Signature\n"
        "-keepattributes *Annotation*\n"
        "-dontwarn com.google.android.play.core.**\n"
    )


patch_gradle()
patch_manifest()
write_proguard()
