#!/usr/bin/env python3
"""Inject Copy Bundle Resources entries that XcodeGen drops under Xcode 27."""
from __future__ import annotations

import hashlib
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
PBX = ROOT / "UyghurLatin.xcodeproj" / "project.pbxproj"

# path relative to ios/, target folder name
RESOURCES: list[tuple[str, str, str]] = [
    ("UyghurLatin/Assets.xcassets", "UyghurLatin", "folder.assetcatalog"),
    ("UyghurLatin/PrivacyInfo.xcprivacy", "UyghurLatin", "text.xml"),
    ("UyghurLatin/Resources/meta.json", "UyghurLatin", "text.json"),
    ("UyghurLatin/Resources/THIRD_PARTY_NOTICES.md", "UyghurLatin", "net.daringfireball.markdown"),
    ("UyghurLatin/Resources/notices", "UyghurLatin", "folder"),
    ("UyghurLatin/en.lproj", "UyghurLatin", "folder"),
    ("UyghurLatin/zh-Hans.lproj", "UyghurLatin", "folder"),
    ("UyghurLatin/ug.lproj", "UyghurLatin", "folder"),
    ("UyghurLatin/ug-Latn.lproj", "UyghurLatin", "folder"),
    ("UyghurLatinKeyboard/Resources/lexicon.bin", "UyghurLatinKeyboard", "file"),
    ("UyghurLatinKeyboard/Resources/meta.json", "UyghurLatinKeyboard", "text.json"),
    ("UyghurLatinKeyboard/PrivacyInfo.xcprivacy", "UyghurLatinKeyboard", "text.xml"),
    ("UyghurLatinKeyboard/en.lproj", "UyghurLatinKeyboard", "folder"),
    ("UyghurLatinKeyboard/zh-Hans.lproj", "UyghurLatinKeyboard", "folder"),
    ("UyghurLatinKeyboard/ug.lproj", "UyghurLatinKeyboard", "folder"),
    ("UyghurLatinKeyboard/ug-Latn.lproj", "UyghurLatinKeyboard", "folder"),
]


def hid(seed: str) -> str:
    return hashlib.md5(seed.encode()).hexdigest()[:24].upper()


def find_group_id(text: str, name: str) -> str:
    pattern = r"([A-F0-9]{24}) /\* " + re.escape(name) + r" \*/ = \{\s*isa = PBXGroup;"
    m = re.search(pattern, text)
    if not m:
        raise RuntimeError(f"group not found: {name}")
    return m.group(1)


def find_target_build_phases_span(text: str, name: str) -> tuple[int, int, str]:
    pattern = (
        r"([A-F0-9]{24}) /\* " + re.escape(name) + r" \*/ = \{\s*"
        r"isa = PBXNativeTarget;\s*"
        r"buildConfigurationList = [A-F0-9]{24} /\* [^*]+ \*/;\s*"
        r"buildPhases = \(\s*"
        r"((?:.|\n)*?)\s*\);"
    )
    m = re.search(pattern, text)
    if not m:
        raise RuntimeError(f"target not found: {name}")
    return m.start(2), m.end(2), m.group(2)


def main() -> int:
    text = PBX.read_text(encoding="utf-8")
    if "/* Begin patched resources */" in text:
        print("Resources already patched")
        return 0

    file_refs: list[str] = []
    build_files: list[str] = []
    by_target: dict[str, list[str]] = {"UyghurLatin": [], "UyghurLatinKeyboard": []}
    group_children: dict[str, list[str]] = {"UyghurLatin": [], "UyghurLatinKeyboard": []}

    for rel, target, ftype in RESOURCES:
        path = ROOT / rel
        if not path.exists():
            print(f"missing: {rel}", file=sys.stderr)
            return 1
        name = pathlib.Path(rel).name
        nested = pathlib.Path(rel).relative_to(target).as_posix()
        fr = hid(f"fr:{rel}")
        bf = hid(f"bf:{rel}")
        file_refs.append(
            f'\t\t{fr} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = {ftype}; '
            f'name = "{name}"; path = "{nested}"; sourceTree = "<group>"; }};'
        )
        build_files.append(
            f"\t\t{bf} /* {name} in Resources */ = {{isa = PBXBuildFile; fileRef = {fr} /* {name} */; }};"
        )
        by_target[target].append(f"\t\t\t\t{bf} /* {name} in Resources */,")
        group_children[target].append(f"\t\t\t\t{fr} /* {name} */,")

    host_phase = hid("phase:UyghurLatin:Resources")
    kbd_phase = hid("phase:UyghurLatinKeyboard:Resources")

    resources_section = "\n".join(
        [
            "/* Begin patched resources */",
            "/* Begin PBXResourcesBuildPhase section */",
            f"\t\t{host_phase} /* Resources */ = {{",
            "\t\t\tisa = PBXResourcesBuildPhase;",
            "\t\t\tbuildActionMask = 2147483647;",
            "\t\t\tfiles = (",
            *by_target["UyghurLatin"],
            "\t\t\t);",
            "\t\t\trunOnlyForDeploymentPostprocessing = 0;",
            "\t\t};",
            f"\t\t{kbd_phase} /* Resources */ = {{",
            "\t\t\tisa = PBXResourcesBuildPhase;",
            "\t\t\tbuildActionMask = 2147483647;",
            "\t\t\tfiles = (",
            *by_target["UyghurLatinKeyboard"],
            "\t\t\t);",
            "\t\t\trunOnlyForDeploymentPostprocessing = 0;",
            "\t\t};",
            "/* End PBXResourcesBuildPhase section */",
            "/* End patched resources */",
        ]
    )

    text = text.replace(
        "/* End PBXBuildFile section */",
        "\n".join(build_files) + "\n/* End PBXBuildFile section */",
    )
    text = text.replace(
        "/* End PBXFileReference section */",
        "\n".join(file_refs) + "\n/* End PBXFileReference section */",
    )

    for target, children in group_children.items():
        gid = find_group_id(text, target)
        pattern = (
            r"(" + gid + r" /\* " + re.escape(target) + r" \*/ = \{\n"
            r"\t\t\tisa = PBXGroup;\n"
            r"\t\t\tchildren = \()\n"
        )
        text, n = re.subn(pattern, r"\1\n" + "\n".join(children) + "\n", text, count=1)
        if n != 1:
            print(f"failed to patch group children: {target}", file=sys.stderr)
            return 1

    for target, phase in (("UyghurLatin", host_phase), ("UyghurLatinKeyboard", kbd_phase)):
        start, end, old_phases = find_target_build_phases_span(text, target)
        if "/* Resources */" in old_phases:
            continue
        new_phases = f"\n\t\t\t\t{phase} /* Resources */," + old_phases
        text = text[:start] + new_phases + text[end:]

    text = text.replace(
        "/* Begin PBXSourcesBuildPhase section */",
        resources_section + "\n\n/* Begin PBXSourcesBuildPhase section */",
    )
    text = text.replace(
        "knownRegions = (\n\t\t\t\tBase,\n\t\t\t\ten,\n\t\t\t);",
        "knownRegions = (\n\t\t\t\tBase,\n\t\t\t\ten,\n\t\t\t\t\"zh-Hans\",\n\t\t\t\tug,\n\t\t\t\t\"ug-Latn\",\n\t\t\t);",
    )

    PBX.write_text(text, encoding="utf-8")
    print(f"Patched {len(RESOURCES)} resources into {PBX.name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
