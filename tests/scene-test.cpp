// Standalone, offscreen verification of the same compositor used by the guest.
#include "qt_amstradscene.hpp"
#include <QCoreApplication>
#include <QDir>
#include <QFileInfo>
#include <cmath>
#include <cstdio>

int main(int argc, char **argv)
{
    QCoreApplication app(argc, argv);
    if (argc != 3) return 2;
    const QImage original(argv[1]);
    if (original.size() != QSize(1254, 1254)) return 3;
    const QString drivesDir = QFileInfo(argv[1]).absolutePath() + "/drives";
    const auto drives = amstrad::loadDrives(drivesDir);
    if (!drives.valid()) return 20;
    for (int d = 0; d < 2; ++d) {
        const QString prefix = drivesDir + "/drive-";
        const QImage mechanism(prefix + "closed-mechanism.png");
        const QImage disk(prefix + "closed-red.png");
        if (mechanism.isNull() || disk.isNull() ||
            qAlpha(disk.pixel(115, 30)) != 0 || qAlpha(disk.pixel(100, 60)) != 0) return 21;
        // The loader must retain the shared lever for every disk colour,
        // while disk-only files contain no repainted mechanism.
        for (int f = amstrad::DiskBlack; f < amstrad::DriveFaceCount; ++f)
            if (drives.face[d][f].pixel(115, 30) != mechanism.pixel(115, 30)) return 22;
        if (drives.face[d][amstrad::DiskRed].pixel(150, 60) ==
            drives.face[d][amstrad::DiskBlue].pixel(150, 60)) return 23;
        for (int y = 0; y < disk.height(); ++y)
            if (y < 57 || y > 64)
                for (int x = 0; x < disk.width(); ++x)
                    if (qAlpha(disk.pixel(x, y))) return 24;
    }
    if (qAlpha(original.pixel(0, 0)) != 0 || qAlpha(original.pixel(1253, 1253)) != 0 ||
        qAlpha(original.pixel(600, 400)) != 255) return 13;
    // Keep the dark outer sides and rounded bottoms of both feet. A cutoff
    // suitable for the bright case used to clip these shaded hardware pixels.
    for (auto foot : {QPoint(212, 1234), QPoint(1039, 1234),
                      QPoint(187, 1241), QPoint(1066, 1241)})
        if (qAlpha(original.pixel(foot)) != 255) return 15;
    const QImage art = amstrad::prepareCabinet(original);
    if (art.pixel(200, 100) != original.pixel(200, 100) ||
        qGray(art.pixel(330, 200)) >= qGray(original.pixel(330, 200)) / 2 ||
        qGray(art.pixel(600, 400)) < 10) return 9;
    QDir().mkpath(argv[2]);
    // Nonzero origin and padded pitch catch mistaken tightly packed copies.
    QImage frame(2048, 2048, QImage::Format_RGB32);
    frame.fill(0x00deadbe);
    const QRect src(13, 7, 640, 200);
    amstrad::testPattern(frame, src);
    if (frame.pixel(13, 7) != 0xffff0000 || frame.pixel(93, 7) != 0xff00ff00 ||
        frame.pixel(173, 7) != 0xff0000ff || frame.pixel(12, 7) != 0xffdeadbe) return 4;
    for (auto size : {QSize(1254, 1254), QSize(1600, 900), QSize(600, 900), QSize(1700, 1700)}) {
        const auto l = amstrad::sceneLayout(size);
        if (std::abs(l.video.width() / l.video.height() - 4.0/3.0) > 1e-6 ||
            !l.aperture.contains(l.video) || l.cabinet.width() != l.cabinet.height()) return 5;
        if (l.video.top() <= l.aperture.top() || l.video.bottom() >= l.aperture.bottom() ||
            l.video.left() <= l.aperture.left() || l.video.right() >= l.aperture.right()) return 8;
        QImage out(size, QImage::Format_RGB32);
        out.fill(amstrad::backgroundColor());
        QPainter p(&out);
        amstrad::paintCabinet(p, art, l);
        amstrad::paintVideo(p, frame, src, art, l, false);
        p.end();
        QImage off(size, QImage::Format_RGB32);
        off.fill(amstrad::backgroundColor());
        QPainter offPainter(&off);
        amstrad::paintCabinet(offPainter, art, l);
        offPainter.end();
        // Both the transparent master margin and extra wide/tall window area
        // must expose the same charcoal, with no square background seam.
        const QPoint margin(qRound(l.cabinet.left() + 5 * l.scale),
                            qRound(l.cabinet.top() + 5 * l.scale));
        if (out.pixel(0, 0) != amstrad::backgroundColor().rgba() ||
            out.pixel(margin) != amstrad::backgroundColor().rgba() ||
            off.pixel(margin) != amstrad::backgroundColor().rgba()) return 14;
        const QRgb colors[] = {0xffff0000, 0xff00ff00, 0xff0000ff, 0xffffffff};
        for (int i=0; i<4; ++i) {
            const QPoint point(qRound(l.video.x() + l.video.width() * (i + .5) / 8),
                               qRound(l.video.center().y()));
            const QColor base(off.pixel(point)), actual(out.pixel(point)), emitted(colors[i]);
            for (int channel = 0; channel < 3; ++channel) {
                const int background[] = {base.red(), base.green(), base.blue()};
                const int light[] = {emitted.red(), emitted.green(), emitted.blue()};
                const int measured[] = {actual.red(), actual.green(), actual.blue()};
                const int expected = qRound(.1 * background[channel] + .9 * std::min(255, background[channel] + light[channel]));
                if (std::abs(measured[channel] - expected) > 2) {
                    std::printf("blend %dx%d bar %d channel %d: base %d light %d actual %d\n", size.width(), size.height(), i, channel, background[channel], light[channel], measured[channel]);
                    return 6;
                }
            }
        }
        if (!out.save(QString("%1/pattern-%2x%3.png").arg(argv[2]).arg(size.width()).arg(size.height()))) return 7;
        // Repeated paints must not accumulate emission. Clearing a lit frame
        // back to black must restore the off glass, even with a clip (allow one
        // code value for Qt's clipped/scaled raster rounding).
        const QImage first = out.copy();
        QPainter again(&out);
        amstrad::paintVideo(again, frame, src, art, l, false);
        again.end();
        if (out != first) return 10;
        QImage black(src.size(), QImage::Format_RGB32);
        black.fill(Qt::black);
        QPainter clear(&out);
        clear.setClipRect(l.video);
        amstrad::paintVideo(clear, black, black.rect(), art, l, false);
        clear.end();
        if (out != off) {
            for (int y=0; y<size.height(); ++y) for (int x=0; x<size.width(); ++x)
                if (std::abs(qRed(out.pixel(x,y)) - qRed(off.pixel(x,y))) > 1 ||
                    std::abs(qGreen(out.pixel(x,y)) - qGreen(off.pixel(x,y))) > 1 ||
                    std::abs(qBlue(out.pixel(x,y)) - qBlue(off.pixel(x,y))) > 1) {
                    std::printf("erase %dx%d at %d,%d: %08x != %08x\n", size.width(), size.height(), x,y,out.pixel(x,y),off.pixel(x,y));
                    return 11;
                }
        }
        if (!off.save(QString("%1/off-%2x%3.png").arg(argv[2]).arg(size.width()).arg(size.height()))) return 12;
    }
    std::puts("PASS: transparent exterior and uniform charcoal at every size; glass retained under black, reflection reduced, no light accumulation, clipped erase, RGB channels, pitch, aspect and resize layouts");
    return 0;
}
