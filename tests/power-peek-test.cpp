// Exercise the actual painted button through a delayed power acknowledgement.
#include "qt_amstradpower.hpp"
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
    void paintEvent(QPaintEvent *) override {
        QPainter p(this);
        p.fillRect(rect(), amstrad::backgroundColor());
        amstrad::paintCabinet(p, cabinet, amstrad::sceneLayout(size()));
    }
};

int main(int argc, char **argv)
{
    QApplication app(argc, argv);
    try {
        require(argc == 2, "Supply the rear-button atlas path");
        QTemporaryDir settings;
        SceneHost host;
        host.setFont(QFont("Segoe UI"));
        host.cabinet = amstrad::prepareCabinet(QImage(QFileInfo(QString::fromLocal8Bit(argv[1])).dir().filePath("../pc1512-front.png")));
        host.resize(950, 1030);
        AmstradPowerPeek peek(&host, QString::fromLocal8Bit(argv[1]), settings.filePath("test.ini"));
        host.show();
        int requests = 0;
        peek.toggle = [&] { ++requests; }; // Leave acknowledgement pending, like a slow cold boot.
        for (bool bay : {false, true}) {
            peek.setCableView(bay);
            peek.changed(false);
            settle(200);
            require(peek.isVisible(), "Off button did not appear");
            auto *viewButton = peek.findChild<QToolButton *>();
            require(viewButton != nullptr, "View menu button missing");
            QEvent menuLeave(QEvent::Leave);
            QApplication::sendEvent(&peek, &menuLeave);
            require(viewButton->isHidden(), "View menu button visible without hover");
            QEvent menuEnter(QEvent::Enter);
            QApplication::sendEvent(&peek, &menuEnter);
            require(viewButton->isVisible(), "View menu button missing on hover");
            bool menuSeen = false;
            const int requestsBeforeMenu = requests;
            QTimer::singleShot(50, [&] {
                auto *menu = qobject_cast<QMenu *>(QApplication::activePopupWidget());
                menuSeen = menu && menu->actions().size() == 2;
                if (menu) menu->close();
            });
            viewButton->click();
            require(menuSeen, "View button did not open both layout choices");
            require(requests == requestsBeforeMenu, "View menu operated the power switch");
            // The rear-switch callout must remain beside the monitor at all
            // supported shapes, including the former overlapping default.
            for (const QSize size : {QSize(950, 1030), QSize(1106, 1030), QSize(640, 800), QSize(1920, 1080)}) {
                host.resize(size);
                peek.place();
                settle(30);
                const auto l = amstrad::sceneLayout(size);
                require(peek.geometry().left() > peek.spot().x() + 24*l.scale, "Callout overlaps the monitor/anchor");
                require(host.rect().contains(peek.geometry()), "Callout extends beyond the window");
                const qreal magnification = peek.photoRect().width() / (214 * l.scale);
                if (bay && size == QSize(1106, 1030))
                    require(magnification > 1.3, "Rear bay did not grow in the normal window");
                if (bay && size == QSize(1920, 1080))
                    require(std::abs(magnification - 2.0) < .02, "Rear bay did not reach 2x in a wide window");
                if (!bay)
                    require(std::abs(magnification - 1.0) < .02, "Button close-up changed size");
                require(std::abs(peek.spot().y() - (l.cabinet.top() + 735*l.scale)) < .01, "Rear-button anchor moved");
                require(host.grab().save(QDir(QCoreApplication::applicationDirPath()).filePath(
                    QString("power-%1-%2x%3.png").arg(bay ? "bay" : "close").arg(size.width()).arg(size.height()))), "Could not save layout preview");
                auto masterPoint = [&](qreal x, qreal y) {
                    return QPointF(l.cabinet.left() + x*l.scale, l.cabinet.top() + y*l.scale).toPoint();
                };
                peek.changed(true);
                peek.hide();
                peek.track(masterPoint(1090, 735), false);
                require(!peek.isVisible(), "Old left-hand hotspot still reveals the popup");
                peek.track(masterPoint(1117, 600), false);
                require(!peek.isVisible(), "Old upper hotspot still reveals the popup");
                peek.track(peek.spot().toPoint(), false);
                require(!peek.isVisible(), "Monitor-edge marker still reveals the popup");
                peek.track(masterPoint(993, 773), false);
                require(!peek.isVisible(), "Monitor badge reveals the power popup");
                peek.track((peek.pos() + peek.buttonCenter()), false);
                require(peek.isVisible(), "Hidden popup's on-screen button position did not reveal it");
                peek.hide();
                peek.track((peek.pos() + peek.photoRect().topLeft() + QPointF(10*l.scale, 50*l.scale)).toPoint(), false);
                require(peek.isVisible(), "Hidden popup's surrounding plastic did not reveal it");
                peek.hide();
                peek.track(QPointF(peek.geometry().center().x(), peek.geometry().bottom() - 10*l.scale).toPoint(), false);
                require(peek.isVisible(), "Hidden popup's POWER caption area did not reveal it");
                peek.changed(false);
                settle(200);
            }
            const qreal s = amstrad::sceneLayout(host.size()).scale;
            peek.changed(true);
            peek.hide();
            peek.track(peek.pos() + peek.buttonCenter(), false);
            peek.dismissLater();
            QEvent enter(QEvent::Enter);
            QApplication::sendEvent(&peek, &enter);
            settle(650);
            require(peek.isVisible(), "Entering the newly revealed popup did not cancel dismissal");
            peek.dismissLater();
            const QPointF passage((peek.spot().x() + peek.x())/2,
                                  (peek.spot().y() + peek.y() + peek.photoRect().center().y())/2);
            peek.track(passage.toPoint(), false);
            settle(650);
            require(peek.isVisible(), "Popup hid while crossing between its leaders");
            peek.track(QPointF(peek.spot().x(), peek.y() + 8*s).toPoint(), false);
            settle(650);
            require(!peek.isVisible(), "Invisible area above the leaders kept the popup open");
            peek.track(peek.pos() + peek.buttonCenter(), false);
            peek.track(QPointF(peek.spot().x() - 27*s, peek.spot().y()).toPoint(), false);
            settle(650);
            require(!peek.isVisible(), "Old left-hand hotspot kept the popup open");
            peek.changed(false);
            settle(200);
            peek.track(QPoint(0, 0), false);
            QEvent leave(QEvent::Leave);
            QApplication::sendEvent(&peek, &leave);
            settle(1300);
            require(peek.isVisible(), "Off button hid after pointer leave");
            if (bay) peek.setFocus();
            auto photo = [&] {
                // Compare the sharp switch, excluding plastic edges that blend
                // with the live frosted backdrop when power changes.
                const auto r = peek.photoRect();
                return peek.grab().toImage().copy(r.adjusted(r.width()*.2, r.height()*.2,
                                                            -r.width()*.2, -r.height()*.2).toAlignedRect());
            };
            const QImage released = photo();
            const QPointF center(peek.buttonCenter());
            QMouseEvent down(QEvent::MouseButtonPress, center, Qt::LeftButton, Qt::LeftButton, Qt::NoModifier);
            QApplication::sendEvent(&peek, &down);
            const QImage pressed = photo();
            if (bay)
                require(peek.grab().save(QDir(QCoreApplication::applicationDirPath()).filePath(
                    "power-bay-focus-pressed.png")), "Could not save pressed bay preview");
            require(pressed != released, "Press did not change the button image");
            QMouseEvent up(QEvent::MouseButtonRelease, center, Qt::LeftButton, Qt::NoButton, Qt::NoModifier);
            QApplication::sendEvent(&peek, &up);
            settle(200);
            require(photo() == pressed, "Button bounced back before power-on acknowledgement");
            const int sent = requests;
            QApplication::sendEvent(&peek, &down);
            QApplication::sendEvent(&peek, &up);
            require(requests == sent, "A pending transition accepted a second activation");
            peek.changed(true);
            if (bay)
                require(peek.grab().save(QDir(QCoreApplication::applicationDirPath()).filePath(
                    "power-bay-power-on-transition.png")), "Could not save rear-bay power-on preview");
            if (bay) {
                const QImage transition = peek.grab().toImage();
                const QColor frame = transition.pixelColor(peek.width()/2,
                    qMin(peek.height()-1, qRound(peek.photoRect().bottom())+2));
                require(frame.blue() - frame.red() < 20, "Blue fallback flashed on rear-bay power-on");
            }
            require(photo() == pressed, "Acknowledgement changed the latched button image");
            settle(1300);
            require(!peek.isVisible(), "Powered-on inset did not auto-hide");
        }
        // Render a detail at a desktop-like scale for visual review.
        host.resize(3200, 2000);
        peek.setCableView(false);
        peek.changed(false);
        settle(200);
        peek.clearFocus();
        peek.grab().save(QDir(QCoreApplication::applicationDirPath()).filePath("power-rounded-preview.png"));
        const qreal scale = amstrad::sceneLayout(host.size()).scale;
        const QRectF detail = QRectF(peek.geometry()).united(QRectF(peek.spot(), QSizeF(1, 1)))
            .adjusted(-45*scale, -30*scale, 20*scale, 20*scale);
        host.grab(detail.toAlignedRect()).save(QDir(QCoreApplication::applicationDirPath()).filePath("power-leaders-preview.png"));
        std::puts("PASS: both views reveal over their hidden on-screen popup at every size, not over the monitor or its badge; leader travel stays open, stale hover areas dismiss, and power latches without flicker.");
        return 0;
    } catch (const std::exception &error) {
        std::fprintf(stderr, "FAIL: %s\n", error.what());
        return 1;
    }
}
