
MixerControl : GlobalControlBase {
	var <>mixerGui, controlKey;

	update { |bus, msg|
		value = msg[0];
		(mixerGui.notNil).if({
			mixerGui.updateView(controlKey, value)
		});
	}

	watch { |key, gui, count = 0|
		mixerGui = gui;
		controlKey = key;
		super.watch(count);
	}

	stopWatching { |count = 0|
		mixerGui = controlKey = nil;
		super.stopWatching(count);
	}

	makeGUI {}	// MixerChannelGUI class does this
}