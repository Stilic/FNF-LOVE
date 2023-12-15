return {
	DEBUG_MODE = true,
	splashScreen = true,

	title = "Friday Night Funkin' LÖVE",
	file = "FNF-LOVE",
	icon = "art/icon.png",
	version = "0.6.4",
	package = "com.stilic.fnflove",
	width = 1280,
	height = 720,
	company = "Stilic",

	flags = {
		CheckForUpdates = false,

		InitialAutoFocus = false,
		ParallelUpdate = false, -- VERY CPU INTENSIVE

		LoxelForceRenderCameraComplex = false,
		LoxelDisableRenderCameraComplex = false,
		LoxelDisableScissorOnRenderCameraSimple = false,
		LoxelDefaultClipCamera = true,
		--this is stupid LoxelRenderTransparentGraphics = false,
	}
}
