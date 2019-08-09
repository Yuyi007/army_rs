class('SystemStatusUtil')

local m = SystemStatusUtil

SystemStatusUtil.rttLv1 = 150
SystemStatusUtil.rttLv2 = 80

SystemStatusUtil.NetworkReachability = {}
SystemStatusUtil.NetworkReachability.NotReachable = 0
SystemStatusUtil.NetworkReachability.ReachableViaCarrierDataNetwork = 0
SystemStatusUtil.NetworkReachability.ReachableViaLocalAreaNetwork = 0