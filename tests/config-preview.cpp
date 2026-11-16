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
    // The real panel (addMachinePanel), once for each computer fitted.
    for (int machine = 0; machine < 2; ++machine) {
        QMenu menu(&host);
        amstrad::stylePopupMenu(&menu);
        amstrad::MachinePanel panel;
        panel.front.pc1640 = machine;
        panel.front.left = machine ? amstrad::BayHdd : amstrad::BayBlank;
        panel.unit = [&](const amstrad::Front &front) {
            QImage unit = amstrad::composeCabinet(art, fittings, front);
            const QRectF c = amstrad::ConfigChoice::masterCrop();
            const qreal s = unit.width() / 1254.0;
            unit = unit.copy(QRectF(c.x()*s, c.y()*s, c.width()*s, c.height()*s).toAlignedRect().intersected(unit.rect()));
            return amstrad::unitPicture(unit, host.devicePixelRatioF());
        };
        panel.choose = [](bool, int) {};
        amstrad::addMachinePanel(&menu, panel);
        menu.ensurePolished(); menu.resize(menu.sizeHint());
        menu.move(host.mapToGlobal(QPoint(60,20)));
        menu.show(); QApplication::processEvents();
        QString out = QString::fromLocal8Bit(argv[2]);
        if (machine) out.replace(".png", "-1640.png");
        if (!menu.grab().save(out)) return 3;
        std::printf("%s %dx%d\n", qPrintable(out), menu.width(), menu.height());
    }
    return 0;
}
