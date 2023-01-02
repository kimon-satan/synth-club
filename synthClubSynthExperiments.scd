



(
x = {|carrier= 100,
	syncRate = 1,
	freqModFreq = 0.2,
	freqAmp = 0.1,
	freqPhase = 0,
	ampModFreq = 1,
	ampModAmp = 0,
	ampPhase = 0, // it might not make sense to adjust phases as they will go out of sync in anycase
	lfNoiseFreq = 1,
	lfNoiseAmp = 0.2,
	amp = 0.1,
	pan = 0
	|

	var freqMod = SinOsc.kr(freqModFreq,freqPhase,carrier*freqAmp,carrier),
	ampMod = LFTri.ar(ampModFreq, ampPhase, ampModAmp, 1-ampModAmp) * amp,
	//some noise for dirtying amp
	noise = LFNoise1.ar(lfNoiseFreq,lfNoiseAmp,1-lfNoiseAmp);

	Pan2.ar(SyncSaw.ar(
		freqMod,
		syncRate * freqMod, //swap freqMod for carrier for sweep effect
		ampMod * noise),
	pan);

}.play;
)

x.set(\lfNoiseFreq, 10);
x.set(\lfNoiseAmp, 0.5);

x.set(\syncRate, 4);



