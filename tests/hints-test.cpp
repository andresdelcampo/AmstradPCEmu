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

        // Every keyboard shortcut, in a KEYS card just above the mark.
        const QRect keys = hints.keysArea().toAlignedRect();
        require(!keys.isEmpty() && host.rect().contains(keys), "KEYS card missing or outside the window");
        require(keys.bottom() < hints.y() && keys.right() <= hints.geometry().right() + 1, "KEYS card not above the mark");
        require(differs(over, rest, keys.adjusted(10, 10, -10, -10)), "KEYS card not drawn");
        require(!keys.intersects(power), "KEYS card over the power close-up");
        for (int i = 0; i < amstrad::HintAreaCount; ++i)
            require(!keys.intersects(amstrad::hintRect(l, amstrad::hintAreas()[i]).toAlignedRect()),
                    "KEYS card over a live part");
        require(amstrad::hotspot(l, amstrad::hintRect(l, amstrad::hintAreas()[4]).center()) == amstrad::HotMakerBadge,
                "AMSTRAD plate is not a live part");

        QEvent leave(QEvent::Leave);
        // Other window shapes: the card still fits clear of the parts.
        for (const QSize size : { QSize(820, 950), QSize(1600, 900), QSize(1920, 1080), QSize(700, 560) }) {
            host.resize(size);
            hints.place();
            peek.place();
            settle(120);
            const auto lo = amstrad::sceneLayout(host.size());
            const QRect k = hints.keysArea().toAlignedRect();
            host.grab().save(out + QString("/keys-%1x%2.png").arg(size.width()).arg(size.height()));
            require(host.rect().contains(k), "KEYS card outside a resized window");
            require(!k.intersects(peek.geometry()), "KEYS card over the power close-up when resized");
            // The middle mouse button goes only where the card would meet the casing.
            require(hints.overlay()->keysMouse == (size.width() >= 1600), "KEYS card mouse kept or dropped wrongly");
            if (size.height() < 700) continue; // a very small window has no room beside the cabinet
            for (int i = 0; i < amstrad::HintAreaCount; ++i)
                require(!k.intersects(amstrad::hintRect(lo, amstrad::hintAreas()[i]).toAlignedRect()),
                        "KEYS card over a live part when resized");
        }
        host.resize(1100, 950);
        hints.place();
        peek.place();
        settle(120);
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
        // The corner controls fade while the mouse rests and return when it moves.
        captured = false;
        qputenv("AMSTRAD_FADE_CONTROLS", "1");
        bool held = false;
        qreal shownAt = 1;
        AmstradChromeFade fader(&host, &host);
        fader.hold  = [&] { return held; };
        fader.apply = [&](qreal o) { shownAt = o; };
        settle(AmstradChromeFade::RestMs + 900);
        require(shownAt == 0, "Corner controls did not fade while the mouse rested");
        QMouseEvent move(QEvent::MouseMove, QPointF(40, 40), Qt::NoButton, Qt::NoButton, Qt::NoModifier);
        QApplication::sendEvent(&host, &move);
        settle(300);
        require(shownAt == 1, "Corner controls did not return when the mouse moved");
        held = true;
        settle(AmstradChromeFade::RestMs + 900);
        require(shownAt == 1, "Corner controls faded while held");
        held = false;
        settle(AmstradChromeFade::RestMs + 900);
        require(shownAt == 0, "Corner controls did not fade once released");
        qputenv("AMSTRAD_FADE_CONTROLS", "0");
        qreal untouched = 1;
        AmstradChromeFade still(&host, &host);
        still.apply = [&](qreal o) { untouched = o; };
        settle(AmstradChromeFade::RestMs + 900);
        require(untouched == 1, "AMSTRAD_FADE_CONTROLS=0 ignored");
        // Taking the mouse shows how to release it, on the bezel under the glass.
        qputenv("AMSTRAD_CAPTURE_HINT", "1");
        {
            bool guestHas = false;
            AmstradCaptureHint capture(&host);
            capture.captured = [&] { return guestHas; };
            settle(200);
            require(!capture.pill()->shown(), "Release hint shown before capture");
            guestHas = true;
            settle(400);
            require(capture.pill()->shown(), "Release hint missing on capture");
            const QRect pill = capture.pill()->geometry();
            require(!pill.intersects(l.video.toAlignedRect()), "Release hint covers the picture");
            require(pill.top() > l.aperture.bottom() && pill.bottom() < l.cabinet.top() + 830 * l.scale,
                    "Release hint is not on the bezel below the glass");
            for (int i = 0; i < amstrad::HintAreaCount; ++i)
                require(!pill.intersects(amstrad::hintRect(l, amstrad::hintAreas()[i]).toAlignedRect()),
                        "Release hint covers a badge");
            host.grab().save(out + "/capture-hint.png");
            settle(AmstradCaptureHint::HoldMs + 900);
            require(!capture.pill()->shown(), "Release hint did not fade");
            guestHas = false;
            settle(200);
            guestHas = true;
            settle(300);
            require(capture.pill()->shown(), "Release hint missing on the next capture");
            guestHas = false;
            settle(400);
            require(!capture.pill()->shown(), "Release hint stays after release");
        }
        qputenv("AMSTRAD_CAPTURE_HINT", "0");
        {
            bool guestHas = false;
            AmstradCaptureHint quiet(&host);
            quiet.captured = [&] { return guestHas; };
            guestHas = true;
            settle(300);
            require(!quiet.pill()->shown(), "AMSTRAD_CAPTURE_HINT=0 ignored");
        }

        // Corner controls name their keys once the pointer rests on them.
        {
            AmstradCornerButton zoomButton(&host, AmstradCornerButton::Zoom);
            bool zoomed = false;
            zoomButton.zoomed = [&] { return zoomed; };
            zoomButton.place();
            exitButton.place();
            modeButton.place();
            QApplication::sendEvent(&modeButton, &enter);
            settle(AmstradCornerButton::TagDelayMs / 2);
            require(!modeButton.keyTag()->shown(), "Key tag shown without a pause");
            settle(AmstradCornerButton::TagDelayMs + 250);
            require(modeButton.keyTag()->shown(), "Fullscreen key tag missing");
            require(host.rect().contains(modeButton.keyTag()->geometry()), "Key tag outside the window");
            require(modeButton.keyTag()->geometry().top() > modeButton.geometry().bottom(), "Key tag over its control");
            host.grab().save(out + "/corner-tag-fullscreen.png");
            QApplication::sendEvent(&modeButton, &leave);
            settle(300);
            require(!modeButton.keyTag()->shown(), "Key tag stays after leaving");
            QApplication::sendEvent(&zoomButton, &enter);
            settle(AmstradCornerButton::TagDelayMs + 250);
            host.grab().save(out + "/corner-tag-zoom.png");
            QApplication::sendEvent(&zoomButton, &leave);
            QApplication::sendEvent(&exitButton, &enter);
            settle(AmstradCornerButton::TagDelayMs + 250);
            require(exitButton.keyTag()->shown(), "Exit key tag missing");
            require(exitButton.keyTag()->geometry().right() == exitButton.geometry().right(),
                    "Exit key tag not aligned with its control");
            host.grab().save(out + "/corner-tag-exit.png");
            QApplication::sendEvent(&exitButton, &leave);
            settle(300);
        }
        std::puts("hints: ok");
        return 0;
    } catch (const std::exception &error) {
        std::fprintf(stderr, "hints: %s\n", error.what());
        return 1;
    }
}
