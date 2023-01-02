(
SynthDef.new(\noiseModSaw2, {|noiseFreq=0, noiseMul=0|

	var freqs = NamedControl.kr(\freqs, [300, 400, 500, 600]);

	var bank = Array.fill(4,{|i|

		var noiseMod = LFNoise1.ar(10,10);
		Saw.ar(freqs[i]+noiseMod,0.1)
	});
	var sig = Splay.ar(bank);
	Out.ar(0,sig);
}).add;
)

(
a.free;
a = MIDIFunc.cc({|...args|
	args.postln;


});

)


x = Synth(\noiseModSaw2);
x.seti(\freqs, 2, 50);
