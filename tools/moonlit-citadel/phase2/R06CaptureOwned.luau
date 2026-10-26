local function capture(port, label, position, target)
	assert(game.PlaceId == 0 and game.GameId == 0 and not game:GetService("RunService"):IsRunning(), "Owned fixture Edit capture only")
	assert(label:match("^[%w_]+$"))
	local service = game:GetService("StudioCaptureService")
	assert(service:CanCaptureScreenshot(), "Native plugin capture permission unavailable")
	local camera, H = workspace.CurrentCamera, game:GetService("HttpService")
	local oldFrame, oldFocus, oldType, oldHttp = camera.CFrame, camera.Focus, camera.CameraType, H.HttpEnabled
	local result = {label = label, cameraPosition = {position.X, position.Y, position.Z}, target = {target.X, target.Y, target.Z}, uiCaptureMode = "All"}
	local ok, reason = xpcall(function()
		camera.CameraType, camera.CFrame, camera.Focus = Enum.CameraType.Scriptable, CFrame.lookAt(position, target), CFrame.new(target)
		task.wait(.3)
		local shot = service:CaptureScreenshot({Format = Enum.StudioCaptureScreenshotFormat.PNG, UICaptureMode = Enum.UICaptureMode.All})
		local deadline = os.clock() + 15
		repeat task.wait(.05) until shot.BufferStatus == Enum.StudioCaptureBufferStatus.Ready or shot.BufferStatus == Enum.StudioCaptureBufferStatus.Error or os.clock() > deadline
		assert(shot.BufferStatus == Enum.StudioCaptureBufferStatus.Ready, game.HttpService:JSONEncode(shot:GetErrors()))
		local bytes = shot:GetBuffer()
		local encoded = buffer.tostring(game:GetService("EncodingService"):Base64Encode(bytes))
		H.HttpEnabled = true
		local payload = {candidate = "MC_P2_C01_R06", label = label, mimeType = "image/png", base64 = encoded, capture = result}
		local reply = H:RequestAsync({Url = "http://127.0.0.1:" .. port .. "/MC_P2_R06_view_" .. label .. ".json", Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = H:JSONEncode(payload)})
		assert(reply.Success, reply.StatusCode)
		result.receipt, result.imageBytes = H:JSONDecode(reply.Body), buffer.len(bytes)
	end, debug.traceback)
	camera.CFrame, camera.Focus, camera.CameraType, H.HttpEnabled = oldFrame, oldFocus, oldType, oldHttp
	result.ok, result.failure = ok, if ok then nil else tostring(reason)
	result.cameraRestored, result.httpRestored = camera.CFrame == oldFrame and camera.Focus == oldFocus and camera.CameraType == oldType, H.HttpEnabled == oldHttp
	return H:JSONEncode(result)
end
return capture
