-- proto.lua
--

local proto = [[

message Person {
    required string name = 1;
    required string address = 2;
    required int32 age = 3;
    optional Location location = 4;
}

message Location
{
    required string region = 1;
    optional string country = 2;
}

]]

return proto