return {
	DEBUG_MODE = true,
	splashScreen = true,

	title = "Friday Night Funkin' Löve",
	file = "FNF-LOVE",
	icon = "art/icon.png",
	version = "0.7.0",
	package = "com.stilic.fnflove",
	width = 1280,
	height = 720,
	company = "Stilic",

	flags = {
		CheckForUpdates = false,

		InitialAutoFocus = true,
		InitialParallelUpdate = true,
		InitialAsyncInput = false,

		LoxelInitWindow = false,
		LoxelForceRenderCameraComplex = false,
		LoxelDisableRenderCameraComplex = false,
		LoxelDisableScissorOnRenderCameraSimple = false,
		LoxelDefaultClipCamera = true,
		LoxelShowPrintsInScreen = false
	}
}
