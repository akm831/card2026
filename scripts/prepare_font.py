"""Prepare the OFL-licensed Japanese font on macOS/Linux/Windows."""
import hashlib,pathlib,urllib.request
path=pathlib.Path(__file__).resolve().parents[1]/'godot/fonts/NotoSansJP.ttf'
url='https://raw.githubusercontent.com/google/fonts/295d98a7a0c17c68f1341eaeea354e7960ea70d3/ofl/notosansjp/NotoSansJP%5Bwght%5D.ttf'
expected='c2f3b4d463500a2ddcd3849cded1fceeb9fd6d1c32e6cbecd568453ba50fc68f'
if not path.exists():
 path.parent.mkdir(parents=True,exist_ok=True)
 with urllib.request.urlopen(url,timeout=120) as response:path.write_bytes(response.read())
if hashlib.sha256(path.read_bytes()).hexdigest()!=expected:raise SystemExit('Japanese font checksum mismatch')
print('Japanese font verified (SIL OFL 1.1).')

# Pinning a static instance avoids variable-font rendering regressions on mobile.
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont
static_path=path.with_name('NotoSansJP-Bold.ttf')
if not static_path.exists():
 font=TTFont(path)
 instantiateVariableFont(font,{'wght':700},inplace=True)
 font.save(static_path)
check=TTFont(static_path)
assert 'fvar' not in check and check['OS/2'].usWeightClass == 700
print('Static bold Japanese font verified.')
