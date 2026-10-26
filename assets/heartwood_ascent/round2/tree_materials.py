"""Portable colour/roughness atlases; the exported UVs do not need Blender shaders."""

from pathlib import Path
import math
import struct
import zlib


PALETTE = [
    ("cedar", (145, 86, 48), .91),
    ("sienna_shadow", (103, 61, 39), .94),
    ("amber_wood", (181, 113, 59), .89),
    ("olive_leaf", (79, 108, 43), .94),
    ("moss_leaf", (48, 86, 46), .96),
    ("young_leaf", (126, 153, 61), .91),
    ("peach_petal", (243, 172, 119), .88),
    ("gold_petal", (255, 218, 143), .86),
    ("pollen", (220, 150, 45), .89),
    ("wood_edge", (204, 149, 87), .92),
    ("fern", (74, 121, 57), .95),
    ("leaf_shadow", (33, 62, 37), .97),
    ("petal_tip", (255, 236, 182), .88),
    ("scale_avatar_blue", (40, 106, 166), .93),
    ("scale_avatar_head", (240, 184, 62), .93),
    ("study_ground", (107, 105, 83), .97),
]


def _png(path, size, pixels):
    def chunk(kind, value):
        return (struct.pack(">I", len(value)) + kind + value
                + struct.pack(">I", zlib.crc32(kind + value) & 0xffffffff))
    rows = b"".join(b"\0" + pixels[y * size * 4:(y + 1) * size * 4]
                    for y in range(size))
    path.write_bytes(b"\x89PNG\r\n\x1a\n"
                     + chunk(b"IHDR", struct.pack(">IIBBBBB", size, size, 8, 6, 0, 0, 0))
                     + chunk(b"IDAT", zlib.compress(rows, 6)) + chunk(b"IEND", b""))


def write_atlases(output_dir, selected=False):
    """Each tile has an eight-pixel gutter; UVs stay inside that gutter."""
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    size = 1024 if selected else 512
    tile = size // 4
    colour = bytearray(size * size * 4)
    roughness = bytearray(size * size * 4)
    for y in range(size):
        for x in range(size):
            index = (y // tile) * 4 + x // tile
            _, rgb, rough = PALETTE[index]
            u = (min(tile - 9, max(8, x % tile)) - 8) / (tile - 16)
            v = (min(tile - 9, max(8, y % tile)) - 8) / (tile - 16)
            noise = math.sin(x * 12.9898 + y * 78.233) * 43758.5453
            noise = (noise - math.floor(noise) - .5) * .026
            shade = 1.0 + noise
            if index in (0, 1, 2, 9):
                grain = u * 27 + .44 * math.sin(v * 8 + u * 6)
                seam = max(0, math.cos(grain * math.tau)) ** 18
                wide = .5 + .5 * math.sin(u * 46 + math.sin(v * 9))
                # Long, broken channels follow the sweep; large form carries the relief.
                shade += .07 * wide - .15 * seam * (.6 + .4 * math.sin(v * 13) ** 2)
            elif index in (3, 4, 5, 10, 11):
                midrib = math.exp(-abs(u - .5) * 55)
                vein = max(0, math.cos((v * 6 + abs(u - .5) * 4) * math.tau)) ** 18
                shade += .08 * midrib + .055 * vein - .065 * abs(u - .5)
            elif index in (6, 7, 12):
                shade += .025 * math.sin(u * 80) + .07 * (1 - v)
            offset = (y * size + x) * 4
            colour[offset:offset + 4] = bytes(
                [max(0, min(255, round(channel * shade))) for channel in rgb] + [255])
            r = round(rough * 255)
            roughness[offset:offset + 4] = bytes((r, r, r, 255))
    colour_path = output_dir / "heartwood-colour.png"
    roughness_path = output_dir / "heartwood-roughness.png"
    _png(colour_path, size, colour)
    _png(roughness_path, size, roughness)
    return colour_path, roughness_path, size


def tile_uv(index, u, v, atlas_size):
    gutter = 8 / (atlas_size / 4)
    u = gutter + (1 - 2 * gutter) * max(0, min(1, u))
    v = gutter + (1 - 2 * gutter) * max(0, min(1, v))
    return ((index % 4 + u) / 4, 1 - (index // 4 + v) / 4)


def make_materials(bpy, colour_path, roughness_path, prefix):
    material = bpy.data.materials.new(prefix + "_PortableAtlas")
    material.use_nodes = True
    material.diffuse_color = (.45, .29, .13, 1)
    nodes = material.node_tree.nodes
    bsdf = nodes.get("Principled BSDF")
    bsdf.inputs["Roughness"].default_value = .92
    bsdf.inputs["Metallic"].default_value = 0
    if "Specular IOR Level" in bsdf.inputs:
        bsdf.inputs["Specular IOR Level"].default_value = .22
    colour = nodes.new("ShaderNodeTexImage")
    colour.name = "Roblox_colour_atlas"
    colour.image = bpy.data.images.load(str(colour_path), check_existing=True)
    colour.image.pack()
    colour.interpolation = "Linear"
    material.node_tree.links.new(colour.outputs["Color"], bsdf.inputs["Base Color"])
    rough = nodes.new("ShaderNodeTexImage")
    rough.name = "Roblox_roughness_atlas"
    rough.image = bpy.data.images.load(str(roughness_path), check_existing=True)
    rough.image.pack()
    rough.image.colorspace_settings.name = "Non-Color"
    material.node_tree.links.new(rough.outputs["Color"], bsdf.inputs["Roughness"])
    clay = bpy.data.materials.new(prefix + "_SilhouetteClay")
    clay.use_nodes = True
    clay.node_tree.nodes.get("Principled BSDF").inputs["Base Color"].default_value = (.53, .47, .38, 1)
    clay.node_tree.nodes.get("Principled BSDF").inputs["Roughness"].default_value = .94
    return material, clay
