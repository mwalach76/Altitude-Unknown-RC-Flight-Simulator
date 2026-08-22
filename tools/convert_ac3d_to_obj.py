#!/usr/bin/env python3
"""Convert the subset of AC3D used by the FlightGear Rascal to Godot OBJ files."""

from __future__ import annotations

import argparse
from dataclasses import dataclass, field
from pathlib import Path
import shlex


CONTROL_PIVOTS = {
    "L_Aileron": (0.735, 0.139, 0.450),
    "R_Aileron": (0.735, 0.139, -0.450),
    "Elevator": (1.752, 0.051, 0.0),
    "Rudder": (1.752, 0.0, 0.0),
    "Prop_Disk": (0.0508, 0.0, 0.0),
}
CG_X_METERS = 0.92456  # 36.4 inches from the Rascal JSBSim definition.


@dataclass
class Surface:
    material: int
    refs: list[tuple[int, float, float]]


@dataclass
class AcObject:
    name: str = "unnamed"
    texture: bool = False
    vertices: list[tuple[float, float, float]] = field(default_factory=list)
    surfaces: list[Surface] = field(default_factory=list)
    children: list["AcObject"] = field(default_factory=list)


def parse_object(lines: list[str], index: int) -> tuple[AcObject, int]:
    obj = AcObject()
    while index < len(lines):
        line = lines[index].strip()
        index += 1
        if line.startswith("name "):
            obj.name = shlex.split(line)[1]
        elif line.startswith("texture "):
            obj.texture = True
        elif line.startswith("numvert "):
            count = int(line.split()[1])
            for _ in range(count):
                obj.vertices.append(tuple(map(float, lines[index].split())))
                index += 1
        elif line.startswith("numsurf "):
            count = int(line.split()[1])
            for _ in range(count):
                while not lines[index].startswith("SURF"):
                    index += 1
                index += 1
                material = int(lines[index].split()[1])
                index += 1
                ref_count = int(lines[index].split()[1])
                index += 1
                refs = []
                for _ in range(ref_count):
                    parts = lines[index].split()
                    refs.append((int(parts[0]), float(parts[1]), float(parts[2])))
                    index += 1
                obj.surfaces.append(Surface(material, refs))
        elif line.startswith("kids "):
            count = int(line.split()[1])
            for _ in range(count):
                if not lines[index].startswith("OBJECT"):
                    raise ValueError(f"Expected OBJECT at line {index + 1}")
                child, index = parse_object(lines, index + 1)
                obj.children.append(child)
            return obj, index
    return obj, index


def flatten(obj: AcObject) -> list[AcObject]:
    result = [obj] if obj.vertices and obj.surfaces else []
    for child in obj.children:
        result.extend(flatten(child))
    return result


def godot_vertex(vertex: tuple[float, float, float], pivot=None):
    ac_x, ac_y, ac_z = vertex
    if pivot:
        ac_x -= pivot[0]
        ac_y -= pivot[1]
        ac_z -= pivot[2]
        return ac_z, ac_y, ac_x
    return ac_z, ac_y, ac_x - CG_X_METERS


def write_obj(path: Path, objects: list[AcObject], pivot=None) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    vertex_offset = 1
    texcoord_offset = 1
    with path.open("w", encoding="utf-8") as output:
        output.write("# Converted from FlightGear/ArduPilot Rascal AC3D geometry\n")
        output.write("mtllib rascal.mtl\n")
        for obj in objects:
            output.write(f"o {obj.name}\n")
            for vertex in obj.vertices:
                x, y, z = godot_vertex(vertex, pivot)
                output.write(f"v {x:.7f} {y:.7f} {z:.7f}\n")
            faces_by_material: dict[str, list[str]] = {}
            for surface in obj.surfaces:
                if len(surface.refs) < 3:
                    continue
                face = []
                for vertex_index, u, v in surface.refs:
                    output.write(f"vt {u:.7f} {1.0 - v:.7f}\n")
                    face.append(f"{vertex_offset + vertex_index}/{texcoord_offset}")
                    texcoord_offset += 1
                material = f"{'tex_' if obj.texture else ''}mat{surface.material}"
                faces_by_material.setdefault(material, []).append("f " + " ".join(face))
            for material, faces in faces_by_material.items():
                output.write(f"usemtl {material}\n")
                output.write("\n".join(faces) + "\n")
            vertex_offset += len(obj.vertices)


def parse_materials(lines: list[str]):
    materials = []
    for line in lines:
        if not line.startswith("MATERIAL"):
            continue
        parts = line.split()
        rgb_index = parts.index("rgb")
        trans_index = parts.index("trans")
        materials.append((tuple(map(float, parts[rgb_index + 1:rgb_index + 4])), 1.0 - float(parts[trans_index + 1])))
    return materials


def write_mtl(path: Path, materials) -> None:
    with path.open("w", encoding="utf-8") as output:
        for index, (rgb, alpha) in enumerate(materials):
            for textured in (False, True):
                output.write(f"newmtl {'tex_' if textured else ''}mat{index}\n")
                output.write(f"Kd {rgb[0]} {rgb[1]} {rgb[2]}\n")
                output.write(f"d {alpha}\n")
                output.write("map_Kd rascal.png\n" if textured else "")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    lines = args.source.read_text(encoding="utf-8").splitlines()
    first_object = next(index for index, line in enumerate(lines) if line.startswith("OBJECT"))
    root, _ = parse_object(lines, first_object + 1)
    objects = flatten(root)
    controls = set(CONTROL_PIVOTS)
    write_obj(args.output / "rascal_body.obj", [obj for obj in objects if obj.name not in controls])
    for name, pivot in CONTROL_PIVOTS.items():
        matches = [obj for obj in objects if obj.name == name]
        if not matches:
            raise ValueError(f"Missing control surface {name}")
        write_obj(args.output / f"{name.lower()}.obj", matches, pivot)
    write_mtl(args.output / "rascal.mtl", parse_materials(lines))


if __name__ == "__main__":
    main()
