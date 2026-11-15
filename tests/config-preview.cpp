// Render the machine configuration selector in isolation for quick visual iteration.
#include "qt_amstradscene.hpp"
#include "qt_amstradmenu.hpp"
#include <QDir>
#include <cstdio>

class ConfigPreviewHost : public QWidget {
public:
    QImage cabinet;
    void paintEvent(QPaintEvent *) override {
        QPainter p(this); p.fillRect(rect(),amstrad::backgroundColor());
        amstrad::paintCabinet(p,cabinet,amstrad::sceneLayout(size()));
    }
};

int main(int argc, char **argv)
{
    QApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QApplication app(argc, argv);
    app.setFont(QFont("Segoe UI", 9));
    if (argc != 3) { std::fprintf(stderr, "Supply project root and output PNG\n"); return 1; }
    const QDir root(QString::fromLocal8Bit(argv[1]));
    const QImage art = amstrad::prepareCabinet(QImage(root.filePath("assets/front/pc1512-front.png")));
    const auto fittings = amstrad::loadFittings(root.filePath("assets/front/drives"),
        root.filePath("assets/front/badges"), root.filePath("assets/front/leds"));
    if (art.isNull() || !fittings.valid()) return 2;
    ConfigPreviewHost host; host.cabinet=art; host.resize(1500,900); host.show();
    QApplication::processEvents();
    static const char *const names[] = { "DD", "SD", "SD, factory sticker", "HD20" };
    static const char *const texts[] = { "Two 5¼\" floppy drives: A: and B:.",
        "One floppy drive, A:. Blank plate in the left bay.",
        "As SD, with the second-drive warning label on the plate.",
        "20 MB hard disk C: and one floppy drive, A:." };
    // One column as shipped, two with the PC1640 enabled.
    for (int machines = 1; machines <= 2; ++machines) {
        QMenu menu(&host);
        amstrad::stylePopupMenu(&menu);
        amstrad::addCaption(&menu, "Machine configuration",
            "Choose the computer and its drive layout. Hardware changes restart the PC.", 16);
        auto *grid = amstrad::addGrid(&menu, true);
        grid->setHorizontalSpacing(24); grid->setVerticalSpacing(0);
        for (int m = 0; m < machines; ++m) {
            grid->addWidget(new amstrad::MenuCaption(m ? "PC1640" : "PC1512",
                m ? "640K memory, EGA graphics" : "512K memory, CGA graphics", true, amstrad::ConfigChoice::Width, 16), 0, m);
            for (int bay = 0; bay < amstrad::LeftBayCount; ++bay) {
                amstrad::Front front; front.left = amstrad::LeftBay(bay); front.pc1640 = m;
                QImage unit = amstrad::composeCabinet(art, fittings, front);
                const QRectF c = amstrad::ConfigChoice::masterCrop();
                const qreal s = unit.width() / 1254.0;
                unit = unit.copy(QRectF(c.x()*s, c.y()*s, c.width()*s, c.height()*s).toAlignedRect().intersected(unit.rect()));
                grid->addWidget(new amstrad::ConfigChoice(amstrad::unitPicture(unit, host.devicePixelRatioF()),
                    QString(m ? "PC1640 " : "PC1512 ") + names[bay], QString::fromUtf8(texts[bay]),
                    m == 0 && bay == 1, [] {}), bay + 1, m);
            }
        }
        menu.ensurePolished(); menu.resize(menu.sizeHint());
        menu.move(host.mapToGlobal(QPoint(60,120)));
        menu.show(); QApplication::processEvents();
        QString out = QString::fromLocal8Bit(argv[2]);
        if (machines == 2) out.replace(".png", "-1640.png");
        if (!menu.grab().save(out)) return 3;
        std::printf("%s %dx%d\n", qPrintable(out), menu.width(), menu.height());
    }
    return 0;
}
