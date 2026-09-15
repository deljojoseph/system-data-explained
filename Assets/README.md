# App Icon

Edit this file in Icon Composer, then save it in place:

```text
Assets/system-data-explained.icon
```

Rebuild from the project directory:

```sh
./Scripts/build_local_app.sh
open ".build/app/System Data Explained.app"
```

The script uses Xcode's asset compiler to build the native Liquid Glass icon and its older-macOS fallback. It installs `Assets.car`, `system-data-explained.icns`, and Apple's generated icon metadata in the app bundle before signing it. Xcode 26 or later is required to compile the Icon Composer source; the app still supports macOS 14 or later.

`Icon-macOS-Default-1024x1024@1x.png` is a flattened preview for screenshots or marketing. It is not the runtime icon source. Keep the `.icon` directory and its `Assets` together in Git. Do not manually add another rounded mask, shadow, or resize the layered artwork for each device; Apple's compiler handles the platform renderings.

When a native Xcode application target is added, add the `.icon` file to that target and set **App Icon** to `system-data-explained`. Do not also define an app icon set with that same name. See [Apple's Icon Composer guide](https://developer.apple.com/documentation/xcode/creating-your-app-icon-using-icon-composer).
