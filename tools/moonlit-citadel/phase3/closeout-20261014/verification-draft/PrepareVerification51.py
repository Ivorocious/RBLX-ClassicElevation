from pathlib import Path

old = Path(__file__).resolve().parent
new = old.parent / "verification51"
new.mkdir(exist_ok=True)
old_plan = "74c77a93fd4a4c3e477f54333edc67d21b5d0bcc92b39084c49c21891cf59eb4"
new_plan = "95352d0a83b16c50acb3c6e6e6c99a4d1deffb19cac81105783b1bea9e240f03"
old_packet = "2aca31596c1264413a10c554ae81ee7c42630a8732567c98fb7c276ecd4fe2c1"
new_packet = "016c10fdcc4d70a75af996216a2cef4687b773a3a42bc7ea389b4608273e62c4"
names = ["GeometryAudit49.luau", "ExpectedAppearance50.luau", "AuditNative50.luau", "RunAudit50.luau",
         "TestAuditNative50.luau", "PrepareApprovedTemplates50.luau", "PrepareSourceSpecs50.py", "CompileAudit50.luau", "FreezeVerification50.py"]
for name in names:
    text = (old / name).read_text(encoding="utf8")
    for source, target in {
        "verification-draft/": "verification51/", "Source50": "Source51", "Source 50": "Source 51",
        "source50": "source51", 'sourceRevision"] == 50': 'sourceRevision"] == 51',
        'buildRevision"] == 44': 'buildRevision"] == 45',
        "source=50": "source=51", "build=44": "build=45", '"source": 50': '"source": 51', '"build": 44': '"build": 45',
        "SourceRevision',50": "SourceRevision',51", "BuildRevision',44": "BuildRevision',45",
        "MC_P3_CLOSEOUT_FC01": "MC_P3_CLOSEOUT_FC02", "combined-plan50": "combined-plan51",
        "approved-templates50": "approved-templates51", "source-specs50": "source-specs51", "audit-fixtures50": "audit-fixtures51",
        "fixture-failure50": "fixture-failure51", "verification-freeze50": "verification-freeze51",
        "ExpectedAppearance50": "ExpectedAppearance51", "AuditNative50": "AuditNative51", "RunAudit50": "RunAudit51",
        "units=233": "units=243", "meshes=609": "meshes=639", "triangles=197402": "triangles=198722",
        "expectedUnits=233": "expectedUnits=243", "expectedMeshes=609": "expectedMeshes=639", "expectedTriangles=197402": "expectedTriangles=198722",
        "#exports.units==233": "#exports.units==243", "PlanUnits',233": "PlanUnits',243", "MeshParts',609": "MeshParts',639",
        "PlacedTriangles',197402": "PlacedTriangles',198722", '"units": 233': '"units": 243', '"meshes": 609': '"meshes": 639',
        '"triangles": 197402': '"triangles": 198722', old_plan: new_plan, old_packet: new_packet,
    }.items():
        text = text.replace(source, target)
    (new / name.replace("50", "51")).write_text(text, encoding="utf8")
print(new)
