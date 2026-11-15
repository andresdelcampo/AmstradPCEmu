"""Export the reviewable fork patch, including new source files, without staging."""
from pathlib import Path
import difflib
import subprocess

root = Path(__file__).resolve().parents[1]
source = root / 'upstream/86Box'
patch = subprocess.check_output(['git','-C',str(source),'diff','--binary'], text=True)
untracked = subprocess.check_output(['git','-C',str(source),'ls-files','--others','--exclude-standard'],text=True)
for name in untracked.splitlines():
    path = source / name
    if path.suffix not in ('.hpp','.cpp','.h','.c','.glsl','.frag','.vert','.slang','.txt','.md'):
        raise RuntimeError(f'Review untracked file before exporting: {name}')
    lines = path.read_text(encoding='utf-8').splitlines(keepends=True)
    patch += f'diff --git a/{name} b/{name}\nnew file mode 100644\n'
    patch += ''.join(difflib.unified_diff([],lines,fromfile='/dev/null',tofile=f'b/{name}'))
out = root / 'patches/86box-pc1512.patch'
out.parent.mkdir(exist_ok=True)
out.write_text(patch,encoding='utf-8',newline='\n')
print(out)
