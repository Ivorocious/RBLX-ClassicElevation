"""Turn outward-facing SC_R_Horizon28 placements toward the course center."""
import math


ASSET_ID = "SC_R_Horizon28"
COURSE_CENTER_XZ = (0.0, 0.0)


def _inward_alignment(position, yaw_degrees):
    x, _, z = position
    dx = COURSE_CENTER_XZ[0] - x
    dz = COURSE_CENTER_XZ[1] - z
    length = math.hypot(dx, dz)
    if length == 0:
        raise ValueError("A Horizon28 placement cannot sit at the course center.")

    yaw = math.radians(yaw_degrees)
    # The presentation face is Roblox local -Z; Roblox Y yaw rotates it to
    # (-sin(yaw), -cos(yaw)) in the layout's XZ plane.
    face_x = -math.sin(yaw)
    face_z = -math.cos(yaw)
    return (face_x * dx + face_z * dz) / length


def apply(data):
    """Rotate only outward-facing Horizon28 placements by 180 degrees."""
    for placement in data.get("placements", []):
        if placement.get("asset") != ASSET_ID:
            continue

        yaw = float(placement["yaw"])
        if _inward_alignment(placement["p"], yaw) < 0:
            placement["yaw"] = (yaw + 180.0) % 360.0
            if placement["yaw"] >= 180.0:
                placement["yaw"] -= 360.0

    return data
