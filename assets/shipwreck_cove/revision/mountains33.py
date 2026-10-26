"""Aim imported SC_R_Horizon28 front slopes toward the course center."""
import math


ASSET_ID = "SC_R_Horizon28"
COURSE_CENTER_XZ = (0.0, 0.0)


def _front_alignment(position, yaw_degrees):
    """Return alignment of imported local +Z with the course-center direction."""
    x, _, z = position
    inward_x = COURSE_CENTER_XZ[0] - x
    inward_z = COURSE_CENTER_XZ[1] - z
    length = math.hypot(inward_x, inward_z)
    if length == 0:
        raise ValueError("A Horizon28 placement cannot sit at the course center.")

    yaw = math.radians(yaw_degrees)
    # The importer adds 180 degrees after Blender Y is mapped to Roblox -Z.
    front_x = math.sin(yaw)
    front_z = math.cos(yaw)
    return (front_x * inward_x + front_z * inward_z) / length


def apply(data):
    """Rotate outward-facing Horizon28 placements to aim their local +Z inward."""
    for placement in data.get("placements", []):
        if placement.get("asset") != ASSET_ID:
            continue

        yaw = float(placement["yaw"])
        if _front_alignment(placement["p"], yaw) < 0:
            placement["yaw"] = (yaw + 180.0) % 360.0
            if placement["yaw"] >= 180.0:
                placement["yaw"] -= 360.0

    return data
