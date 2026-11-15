// Render the floppy drive panel in isolation for quick visual iteration, and
// check the disk box's bookkeeping on a throwaway VM folder.
#include "qt_amstradscene.hpp"
#include "qt_amstradmenu.hpp"
#include <QDir>
#include <QFile>
#include <cstdio>

class DiskPreviewHost : public QWidget {
public:
    QImage cabinet;
    void paintEvent(QPaintEvent *) override {
        QPainter p(this); p.fillRect(rect(),amstrad::backgroundColor());
        amstrad::paintCabinet(p,cabinet,amstrad::sceneLayout(size()));
    }
};

static int failures = 0;
static void require(bool ok, const char *what)
{
    if (!ok) { std::fprintf(stderr, "FAIL: %s\n", what); ++failures; }
}

int main(int argc, char **argv)
{
    QApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QApplication app(argc, argv);
    app.setFont(QFont("Segoe UI", 9));
    if (argc != 4) { std::fprintf(stderr, "Supply project root, a scratch VM folder and the output PNG\n"); return 1; }
    const QDir root(QString::fromLocal8Bit(argv[1]));
    const QString vm = QString::fromLocal8Bit(argv[2]);
    QString out = QString::fromLocal8Bit(argv[3]);

    // A throwaway VM folder: the system set (360K, as named in the wild), some
    // of the user's own disks and a DOS look-alike that must lose to the set.
    QDir(vm).removeRecursively();
    QDir().mkpath(vm + "/media");
    auto touch = [&](const QString &name, int size = 368640) {
        QFile f(vm + "/media/" + name); f.open(QIODevice::WriteOnly); f.resize(size); return QDir::cleanPath(f.fileName());
    };
    const QString dos = touch("PC1512 A1 - MSDOS.img"), gem1 = touch("PC1512 A2 - GEM1.img"), gem2 = touch("PC1512 A3 - GEM2.img");
    touch("dos_boot_disk.img", 1474560);
    const QString hdutils = touch("PC1512 A5 - HDUTILS.img");
    const QString games = touch("PC1512 J1 - Digger JBird Cat Pango TopGun Zaxxon Chess.IMA"),
                  flight = touch("PC1512 J - Flight Simulator v2.12.img"), work = touch("letters.img"),
                  bushido = touch("PC1512 J - Bushido.IMA");
    {
        amstrad::DiskBox box(vm);
        require(amstrad::DiskBox::same(box.systemDisc(0), dos), "MS-DOS disc found by name, look-alike ignored");
        require(amstrad::DiskBox::same(box.systemDisc(1), gem1) && amstrad::DiskBox::same(box.systemDisc(2), gem2), "GEM discs told apart");
        require(box.systemDisc(3).isEmpty(), "missing DOS Plus disc reported missing");
        require(box.systemIndex("wp://" + dos) == 0 && box.systemIndex(work) < 0, "system disc recognised through wp://");
        box.remember(work, false); box.remember(dos, true); box.remember(bushido, false);
        box.remember(flight, true); box.remember(games, false); box.remember("wp://media/letters.img", true);
        require(box.recent().size() == 4 && amstrad::DiskBox::same(box.recent().first(), work), "recent disks: newest first, no system discs, no duplicates");
        require(box.isProtected(work) && box.isProtected(flight) && !box.isProtected(games), "tabs follow how a disk was mounted");
        box.setProtected(work, false); box.forget(bushido);
        require(!box.isProtected(work) && box.recent().size() == 3, "tab peeled off; disk taken out of the box");
        require(box.openProtected(), "opened images are protected unless changed");
        box.setSystemDisc(3, bushido);
        require(box.systemIndex(bushido) == 3, "a chosen image becomes the system disc");
        box.unlinkSystemDisc(3); box.unlinkSystemDisc(0);
        require(box.systemDisc(0).isEmpty() && box.systemIndex(dos) < 0, "an unlinked system disc is not guessed again");
        box.setSystemDisc(0, dos);
        require(box.systemIndex(dos) == 0, "choosing an image links it again");
    }
    require(amstrad::DiskBox(vm).recent().size() == 3, "the box persists");
    {
        // Disc 5 belongs to hard disc machines; elsewhere it is the user's own disk.
        amstrad::DiskBox floppyOnly(vm), hardDisc(vm, true);
        floppyOnly.remember(hdutils, true);
        require(floppyOnly.systemIndex(hdutils) < 0 && floppyOnly.recent().contains(hdutils), "HD utilities: an ordinary disk without a hard disc");
        require(hardDisc.systemIndex(hdutils) == 4 && !hardDisc.recent().contains(hdutils), "HD utilities: system disc 5 with a hard disc");
        require(amstrad::diskColour(hdutils) == amstrad::DiskPurple && amstrad::diskColour(hdutils, false) == amstrad::DiskBlack, "purple in the drive only on hard disc machines");
        floppyOnly.forget(hdutils);
    }

    const QImage art = amstrad::prepareCabinet(QImage(root.filePath("assets/front/pc1512-front.png")));
    const auto fittings = amstrad::loadFittings(root.filePath("assets/front/drives"),
        root.filePath("assets/front/badges"), root.filePath("assets/front/leds"));
    const auto faces = amstrad::loadDrives(root.filePath("assets/front/drives"));
    if (art.isNull() || !fittings.valid() || !faces.valid()) return 2;
    DiskPreviewHost host; host.cabinet=art; host.resize(1500,1000); host.show();
    QApplication::processEvents();
    const qreal ratio = host.devicePixelRatioF();
    auto bay = [&](int face) {
        QImage unit = amstrad::composeCabinet(art, fittings, amstrad::Front());
        { QPainter p(&unit); p.drawImage(amstrad::driveRect(amstrad::layout(unit.size()), 1), faces.face[1][face]); }
        const qreal s = unit.width() / 1254.0;
        const QRectF c = amstrad::masterBay(1).adjusted(-6,-6,6,-30);
        return amstrad::menuPicture(unit.copy(QRectF(c.x()*s, c.y()*s, c.width()*s, c.height()*s).toAlignedRect()),
                                    QSize(amstrad::MenuCard::PictureBox, 103), ratio);
    };
    // Three states: a user's disk in A:, a system disc in A:, and an empty B:.
    struct State { const char *suffix; int drive; QString a, b; bool wp; int face; bool hd; };
    const State states[] = { { "", 0, work, QString(), false, amstrad::DiskBlack, false },
                             { "-system", 0, "wp://" + dos, gem1, true, amstrad::DiskRed, false },
                             { "-empty", 1, dos, QString(), false, amstrad::DriveOpen, false },
                             { "-hd20", 0, "wp://" + hdutils, QString(), true, amstrad::DiskPurple, true } };
    for (const State &state : states) {
        QMenu menu(&host);
        amstrad::stylePopupMenu(&menu);
        amstrad::DrivePanel panel;
        panel.drive = state.drive; panel.hardDisk = state.hd; panel.vmFolder = vm; panel.artFolder = root.filePath("assets/front/disks");
        panel.mounted[0] = state.a; panel.mounted[1] = state.b; panel.mountedProtected = state.wp;
        panel.closed = bay(state.face); panel.open = bay(amstrad::DriveOpen);
        panel.insert = [](const QString &, bool) {}; panel.browse = [](bool) {};
        panel.create = [] {}; panel.eject = [] {}; panel.locate = [](int) {};
        amstrad::addDrivePanel(&menu, panel, ratio);
        require(menu.findChildren<QAbstractButton *>().size() >= 7, "drive card, system discs, Open and New present");
        menu.ensurePolished(); menu.resize(menu.sizeHint());
        menu.move(host.mapToGlobal(QPoint(60,40)));
        menu.show(); QApplication::processEvents();
        QString file = out; file.replace(".png", QString(state.suffix) + ".png");
        if (!menu.grab().save(file)) return 3;
        std::printf("%s %dx%d\n", qPrintable(file), menu.width(), menu.height());
    }
    return failures ? 4 : 0;
}
