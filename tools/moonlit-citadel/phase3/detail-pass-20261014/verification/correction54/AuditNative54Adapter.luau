--!nonstrict
local Adapter={}
function Adapter.Run(context)
    assert(context and context.frozenNativeAudit53 and context.expected and context.expected.source>53,
        "Inject the unchanged native audit and exact corrective candidate identity")
    assert(context.baseline52SnapshotSHA256=="3eda16621db02dcfc6235f8e90ce698d7c2d5dab4f5e1957610fa41dee4dcc7a",
        "Reference the immutable fresh Source52 snapshot")
    for _,name in {"editable","stored"} do
        assert(context.before[name].records[""].attrs.SourceRevision==52,"Compare the correction against fresh Source52")
    end
    local supplied=table.clone(context)
    supplied.afterSnapshotName=context.afterSnapshotName or "AfterRestoredSnapshot"..context.expected.source
    local report=context.frozenNativeAudit53.Run(supplied)
    report.baseline52SnapshotSHA256=context.baseline52SnapshotSHA256
    report.original53ReviewStatus="Held separately; no prior score transferred"
    report.correctionSource=context.expected.source
    return report
end
return Adapter
