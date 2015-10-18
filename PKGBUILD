# Maintainer: Klemen Strnisa <klemen.strnisa@yahoo.com>

pkgname=odroid-xu-fanctl
pkgver=1.0.0
pkgrel=1
pkgdesc='Fan control helper scripts for Odroid XU3/XU4'
arch=('any')
url='https://github.com/kstrnisa/odroid-xu-fanctl'
license=('GPL3')
depends=('cpupower')
source=(${pkgname}-${pkgver}::https://github.com/kstrnisa/odroid-xu-fanctl/archive/v${pkgver}.zip)
sha512sums=(SKIP)

package(){
    cd ${pkgname}-${pkgver}
    install -D fanctl.sh "${pkgdir}/usr/bin/fanctl.sh"
    install -D fanmon.sh "${pkgdir}/usr/bin/fanmon.sh"
    install -D fanctl.service "${pkgdir}/usr/lib/systemd/system/fanctl.service"
}
