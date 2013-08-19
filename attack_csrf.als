open models/basic
open models/crypto[Data]

-- module GoodServer
one sig GoodServer extends Module {
	cookies : Op -> Cookie,
	addr : lone Addr,
	protected : set Op,
}{
	all o : this.receives[(httpReq)] | o in protected implies some o.((httpReq) <: headers) & cookies[o]
	all o : this.sends[(httpResp)] | triggeredBy[o, httpReq]
}

-- module BadServer
one sig BadServer extends Module {
	addr : lone Addr,
}{
	all o : this.sends[(httpResp)] | triggeredBy[o, httpReq2]
}

-- module GoodClient
one sig GoodClient extends Module {
	cookies : Addr -> Cookie,
}{
	all o : this.sends[(httpReq)] | (some cookies[o.((httpReq) <: dest)] implies some o.((httpReq) <: headers) & cookies[o.((httpReq) <: dest)]) and ((o.((httpReq) <: headers) & Payload in creates) or (triggeredBy[o, httpResp] and some o.((httpReq) <: trigger).respHeaders & BadDOM))
	all o : this.sends[(httpReq2)] | (some cookies[o.((httpReq2) <: dest2)] implies some o.((httpReq2) <: headers2) & cookies[o.((httpReq2) <: dest2)]) and (no o.((httpReq2) <: headers2) & Payload)
}

fact trustedModuleFacts {
	TrustedModule = GoodServer + GoodClient
}
-- operation httpResp
sig httpResp extends Op {
	respHeaders : set Data,
}{
	args = respHeaders
	sender in GoodServer + BadServer
	receiver in GoodClient
}
-- operation httpReq
sig httpReq extends Op {
	headers : set Data,
	dest : lone Addr,
}{
	args = headers + dest
	sender in GoodClient
	receiver in GoodServer
}
-- operation httpReq2
sig httpReq2 extends Op {
	headers2 : set Data,
	dest2 : lone Addr,
}{
	args = headers2 + dest2
	sender in GoodClient
	receiver in BadServer
}
fact dataFacts {
	creates.Cookie in GoodServer
	creates.BadDOM in BadServer
	no creates.Addr
	no creates.Payload
}
sig Cookie extends Data {}
sig BadDOM extends Data {}
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
