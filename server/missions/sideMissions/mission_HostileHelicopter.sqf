private ["_missionMarkerName","_missionType","_picture","_vehicleName","_hint","_waypoint","_waypoints","_groupsm","_vehicles","_marker","_failed","_startTime","_numWaypoints","_ammobox","_createVehicle","_leader"];

#include "sideMissionDefines.sqf"

_missionMarkerName = "HostileHeli_Marker";
_missionType = "HostileHeli";

diag_log format["WASTELAND SERVER - Side Mission Started: %1", _missionType];

diag_log format["WASTELAND SERVER - Side Mission Waiting to run: %1", _missionType];
[sideMissionDelayTime] call createWaitCondition;
diag_log format["WASTELAND SERVER - Side Mission Resumed: %1", _missionType];

_groupsm = createGroup civilian;

_createVehicle = {
    private ["_type","_position","_direction","_groupsm","_vehicle","_soldier"];
    
    _type = _this select 0;
    _position = _this select 1;
    _direction = _this select 2;
    _groupsm = _this select 3;
    
    _vehicle = _type createVehicle _position;
    _vehicle setDir _direction;
    _groupsm addVehicle _vehicle;
    
    _soldier = [_groupsm, _position] call createRandomSoldier; 
    _soldier moveInDriver _vehicle;
    _vehicle
};

_vehicles = [];
_vehicles set [0, ["O_Ka60_F", [7096.54,5961.44,0.0016098], 110, _groupsm] call _createVehicle];

_leader = driver (_vehicles select 0);
_groupsm selectLeader _leader;
_leader setRank "LIEUTENANT";

_groupsm setCombatMode "WHITE";
_groupsm setBehaviour "AWARE";
_groupsm setFormation "STAG COLUMN";
_groupsm setSpeedMode "LIMITED";

_waypoints = [
    [7096.54,5961.44,0.0016098],
    [6421.47,5425.19,0.00143147],
    [4368.64,3818.18,0.00146484],
    [5027.28,5904.69,0.00134277],
    [2695.63,5802.37,0.00144649],
    [1955.14,3525.81,0.00142336],
    [2984.66,1869.46,0.00144958],
    [4601.99,5296.73,0.00160217],
    [4368.64,3818.18,0.00146484],
    [5027.28,5904.69,0.00134277],
    [2695.63,5802.37,0.00144649],
    [1955.14,3525.81,0.00142336],
    [2984.66,1869.46,0.00144958],
    [4601.99,5296.73,0.00160217],
    [1886.15,5728.88,0.00145006]
];
{
    _waypoint = _groupsm addWaypoint [_x, 0];
    _waypoint setWaypointType "MOVE";
    _waypoint setWaypointCompletionRadius 55;
    _waypoint setWaypointCombatMode "WHITE"; // Defensiv behaviour
    _waypoint setWaypointBehaviour "AWARE"; // Force convoy to normaly drive on the street.
    _waypoint setWaypointFormation "STAG COLUMN";
    _waypoint setWaypointSpeed "LIMITED";
} forEach _waypoints;

_marker = createMarker [_missionMarkerName, position leader _groupsm];
_marker setMarkerType "mil_destroy";
_marker setMarkerSize [1.25, 1.25];
_marker setMarkerColor "ColorRed";
_marker setMarkerText "Hostile Helicopter";

_picture = getText (configFile >> "CfgVehicles" >> "O_Ka60_F" >> "picture");
_vehicleName = getText (configFile >> "cfgVehicles" >> "O_Ka60_F" >> "displayName");
_hint = parseText format ["<t align='center' color='%4' shadow='2' size='1.75'>!! WARNING !!</t><br/><t align='center' color='%4'>------------------------------</t><br/><t align='center' color='%5' size='1.25'>%1</t><br/><t align='center'><img size='5' image='%2'/></t><br/><t align='center' color='%5'>A armed <t color='%4'>%3</t> is patrolling the island. Destroy or steal it!</t>", _missionType, _picture, _vehicleName, sideMissionColor, subTextColor];
messageSystem = _hint;
if (!isDedicated) then { call serverMessage };
publicVariable "messageSystem";

diag_log format["WASTELAND SERVER - Side Mission Waiting to be Finished: %1", _missionType];

_failed = false;
_startTime = floor(time);
_numWaypoints = count waypoints _groupsm;
waitUntil
{
    private ["_unitsAlive"];
    
    sleep 10; 
    
    _marker setMarkerPos (position leader _groupsm);
    
    if ((floor time) - _startTime >= sideMissionTimeout) then { _failed = true };
    if (currentWaypoint _groupsm >= _numWaypoints) then { _failed = true }; // Convoy got successfully to the target location
    _unitsAlive = { alive _x } count units _groupsm;
    
    _unitsAlive == 0 || _failed
};

if(_failed) then
{
    // Mission failed
    deleteVehicle _vehicle;
    {deleteVehicle _x;}forEach units _groupsm; 
	deleteGroup _groupsm; 
    _hint = parseText format ["<t align='center' color='%4' shadow='2' size='1.75'>! NOTICE !</t><br/><t align='center' color='%4'>------------------------------</t><br/><t align='center' color='%5' size='1.25'>%1</t><br/><t align='center'><img size='5' image='%2'/></t><br/><t align='center' color='%5'>The patrol ended, the enemy has survived and escaped</t>", _missionType, _picture, _vehicleName, failMissionColor, subTextColor];
    messageSystem = _hint;
    if (!isDedicated) then { call serverMessage };
    publicVariable "messageSystem";
    diag_log format["WASTELAND SERVER - Side Mission Failed: %1",_missionType];
} else {
    // Mission complete

    _ammobox = "Box_NATO_Wps_F" createVehicle getMarkerPos _marker;
    clearMagazineCargoGlobal _ammobox;
    clearWeaponCargoGlobal _ammobox; 
    [_ammobox,"mission_Side_USSpecial"] call fn_refillbox;
    _hint = parseText format ["<t align='center' color='%4' shadow='2' size='1.75'>PATROL IS DOWN</t><br/><t align='center' color='%4'>------------------------------</t><br/><t align='center' color='%5' size='1.25'>%1</t><br/><t align='center'><img size='5' image='%2'/></t><br/><t align='center' color='%5'>The sky is clear agian, the enemy patrol was taken out!</t>", _missionType, _picture, _vehicleName, successMissionColor, subTextColor];
    messageSystem = _hint;
    if (!isDedicated) then { call serverMessage };
    publicVariable "messageSystem";
    diag_log format["WASTELAND SERVER - Side Mission Success: %1",_missionType];
};

deleteMarker _marker;
