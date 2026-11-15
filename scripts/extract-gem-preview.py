"""Read the installed FAT12 DOS disk and decode its original GEM sample images.

No disk writes, extra packages or approximate image reconstruction.
GEM encoding reference: https://www.seasip.info/Gem/ff_img.html
Palette cross-check: FFmpeg libavcodec/gemdec.c (default GEM indexed palette).
"""
from pathlib import Path
import hashlib
import json
import struct
import zlib

ROOT = Path(__file__).resolve().parents[1]
SOURCE = Path('C:/Emulators/86Box/Disks/PC1512 A1 - MSDOS.img')
OUT = ROOT / 'assets/front/monitor'

def disk_images(source=SOURCE):
    disk = source.read_bytes()
    bps = struct.unpack_from('<H', disk, 11)[0]
    spc, reserved, fats = disk[13], struct.unpack_from('<H', disk, 14)[0], disk[16]
    entries, spf = struct.unpack_from('<H', disk, 17)[0], struct.unpack_from('<H', disk, 22)[0]
    root = (reserved + fats * spf) * bps
    data = root + ((entries * 32 + bps - 1) // bps) * bps
    fat = disk[reserved * bps:(reserved + spf) * bps]
    def chain(cluster):
        result, seen = bytearray(), set()
        while 2 <= cluster < 0xff8:
            if cluster in seen: raise ValueError('FAT loop')
            seen.add(cluster)
            offset = data + (cluster - 2) * spc * bps
            result.extend(disk[offset:offset + spc * bps])
            pair = int.from_bytes(fat[cluster * 3 // 2:cluster * 3 // 2 + 2], 'little')
            cluster = pair >> 4 if cluster & 1 else pair & 0xfff
        return bytes(result)
    def scan(directory, prefix=''):
        for offset in range(0, len(directory), 32):
            e = directory[offset:offset+32]
            if not e or not e[0]: break
            if e[0] in (229,46) or e[11] & 8: continue
            name, ext = e[:8].decode('ascii').rstrip(), e[8:11].decode('ascii').rstrip()
            name += '.' + ext if ext else ''
            cluster, size = struct.unpack_from('<H',e,26)[0], struct.unpack_from('<I',e,28)[0]
            if e[11] & 16: yield from scan(chain(cluster), prefix + name + '/')
            else: yield prefix + name, chain(cluster)[:size]
    return dict(scan(disk[root:root + entries * 32])), hashlib.sha256(disk).hexdigest()

def decode(payload):
    version, words, planes, pattern_size, pixel_w, pixel_h, width, height = struct.unpack_from('>8H',payload)
    assert version == 1 and planes in (1,4) and 0 < width <= 4096 and 0 < height <= 4096
    gem_palette = [(255,255,255),(255,0,0),(0,255,0),(255,255,0),
                   (0,0,255),(255,0,255),(0,255,255),(174,174,174),
                   (85,85,85),(174,0,0),(0,174,0),(174,174,0),
                   (0,0,174),(174,0,174),(0,174,174),(0,0,0)]
    offset, stride, rows = words * 2, (width + 7) // 8, []
    while len(rows) < height:
        repeat = 1
        if payload[offset:offset+3] == b'\0\0\xff':
            repeat = payload[offset+3]; offset += 4
        line = []
        for _ in range(planes):
            row = bytearray()
            while len(row) < stride:
                code = payload[offset]; offset += 1
                if code == 0:
                    count = payload[offset]; offset += 1
                    assert count
                    pattern = payload[offset:offset+pattern_size]; offset += pattern_size
                    row.extend(pattern * count)
                elif code == 128:
                    count = payload[offset]; offset += 1
                    row.extend(payload[offset:offset+count]); offset += count
                else:
                    row.extend(bytes([255 if code & 128 else 0]) * (code & 127))
            assert len(row) == stride
            line.append(row)
        rgb = bytearray()
        for x in range(width):
            bits = [(row[x//8] >> (7-x%8)) & 1 for row in line]
            if planes == 1:
                value = 0 if bits[0] else 255
                rgb.extend((value,value,value))
            else:
                rgb.extend(gem_palette[sum(bit << i for i,bit in enumerate(bits))])
        rows.extend([bytes(rgb)] * repeat)
    assert len(rows) == height and offset == len(payload), (len(rows),height,offset,len(payload))
    return width, height, rows, {'width':width,'height':height,'planes':planes,'pixel_width':pixel_w,'pixel_height':pixel_h}

def png(width,height,rows):
    def chunk(tag, data):
        return struct.pack('>I',len(data)) + tag + data + struct.pack('>I',zlib.crc32(tag+data))
    return b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR',struct.pack('>IIBBBBB',width,height,8,2,0,0,0)) + chunk(b'IDAT',zlib.compress(b''.join(b'\0'+row for row in rows),9)) + chunk(b'IEND',b'')

def main():
    files, before = disk_images()
    OUT.mkdir(exist_ok=True)
    report = {'source_disk_sha256':before,'files':{}}
    for source, target in [('IMAGES/PC1512.IMG','gem-pc1512-original.png'),('IMAGES/TIGER.IMG','gem-tiger-original.png')]:
        payload = files[source]
        w,h,rows,details = decode(payload)
        result = png(w,h,rows)
        (OUT/target).write_bytes(result)
        report['files'][source] = dict(details, source_sha256=hashlib.sha256(payload).hexdigest(),png_sha256=hashlib.sha256(result).hexdigest(),output=target)
    assert hashlib.sha256(SOURCE.read_bytes()).hexdigest() == before
    house_disk = SOURCE.with_name('PC1512 A5 - HDUTILS.img')
    house_files, house_before = disk_images(house_disk)
    payload = house_files['IMAGES/HOUSE.IMG']
    w,h,rows,details = decode(payload)
    result = png(w,h,rows)
    (OUT/'gem-house-original.png').write_bytes(result)
    assert hashlib.sha256(house_disk.read_bytes()).hexdigest() == house_before
    report['house_disk_sha256'] = house_before
    report['files']['A5:IMAGES/HOUSE.IMG'] = dict(details, source_sha256=hashlib.sha256(payload).hexdigest(),png_sha256=hashlib.sha256(result).hexdigest(),output='gem-house-original.png')
    (OUT/'original-samples.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
    print(json.dumps(report,indent=2))

if __name__ == '__main__': main()
