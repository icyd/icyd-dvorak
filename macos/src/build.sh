#!/bin/sh
set -e -x
LAYOUT="Icyd Dvorak"
LANGUAGE=es
VERSION=1.0
COPYRIGHT="Copyright 1997--2017 (c) Roland Kaufmann"

# copy files from where this script is located
pushd $(dirname $0)
SRC_DIR="$(pwd)"
popd

# create a fakeroot directory and path therein
ROOT_DIR="$LAYOUT.tmp"
rm -rf "$ROOT_DIR"
mkdir -p "$ROOT_DIR/Library/Keyboard Layouts"
pushd "$ROOT_DIR/Library/Keyboard Layouts"

# Recipe by jagboy
# <http://hints.macworld.com/comment.php?mode=view&cid=60218>
mkdir "$LAYOUT.bundle"
mkdir "$LAYOUT.bundle/Contents"

# Text Input Source Services keys by Jordan Rose
# <http://belkadan.com/blog/2012/04/Keyboard-Adventures/>
# see bottom of HIToolbox.framework/.../TextInputSources.h
cat >> "$LAYOUT.bundle/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
<key>CFBundleIdentifier</key><string>com.apple.keyboardlayout.$LAYOUT</string>
<key>CFBundleName</key><string>$LAYOUT</string>
<key>CFBundleVersion</key><string>$VERSION</string>
<key>KLInfo_$LAYOUT</key>
  <dict>
  <key>TISInputSourceID</key><string>com.apple.keyboardlayout.$LAYOUT</string>
  <key>TISIntendedLanguage</key><string>$LANGUAGE</string>
  </dict>
</dict>
</plist>
EOF

cat >> "$LAYOUT.bundle/Contents/version.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
<key>BuildVersion</key><string>$VERSION</string>
<key>CFBundleVersion</key><string>$VERSION</string>
<key>ProjectName</key><string>$LAYOUT</string>
<key>SourceVersion</key><string>$VERSION</string>
</dict>
</plist>
EOF

mkdir "$LAYOUT.bundle/Contents/Resources"
cp "$SRC_DIR/$LAYOUT.keylayout" "$LAYOUT.bundle/Contents/Resources/"
# Install Keyboard Tools (needs Rosetta from Optional Installs) from:
# http://developer.apple.com/fonts/fonttools/AppleFontToolSuite3.1.0.dmg.zip
[ -x /usr/bin/klcompiler ] && /usr/bin/klcompiler "$SRC_DIR/$LAYOUT.keylayout" > /dev/null
if [ -e "$SRC_DIR/$LAYOUT.png" ]; then
  sips -s format icns "$SRC_DIR/$LAYOUT.png" --out "$LAYOUT.bundle/Contents/Resources/$LAYOUT.icns"
elif [ -e "$SRC_DIR/$LAYOUT.icns" ]; then
  cp "$SRC_DIR/$LAYOUT.icns" "$LAYOUT.bundle/Contents/Resources/";
fi

mkdir "$LAYOUT.bundle/Contents/Resources/Spanish.lproj"
cat >> "$LAYOUT.bundle/Contents/Resources/Spanish.lproj/InfoPlist.strings" <<EOF
NSHumanReadableCopyright = "$COPYRIGHT";
"$LAYOUT" = "$LAYOUT";
EOF

# try to figure out where PackageMaker from the Auxiliary Tools is
if [ -d /Applications/Xcode.app/Contents/Applications/PackageMaker.app ]; then
  APPROOT=/Applications/Xcode.app/Contents/Applications
elif [ -d /Developer/Applications/Utilities/PackageMaker.app ]; then
  APPROOT=/Developer/Application/Utilities
elif [ -d /Volumes/Auxiliary\ Tools/PackageMaker.app ]; then
  APPROOT=/Volumes/Auxiliary\ Tools
else
  APPROOT=/Applications
fi

# bundle bit must be set on the directory for it to be recognized as a bundle
/usr/bin/SetFile -a B "$LAYOUT.bundle"

# leave fakeroot
popd

# create a package
# <http://www.manpagez.com/man/1/packagemaker/>
"${APPROOT}/PackageMaker.app/Contents/MacOS/PackageMaker" \
  -v \
  -k \
  -r "$ROOT_DIR" \
  -f "$ROOT_DIR/Library/Keyboard Layouts/$LAYOUT.bundle/Contents/Info.plist" \
  -o "$LAYOUT v$VERSION.pkg" \
  -n "$VERSION" \
  -t "$LAYOUT" \
  -x \\.DS_Store \
  -g 10.3 \
  -h system \

# final files that are uploaded should be without spaces
TRANSLATED=$(echo "$LAYOUT" | sed 's/\ //g')-$(echo "$VERSION" | sed 's/\./_/g')
rm -rf "$TRANSLATED.pkg.zip"
rm -rf "$TRANSLATED.src.zip"

# create a packed file from the directory (use -k for .zip)
ditto -c -k --noacl --sequesterRsrc --keepParent "$LAYOUT v$VERSION.pkg" "$TRANSLATED.pkg.zip"

#hdiutil create --srcfolder "$LAYOUT v$VERSION.pkg" -format UDZO -volname "$LAYOUT v$VERSION" -o "$TRANSLATED.dmg"

# create source distribution
rm -rf "$LAYOUT.src"
mkdir "$LAYOUT.src"
cp "$SRC_DIR/$LAYOUT.keylayout" "$LAYOUT.src"
cp "$SRC_DIR/build.sh" "$LAYOUT.src"
ditto -c -k --noacl --sequesterRsrc "$LAYOUT.src" "$TRANSLATED.src.zip"

# sudo installer -pkg "$LAYOUT v$VERSION.pkg" -target /
# lsbom -fls "/var/db/receipts/com.apple.keylayout.$LAYOUT.bom"

# uninstall:
# sudo rm -rf "/Library/Keyboard Layouts/$LAYOUT.bundle/"
# sudo pkgutil --forget com.apple.keylayout.$LAYOUT
# sudo rm /System/Library/Caches/com.apple.IntlDataCache.le*
# rm /private/var/folders/*/*/-Caches-/com.apple.IntlDataCache.le*
# sudo shutdown -r now
