module baisc

open util/ordering[Step] as SO

sig Step {}

/**
	* Generic part of the model
	*/
abstract sig Data {
	fields : set Data
}
abstract sig Module {
	accesses : Data -> Step,
	creates : set Data,
}{
	creates.fields in creates

	all d : Data, t : Step |
		d in accesses.t implies {
			(t not in SO/first and d in accesses.(t.prev)) or
			(t in SO/first and d in (creates + creates.fields)) or
			some m2 : Module - this | flows[m2, this, d, t]
		}
}
pred flows[from, to : Module, d : Data, t : Step] {
	(some o : SuccessOp {
		t = o.post
		((from = o.sender and to = o.receiver and d in (o.args + o.args.fields)))
	})
}

-- operations
fun SuccessOp : set Op {
	receiver.Module
}

abstract sig Op {
	pre, post : Step,
	trigger : lone Op,
	sender : Module,
	receiver : lone Module,
	args : set Data
}{
	(args + args.fields) in sender.accesses.pre
	post = pre.next
	pre = SO/first implies no trigger
	some trigger implies {
		trigger.@post = pre
		trigger.@receiver = sender
	}
}
fun receives[m : Module, es : set Op] : set Op {
	receiver.m & es
}

fun sends[m : Module, es : set Op]  : set Op {
	sender.m & es
}

-- some helper predicates/functions
pred triggeredBy[o : Op, t : set Op] {
	some o.trigger & t
}

-- propertiess
sig CriticalData in Data {}
sig GoodData, BadData in CriticalData {}
fact DataFacts {
	no GoodData & BadData
	CriticalData = GoodData + BadData
	creates.GoodData in TrustedModule
	creates.BadData in UntrustedModule
}
sig TrustedModule, UntrustedModule in Module {}
sig ProtectedModule in Module {}
fact {
	Module = TrustedModule + UntrustedModule
	no TrustedModule & UntrustedModule
	ProtectedModule in TrustedModule
}

pred Confidentiality {
	no m : UntrustedModule, t : Step |
		some m.accesses.t & GoodData
}	

pred Integrity {
	no m : ProtectedModule, t : Step |
		some m.accesses.t & BadData
}

fun arg[d : Data] : set Data {
	d + d.fields
}

