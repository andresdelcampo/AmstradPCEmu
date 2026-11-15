#include <QGuiApplication>
#include <QSurfaceFormat>
#include <QOffscreenSurface>
#include <QThread>
#include <QDebug>
#include <QFileInfo>
#include "qt_ibmulatorcrt.hpp"
#include <cstdio>
#include <cmath>

int main(int argc, char **argv)
{
    QGuiApplication app(argc, argv);
    QSurfaceFormat format;
    format.setVersion(3, 3);
    format.setProfile(QSurfaceFormat::CoreProfile);
    QOffscreenSurface surface;
    surface.setFormat(format);
    surface.create();
    if (argc < 3 || !surface.isValid()) return 2;
    auto context = std::make_unique<QOpenGLContext>();
    context->setFormat(format);
    if (!context->create()) return 2;
    QThread worker;
    QObject work;
    work.moveToThread(&worker);
    context->moveToThread(&worker);
    worker.start();
    int result = 0;
    QMetaObject::invokeMethod(&work, [&] {
        IBMulatorCRT filter(&surface, QString::fromLocal8Bit(argv[1]), std::move(context));
        QImage source(2048, 200, QImage::Format_RGB32);
        source.fill(Qt::black);
        // Non-zero X offset and the real producer pitch; distinguish top/bottom.
        for (int y=0; y<200; ++y)
            for (int x=11; x<651; ++x)
                source.setPixel(x,y, x<331 ? (y<100 ? 0x00ff0000 : 0x000000ff) : 0x0000ff00);
        QImage output = filter.apply(source, QRect(11,0,640,200), QSize(720,540));
        if (output.isNull()) { fprintf(stderr,"CRT error: %s\n",qPrintable(filter.error())); result=3; }
        else {
            const QColor red=output.pixelColor(180,135), blue=output.pixelColor(180,405), green=output.pixelColor(540,135);
            if (!(red.red()>200 && red.blue()<20 && blue.blue()>200 && blue.red()<20 && green.green()>200)) result=4;
            if (!output.save(QString::fromLocal8Bit(argv[2]))) result=5;
            // Exercise FBO resize and cleanup on its owning worker.
            if (filter.apply(source,QRect(11,0,640,200),QSize(432,324)).size()!=QSize(432,324)) result=6;
            qInfo() << "IBMulator CRT GPU:" << filter.renderer() << "colors:" << red << blue << green << "result:" << result;
            fprintf(stderr,"CRT renderer: %s; red=%08x blue=%08x green=%08x result=%d\n", qPrintable(filter.renderer()), red.rgba(), blue.rgba(), green.rgba(), result);

            QImage stripes(640,200,QImage::Format_RGB32);
            for (int y=0;y<200;++y)
                for (int x=0;x<640;++x)
                    stripes.setPixel(x,y,x%2 ? 0x00ffffff : 0);
            filter.setSharpSampling(false); filter.setConvergence(.5f);
            const QImage soft=filter.apply(stripes,stripes.rect(),QSize(640,480));
            filter.setSharpSampling(true); filter.setConvergence(0.f);
            const QImage sharp=filter.apply(stripes,stripes.rect(),QSize(640,480));
            auto contrast=[](const QImage &image) {
                double difference=0;
                for (int x=289;x<352;++x)
                    difference+=std::abs(qGray(image.pixel(x,240))-qGray(image.pixel(x-1,240)))/255.;
                return difference/63.;
            };
            const double oldContrast=contrast(soft), newContrast=contrast(sharp);
            int maxFringe=0;
            for(int x=280;x<360;++x) {
                const QColor c=sharp.pixelColor(x,240);
                maxFringe=std::max(maxFringe,std::max(std::abs(c.red()-c.green()),std::abs(c.blue()-c.green())));
            }
            fprintf(stderr,"CRT mono stripe contrast soft=%.4f sharp=%.4f; maxRGBfringe=%d\n",oldContrast,newContrast,maxFringe);
            if (!(newContrast>oldContrast*1.5 && newContrast>.65 && maxFringe<=1)) result=7;
            const QString folder=QFileInfo(QString::fromLocal8Bit(argv[2])).absolutePath();
            soft.save(folder+"/ibmulator-crt-stripes-soft.png");
            sharp.save(folder+"/ibmulator-crt-stripes-sharp.png");
            if(argc>=4) {
                const QImage dos(QString::fromLocal8Bit(argv[3]));
                if(dos.isNull()) result=8;
                else {
                    filter.setSharpSampling(false); filter.setConvergence(.5f);
                    if(!filter.apply(dos,dos.rect(),QSize(492,369)).save(folder+"/ibmulator-crt-dos-soft.png")) result=9;
                    filter.setSharpSampling(true); filter.setConvergence(0.f);
                    if(!filter.apply(dos,dos.rect(),QSize(492,369)).save(folder+"/ibmulator-crt-dos-sharp.png")) result=9;
                    fprintf(stderr,"CRT actual DOS input=%dx%d; output=492x369 before/after saved\n",dos.width(),dos.height());
                }
            }
        }
        filter.close();
    }, Qt::BlockingQueuedConnection);
    worker.quit();
    worker.wait();
    return result;
}
