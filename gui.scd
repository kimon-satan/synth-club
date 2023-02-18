// functions
(

// a function which removes all sliders
~clearSliders = { ~sliders.do{|val|val.remove} };
// a function which removes all pots
~clearPots = {~pots.do{|val| val.remove} };

~createSliders = {|key|

	~sliderView.decorator=FlowLayout(~sliderView.bounds, Point(20,20),8@4);
	~sliders = [];

	~synthSliderControls.at(key).size().do{|i|
		var slider = EZSlider.new(~sliderView, 400@20,
			label: ~synthSliderControls.at(key)[i][0].asString,
			initVal: ~synthSliderControls.at(key)[i][2],
			action: {|v|
				if(~cSynth != nil, {
					~cSynth.set(~synthSliderControls.at(key)[i][0],~synthSliderControls.at(key)[i][1].map(v.value));
				});
				~synthSliderControls.at(key)[i][2] = v.value
			}
		);

		~sliders = ~sliders.add(slider);
	};
};

~createPots = {|key|
	~potsSynced = Array.fill(8,{false});
	~pots = [];
	~potsView.decorator=FlowLayout(~potsView.bounds, Point(20,20),8@4);

	2.do{|r|
		4.do{|c|
			var i = r * 4 + c,
			pot = EZKnob.new(~potsView, 150@120,
				label: ~synthPotControls.at(key)[i][0].asString,
				initVal: ~synthPotControls.at(key.asSymbol)[i][2],
				action: {|v|
					if(~cSynth != nil, {
						~cSynth.set(~synthPotControls.at(key)[i][0],~synthPotControls.at(key)[i][1].map(v.value));
					});
					~synthPotControls.at(key.asSymbol)[i][2] = v.value;
				}
			);
			{pot.setColors(knobColors: [Color.red])}.defer;
			~pots = ~pots.add(pot);

		};
		~potsView.decorator.nextLine;
	};
};

~updatePot = {|potIndex, val|
	~pots[potIndex].value = val;
	~potsSynced[potIndex] = false;
	~pots[potIndex].setColors(knobColors: [Color.red]);
};

~findIndex = {|list, key|
	var val = nil;
	list.do{|v,i| if(v.key == key, {val = i})};
	val;
};

~switchSynthGui ={|key|
	key.postln;
	~clearSliders.value;
	~clearPots.value;
	~createSliders.value(key);
	~createPots.value(key);
	{
		~listView.value = ~findIndex.value(~listView.items, key);
		if(~synthToggles.at(key) == true,
			{~releaseButton.value = 1;
				~releaseButton.value.postln;
			},
			{~releaseButton.value = 0});

		~synthDefView.value = ~findIndex.value(~synthDefView.items, ~synthTypes.at(key));

	}.defer;
}

)


//reset pots to zero
8.do{|i|{~updatePot.value(i,0)}.defer};

//create the GUI mirror
(

var kLayout;

try{ w.close}{"no window yet".postln};
w=Window.new("GUI", 800@800).front;

w.view.decorator=FlowLayout(w.view.bounds, Point(10,10));
w.view.decorator.gap=8@8;

~listView = EZListView.new(w,200@230, "Select Synth");

//todo make ordered
8.do{|i|
	var key = ("synth_"++(i+36)).asSymbol;
	~listView.addItem(key,{
		~switchSynth.value(key);
		~switchSynthGui.value(key);
	});
};

~synthDefView = EZListView.new(w,200@230, "Change SynthDefs");

~sliderTemplates.keys.do({|key|
	~synthDefView.addItem(key,{
		if(~cSynth != nil, {
			~releaseSynth.value(~cSynthKey);
			{~releaseButton.value = 0}.defer
		});
		~setSynthType.value(~cSynthKey, key);
		~switchSynthGui.value(~cSynthKey);
	});

});


//// Buttons

~releaseButton = Button.new(w,80@60);
~releaseButton.states_([["Start"],["Release", Color.black,Color.green]]);
~releaseButton.action = {|butt|
	if(butt.value == 1,{
		~synthToggles.put(~cSynthKey, true);
		~startSynth.value(~cSynthKey);

	},{
		~releaseSynth.value(~cSynthKey);
		~releaseButton.value = 0;
	})

};


w.view.decorator.nextLine;

~sliderView = CompositeView(w,700@300);
~sliderView.background = Color.magenta.alpha_(0.3);

w.view.decorator.nextLine;

~potsView = CompositeView(w,700@300);
~potsView.background = Color.green.alpha_(0.3);

~switchSynthGui.value(~cSynthKey);

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
			var key = "synth_"++val;
			~startSynth.value((key).asSymbol, touchVel);
	},val));

	~pads = ~pads.add(
		MIDIFunc.noteOff({
			~releaseSynth.value(("synth_"++val).asSymbol);
			{~releaseButton.value = 0;}.defer;
	},val));
};

//bottom 4
4.do{|i|
	var val = i+36;
	~pads = ~pads.add(
		MIDIFunc.noteOn({
			var key = ("synth_"++val).asSymbol;
			if(~synthToggles.at(key) == false,{
				~synthToggles.put(key, true);
				~startSynth.value(key);
				{~switchSynthGui.value(key)}.defer;
			},{
				if(~synths.at(key) == ~cSynth,{
					{~releaseButton.value = 0;}.defer});
				~releaseSynth.value(key);
			});

	},val));

};

)