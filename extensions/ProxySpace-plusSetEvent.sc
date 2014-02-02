+ ProxySpace {
	setEvent { |event|
		var out = (type: \psSet, proxyspace: this, gt: 1, t_trig: 1);
		if(event.isKindOf(Dictionary)) { out.putAll(event) };
		^out
	}
}
