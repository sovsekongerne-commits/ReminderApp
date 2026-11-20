"""Tilpasser den genererede android/app/build.gradle(.kts) til appens plugins."""
import pathlib, re, sys
p = pathlib.Path('android/app/build.gradle.kts')
kts = p.exists()
if not kts:
    p = pathlib.Path('android/app/build.gradle')
t = p.read_text()
# permission_handler kræver compileSdk 37
t = re.sub(r'compileSdk\s*=\s*flutter\.compileSdkVersion', 'compileSdk = 37', t)
t = re.sub(r'compileSdkVersion\s+flutter\.compileSdkVersion', 'compileSdkVersion 37', t)
# flutter_local_notifications kræver minSdk 24 og desugaring
t = re.sub(r'minSdk\s*=\s*flutter\.minSdkVersion', 'minSdk = 24', t)
t = re.sub(r'minSdkVersion\s+flutter\.minSdkVersion', 'minSdkVersion 24', t)
if 'CoreLibraryDesugaring' not in t and 'coreLibraryDesugaringEnabled' not in t:
    if kts:
        t = t.replace('compileOptions {', 'compileOptions {\n        isCoreLibraryDesugaringEnabled = true', 1)
        t += '\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n}\n'
    else:
        t = t.replace('compileOptions {', 'compileOptions {\n        coreLibraryDesugaringEnabled true', 1)
        t += "\ndependencies {\n    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'\n}\n"
p.write_text(t)
print(t)
