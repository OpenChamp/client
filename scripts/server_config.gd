extends Node

# This singleton will store configurable info about the server, such as custom balance values and settings.

# These would be consts, but they need to be server-modifiable for custom balancing.
var stunned_cc_mask := 0b001111
var snared_cc_mask := 0b000011
var disarmed_cc_mask := 0b000100
var silenced_cc_mask := 0b001010
var grounded_cc_mask := 0b000010
var stasis_cc_mask := 0b101111
