#!/usr/bin/env python3
"""Package Liverpool's Labrador left-limb STL meshes into selectable RealityKit scenes."""

import argparse
import json
from pathlib import Path
import subprocess
from tempfile import TemporaryDirectory

import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
GEOMETRY = "Models & Data/Labrador/Model & Geometry/Labrador_Geometries"
STL_TRIANGLE = np.dtype([("normal", "<f4", 3), ("points", "<f4", (3, 3)), ("attribute", "<u2")])


def read_stl(path):
    data = path.read_bytes()
    triangles = np.frombuffer(data, dtype=STL_TRIANGLE, offset=84)["points"]
    positions, inverse = np.unique(np.round(triangles.reshape(-1, 3), 5), axis=0, return_inverse=True)
    faces = inverse.reshape(-1, 3)
    # Coordinates in the archived CT meshes are millimeters, with Y vertical.
    normals = np.zeros_like(positions)
    vertices = positions[faces]
    face_normals = np.cross(vertices[:, 1] - vertices[:, 0], vertices[:, 2] - vertices[:, 0])
    valid = np.linalg.norm(face_normals, axis=1) > 0.00001
    for corner in range(3):
        np.add.at(normals, faces[valid, corner], face_normals[valid])
    normals /= np.maximum(np.linalg.norm(normals, axis=1, keepdims=True), 0.00001)
    return positions, faces[valid], normals


def surface(mesh, predicate):
    positions, faces, normals = mesh
    centers = positions[faces].mean(axis=1)
    selected = faces[predicate(*centers.T)]
    if len(selected) == 0:
        raise ValueError("No triangles match the anatomical annotation")
    used, inverse = np.unique(selected, return_inverse=True)
    return positions[used], inverse.reshape(-1, 3), normals[used]


def shoulder(scapula, humerus):
    def glenoid(x, y, z):
        return (y < -68.5) & (x < 98) & (z < -1089)

    def head(x, y, z):
        return (y > -91) & (z < -1097 + 0.23 * (y + 82)) & (x < 106)

    return {
        "scapula": surface(scapula, lambda x, y, z: ~glenoid(x, y, z)),
        "glenoid": surface(scapula, glenoid),
        "humerus": surface(humerus, lambda x, y, z: ~head(x, y, z)),
        "humeral_head": surface(humerus, head),
    }


def elbow(humerus, forearm):
    def radius(x, y, z):
        seam = np.interp(y, [-372, -301, -278, -244, -229, -215],
                         [-1101, -1101, -1101.5, -1103.8, -1105.7, -1105])
        return (y < -216) & (z > seam + 0.12 * (x - 94))

    def radial_head(x, y, z):
        return radius(x, y, z) & (y > -229.5)

    def olecranon(x, y, z):
        return ~radius(x, y, z) & (y > -212) & (z < -1108.5)

    return {
        "humerus": surface(humerus, lambda x, y, z: y < -177),
        "ulna": surface(forearm, lambda x, y, z: ~(radius(x, y, z) | olecranon(x, y, z))),
        "radius": surface(forearm, lambda x, y, z: radius(x, y, z) & ~radial_head(x, y, z)),
        "radial_head": surface(forearm, radial_head),
        "olecranon": surface(forearm, olecranon),
    }


def carpus(carpals, forearm):
    # The source merges adjacent bones. These are surface annotations, preserving the original geometry.
    def accessory(x, y, z):
        return (z < -1108.3 - 0.28 * (-373 - y)) & (y > -380.5) & (x > 72.5)

    def proximal(x, y, z):
        return y > -379.3 - 0.17 * (x - 72.0) + 0.07 * (z + 1102)

    def intermedioradial(x, y, z):
        return proximal(x, y, z) & ~accessory(x, y, z) & (x < 74.8 - 0.17 * (z + 1102))

    def distal(x, y, z):
        return ~proximal(x, y, z) & ~accessory(x, y, z) & (y > -388.2 - 0.18 * (x - 72.0))

    return {
        "accessory": surface(carpals, accessory),
        "intermedioradial": surface(carpals, intermedioradial),
        "ulnar": surface(carpals, lambda x, y, z: proximal(x, y, z) & ~(accessory(x, y, z) | intermedioradial(x, y, z))),
        "distal_row": surface(carpals, distal),
        "metacarpal_context": surface(carpals, lambda x, y, z: ~(accessory(x, y, z) | proximal(x, y, z) | distal(x, y, z))),
        "forearm_context": surface(forearm, lambda x, y, z: y < -348),
    }


def triples(values):
    return ", ".join(f"({x:.7g}, {y:.7g}, {z:.7g})" for x, y, z in values)


def write_scene(name, parts, directory):
    all_positions = np.concatenate([positions for positions, _, _ in parts.values()])
    center = (all_positions.min(axis=0) + all_positions.max(axis=0)) / 2
    # Rotate so the left lateral surface faces the virtual camera.
    orientation = np.array([[0, 0, -1], [0, 1, 0], [1, 0, 0]], dtype=float)
    blocks = []
    for identifier, (positions, faces, normals) in parts.items():
        points = ((positions - center) @ orientation.T) * .001
        normals = normals @ orientation.T
        indices = ", ".join(map(str, faces.ravel()))
        counts = ", ".join(["3"] * len(faces))
        blocks.append(f'''
    def Mesh "{identifier}" {{
        uniform token subdivisionScheme = "none"
        uniform bool doubleSided = true
        int[] faceVertexCounts = [{counts}]
        int[] faceVertexIndices = [{indices}]
        point3f[] points = [{triples(points)}]
        normal3f[] normals = [{triples(normals)}] (interpolation = "vertex")
        float3[] extent = [{triples([points.min(0), points.max(0)])}]
    }}
''')
    (directory / f"{name}.usda").write_text(f'''#usda 1.0
(
    defaultPrim = "{name}"
    metersPerUnit = 1
    upAxis = "Y"
)
def Xform "{name}" {{
    {''.join(blocks)}
}}
''')
    subprocess.run(["usdcat", f"{name}.usda", "-o", f"{name}.usdc"], cwd=directory, check=True)
    subprocess.run(["usdzip", f"{name}.usdz", f"{name}.usdc"], cwd=directory, check=True)
    return directory / f"{name}.usdz"



def write_thumbnail(name, parts, directory):
    triangles = np.concatenate([positions[faces] for positions, faces, _ in parts.values()])
    # Show the anterolateral surface in the same orientation used in the viewer.
    x, y, z = triangles.transpose(2, 0, 1)
    projection = np.stack([-0.94 * z + 0.34 * x, -y], axis=-1)
    extent = np.ptp(projection, axis=(0, 1))
    center = (projection.max(axis=(0, 1)) + projection.min(axis=(0, 1))) / 2
    pixels = (projection - center) * (180 / extent.max()) + 120
    normals = np.cross(triangles[:, 1] - triangles[:, 0], triangles[:, 2] - triangles[:, 0])
    normals /= np.maximum(np.linalg.norm(normals, axis=1, keepdims=True), 0.00001)
    luminance = 0.35 + 0.65 * np.clip(normals @ [0.7, 0.6, -0.39], 0, 1)
    depths = (0.94 * x + 0.34 * z).mean(axis=1)
    image = Image.new("RGBA", (240, 240))
    draw = ImageDraw.Draw(image)
    for index in np.argsort(depths):
        color = tuple(int(channel * luminance[index]) for channel in (243, 226, 192))
        draw.polygon([tuple(vertex) for vertex in pixels[index]], fill=(*color, 255))

    assets = directory / f"{name}_preview.imageset"
    assets.mkdir(exist_ok=True)
    image.resize((120, 120), Image.Resampling.LANCZOS).save(assets / "preview.png")
    (assets / "Contents.json").write_text(json.dumps({
        "images": [{"filename": "preview.png", "idiom": "universal", "scale": "2x"}],
        "info": {"author": "xcode", "version": 1},
    }, indent=2) + "\n")

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("archive", type=Path, help="Liverpool Models & Data.7z archive")
    args = parser.parse_args()
    output = ROOT / "AnatomiaCanina" / "Models"
    output.mkdir(parents=True, exist_ok=True)
    with TemporaryDirectory() as working:
        working = Path(working)
        names = ["L SCAP.stl", "L HUM.stl", "L RAD.stl", "L MAN_carpals.stl"]
        sources = [f"{GEOMETRY}/{name}" for name in names]
        subprocess.run(["tar", "-xf", str(args.archive.resolve()), "-C", working, *sources], check=True)
        scapula, humerus, forearm, carpals = [read_stl(working / source) for source in sources]
        scenes = {
            "shoulder": shoulder(scapula, humerus),
            "elbow": elbow(humerus, forearm),
            "carpus": carpus(carpals, forearm),
        }
        for name, parts in scenes.items():
            generated = write_scene(name, parts, working)
            (output / generated.name).write_bytes(generated.read_bytes())
            write_thumbnail(name, parts, output.parent / "Assets.xcassets")
            print(name, {part: len(mesh[1]) for part, mesh in parts.items()}, flush=True)


if __name__ == "__main__":
    main()
