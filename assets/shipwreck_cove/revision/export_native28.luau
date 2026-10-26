assert(not game:GetService('RunService'):IsRunning(), 'Edit mode required')
assert(game.PlaceId==85558151074819 and game.CreatorId==86069177, 'Wrong experience')
local model=workspace.Course_ShipwreckCove
assert(model:GetAttribute('ShipwreckBuild')=='SC_MAP_28')
local blob=game:GetService('SerializationService'):SerializeInstancesAsync({model})
local raw=buffer.tostring(blob)
local alphabet='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local pieces=table.create(math.ceil(#raw/3))
local function digit(n) local i=n%64+1;return alphabet:sub(i,i) end
for i=1,#raw,3 do
    local a,b,c=string.byte(raw,i,i+2)
    local n=a*65536+(b or 0)*256+(c or 0)
    pieces[#pieces+1]=digit(math.floor(n/262144))..digit(math.floor(n/4096))
        ..(if b then digit(math.floor(n/64)) else '=')..(if c then digit(n) else '=')
end
local encoded=table.concat(pieces)
local name='__SC28NativeExport_'..model:GetAttribute('ReviewBuild')
assert(not game.ServerStorage:FindFirstChild(name),'This build already has an export; read existing chunks')
local output=Instance.new('Folder');output.Name=name
output:SetAttribute('Bytes',#raw);output:SetAttribute('Build',model:GetAttribute('ReviewBuild'))
for i=1,#encoded,100000 do
    local chunk=Instance.new('StringValue');chunk.Name=tostring(math.ceil(i/100000))
    chunk.Value=encoded:sub(i,i+99999);chunk.Parent=output
end
output.Parent=game.ServerStorage
return {folder=name,bytes=#raw,chunks=#output:GetChildren(),build=model:GetAttribute('ReviewBuild')}
