# Maintainer: Klemen Strnisa <klemen.strnisa@yahoo.com>

pkgname=odroid-xu-fanctl
pkgver=1.0.0
pkgrel=1
pkgdesc='Fan control helper scripts for Odroid XU3/XU4'
arch=('any')
url='https://github.com/kstrnisa/odroid-xu-fanctl'
license=('GPL3')
source=(${pkgname}-${pkgver}::https://github.com/kstrnisa/odroid-xu-fanctl/archive/v${pkgver}.zip)
sha512sums=(SKIP)

package(){
    cd ${pkgname}-${pkgver}
    mkdir -p "${pkgdir}/usr/bin/"
    cp fanctl.sh "${pkgdir}/usr/bin/"
    cp fanmon.sh "${pkgdir}/usr/bin/"
}
