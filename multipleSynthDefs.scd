MIDIIn.connectAll;

(

SynthDef.new(\noiseySaw, {|carrier= 100,
	syncRate = 1,
	freqModFreq = 0.2,
	freqAmp = 0.1,
	freqPhase = 0,
	ampModFreq = 1,
	ampModAmp = 0,
	ampPhase = 0, // it might not make sense to adjust phases as they will go out of sync in anycase
	lfNoiseFreq = 1,
	lfNoiseAmp = 0.2,
	filFreq = 440,
	rq = 1,
	amp = 0.1,
	lfFreq = 10,
	lfAmp = 100,
	pan = 0,
	attackTime = 0.01,
	decayTime = 0.01,
	sustainLevel = 1,
	releaseTime = 1,
	gate = 1|

	var
	ampMod = LFTri.ar(ampModFreq, ampPhase, ampModAmp, 1-ampModAmp) * amp,
	//some noise for dirtying amp
	noise = LFNoise1.ar(lfNoiseFreq,lfNoiseAmp,1-lfNoiseAmp),
	freqNoise = LFNoise1.kr(lfFreq, lfAmp),
	freqMod = SinOsc.kr(freqModFreq,freqPhase,carrier*freqAmp,carrier),
	output = SyncSaw.ar(
		freqMod + freqNoise,
		syncRate * carrier, //swap freqMod for carrier for sweep effect
		ampMod * noise),
	filtered = BPF.ar(output, filFreq, rq),
	sig = Pan2.ar(filtered,pan);

	sig = sig * EnvGen.ar(Env.adsr(attackTime, decayTime, sustainLevel,releaseTime),gate,doneAction:2);

	Out.ar(0,sig);

}).send(s);

SynthDef.new(\smoothSine,{|
	carrier= 100,
	freqModFreq = 0.2,
	freqAmp = 0.1,
	freqPhase = 0,
	ampModFreq = 1,
	ampModAmp = 0,
	ampPhase = 0, // it might not make sense to adjust phases as they will go out of sync in anycase
	lfNoiseFreq = 1,
	lfNoiseAmp = 0.2,
	amp = 0.1,
	lfFreq = 10,
	lfAmp = 100,
	pan = 0,
	attackTime = 0.01,
	decayTime = 0.01,
	sustainLevel = 1,
	releaseTime = 1,
	gate = 1|

	var
	ampMod = LFTri.ar(ampModFreq, ampPhase, ampModAmp, 1-ampModAmp) * amp,
	//some noise for dirtying amp
	noise = LFNoise1.ar(lfNoiseFreq,lfNoiseAmp,1-lfNoiseAmp),
	freqNoise = LFNoise1.kr(lfFreq, lfAmp),
	freqMod = SinOsc.kr(freqModFreq,freqPhase,carrier*freqAmp,carrier),
	output = SinOsc.ar(
		freqMod + freqNoise,
		0,
		ampMod * noise),

	sig = Pan2.ar(output,pan);

	sig = sig * EnvGen.ar(Env.adsr(attackTime, decayTime, sustainLevel,releaseTime),gate,doneAction:2);

	Out.ar(0,sig);
}).send(s);

)


(
//create the new synth with values according to the knobs
~startSynth = {|key, touchVel|
	var vals = [], spec = ControlSpec(0,127,\lin,1,0);

	~synthPotControls.at(key).do({|v,i|
		vals = vals.add(v[0]);
		vals = vals.add(v[1].map(v[2]));
	});

	~synthSliderControls.at(key).do({|v,i|

		var ok = (v[0] != \amp ).or(touchVel == nil);
		if(ok == true,{
			vals = vals.add(v[0]);
			vals = vals.add(v[1].map(v[2]));
			vals.postln;
		});
	});

	if(touchVel != nil,{

		vals = vals.add(\amp);
		vals = vals.add(spec.unmap(touchVel));
	});

	~synths.put(key,Synth.new(~synthTypes.at(key),  vals));

	if(~synthToggles.at(key) == true,{
		~switchSynth.value(key);
	});

};

~switchSynth = {|key|
	~cSynth = ~synths.at(key.asSymbol);
	~cSynthKey = key.asSymbol;
};

~releaseSynth = {|key|
	~synths.at(key).set(\gate, 0);
	if(~synths.at(key) == ~cSynth, {~cSynth = nil});
	~synths.removeAt(key);
	{
		~synthToggles.put(key, false);
	}.defer;
};

~setSynthType = {|synth_key, synth_type|
	var potControls, sliderControls;
	~synthTypes.put(synth_key, synth_type);
	potControls = ~potTemplates.at(synth_type).collectCopy({|x|x.collectCopy({|y|y})});
	~synthPotControls.put(synth_key,
		potControls
	);
	sliderControls = ~sliderTemplates.at(synth_type).collectCopy({|x|x.collectCopy({|y|y})});
	~synthSliderControls.put(synth_key,
		sliderControls
	);
};

)


(

~potTemplates = Dictionary();
~sliderTemplates = Dictionary();

~potTemplates.put(\noiseySaw, [
		[\carrier, ControlSpec.new(10,400,'exp'), 0.5],
		[\syncRate, ControlSpec.new(1,50,'exp'), 0.5],
		[\freqModFreq, ControlSpec.new(0.1,50,'exp'), 0.5],
		[\freqAmp, ControlSpec.new(0,1,'lin'), 0],
		[\ampModFreq, ControlSpec.new(0.1,50,'exp'), 0.5],
		[\ampModAmp, ControlSpec.new(0,1,'lin'), 0],
		[\filFreq, ControlSpec.new(10,4000,'exp'), 200],
		[\rq, ControlSpec.new(0.01,1,'lin'), 0.5],
	]);

~potTemplates.put(\smoothSine, [
		[\carrier, ControlSpec.new(10,400,'exp'), 0.5],
		[\lfNoiseFreq, ControlSpec.new(1,25,'exp'), 0.5],
		[\freqModFreq, ControlSpec.new(0.1,50,'exp'), 0.5],
		[\freqAmp, ControlSpec.new(0,1,'lin'), 0],
		[\ampModFreq, ControlSpec.new(0.1,50,'exp'), 0.5],
		[\ampModAmp, ControlSpec.new(0,1,'lin'), 0],
		[\lfFreq, ControlSpec.new(1,25,'exp'), 10],
		[\lfAmp, ControlSpec.new(0.01,2000,'exp'), 0.01],
	]);

~sliderTemplates.put(\noiseySaw, [
		[\amp,  ControlSpec.new(0,1,'lin'), 0.1],
		[\pan,  ControlSpec.new(-1,1,'lin'), 0],
		[\attackTime,  ControlSpec.new(0.01,5,'lin'), 0.01],
		[\releaseTime,  ControlSpec.new(0.01,5,'lin'), 0.1],
		[\lfNoiseFreq, ControlSpec.new(1,25,'exp'), 0.5],
		[\lfNoiseAmp, ControlSpec.new(0,1,'lin'), 0],
		[\lfFreq, ControlSpec.new(1,25,'exp'), 10],
		[\lfAmp, ControlSpec.new(0.01,2000,'exp'), 0.01],
	]);

~sliderTemplates.put(\smoothSine, [
		[\amp,  ControlSpec.new(0,1,'lin'), 0.1],
		[\pan,  ControlSpec.new(-1,1,'lin'), 0],
		[\attackTime,  ControlSpec.new(0.01,5,'lin'), 0.01],
		[\releaseTime,  ControlSpec.new(0.01,5,'lin'), 0.1],
		[\lfNoiseAmp, ControlSpec.new(0,1,'lin'), 0],
	]);

~synthPotControls = Dictionary();
~synthSliderControls = Dictionary();
~synthToggles = Dictionary();
~synthTypes = Dictionary();

8.do{|i|
	var val = 36 + i;
	~setSynthType.value(("synth_"++val).asSymbol, \noiseySaw);
	~synthToggles.put(("synth_"++val).asSymbol, false);
};

~synths = Dictionary();
~cSynth = nil;
~cSynthKey = "synth_36".asSymbol;

)



//freeAll
(
~synths.keys.do{|key|
	~releaseSynth.value(key);
	~synthToggles.put(key, false);
};
)




