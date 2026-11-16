// Render the actual selector in isolation for quick visual iteration.
#include "qt_amstradmonitor.hpp"
#include <QDir>
#include <QFile>
#include <cstdio>
#include <cstring>

class MonitorPreviewHost : public QWidget {
public:
    QImage cabinet;
    void paintEvent(QPaintEvent *) override {
        QPainter p(this); p.fillRect(rect(),amstrad::backgroundColor());
        amstrad::paintCabinet(p,cabinet,amstrad::sceneLayout(size()));
    }
};

int main(int argc, char **argv)
{
    QApplication app(argc, argv);
    app.setFont(QFont("Segoe UI", 9));
    if (argc != 4 && argc != 5) { std::fprintf(stderr, "Supply project root, font ROM and output PNG\n"); return 1; }
    const QDir root(QString::fromLocal8Bit(argv[1]));
    QFile rom(QString::fromLocal8Bit(argv[2]));
    if (!rom.open(QIODevice::ReadOnly)) return 2;
    const QByteArray bytes = rom.readAll();
    if (bytes.size() < 2048) return 3;
    uint8_t font[256][8]; std::memcpy(font, bytes.constData(), sizeof(font));
    const QImage sample = amstrad::monitorSample(font);
    // Fail if any source pixel escapes the selected four-colour CGA palette.
    for (int y = 0; y < sample.height(); ++y)
        for (int x = 0; x < sample.width(); ++x) {
            const QRgb c = sample.pixel(x,y);
            if (c != qRgb(0,0,0) && c != qRgb(85,255,255) && c != qRgb(255,85,255) && c != qRgb(255,255,255)) return 4;
        }
    // The swatches must be solid rectangles with complete square corners.
    for (int i = 0; i < 3; ++i) {
        const QRgb expected = i == 0 ? qRgb(85,255,255) : i == 1 ? qRgb(255,85,255) : qRgb(255,255,255);
        for (int y = 112; y < 152; ++y)
            for (int x = 24 + i * 96; x < 104 + i * 96; ++x)
                if (sample.pixel(x,y) != expected) return 7;
    }
    QImage art(root.filePath("assets/front/pc1512-front.png"));
    art = amstrad::prepareCabinet(art);
    const auto fittings = amstrad::loadFittings(root.filePath("assets/front/drives"),
        root.filePath("assets/front/badges"), root.filePath("assets/front/leds"));
    if (art.isNull() || !fittings.valid()) return 5;
    QImage tiger(root.filePath("assets/front/monitor/gem-paint-tiger.png"));
    QImage house(root.filePath("assets/front/monitor/gem-house-original.png"));
    if (tiger.isNull() || house.isNull()) return 8;
    const QImage framedHouse = amstrad::gemPaintHouse(tiger, house, font);
    const QImage originalFrame = tiger.convertToFormat(QImage::Format_RGB32);
    framedHouse.save(root.filePath("local/monitor-preview/house-screen.png"));
    // Chrome is preserved; only the canvas and document title may change.
    if (framedHouse.copy(QRect(0,44,111,320)) != originalFrame.copy(QRect(0,44,111,320)) ||
        framedHouse.copy(QRect(496,44,143,320)) != originalFrame.copy(QRect(496,44,143,320))) return 9;
    if (framedHouse.copy(QRect(25,24,580,18)) == originalFrame.copy(QRect(25,24,580,18))) return 10;
    MonitorPreviewHost host; host.cabinet=art; host.resize(1100,850); host.show();
    QApplication::processEvents();
    QMenu menu(&host);
    auto *row = amstrad::addMonitorSelector(&menu);
    for (bool mono : { false, true }) {
        amstrad::Front front; front.mono = mono;
        row->addWidget(new amstrad::MonitorChoice(amstrad::monitorPhotograph(amstrad::composeCabinet(art, fittings, front), mono ? tiger : framedHouse, mono),
            mono, !mono, [] {}));
    }
    menu.ensurePolished(); menu.resize(menu.sizeHint());
    menu.move(host.mapToGlobal(QPoint(180,180)));
    menu.show(); QApplication::processEvents();
    bool saved = menu.grab().save(QString::fromLocal8Bit(argv[3]));
    if (argc == 5) {
        // The PC1640's three monitors, from its own video ROM's 8x14 font.
        QFile rom1640(QString::fromLocal8Bit(argv[4]));
        if (!rom1640.open(QIODevice::ReadOnly)) return 11;
        const auto font8 = amstrad::screenFont8(font), font14 = amstrad::screenFont14(rom1640.readAll());
        if (!font14.valid()) return 12;
        menu.hide();
        QMenu menu1640(&host);
        auto *row1640 = amstrad::addMonitorSelector(&menu1640);
        row1640->setSpacing(12);
        static const char *const names[] = { "PC-MD", "PC-CD", "PC-ECD" };
        static const char *const details[] = { "Monochrome, 350 lines", "Colour, 200 lines", "Enhanced colour, 350 lines" };
        const QString folder = QFileInfo(QString::fromLocal8Bit(argv[3])).path();
        for (int s = 0; s < amstrad::Screen1640Count; ++s) {
            amstrad::Front front; front.pc1640 = true; front.screen = amstrad::Screen1640(s);
            const QImage sample = amstrad::screenSample1640(front.screen, font8, font14);
            sample.save(folder + QString("/screen-%1.png").arg(names[s]));
            const bool md = s == amstrad::ScreenMD, cd = s == amstrad::ScreenCD;
            if (sample.size() != QSize(md ? 720 : 640, cd ? 200 : 350)) return 13;
            row1640->addWidget(new amstrad::MonitorChoice(
                amstrad::monitorPhotograph(amstrad::composeCabinet(art, fittings, front), sample, false, true),
                names[s], details[s], names[s], s == amstrad::ScreenECD, [] {},
                amstrad::screenLens(cd ? font8 : font14, md ? 9 : 8, md ? qRgb(0xff,0xfd,0xed) : qRgb(255,255,255), 192), 264));
        }
        menu1640.ensurePolished(); menu1640.resize(menu1640.sizeHint());
        menu1640.move(host.mapToGlobal(QPoint(120,180)));
        menu1640.show(); QApplication::processEvents();
        saved = menu1640.grab().save(folder + "/monitor-1640.png") && saved;
    }
    std::puts(saved ? "PASS: original disk house in colour, supplied tiger in monochrome; fallback palette and square corners checked." : "FAIL: could not save preview.");
    return saved ? 0 : 6;
}
