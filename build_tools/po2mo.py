#!/usr/bin/env python3
"""Compile the bundled .po catalogues into .mo files without GNU gettext.

The CI workflow shells out to msgfmt, which only exists on machines that have
GNU gettext installed. On a stock macOS box it does not, so this produces the
same binaries using nothing but the standard library.

Usage: python3 build_tools/po2mo.py [i18n_dir]
"""

import array
import glob
import os
import struct
import sys

# .mo magic number, little endian
MO_MAGIC = 0x950412DE


def parse_po(path):
    """Return {msgid: msgstr} for the simple entries in a .po file."""
    entries = {}
    msgid = msgstr = None
    mode = None

    with open(path, encoding="utf-8") as handle:
        for raw in handle:
            line = raw.strip()

            if line.startswith("#") or not line:
                continue
            if line.startswith("msgid "):
                if msgid and msgstr:
                    entries[msgid] = msgstr
                msgid = _unquote(line[6:])
                msgstr = None
                mode = "id"
            elif line.startswith("msgstr "):
                msgstr = _unquote(line[7:])
                mode = "str"
            elif line.startswith('"') and msgid is not None:
                if mode == "id":
                    msgid += _unquote(line)
                elif mode == "str":
                    msgstr = (msgstr or "") + _unquote(line)

    if msgid and msgstr:
        entries[msgid] = msgstr
    return entries


def _unquote(text):
    """Decode one quoted gettext string, honouring escapes and concatenation."""
    text = text.strip()
    if text.startswith('"') and text.endswith('"'):
        text = text[1:-1]
    out = []
    escaped = False
    for ch in text:
        if escaped:
            out.append({"n": "\n", "t": "\t", "r": "\r", '"': '"', "\\": "\\"}.get(ch, ch))
            escaped = False
        elif ch == "\\":
            escaped = True
        else:
            out.append(ch)
    return "".join(out)


def write_mo(entries, path):
    """Serialise {msgid: msgstr} into the GNU .mo binary format."""
    # gettext.GNUTranslations reads the charset from this metadata entry, and
    # falls back to ascii when it is missing, which breaks any non-ascii
    # catalogue. Plural forms are unused by Macast, so an empty msgstr is fine.
    metadata = "Content-Type: text/plain; charset=UTF-8\n"
    entries = dict(entries)
    entries[""] = metadata

    keys = sorted(entries.keys())

    offsets = []
    ids = b""
    strs = b""
    for key in keys:
        key_b = key.encode("utf-8")
        val_b = entries[key].encode("utf-8")
        offsets.append((len(ids), len(key_b), len(strs), len(val_b)))
        ids += key_b + b"\0"
        strs += val_b + b"\0"

    count = len(keys)
    keystart = 7 * 4 + 16 * count
    valuestart = keystart + len(ids)

    key_offsets = []
    val_offsets = []
    for o1, l1, o2, l2 in offsets:
        key_offsets += [l1, o1 + keystart]
        val_offsets += [l2, o2 + valuestart]

    with open(path, "wb") as handle:
        handle.write(struct.pack(
            "Iiiiiii", MO_MAGIC, 0, count, 7 * 4, 7 * 4 + count * 8, 0, 0))
        handle.write(array.array("i", key_offsets + val_offsets).tobytes())
        handle.write(ids)
        handle.write(strs)


def main():
    root = sys.argv[1] if len(sys.argv) > 1 else "i18n"
    built = 0
    for po in sorted(glob.glob(os.path.join(root, "*", "LC_MESSAGES", "*.po"))):
        mo = po[:-3] + ".mo"
        entries = parse_po(po)
        if not entries:
            print("    skip (no entries): %s" % po)
            continue
        write_mo(entries, mo)
        print("    %s (%d entries, %d bytes)"
              % (mo, len(entries), os.path.getsize(mo)))
        built += 1
    if not built:
        print("    no .po files found under %s" % root, file=sys.stderr)
        return 1
    print("    compiled %d catalogue(s)" % built)
    return 0


if __name__ == "__main__":
    sys.exit(main())