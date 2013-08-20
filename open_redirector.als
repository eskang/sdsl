open models/basic
open models/crypto[Data]

-- module User
one sig User extends Module {
	visits : set Addr,
}{
	all o : this.sends[(visit)] | (some (visits & o.dest))
	not ((some (visits & BadServer.addr)))
}

-- module GoodClient
one sig GoodClient extends Module {
}{
	all o : this.sends[(httpReq)] | (((some (o.trigger & (visit)))) and (o.addr = o.trigger.addr)) or (((some (o.trigger & (httpResp)))) and (o.addr = o.trigger.redirect))
	all o : this.sends[(httpReq2)] | (((some (o.trigger & (visit)))) and (o.addr = o.trigger.addr)) or (((some (o.trigger & (httpResp)))) and (o.addr = o.trigger.redirect))
}

-- module BadServer
one sig BadServer extends Module {
	addr : lone Addr,
}
-- module GoodServer
one sig GoodServer extends Module {
	addr : lone Addr,
}
fact trustedModuleFacts {
	TrustedModule = GoodClient + GoodServer + User
}
-- operation httpReq
sig httpReq extends Op {
	addr : lone Data,
}{
	args = addr
	sender in GoodClient
	receiver in GoodServer
}
-- operation httpResp
sig httpResp extends Op {
	redirect : lone Data,
}{
	args = redirect
	sender in BadServer + GoodServer
	receiver in GoodClient
}
-- operation visit
sig visit extends Op {
	dest : lone Data,
}{
	args = dest
	sender in User
	receiver in GoodClient
}
-- operation httpReq2
sig httpReq2 extends Op {
	addr2 : lone Data,
}{
	args = addr2
	sender in GoodClient
	receiver in BadServer
}
fact dataFacts {
	no creates.Payload
}
sig Addr extends Data {}
sig Payload extends Data {}
sig OtherData extends Data {}
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
