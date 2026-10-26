return function(root)
 local rows={}
 for _,p in root:GetDescendants() do
  if p:IsA("BasePart") then
   local row={p:GetFullName():sub(#root:GetFullName()+2),p.ClassName,tostring(p.CanCollide),tostring(p.CanQuery),tostring(p:GetAttribute("Role"))}
   for _,n in {p.CFrame:GetComponents()} do table.insert(row,string.format("%.5f",if math.abs(n)<.000005 then 0 else n)) end
   for _,n in {p.Size.X,p.Size.Y,p.Size.Z,p.Color.R,p.Color.G,p.Color.B,p.Transparency} do table.insert(row,string.format("%.5f",if math.abs(n)<.000005 then 0 else n)) end
   table.insert(rows,table.concat(row,"|"))
  end
 end
 table.sort(rows)
 local hash=2166136261
 for _,row in rows do
  for i=1,#row do
   local h=bit32.bxor(hash,string.byte(row,i))
   local low,high=bit32.band(h,65535),bit32.rshift(h,16)
   hash=(low*403+bit32.band(low*256+high*403,65535)*65536)%4294967296
  end
 end
 return {parts=#rows,hash=string.format("%08x",hash)}
end
