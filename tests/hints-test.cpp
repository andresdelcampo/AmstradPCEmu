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
        AmstradCornerButton exitButton(&host, AmstradCornerButton::Exit);
        int exits = 0;
        exitButton.blocked = [&] { return captured; };
        exitButton.activate = [&] { ++exits; };
        exitButton.place();
        require(exitButton.isVisible(), "Exit control missing");
        require(exitButton.geometry().topRight().x() == hints.geometry().right(),
                "Exit control does not align with help");
        require(exitButton.geometry().top() == host.height() - hints.geometry().bottom() - 1,
                "Exit control does not mirror help vertically");
        const QPoint center = exitButton.rect().center();
        QMouseEvent press(QEvent::MouseButtonPress, center, Qt::LeftButton, Qt::LeftButton, Qt::NoModifier);
        QMouseEvent release(QEvent::MouseButtonRelease, center, Qt::LeftButton, Qt::NoButton, Qt::NoModifier);
        QApplication::sendEvent(&exitButton, &press);
        QApplication::sendEvent(&exitButton, &release);
        require(exits == 1, "Exit control did not activate");
        AmstradCornerButton modeButton(&host, AmstradCornerButton::Fullscreen);
        bool fullscreen = false;
        modeButton.blocked = [&] { return captured; };
        modeButton.fullscreen = [&] { return fullscreen; };
        modeButton.activate = [&] { fullscreen = !fullscreen; };
        modeButton.place();
        require(modeButton.isVisible() && modeButton.geometry().right() == exitButton.geometry().left() - 5,
                "Fullscreen control is not next to exit");
        require(modeButton.accessibleName() == "Enter fullscreen", "Windowed label is wrong");
        QMouseEvent modePress(QEvent::MouseButtonPress, modeButton.rect().center(), Qt::LeftButton, Qt::LeftButton, Qt::NoModifier);
        QMouseEvent modeRelease(QEvent::MouseButtonRelease, modeButton.rect().center(), Qt::LeftButton, Qt::NoButton, Qt::NoModifier);
        QApplication::sendEvent(&modeButton, &modePress);
        QApplication::sendEvent(&modeButton, &modeRelease);
        modeButton.place();
        require(fullscreen && modeButton.accessibleName() == "Exit fullscreen", "Fullscreen control did not switch state");
        QApplication::sendEvent(&modeButton, &modePress);
        QApplication::sendEvent(&modeButton, &modeRelease);
        require(!fullscreen, "Fullscreen control did not switch back");
        captured = true;
        exitButton.place();
        modeButton.place();
        require(exitButton.isHidden(), "Exit control stays visible during mouse capture");
        require(modeButton.isHidden(), "Fullscreen control stays visible during mouse capture");
        std::puts("hints: ok");
        return 0;
    } catch (const std::exception &error) {
        std::fprintf(stderr, "hints: %s\n", error.what());
        return 1;
    }
}
