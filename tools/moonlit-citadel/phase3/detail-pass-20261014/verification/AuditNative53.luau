--!nonstrict
local Audit = {}
function Audit.Run(context)
    assert(context and context.snapshot and context.compare and context.geometry52 and context.adjustment52,
        "Provide the unchanged existing geometry/part oracle plus new snapshot/comparison helpers")
    assert(context.before and context.plan and context.expected and context.libraries,"Bind fresh52 recovery and final53 inputs")
    assert(context.sourceGuard and context.sourceGuard.pass and context.otherMaps and context.otherMaps.pass,
        "Fresh native source guard and other-map hashes are separate required proofs")
    assert(context.clearance and context.clearance.pass,"Bound actual DT01 occupied geometry clearance required")
    assert(context.expected.units<=350 and context.expected.meshes<=900 and context.expected.triangles<=420000
        and context.expected.architecture<=260,"Owner-approved combined detail budgets exceeded")
    assert(context.dtManifest and context.dtManifest.export_parts,"Use the measured DT01 export manifest")
    local costs={};for _,part in context.dtManifest.export_parts do assert(not costs[part.name]);costs[part.name]=part end
    local detailLedger={pass=true,models={}}
    for _,course in {context.editable,context.stored} do
        local world=assert(course.Decoration.Phase3World)
        local row={units=0,meshes=0,triangles=0}
        for _,data in context.plan.units or context.plan do
            if data.library~="DT01" then continue end
            local district=assert(world:FindFirstChild(data.district))
            local unit=assert(district:FindFirstChild(data.name))
            row.units+=1
            for _,part in unit:GetDescendants() do
                if not part:IsA("BasePart") then continue end
                assert(part:IsA("MeshPart"),"New detail geometry is authored mesh scenery")
                local measured=assert(costs[part.Name],"Bind new detail material mesh to its measured export")
                assert(measured.asset==data.asset,"Measured detail asset differs")
                local tag=part:GetAttribute("SourceTriangles")
                assert(tag==nil or tag==measured.triangles,"Measured new detail triangle tag differs")
                row.meshes+=1;row.triangles+=measured.triangles
            end
        end
        assert(row.units+243==context.expected.units and row.meshes+639==context.expected.meshes
            and row.triangles+198722==context.expected.triangles,"Exact additive measured detail ledger differs")
        assert(world:GetAttribute("PlacedTriangles")==context.expected.triangles,"Final triangle ledger differs")
        table.insert(detailLedger.models,row)
    end
    assert(context.adjustment52.ValidatePlan(context.plan.units or context.plan).pass,"Keep the exact accepted Source52 material adjustment")
    local S=context.snapshot
    local after=S.CaptureSession({editable=context.editable,stored=context.stored})
    local receipt,raw=S.SaveChunks(context.recovery,context.afterSnapshotName or "AfterSnapshot53",after)
    if context.afterSnapshotSink then context.afterSnapshotSink(raw,receipt) end
    local preservation=context.compare.Run(context.before,after,{plan=context.plan,expected=context.expected,detailAttributes=context.detailAttributes})
    local geometry=context.geometry52.Run({context.editable,context.stored},context.libraries,context.plan,{
        expectedIdentity={source=context.expected.source,build=context.expected.build,packet=context.expected.packet},
        expectedUnits=context.expected.units,expectedMeshes=context.expected.meshes,expectedCourses=2,
        adjustmentOracle=context.adjustment52,requireSourceGuard=false,
        approvedTemplateMetadata=context.approvedER01Metadata})
    local pass=preservation.pass and geometry.geometryPass
    return {pass=pass,source=context.expected.source,build=context.expected.build,candidate=context.expected.candidate,
        preservation=preservation,geometry=geometry,detailLedger=detailLedger,clearance=context.clearance,sourceGuard=context.sourceGuard,otherMaps=context.otherMaps,
        afterSnapshotReceipt=receipt,expected=context.expected,readOnlyExceptOwnedRecovery=true,
        nativeVisualAccepted=false,gameplayRerun=false,
        boundary="Exact fresh native existing-model comparison plus final-plan material-part geometry and additive detail clearance. Rendered detail quality is reviewed separately."}
end
return Audit
