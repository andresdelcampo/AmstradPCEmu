#include "qt_amstradpopup.hpp"
#include <QDir>
#include <QMouseEvent>
#include <cstdio>
#include <stdexcept>

class TestBackdrop : public QWidget {
public:
    QColor colour=QColor(80,140,70);
    bool checker=false;
    void paintEvent(QPaintEvent *) override {
        QPainter p(this); p.fillRect(rect(),colour);
        if (checker)
            for (int y=0; y<height(); y+=16)
                for (int x=0; x<width(); x+=16)
                    p.fillRect(QRect(x,y,16,16),((x/16+y/16)&1) ? Qt::white : Qt::black);
    }
};
static void require(bool value,const char *message) { if (!value) throw std::runtime_error(message); }
static QImage picture(const amstrad::PopupBackdrop &backdrop,QSize size)
{
    QImage result(size,QImage::Format_RGB32); result.fill(Qt::magenta);
    QPainter p(&result); backdrop.paint(p,QRectF(result.rect())); return result;
}
int main(int argc,char **argv)
{
    QApplication app(argc,argv); app.setFont(QFont("Segoe UI",9));
    try {
        require(argc==2 || argc==3,"Supply output directory and optional native-headless flag");
        const bool nativeHeadless=argc==3;
        const QDir output(QString::fromLocal8Bit(argv[1]));
        TestBackdrop host;
        if (nativeHeadless) host.setAttribute(Qt::WA_DontShowOnScreen);
        host.resize(700,500); host.show(); QApplication::processEvents();
        amstrad::PopupBackdrop backdrop; const QSize size(260,160);
        require(backdrop.capture(&host,host.mapToGlobal(QPoint(180,140)),size,false),"Backdrop capture failed");
        const QImage solid=picture(backdrop,size);
        for (QPoint point : {QPoint(0,0),QPoint(130,80),QPoint(259,159)}) {
            const QColor c=solid.pixelColor(point);
            std::printf("Uniform sample %d,%d = %d,%d,%d\n",point.x(),point.y(),c.red(),c.green(),c.blue());
            // Qt's 8-bit blur accumulates a few rounding levels, not a tint.
            require(std::abs(c.red()-80)<=4 && std::abs(c.green()-140)<=4 && std::abs(c.blue()-70)<=4,
                    "Uniform source was tinted or darkened by blur edges");
        }
        host.checker=true;
        require(backdrop.capture(&host,host.mapToGlobal(QPoint(180,140)),size,false),"Pattern capture failed");
        const QImage frost=picture(backdrop,size); int low=255,high=0;
        for (int y=20; y<frost.height()-20; ++y)
            for (int x=20; x<frost.width()-20; ++x) {
                const int v=qGray(frost.pixel(x,y)); low=std::min(low,v); high=std::max(high,v);
            }
        require(high-low<15,"Strong frost retained sharp checkerboard details");
        host.checker=false;
        QMenu menu(&host); amstrad::stylePopupMenu(&menu); int activated=0;
        if (nativeHeadless) menu.setAttribute(Qt::WA_DontShowOnScreen);
        QAction *choose=menu.addAction("Choose disk...",[&] { ++activated; });
        menu.addAction("Unavailable disk")->setEnabled(false);
        auto *recent=menu.addMenu("Recent disks"); recent->addAction("DOS.img");
        if (nativeHeadless) recent->setAttribute(Qt::WA_DontShowOnScreen);
        menu.ensurePolished(); menu.resize(menu.sizeHint());
        menu.move(host.mapToGlobal(QPoint(220,160))); menu.show(); QApplication::processEvents();
        const QImage rendered=menu.grab().toImage().convertToFormat(QImage::Format_RGB32);
        require(menu.property("amstradFrostReady").toBool(),"Native QMenu did not receive shared backdrop");
        int bright=0; const QRect area=menu.actionGeometry(choose).adjusted(4,2,-4,-2);
        for (int y=area.top(); y<=area.bottom(); ++y)
            for (int x=area.left(); x<=area.right(); ++x) {
                QColor c=rendered.pixelColor(x,y); bright += c.red()>225 && c.green()>225 && c.blue()>225;
            }
        require(bright>10,"Native menu text was hidden by backdrop painting");
        require(rendered.save(output.filePath("native-menu.png")),"Could not save menu evidence");
        const QPoint point=menu.actionGeometry(choose).center();
        QMouseEvent down(QEvent::MouseButtonPress,point,menu.mapToGlobal(point),Qt::LeftButton,Qt::LeftButton,Qt::NoModifier);
        QMouseEvent up(QEvent::MouseButtonRelease,point,menu.mapToGlobal(point),Qt::LeftButton,Qt::NoButton,Qt::NoModifier);
        QApplication::sendEvent(&menu,&down); QApplication::sendEvent(&menu,&up);
        require(activated==1,"Native menu action no longer activated once");
        host.colour=QColor(70,90,150);
        recent->ensurePolished(); recent->resize(recent->sizeHint());
        recent->move(host.mapToGlobal(QPoint(260,200))); recent->show(); QApplication::processEvents();
        const QImage sub=recent->grab().toImage();
        require(recent->property("amstradFrostReady").toBool(),"Ordinary submenu did not inherit frost automatically");
        require(sub.save(output.filePath("submenu.png")),"Could not save submenu evidence");
        const QColor refreshed=sub.pixelColor(4,4);
        require(refreshed.blue()>refreshed.green(),"Submenu used an old or unrelated backdrop");
        recent->close(); menu.close();
        std::puts("PASS: untinted capture, strong blur, native text/action, automatic submenus and fresh backdrop.");
        return 0;
    } catch (const std::exception &e) { std::fprintf(stderr,"FAIL: %s\n",e.what()); return 1; }
}
