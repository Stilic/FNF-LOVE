return {
	DEBUG_MODE = true,
	splashScreen = false,

	title = "Friday Night Funkin' Löve",
	file = "FNF-LOVE",
	icon = "art/icon.png",
	version = "0.7.1",
	package = "com.stilic.fnflove",
	width = 1280,notemods
	height = 720,
	FPS = 60,
	company = "Stilic",

	flags = {
		checkForUpdates = false,

		loxelInitialAutoPause = true,
		loxelInitialParallelUpdate = true,
		loxelInitialAsyncInput = false,

		loxelForceRenderCameraComplex = false,
		loxelDisableRenderCameraComplex = false,
		loxelDisableScissorOnRenderCameraSimple = false,
		loxelDefaultClipCamera = true
	}
}
