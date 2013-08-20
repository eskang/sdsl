open models/basic
open models/crypto[Data]

-- module Receiver_EndpointB
one sig Receiver_EndpointB extends Module {
	key : lone Key,
}
-- module Eavesdropper
one sig Eavesdropper extends Module {
}
-- module Sender_EndpointA
one sig Sender_EndpointA extends Module {
	resource : set Resource,
	key : lone Key,
}
-- module Channel
one sig Channel extends Module {
}{
	all o : this.sends[(emit)] | (some (o.trigger & (probe)))
}

-- operation probe
sig probe extends Op {
	data : lone Data,
}{
	args = data
	sender in Eavesdropper
	receiver in Channel
}
-- operation deliver
sig deliver extends Op {
	data : lone Data,
}{
	args = data
	sender in Channel
	receiver in Sender_EndpointA
}
-- operation send_deliver
sig send_deliver extends Op {
	msg : lone Data,
	data : lone Data,
}{
	args = msg + data
	sender in Sender_EndpointA + Channel + Channel
	receiver in Receiver_EndpointB
}
-- operation transmit
sig transmit extends Op {
	data : lone Data,
}{
	args = data
	sender in Receiver_EndpointB + Sender_EndpointA
	receiver in Channel
}
-- operation emit
sig emit extends Op {
	data : lone Data,
}{
	args = data
	sender in Channel
	receiver in Eavesdropper
}
fact dataFacts {
	creates.Resource in Receiver_EndpointB + Sender_EndpointA + Sender_EndpointA
	creates.Ciphertext in Receiver_EndpointB + Sender_EndpointA
	creates.Resource in Receiver_EndpointB + Sender_EndpointA + Sender_EndpointA
}
sig Resource extends Data {}
sig Ciphertext extends Data {}
sig Resource extends Data {}
sig OtherData extends Data {}
fact criticalDataFacts {
	CriticalData = Resource + Resource
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
