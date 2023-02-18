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

~synthPotControls = Dictionary();
~synthSliderControls = Dictionary();
~synthToggles = Dictionary();

8.do{|i|
	var val = 36 + i;
	~synthPotControls.put(("synth_"++val).asSymbol,[
		[\carrier, ControlSpec.new(10,400,'exp'), 0.5],
		[\syncRate, ControlSpec.new(1,50,'exp'), 0.5],
		[\freqModFreq, ControlSpec.new(0.1,50,'exp'), 0.5],
		[\freqAmp, ControlSpec.new(0,1,'lin'), 0],
		[\ampModFreq, ControlSpec.new(0.1,50,'exp'), 0.5],
		[\ampModAmp, ControlSpec.new(0,1,'lin'), 0],
		[\filFreq, ControlSpec.new(10,4000,'exp'), 0],
		[\rq, ControlSpec.new(0,1,'lin'), 0],
	]);

	~synthSliderControls.put(("synth_"++val).asSymbol, [
		[\amp,  ControlSpec.new(0,1,'lin'), 0.1],
		[\pan,  ControlSpec.new(-1,1,'lin'), 0],
		[\attackTime,  ControlSpec.new(0.01,5,'lin'), 0.01],
		[\releaseTime,  ControlSpec.new(0.01,5,'lin'), 0.1],
		[\lfNoiseFreq, ControlSpec.new(1,25,'exp'), 0.5],
		[\lfNoiseAmp, ControlSpec.new(0,1,'lin'), 0],
		[\lfFreq, ControlSpec.new(1,25,'exp'), 10],
		[\lfAmp, ControlSpec.new(0.01,2000,'exp'), 0.01],
	]);

	~synthToggles.put(("synth_"++val).asSymbol, false);
};

~updatePot = {|potIndex, val|
	~pots[potIndex].value = val;
	~potsSynced[potIndex] = false;
	~pots[potIndex].setColors(knobColors: [Color.red]);
};

~synths = Dictionary();
~cSynth = nil;
~cSynthKey = "synth_36".asSymbol;

)

//reset pots to zero
8.do{|i|{~updatePot.value(i,0)}.defer};

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



	~synths.put(key,Synth.new(\noiseySaw,  vals));

	if(~synthToggles.at(key) == true,{
		~switchSynth.value(key);
	});

};



~switchSynth = {|key|
	~cSynth = ~synths.at(key.asSymbol);
	~cSynthKey = key.asSymbol;
	~synthPotControls.at(key).do({|v,i|
		{~updatePot.value(i, v[2])}.defer;
	});

	~synthSliderControls.at(key).do({|v,i|
		{~sliders[i].value = v[2];}.defer;
	});

	{
		~listView.value = ~findIndex.value(~listView.items, key);
		if(~synthToggles.at(key) == true,
			{~releaseButton.value = 1;
				~releaseButton.value.postln;
			},
			{~releaseButton.value = 0});
	}.defer;
};

~releaseSynth = {|key|
	~synths.at(key).set(\gate, 0);
	if(~synths.at(key) == ~cSynth, {~cSynth = nil});
	~synths.removeAt(key);
	{
		~synthToggles.put(key, false);
		~releaseButton.value = 0;
	}.defer;
};

~findIndex = {|list, key|
	var val = nil;
	list.do{|v,i| if(v.key == key, {val = i})};
	val;
}

)



//freeAll
(

~synths.keys.do{|key|
	~releaseSynth.value(key);
	~synthToggles.put(key, false);
};

)


//create the GUI mirror
(

var kLayout;


try{ w.close}{"no window yet".postln};
w=Window.new("GUI", 700@700).front;
w.view.decorator=FlowLayout(w.view.bounds);
w.view.decorator.gap=8@8;

~listView = EZListView.new(w,200@230, "Select Synth");

//todo make ordered
8.do{|i|
	var key = ("synth_"++(i+36)).asSymbol;
	~listView.addItem(key,{~switchSynth.value(key)});
};

//// Buttons

~releaseButton = Button.new(w,80@60);
~releaseButton.states_([["Start"],["Release", Color.black,Color.green]]);
~releaseButton.action = {|butt|
	if(butt.value == 1,{
		~startSynth.value(~cSynthKey)
	},{
		~releaseSynth.value(~cSynthKey)
	})

};


w.view.decorator.nextLine;

~sliders = [];

8.do{|i|
	var key = ("synth_36").asSymbol,
	slider = EZSlider.new(w, 400@20,
		label: ~synthSliderControls.at(key)[i][0].asString,
		initVal: ~synthSliderControls.at(key)[i][2],
		action: {|v|

			if(~cSynth != nil, {
			~cSynth.set(~synthSliderControls.at(~cSynthKey)[i][0],~synthSliderControls.at(~cSynthKey)[i][1].map(v.value));
			});
			~synthSliderControls.at(~cSynthKey)[i][2] = v.value
		}
	);

	~sliders = ~sliders.add(slider);
};

w.view.decorator.nextLine;

~potsSynced = Array.fill(8,{false});

~pots = [];


2.do{|r|
	4.do{|c|
		var i = r * 4 + c, key = ("synth_36").asSymbol,
		pot = EZKnob.new(w, 150@120,
			label: ~synthPotControls.at(key)[i][0].asString,
			initVal: ~synthPotControls.at(key)[i][2],
			action: {|v|

				if(~cSynth != nil, {
					~cSynth.set(~synthPotControls.at(~cSynthKey)[i][0],~synthPotControls.at(~cSynthKey)[i][1].map(v.value));
				});
				~synthPotControls.at(~cSynthKey)[i][2] = v.value
			}
		);
		{pot.setColors(knobColors: [Color.red])}.defer;
		~pots = ~pots.add(pot);
	};
	w.view.decorator.nextLine;
};

a.free;
a = MIDIFunc.cc({|val,id|
	var index = id - 70,
	spec = ControlSpec(0,127,\lin,1,0);

	{
		//get the current gui value

		if(~potsSynced.at(index) == true,{
			~pots.at(index).valueAction_(spec.unmap(val));

		},{
			var diff = (~pots[index].value - spec.unmap(val)).abs;
			if(diff <= (2/128),{
				~potsSynced[index] = true;
				~pots[index].setColors(knobColors: [Color.green]);

			},{diff.postln});
		});



	}.defer;
});


//// PADS


~pads.do({|v,i| ~pads[i].free});
~pads = [];

//top 4 momentary
4.do{|i|

	var val = i+40;

	~pads = ~pads.add(
		MIDIFunc.noteOn({|touchVel|
			~startSynth.value(("synth_"++val).asSymbol, touchVel);
	},val));

	~pads = ~pads.add(
		MIDIFunc.noteOff({
			~releaseSynth.value(("synth_"++val).asSymbol);
	},val));
};


//bottom 4
4.do{|i|
	var val = i+36;
	~pads = ~pads.add(
		MIDIFunc.noteOn({
			if(~synthToggles.at(("synth_"++val).asSymbol) == false,{
				~synthToggles.put(("synth_"++val).asSymbol, true);
				~startSynth.value(("synth_"++val).asSymbol);

			},{

				~releaseSynth.value(("synth_"++val).asSymbol);

			});

	},val));

};



)

/*
TODO:

- toggle autoSwitch on/off


*/
