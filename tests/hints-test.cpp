// Cabinet control hints: the corner mark at rest and with the pointer on it,
// saved for visual review, plus its show/linger/hide behaviour.
#include "qt_amstradhints.hpp"
#include <QApplication>
#include <QEventLoop>
#include <QTemporaryDir>
#include <cstdio>
#include <stdexcept>

static void settle(int milliseconds)
{
    QEventLoop loop;
    QTimer::singleShot(milliseconds, &loop, &QEventLoop::quit);
    loop.exec();
}

static void require(bool condition, const char *message)
{
    if (!condition) throw std::runtime_error(message);
}

class SceneHost : public QWidget {
public:
    QImage cabinet;
    void paintEvent(QPaintEvent *) override
    {
        QPainter p(this);
        p.fillRect(rect(), amstrad::backgroundColor());
        amstrad::paintCabinet(p, cabinet, amstrad::sceneLayout(size()));
    }
};

static bool differs(const QImage &a, const QImage &b, const QRect &area)
{
    for (int y = area.top(); y <= area.bottom(); ++y)
        for (int x = area.left(); x <= area.right(); ++x)
            if (a.pixel(x, y) != b.pixel(x, y)) return true;
    return false;
}

int main(int argc, char **argv)
{
    qunsetenv("AMSTRAD_HINTS");
    qunsetenv("AMSTRAD_HEADLESS");
    QApplication app(argc, argv);
    try {
        require(argc == 3, "Supply the cabinet image and an output folder");
        const QString out = QString::fromLocal8Bit(argv[2]);
        SceneHost host;
        host.setFont(QFont("Segoe UI"));
        host.cabinet = amstrad::prepareCabinet(QImage(QString::fromLocal8Bit(argv[1])));
        require(!host.cabinet.isNull(), "Cabinet image missing");
        host.resize(1100, 950);
        const auto l = amstrad::sceneLayout(host.size());

        bool captured = false;
        int  shown = 0, dismissed = 0;
        amstrad::Front front;
        AmstradHints hints(&host);
        hints.blocked = [&] { return captured; };
        hints.front   = [&] { return front; };
        // The real power close-up, switched on and so hidden until asked for.
        QTemporaryDir folder;
        AmstradPowerPeek peek(&host, QFileInfo(QString::fromLocal8Bit(argv[1])).dir().filePath("power/rear-button-atlas.png"),
                              folder.filePath("amstrad.ini"));
        peek.powered = true;
        hints.showing = [&](bool on) {
            ++(on ? shown : dismissed);
            if (on) peek.reveal();
            else peek.dismissLater();
        };
        hints.powerArea = [&] { return peek.revealArea(); };
        host.show();
        hints.place();
        settle(50);
        require(hints.isVisible(), "Corner mark missing");
        require(host.rect().contains(hints.geometry()), "Corner mark outside the window");
        require(!hints.geometry().intersects(l.cabinet.toAlignedRect().adjusted(0, 0, -110 * l.scale, 0)),
                "Corner mark over the cabinet");
        require(!hints.areasVisible() && peek.isHidden(), "Parts shown without being asked");
        const QImage rest = host.grab().toImage();
        rest.save(out + "/hints-rest.png");

        QEvent enter(QEvent::Enter);
        QApplication::sendEvent(&hints, &enter);
        settle(260);
        require(hints.areasVisible() && shown == 1, "Parts not shown on hover");
        require(hints.overlay()->testAttribute(Qt::WA_TransparentForMouseEvents), "Overlay would take mouse input");
        const QImage over = host.grab().toImage();
        over.save(out + "/hints-shown.png");
        require(!differs(over, rest, l.video.toAlignedRect()), "The overlay reaches the screen");
        require(peek.isVisible(), "Power close-up not brought into view");
        const QRect power = peek.geometry();
        require(differs(over, rest, QRect(power.left() - 8, power.top(), 7, power.height())),
                "Power close-up not framed");
        for (int i = 0; i < amstrad::HintAreaCount; ++i)
            require(differs(over, rest, amstrad::hintRect(l, amstrad::hintAreas()[i]).toAlignedRect()),
                    "A live part is not marked");

        QEvent leave(QEvent::Leave);
        QApplication::sendEvent(&hints, &leave);
        settle(300);
        require(hints.areasVisible() && dismissed == 1, "Parts vanished without lingering");
        settle(1100);
        require(!hints.areasVisible() && peek.isHidden(), "Parts did not fade away");
        require(!differs(host.grab().toImage(), rest, host.rect()), "Something remains after fading");

        // Fitted hardware names the left bay; the guest's mouse removes the mark.
        front.left = amstrad::BayHdd;
        QApplication::sendEvent(&hints, &enter);
        settle(260);
        host.grab().save(out + "/hints-shown-hd20.png");
        captured = true;
        settle(400);
        require(hints.isHidden() && dismissed == 2, "Mark stays while the guest has the mouse");
        settle(1100);
        require(!hints.areasVisible(), "Parts remain over a captured mouse");
        captured = false;
        settle(400);
        require(hints.isVisible(), "Mark did not return");

        qputenv("AMSTRAD_HINTS", "0");
        AmstradHints off(&host);
        off.place();
        settle(300);
        require(off.isHidden(), "AMSTRAD_HINTS=0 ignored");
        std::puts("hints: ok");
        return 0;
    } catch (const std::exception &error) {
        std::fprintf(stderr, "hints: %s\n", error.what());
        return 1;
    }
}
