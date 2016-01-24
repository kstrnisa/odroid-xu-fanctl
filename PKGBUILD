# Maintainer: Klemen Strnisa <klemen.strnisa@yahoo.com>

pkgname=odroid-xu-fanctl
pkgver=2.0.1
pkgrel=1
pkgdesc='Temperature control helper scripts for Odroid XU3/XU4'
arch=('any')
url='https://github.com/kstrnisa/odroid-xu-fanctl'
license=('GPL3')
depends=('cpupower')
source=(${pkgname}-${pkgver}::https://github.com/kstrnisa/odroid-xu-fanctl/archive/v${pkgver}.zip)
sha512sums=(SKIP)

package(){
    cd ${pkgname}-${pkgver}
    install -D fanctl "${pkgdir}/usr/bin/fanctl"
    install -D fanctl.service "${pkgdir}/usr/lib/systemd/system/fanctl.service"
}
