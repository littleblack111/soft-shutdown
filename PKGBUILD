# Maintainer: littleblack111 <littleblack11111@gmail.com>
pkgname=soft-shutdown
pkgver=1.0
pkgrel=1
pkgdesc="Gracefully shutdown userspace GUI applications before system shutdown"
arch=('any')
url="http://example.com"
license=('GPL3')
depends=('wmctrl' 'xorg-xprop')
source=("close-userspace.sh" "shut-userspace.service")
sha256sums=('460ff968c7d504a43acb1205cf83de980ad599671ebb601d8db33b02ad675fc2' '96669484a37c6cd023e13438ea417b1206b378e87589616dc973a0656705d0f7')

package() {
    install -Dm755 "$srcdir/close-userspace.sh" "$pkgdir/usr/bin/close-userspace.sh"
    install -Dm644 "$srcdir/close-userspace.service" "$pkgdir/etc/systemd/system/close-userspace.service"
}

post_install() {
    echo "Enabling and starting the close-userspace service for the user..."
    systemctl --user enable close-userspace.service
    systemctl --user start close-userspace.service
}
