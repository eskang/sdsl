open models/basic
open models/crypto[Data]

-- module User
one sig User extends Module {
	intents : set Addr,
}{
	all o : this.sends[visit] | (some (intents & o.(visit <: dest)))
	(not (some (intents & MaliciousServer.addr)))
}

-- module Client
one sig Client extends Module {
}{
	all o : this.sends[httpReq] | 
		((triggeredBy[o,visit] and o.(httpReq <: addr) = o.trigger.dest)
		or
		(triggeredBy[o,httpResp] and o.(httpReq <: addr) = o.trigger.redirect)
		)
	all o : this.sends[httpReq2] | 
		((triggeredBy[o,visit] and o.(httpReq2 <: addr2) = o.trigger.dest)
		or
		(triggeredBy[o,httpResp] and o.(httpReq2 <: addr2) = o.trigger.redirect)
		)
}

-- module MaliciousServer
one sig MaliciousServer extends Module {
	addr : lone Addr,
}
-- module TrustedServer
one sig TrustedServer extends Module {
	addr : lone Addr,
}{
	all o : this.sends[httpResp] | triggeredBy[o,httpReq]
}


-- fact trustedModuleFacts
fact trustedModuleFacts {
	TrustedModule = Client + TrustedServer + User
}

-- operation httpReq
sig httpReq extends Op {
	addr : lone Data,
}{
	args = addr
	sender in Client
	receiver in TrustedServer
}

-- operation httpResp
sig httpResp extends Op {
	redirect : lone Data,
}{
	args = redirect
	sender in MaliciousServer + TrustedServer
	receiver in Client
}

-- operation visit
sig visit extends Op {
	dest : lone Data,
}{
	args = dest
	sender in User
	receiver in Client
}

-- operation httpReq2
sig httpReq2 extends Op {
	addr2 : lone Data,
}{
	args = addr2
	sender in Client
	receiver in MaliciousServer
}

-- datatype declarations
sig Addr extends Data {
}{
	no fields
}
sig Payload extends Data {
}{
	no fields
}
sig OtherData extends Data {}{ no fields }

-- fact criticalDataFacts
fact criticalDataFacts {
	CriticalData = Payload
}


fun RelevantOp : Op -> Step {
	{o : Op, t : Step | o.post = t and o in SuccessOp}
}

run SanityCheck {
	all m : Module |
		some sender.m & SuccessOp
} for 5 but 9 Data, 10 Step, 9 Op

check Confidentiality {
   Confidentiality 
} for 5 but 9 Data, 10 Step, 9 Op

check Integrity {
   Integrity
} for 5 but 9 Data, 10 Step, 9 Op
