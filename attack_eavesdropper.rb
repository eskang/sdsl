# attack_eavesdropper.rb
# model of a network eavesdropper
#

require 'view.rb'

ep1 = mod :EndpointA do 
  creates :Resource
  exports(:deliver,
          :args => [:data])
  invokes(:transmit)
end

channel = mod :Channel do
  exports(:transmit, 
          :args => [:data])
  exports(:probe,
          :args => [:data])
  invokes(:deliver)
  invokes(:emit,
          :when => triggeredBy(:probe))
end

eavesdropper = mod :Eavesdropper do
  exports(:emit, 
          :args => [:data])
  invokes(:probe)
end

ep2 = mod :EndpointB do
  creates :Resource
  exports(:deliver,
          :args => [:data])
  invokes(:transmit)
end

V_EAVESDROPPER = view :Eavesdropper do
  modules ep1, ep2, channel, eavesdropper
  trusted ep1, ep2, channel
  data :Resource
  critical :Resource
end

# drawView V_EAVESDROPPER
# dumpAlloy V_EAVESDROPPER
