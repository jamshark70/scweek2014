(Platform.userExtensionDir +/+ "psSet-event-type.scd").load;

StartUp.add {
	// condition should be true in 3.6, false in 3.7
	if(SynthDescLib.global['system_setbus_control_1'].isNil) {
		(1 .. SystemSynthDefs.numChannels).do { arg i;
			SynthDef("system_setbus_audio_" ++ i, { arg out = 0, fadeTime = 0, curve = 0, gate = 1;
				var values = NamedControl.ir(\values, 0 ! i);
				var env = Env([In.ar(out, i), values, values], [1, 0], curve, 1);
				var sig = EnvGen.ar(env, gate + Impulse.kr(0), timeScale: fadeTime, doneAction: 2);
				ReplaceOut.ar(out, sig);
			}, [\ir, \kr, \ir, \kr]).add;

			SynthDef("system_setbus_control_" ++ i, { arg out = 0, fadeTime = 0, curve = 0;
				var values = NamedControl.ir(\values, 0 ! i);
				var env = Env([In.kr(out, i), values], [1], curve);
				var sig = EnvGen.kr(env, timeScale: fadeTime, doneAction: 2);
				ReplaceOut.kr(out, sig);
			}, [\ir, \kr, \ir]).add;
		};
	};

	if(Event.default.eventTypes[\fadeBus].isNil) {
		Event.addEventType(\fadeBus, #{ |server|
			var bundle, instrument, rate, bus;
			var array = ~array.as(Array);
			var numChannels = min(~numChannels.value ? 1, array.size);
			if(numChannels > SystemSynthDefs.numChannels) {
				Error(
					"Can't set more than % channels with current setup in SystemSynthDefs."
					.format(SystemSynthDefs.numChannels)
				).throw;
			};
			if (~id.isNil) {
				~id = if(~rate == \audio) { server.nextNodeID } { -1 };
			};
			instrument = "system_setbus_%_%".format(~rate.value ? \control, numChannels);
			// addToTail, so that old bus value can be overridden:
			bundle = [9, instrument, ~id, 1, ~group.asControlInput,
				"values", array,
				"out", ~out.value,
				"fadeTime", ~fadeTime,
				"curve", ~curve
			].asOSCArgArray;
			~schedBundle.value(~lag, ~timingOffset, server, bundle);
			if(~rate == \audio) { // control rate synth frees by itself, because bus holds the value
				~stopServerNode = { server.sendBundle(server.latency, [\n_set, ~id, \gate, 0]) }
			};
		});
	};
};
