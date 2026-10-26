local storage=game:GetService("ServerStorage");local candidate=workspace.KeyboardCircuit_P2_C01;local kit=storage.CourseAssetKits.KeyboardCircuit_Phase2EditableKit_K02;local buffers=shared.KCP2FinalBuffers;local baseline=shared.KCP2NativeRecoveryReceipt04.baseline;local proof=storage.KeyboardCircuitP2NativeRecoveryProof04;local reopenedCourse=proof.ReopenedCourse:GetChildren()[1];local reopenedKit=proof.ReopenedKit:GetChildren()[1];local rebuilt=proof.RebuiltCourse:GetChildren()[1];
local function relative(model,item)
 return item:GetFullName():sub(#model:GetFullName()+2)
end
local function numbers(...)
 local values={...}
 for i,v in values do values[i]=string.format("%.3f",if math.abs(v)<.0005 then 0 else v) end
 return table.concat(values,",")
end
local function geometry(model)
 local entries={}
 for _,v in model:GetDescendants() do
  local path=relative(model,v)
  local row=v.ClassName.."|"..path
  if v:IsA("BasePart") then
   row..="|"..numbers(v.CFrame:GetComponents()).."|"..numbers(v.Size.X,v.Size.Y,v.Size.Z)
   row..="|"..numbers(v.Color.R,v.Color.G,v.Color.B).."|"..v.Material.Name.."|"..tostring(v.CanCollide).."|"..tostring(v.CanTouch).."|"..tostring(v.CanQuery).."|"..tostring(v.CastShadow)
   if v:IsA("MeshPart") then row..="|"..v.MeshId.."|"..v.TextureID.."|"..v.CollisionFidelity.Name end
  elseif v:IsA("TextLabel") then row..="|"..v.Text.."|"..v.Font.Name
  elseif v:IsA("ObjectValue") then row..="|"..(if v.Value and v.Value:IsDescendantOf(model) then relative(model,v.Value) else tostring(v.Value))
  elseif v:IsA("Vector3Value") then row..="|"..numbers(v.Value.X,v.Value.Y,v.Value.Z)
  end
  table.insert(entries,row)
 end
 table.sort(entries)
 return entries
end
local function compare(left,right)
 local a,b=geometry(left),geometry(right)
 local differences={}
 for i=1,math.max(#a,#b) do if a[i]~=b[i] and #differences<12 then table.insert(differences,{index=i,left=a[i],right=b[i]}) end end
 local sourceFailures={}
 for _,v in left.SourceSnapshot:GetChildren() do if v.Source~=right.SourceSnapshot[v.Name].Source then table.insert(sourceFailures,v.Name) end end
 local externalReferences={}
 for _,v in right:GetDescendants() do
  if v:IsA("ObjectValue") and v.Value and not v.Value:IsDescendantOf(right) then table.insert(externalReferences,relative(right,v)) end
  if v:IsA("Constraint") then for _,name in {"Attachment0","Attachment1"} do local attachment=v[name];if attachment and not attachment:IsDescendantOf(right) then table.insert(externalReferences,relative(right,v).."."..name) end end end
 end
 return {passed=#a==#b and #differences==0 and #sourceFailures==0 and #externalReferences==0,leftCount=#a,rightCount=#b,differences=differences,sourceFailures=sourceFailures,externalReferences=externalReferences}
end
local receipt={candidate="KC_P2_C01",constructionIteration=4,uiRevision="KC_P2_UI01",baseline=baseline,
roundTripCourse=compare(candidate,reopenedCourse),roundTripKit=compare(kit,reopenedKit),freshSourceRebuild=compare(candidate,rebuilt),
courseBytes=buffer.len(buffers.course),kitBytes=buffer.len(buffers.kit),proof=proof:GetFullName(),
boundary="Native engine serialization/reopening and fresh-identity source rebuild. Recovery proof is inert in ServerStorage; its copied scripts are disabled. Geometry compared at .001-stud precision; no whole-place save or publication."}
shared.KCP2NativeRecoveryReceipt04=receipt
return game:GetService("HttpService"):JSONEncode(receipt)

